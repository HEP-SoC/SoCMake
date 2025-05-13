cmake_minimum_required(VERSION 3.25)
project(simple_cocotb_example CXX)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "iverilog;xcelium;verilator;vcs" "iverilog")

if(${SIMULATOR} STREQUAL "verilator")
    verilator_build(VERSION 5.012 EXACT_VERSION)
endif()

add_subdirectory(adder)

cocotb(adder
    TOP_MODULE adder
    COCOTB_MODULE ${PROJECT_NAME}
    SIM ${SIMULATOR}
    OUTDIR ${PROJECT_BINARY_DIR}
    PYTHONPATH ${CMAKE_CURRENT_LIST_DIR}
)

help()
