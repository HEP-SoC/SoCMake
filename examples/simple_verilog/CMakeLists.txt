cmake_minimum_required(VERSION 3.25)
project(simple_verilog_example CXX C)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "iverilog;vivado_sim;questa;modelsim;xcelium;vcs;verilator;all" "iverilog")
if(SIMULATOR STREQUAL "all")
    set(ALL_SIMS TRUE)
endif()

add_ip(tb
    DESCRIPTION "Simple verilog testbench")

ip_sources(${IP} VERILOG
    tb.v)

add_subdirectory(adder)
ip_link(${IP} adder)

if(SIMULATOR STREQUAL "iverilog" OR ALL_SIMS)
    iverilog(${IP})
endif()

if(SIMULATOR STREQUAL "questa" OR ALL_SIMS)
    questasim(${IP})
endif()

if(SIMULATOR STREQUAL "modelsim" OR ALL_SIMS)
    modelsim(${IP})
endif()

if(SIMULATOR STREQUAL "vivado_sim" OR ALL_SIMS)
    vivado_sim(${IP})
endif()

if(SIMULATOR STREQUAL "xcelium" OR ALL_SIMS)
    xcelium(${IP})
endif()

if(SIMULATOR STREQUAL "verilator" OR ALL_SIMS)
    verilator(${IP} MAIN VERILATOR_ARGS --timing)
endif()

if(SIMULATOR STREQUAL "vcs" OR ALL_SIMS)
    vcs(${IP})
endif()


help()
