include("../../../SoCMakeConfig.cmake")
cmake_minimum_required(VERSION 3.27)
project(vhpidirect_customc C)

option_enum(SIMULATOR "Which simulator to use" "ghdl;nvc" "ghdl")

add_ip(tb)

ip_sources(tb VHDL
    ./tb.vhd
    )

add_library(customc SHARED
    ./main.c
    )

ip_link(${IP}
    customc)

if(SIMULATOR STREQUAL "ghdl")
    ghdl(${IP})
endif()

if(SIMULATOR STREQUAL "nvc")
    nvc(${IP})
endif()

help()
