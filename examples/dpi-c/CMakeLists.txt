cmake_minimum_required(VERSION 3.25)
project(dpi_example NONE)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "questa;modelsim;xcelium;verilator" "modelsim")

add_ip(tb
    DESCRIPTION "Simple verilog testbench"
    )

ip_sources(${IP} SYSTEMVERILOG
    ${PROJECT_SOURCE_DIR}/tb.sv
    )

add_subdirectory(hello)

ip_link(${IP} hello_dpi)

if(SIMULATOR STREQUAL "questa" OR SIMULATOR STREQUAL "modelsim")
    modelsim(${IP})

elseif(SIMULATOR STREQUAL "xcelium")
    xcelium(${IP})

elseif(SIMULATOR STREQUAL "verilator")
    enable_language(CXX)
    verilator(${IP})
    add_executable(main Vtb__main.cpp)
    target_link_libraries(main tb__vlt)
endif()

help()
