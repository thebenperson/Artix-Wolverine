#!/usr/bin/env sh

# shell script to test the MIDI module

# the virtual keyboard program VMPK sends UDP packets to a multicast
# address; this script listens to the multicast address and pipes the
# data into the testbench

address=225.0.0.37
port=21928

make test=midi || exit

# enable multicast routing to the loopback device
sudo ip route add $address dev lo

cd src

# listen to the virtual keyboard's multicast address and pipe the data
# to the testbench

socat UDP4-RECV:$port,ip-add-membership=$address:lo - | vvp ../bin/a.out -fst

# disable multicast routing to the loopback device
sudo ip route del $address
