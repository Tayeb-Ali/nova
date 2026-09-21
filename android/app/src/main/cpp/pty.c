/*
 * pty.c — minimal forkpty JNI shim for Nova IDE.
 *
 * Native read loop posts output/exit via a Kotlin callback so terminal
 * output is batched on the Kotlin side without JNI churn per byte.
 */
#include <jni.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <pty.h>

#include <android/log.h>
#define LOG_TAG "NovaPty"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

/* First-hop exec policy lives in NovaExecLauncher (Kotlin); these spellings
 * mirror EnvironmentManager.ENV_EXEC_MODE/EXEC_MODE_LINKER/SYSTEM_LINKER. */
#define NOVA_EXEC_MODE_ENTRY "NOVA_EXEC_MODE=linker"
#define NOVA_SYSTEM_LINKER "/system/bin/linker64"

typedef struct {
    int master_fd;
    pid_t child_pid;
} pty_handle;

static JavaVM* g_vm = NULL;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_vm = vm;
    return JNI_VERSION_1_6;
}

typedef struct {
    JavaVM* vm;
    jobject callback; /* global ref to PtyCallback */
    jmethodID on_data;
    jmethodID on_exit;
    int master_fd;
    pid_t child_pid;
} reader_args;

static void* reader_thread(void* arg) {
    reader_args* a = (reader_args*)arg;
    JNIEnv* env = NULL;
    (*a->vm)->AttachCurrentThread(a->vm, &env, NULL);

    char buf[4096];
    ssize_t n;
    while ((n = read(a->master_fd, buf, sizeof(buf))) > 0) {
        jbyteArray arr = (*env)->NewByteArray(env, (jsize)n);
        (*env)->SetByteArrayRegion(env, arr, 0, (jsize)n, (jbyte*)buf);
        (*env)->CallVoidMethod(env, a->callback, a->on_data, arr);
        (*env)->DeleteLocalRef(env, arr);
    }

    int status = 0;
    if (a->child_pid > 0) {
        waitpid(a->child_pid, &status, 0);
    }
    int exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    if (WIFSIGNALED(status)) {
        exit_code = 128 + WTERMSIG(status);
    }
    LOGI("pty session ended exit=%d", exit_code);

    (*env)->CallVoidMethod(env, a->callback, a->on_exit, (jint)exit_code);
    (*env)->DeleteGlobalRef(env, a->callback);
    (*a->vm)->DetachCurrentThread(a->vm);
    free(a);
    return NULL;
}

JNIEXPORT jlong JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeOpen(
        JNIEnv* env, jclass clazz,
        jstring exe, jobjectArray argv, jobjectArray envp, jstring cwd,
        jint cols, jint rows) {
    const char* exe_c = (*env)->GetStringUTFChars(env, exe, NULL);
    jsize argc = (*env)->GetArrayLength(env, argv);
    jsize envc = (*env)->GetArrayLength(env, envp);
    const char* cwd_c = cwd ? (*env)->GetStringUTFChars(env, cwd, NULL) : NULL;

    char** argv_c = calloc((size_t)argc + 1, sizeof(char*));
    for (jsize i = 0; i < argc; i++) {
        jstring s = (jstring)(*env)->GetObjectArrayElement(env, argv, i);
        argv_c[i] = (char*)(*env)->GetStringUTFChars(env, s, NULL);
    }
    argv_c[argc] = NULL;

    char** envp_c = calloc((size_t)envc + 1, sizeof(char*));
    for (jsize i = 0; i < envc; i++) {
        jstring s = (jstring)(*env)->GetObjectArrayElement(env, envp, i);
        envp_c[i] = (char*)(*env)->GetStringUTFChars(env, s, NULL);
    }
    envp_c[envc] = NULL;

    int master = -1;
    pid_t pid = forkpty(&master, NULL, NULL, NULL);
    if (pid < 0) {
        LOGE("forkpty failed: %s", strerror(errno));
        (*env)->ReleaseStringUTFChars(env, exe, exe_c);
        if (cwd_c) (*env)->ReleaseStringUTFChars(env, cwd, cwd_c);
        for (jsize i = 0; i < argc; i++)
            (*env)->ReleaseStringUTFChars(env, (jstring)(*env)->GetObjectArrayElement(env, argv, i), argv_c[i]);
        for (jsize i = 0; i < envc; i++)
            (*env)->ReleaseStringUTFChars(env, (jstring)(*env)->GetObjectArrayElement(env, envp, i), envp_c[i]);
        free(argv_c);
        free(envp_c);
        return -1;
    }

    if (pid == 0) {
        /* child */
        if (cwd_c && chdir(cwd_c) != 0) {
            perror("chdir");
        }
        extern char** environ;
        environ = envp_c;
        /* Final execve only — policy lives in NovaExecLauncher (Kotlin).
         * LD_PRELOAD never covers this first hop, so in linker mode name the
         * system linker explicitly with the real target as its argument.
         * exe is always an absolute prefix ELF here (bash); scripts are
         * handled Kotlin-side. */
        int linker_mode = 0;
        for (jsize e = 0; e < envc; e++) {
            if (strncmp(envp_c[e], NOVA_EXEC_MODE_ENTRY, sizeof(NOVA_EXEC_MODE_ENTRY) - 1) == 0) {
                linker_mode = 1;
                break;
            }
        }
        if (linker_mode && exe_c[0] == '/') {
            char** largv = calloc((size_t)argc + 3, sizeof(char*));
            if (largv) {
                largv[0] = (char*)NOVA_SYSTEM_LINKER;
                largv[1] = (char*)exe_c;
                for (jsize i = 1; i < argc; i++) largv[i + 1] = argv_c[i];
                largv[argc + 1] = NULL;
                LOGI("linker first-hop: %s", exe_c);
                execve(NOVA_SYSTEM_LINKER, largv, envp_c);
                perror("execve linker64");
                free(largv);
                _exit(127);
            }
        }
        execve(exe_c, argv_c, envp_c);
        perror("execve");
        _exit(127);
    }

    /* parent */
    if (cols > 0 && rows > 0) {
        struct winsize ws;
        ws.ws_col = (unsigned short)cols;
        ws.ws_row = (unsigned short)rows;
        ws.ws_xpixel = 0;
        ws.ws_ypixel = 0;
        ioctl(master, TIOCSWINSZ, &ws);
    }

    (*env)->ReleaseStringUTFChars(env, exe, exe_c);
    if (cwd_c) (*env)->ReleaseStringUTFChars(env, cwd, cwd_c);
    for (jsize i = 0; i < argc; i++)
        (*env)->ReleaseStringUTFChars(env, (jstring)(*env)->GetObjectArrayElement(env, argv, i), argv_c[i]);
    for (jsize i = 0; i < envc; i++)
        (*env)->ReleaseStringUTFChars(env, (jstring)(*env)->GetObjectArrayElement(env, envp, i), envp_c[i]);
    free(argv_c);
    free(envp_c);

    pty_handle* h = malloc(sizeof(pty_handle));
    h->master_fd = master;
    h->child_pid = pid;
    LOGI("opened pty master=%d pid=%d", master, pid);
    return (jlong)(intptr_t)h;
}

