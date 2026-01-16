cmake_minimum_required(VERSION 3.25)
project(simple_cocotb_example CXX)

include("../../SoCMakeConfig.cmake")

option_enum(SIMULATOR "Which simulator to use" "iverilog;xcelium;verilator;vcs" "iverilog")

# Support of Verilator is limited with cocotb 
# Cocotb 1.8.1 and verilator 5.012 works together, that's why we build this exact version
# If verilator does not work with cocotb on your machine, it's recommended to use an other tool
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
