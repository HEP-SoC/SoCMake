cmake_minimum_required(VERSION 3.27)
cmake_policy(SET CMP0144 NEW)

project(${TARGET})

include("${CMAKE_CURRENT_LIST_DIR}/../../../utils/socmake_message.cmake")

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  socmake_message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Certain versions of verilator require VERILATOR_ROOT as an environment variable
if(NOT DEFINED ENV{VERILATOR_ROOT})
    set(ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
endif()

foreach(ARG ${ARGUMENTS_LIST})
    string(REPLACE "VERILATE_" "" ARG_MOD ${ARG})
    list(APPEND FORWARDED_ARGS ${ARG_MOD} ${VERILATE_${ARG}})
endforeach()

add_library(${TARGET})
verilate(${TARGET}
    ${FORWARDED_ARGS}
)

if(VERILATE_SYSTEMC)
    find_package(SystemCLanguage REQUIRED HINTS ${SYSTEMC_ROOT})
    verilator_link_systemc(${TARGET})
endif()

### Avoid warnings
if(SYSTEMC_ROOT)
endif()
if(EXECUTABLE_NAME)
endif()