JNIEXPORT jint JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeWrite(
        JNIEnv* env, jclass clazz, jlong handle, jbyteArray data) {
    pty_handle* h = (pty_handle*)(intptr_t)handle;
    if (!h || h->master_fd < 0) return -1;
    jsize len = (*env)->GetArrayLength(env, data);
    jbyte* buf = (*env)->GetByteArrayElements(env, data, NULL);
    ssize_t n = write(h->master_fd, buf, (size_t)len);
    (*env)->ReleaseByteArrayElements(env, data, buf, JNI_ABORT);
    return (jint)n;
}

JNIEXPORT jint JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeResize(
        JNIEnv* env, jclass clazz, jlong handle, jint cols, jint rows) {
    pty_handle* h = (pty_handle*)(intptr_t)handle;
    if (!h || h->master_fd < 0) return -1;
    struct winsize ws;
    ws.ws_col = (unsigned short)cols;
    ws.ws_row = (unsigned short)rows;
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;
    return ioctl(h->master_fd, TIOCSWINSZ, &ws);
}

JNIEXPORT void JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeSignal(
        JNIEnv* env, jclass clazz, jlong handle, jint signal) {
    pty_handle* h = (pty_handle*)(intptr_t)handle;
    if (!h || h->child_pid <= 0) return;
    kill(h->child_pid, signal);
}

JNIEXPORT void JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeClose(
        JNIEnv* env, jclass clazz, jlong handle) {
    pty_handle* h = (pty_handle*)(intptr_t)handle;
    if (!h) return;
    if (h->child_pid > 0) {
        kill(h->child_pid, SIGHUP);
    }
    if (h->master_fd >= 0) {
        close(h->master_fd); /* EOF on master -> reader thread exits & reaps */
    }
    free(h);
}

JNIEXPORT void JNICALL
Java_sd_adaa_codeide_terminal_PtyNative_nativeStartReader(
        JNIEnv* env, jclass clazz, jlong handle, jobject callback) {
    pty_handle* h = (pty_handle*)(intptr_t)handle;
    if (!h) return;

    jclass cb_cls = (*env)->GetObjectClass(env, callback);
    jmethodID on_data = (*env)->GetMethodID(env, cb_cls, "onData", "([B)V");
    jmethodID on_exit = (*env)->GetMethodID(env, cb_cls, "onExit", "(I)V");
    if (!on_data || !on_exit) {
        LOGE("failed to resolve PtyCallback methods");
        return;
    }

    reader_args* a = calloc(1, sizeof(reader_args));
    a->vm = g_vm;
    a->callback = (*env)->NewGlobalRef(env, callback);
    a->on_data = on_data;
    a->on_exit = on_exit;
    a->master_fd = h->master_fd;
    a->child_pid = h->child_pid;

    pthread_t thread;
    if (pthread_create(&thread, NULL, reader_thread, a) != 0) {
        LOGE("pthread_create failed");
        (*env)->DeleteGlobalRef(env, a->callback);
        free(a);
    }
    pthread_detach(thread);
}