cmake_minimum_required(VERSION 3.25)
project(dpi_example NONE)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "questa;vivado_sim;modelsim;xcelium;vcs;verilator;all" "modelsim")
if(SIMULATOR STREQUAL "all")
    set(ALL_SIMS TRUE)
endif()

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} SYSTEMVERILOG
    ${PROJECT_SOURCE_DIR}/tb.sv
    )

add_subdirectory(hello)

ip_link(${IP} hello_dpi)

if(SIMULATOR STREQUAL "questa" OR SIMULATOR STREQUAL "modelsim" OR ALL_SIMS)
    modelsim(${IP})
endif()

if(SIMULATOR STREQUAL "xcelium" OR ALL_SIMS)
    xcelium(${IP})
endif()

if(SIMULATOR STREQUAL "vivado_sim" OR ALL_SIMS)
    vivado_sim(${IP})
endif()

if(SIMULATOR STREQUAL "vcs" OR ALL_SIMS)
    vcs(${IP})
endif()

if(SIMULATOR STREQUAL "verilator" OR ALL_SIMS)
    enable_language(CXX)
    verilator(${IP})
    add_executable(verilator_tb EXCLUDE_FROM_ALL Vtb__main.cpp )
    target_link_libraries(verilator_tb tb__vlt)
endif()

help()
