cmake_minimum_required(VERSION 3.27)
project(verilator_opt_flags NONE)

include(CTest)

# The checks read the compile commands of the verilated models
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Adds a verilated model built with the given verilator() arguments, and a test checking the
# effective optimization option of each group of sources of the model (FAST, SLOW, GLOBAL, see
# check_flags.cmake), "none" for no -O option. Each case has its own IP, so its own verilator()
# ExternalProject.
function(add_opt_flags_test NAME)
    cmake_parse_arguments(ARG "" "FAST;SLOW;GLOBAL" "EXTRA_ARGS" ${ARGN})

    add_ip(tests::verilator::verilator_opt_${NAME}::1)
    ip_sources(${IP} SYSTEMVERILOG ${PROJECT_SOURCE_DIR}/tb.sv)

    verilator(${IP}
        TOP_MODULE tb
        DIRECTORY ${PROJECT_BINARY_DIR}/${NAME}
        ${ARG_EXTRA_ARGS}
    )

    add_test(
        NAME verilator_opt_${NAME}
        COMMAND
            ${CMAKE_COMMAND} -DDIRECTORY=${PROJECT_BINARY_DIR}/${NAME}
            -DFAST=${ARG_FAST} -DSLOW=${ARG_SLOW} -DGLOBAL=${ARG_GLOBAL} -P
            ${PROJECT_SOURCE_DIR}/check_flags.cmake
    )
    set_property(
        TEST verilator_opt_${NAME}
        PROPERTY PASS_REGULAR_EXPRESSION "PASS: "
    )

    add_dependencies(check ${IP}_verilate)
    add_dependencies(check_cdash ${IP}_verilate)
endfunction()

# The calling project variables are read by verilator(), they are set in a function scope so
# they do not affect the other tests.

# No build type, OPT_* arguments or -O flag: Verilator default flags (verilated.mk)
function(test_default)
    set(CMAKE_BUILD_TYPE "")
    set(CMAKE_CXX_FLAGS "")
    add_opt_flags_test(default FAST -Os SLOW none GLOBAL -Os)
endfunction()
test_default()

# The build type of the calling project is used
function(test_build_type)
    set(CMAKE_BUILD_TYPE Release)
    set(CMAKE_CXX_FLAGS "")
    add_opt_flags_test(build_type FAST -O3 SLOW -O3 GLOBAL -O3)
endfunction()
test_build_type()

# An -O flag in CMAKE_CXX_FLAGS is used and not overridden by the Verilator default flags
function(test_cxx_flags)
    set(CMAKE_BUILD_TYPE "")
    set(CMAKE_CXX_FLAGS "-O2")
    add_opt_flags_test(cxx_flags FAST -O2 SLOW -O2 GLOBAL -O2)
endfunction()
test_cxx_flags()

# OPT_* arguments take precedence, the Verilator default flags are not used
function(test_opt_args)
    set(CMAKE_BUILD_TYPE "")
    set(CMAKE_CXX_FLAGS "")
    add_opt_flags_test(opt_args EXTRA_ARGS OPT_FAST -O1 FAST -O1 SLOW none GLOBAL none)
endfunction()
test_opt_args()
