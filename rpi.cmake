set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

#set(CMAKE_SYSROOT /home/schuetz/raspberry_pi/sysroot)
#set(CMAKE_STAGING_PREFIX /home/schuetz/stage)

set(tools /home/schuetz/raspberry_pi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin)
set(CMAKE_C_COMPILER ${tools}/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER ${tools}/arm-linux-gnueabihf-g++)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(WITH_TLS OFF)
set(WITH_SRV OFF)
set(WITH_THREADING OFF)

message(STATUS "using Raspberry Pi toolchain")
