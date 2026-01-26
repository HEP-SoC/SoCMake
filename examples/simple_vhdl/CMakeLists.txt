cmake_minimum_required(VERSION 3.25)
project(simple_mixed_language NONE)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "ghdl;questa;vivado_sim;modelsim;xcelium;vcs;all" "ghdl")
if(SIMULATOR STREQUAL "all")
    set(ALL_SIMS TRUE)
endif()

add_ip(tb
    DESCRIPTION "Simple verilog testbench")

ip_sources(${IP} VHDL
    tb.vhdl)

add_subdirectory(adder)
ip_link(${IP} adder)

if(SIMULATOR STREQUAL "questa" OR ALL_SIMS)
    questasim(${IP})
endif()

if(SIMULATOR STREQUAL "modelsim" OR ALL_SIMS)
    modelsim(${IP})
endif()

if(SIMULATOR STREQUAL "vivado_sim" OR ALL_SIMS)
    vivado_sim(${IP} XVHDL_ARGS -2008)
endif()

if(SIMULATOR STREQUAL "xcelium" OR ALL_SIMS)
    xcelium(${IP} VHDL_COMPILE_ARGS -V200x)
endif()

if(SIMULATOR STREQUAL "vcs" OR ALL_SIMS)
    vcs(${IP})
endif()

if(SIMULATOR STREQUAL "ghdl" OR ALL_SIMS)
    ghdl(${IP})
endif()

help()
