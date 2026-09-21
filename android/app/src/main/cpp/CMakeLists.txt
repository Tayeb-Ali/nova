cmake_minimum_required(VERSION 3.22.1)
project(pty_jni C)

add_library(pty SHARED pty.c)

target_link_libraries(pty
    log
)

# Phase 1 steps 3-4: Nova values baked in (was: upstream com.termux defaults
# for the step-2 baseline build, which passed). Output renamed to nova-exec.
# Plain set() (NOT CACHE): CMake never refreshes a cached default, which
# silently keeps stale values across reconfigures — these are build constants
# owned by this file, so they must always come from here.
set(NOVA_BASE_DIR "/data/user/0/sd.adaa.codeide/files")
set(NOVA_PREFIX "${NOVA_BASE_DIR}/usr")
add_library(novaexec SHARED
    novaexec/termux-exec.c
    novaexec/exec-variants.c
    novaexec/termux-readlink.c
    novaexec/termux-realpath.c
)
target_compile_definitions(novaexec PRIVATE
    TERMUX_BASE_DIR="${NOVA_BASE_DIR}"
    TERMUX_PREFIX="${NOVA_PREFIX}"
)
target_compile_options(novaexec PRIVATE -Wall -Wextra -Wshadow -fvisibility=hidden)
set_target_properties(novaexec PROPERTIES C_STANDARD 23 OUTPUT_NAME "nova-exec")
target_link_libraries(novaexec
    log
    dl
)