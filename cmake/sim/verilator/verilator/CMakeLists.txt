cmake_minimum_required(VERSION 3.27)

project(${TARGET})

include("${CMAKE_CURRENT_LIST_DIR}/../../../utils/socmake_message.cmake")

find_package(verilator)
if(NOT verilator_FOUND)
    socmake_message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Certain (older) versions of verilator require VERILATOR_ROOT as an actual
# OS environment variable, not just a CMake variable. verilator.cmake's
# BUILD_COMMAND wraps `make` with `env VERILATOR_ROOT=...` for the build
# step below, but that wrapping doesn't cover this configure step itself -
# and verilate() a few lines down runs verilator_bin directly (via
# execute_process) during this very configure. So re-export it as an env
# var here too, if it isn't already one (e.g. from a parent shell).
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
