include_guard(GLOBAL)

set(SAIL_INSTALL_LIST_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

# SAIL C-emulator installation macro
macro(sail_install)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${SAIL_INSTALL_LIST_DIR}/../../utils/find_python.cmake")
    include("${SAIL_INSTALL_LIST_DIR}/../../utils/colours.cmake")
    find_python3()

    # Try to find SAIL executable
    find_program(RISCV32_SAIL_EXE riscv_sim_RV32
        HINTS ${FETCHCONTENT_BASE_DIR}/sail/*/*
              ${SAIL_HOME}/* $ENV{SAIL_HOME}/*
        )

    # Install SAIL if executable not found
    if(NOT RISCV32_SAIL_EXE)
        execute_process(COMMAND ${Python3_EXECUTABE} -m pip install -e ${SAIL_INSTALL_LIST_DIR}/requirements.txt)
        execute_process(COMMAND /bin/bash ${SAIL_INSTALL_LIST_DIR}/install_sail.sh
                --prefix ${FETCHCONTENT_BASE_DIR}/sail
                --build-dir ${FETCHCONTENT_BASE_DIR}/sail-build
        )

        find_program(RISCV32_SAIL_EXE riscv_sim_RV32 REQUIRED
                    HINTS ${FETCHCONTENT_BASE_DIR}/sail/*/*
        )
 
        msg("-----------------------------------------------------------------" Yellow)
        msg("-  Successfull installation of Riscv-Sail" Yellow)
        msg("-  You can now delete directory ${FETCHCONTENT_BASE_DIR}/sail-build" Yellow)
        msg("-  Keep the binary installed in ${RISCV32_SAIL_EXE}" Yellow)
        msg("-  Variable is created holding path to sail binary RISCV32_SAIL_EXE" Yellow)
        msg("-----------------------------------------------------------------" Yellow)
    endif()

endmacro()
