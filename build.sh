mkdir build
cd build
export CC=/home/schuetz/raspberry_pi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc 
export CXX=/home/schuetz/raspberry_pi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-g++ 
cmake .. -DWITH_TLS=OFF -DWITH_SRV=OFF -DWITH_THREADING=OFF
make -j
