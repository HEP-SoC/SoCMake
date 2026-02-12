include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "questa;vivado_sim;xcelium;vcs;verilator;all" "questasim")

if(SIMULATOR STREQUAL "questa")
    questasim_configure_cxx(LIBRARIES DPI-C)
elseif(SIMULATOR STREQUAL "xcelium")
    xcelium_configure_cxx(LIBRARIES DPI-C)
elseif(SIMULATOR STREQUAL "vcs")
    vcs_configure_cxx(LIBRARIES DPI-C)
elseif(SIMULATOR STREQUAL "vivado_sim")
    vivado_sim_configure_cxx(LIBRARIES DPI-C)
elseif(SIMULATOR MATCHES "verilator")
    verilator_configure_cxx(LIBRARIES DPI-C)
endif()

cmake_minimum_required(VERSION 3.25)
project(dpi_example NONE)

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} SYSTEMVERILOG
    ${PROJECT_SOURCE_DIR}/tb.sv
    )

add_subdirectory(hello)

ip_link(${IP} hello_dpi)

if(SIMULATOR STREQUAL "questa")
    questasim(${IP})
endif()

if(SIMULATOR STREQUAL "xcelium")
    xcelium(${IP})
endif()

if(SIMULATOR STREQUAL "vivado_sim")
    vivado_sim(${IP})
endif()

if(SIMULATOR STREQUAL "vcs")
    vcs(${IP})
endif()

if(SIMULATOR STREQUAL "verilator")
    enable_language(CXX)
    verilator(${IP} MAIN VERILATOR_ARGS --timing)
endif()

help()
