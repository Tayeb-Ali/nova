cmake_minimum_required(VERSION 3.22.1)
project(pty_jni C)

add_library(pty SHARED pty.c)

target_link_libraries(pty
    log
)