## Options are used for variables and conditional configuration of the project
## To change an option pass it during configuration with `cmake -DSIM_TYPE=SYNTH ../`
## To print help message for options run `make help_options`
## To see options in gui run `cmake-gui ../`

cmake_minimum_required(VERSION 3.28)
project(options_example NONE)

include("../../SoCMakeConfig.cmake")

option_enum("SIM_TYPE" "Type of simulation to run" "SYNTH;GENERIC" "GENERIC")
option_boolean("SIM_TRACE" "Enable tracing vcd file" OFF)
option_string("SIM_TRACE_PATH" "Output of VCD file in case SIM_TRACE is on" "trace.vcd")
option_integer("SIM_NUM_TESTS" "Number of tests in regression" 1)

if(SIM_TYPE STREQUAL SYNTH)
    # Add Synthesis only files
    # ip_sources(${IP} SYSTEMVERILOG <SYNTH_FILES>)
elseif(SIM_TYPE STREQUAL GENERIC)
    # Add Generic only files
    # ip_sources(${IP} SYSTEMVERILOG <SIM_FILES>)
endif()

help()
