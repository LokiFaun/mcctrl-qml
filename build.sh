mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../rpi.cmake
make -j
