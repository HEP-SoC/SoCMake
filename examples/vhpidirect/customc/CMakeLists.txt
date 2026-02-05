include("../../../SoCMakeConfig.cmake")
cmake_minimum_required(VERSION 3.28)
project(vhpidirect_customc C)

add_ip(tb)

ip_sources(tb VHDL
    ./tb.vhd
    )

add_library(customc STATIC
    ./main.c
    )

ip_link(${IP}
    customc)
ghdl(${IP})

