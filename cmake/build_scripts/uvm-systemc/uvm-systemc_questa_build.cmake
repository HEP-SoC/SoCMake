function(uvm_systemc_questa_build)
    cmake_parse_arguments(ARG "EXACT_VERSION" "VERSION;INSTALL_DIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    unset(CMAKE_ARG_VERSION)
    if(ARG_VERSION)
        set(CMAKE_ARG_VERSION "-DVERSION=${ARG_VERSION}")
    endif()

    if(NOT ARG_INSTALL_DIR)
        if(FETCHCONTENT_BASE_DIR)
            set(ARG_INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/uvm-systemc-questa)
        else()
            set(ARG_INSTALL_DIR ${PROJECT_BINARY_DIR}/uvm-systemc-questa)
        endif()
    endif()

    # TODO ARG_VERSION cannot be used as its not following major.minor.patch
    find_package(UVM-SystemC-Questa CONFIG
        HINTS ${ARG_INSTALL_DIR}
        )

    if(NOT UVM-SystemC-Questa_FOUND)
        message(STATUS "${Magenta}[UVM-SystemC-Questa Not Found]${ColourReset}")
        message(STATUS "${Magenta}[Building UVM-SystemC-Questa]${ColourReset}")
        execute_process(COMMAND ${CMAKE_COMMAND}
            -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/questa
            -B ${CMAKE_BINARY_DIR}/uvm-systemc-questa-build 
            ${CMAKE_ARG_VERSION}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
            COMMAND_ECHO STDOUT
            )

        execute_process(COMMAND ${CMAKE_COMMAND}
                --build ${CMAKE_BINARY_DIR}/uvm-systemc-questa-build
                --parallel
                --target install
            )
    endif()

    find_package(UVM-SystemC-Questa CONFIG REQUIRED
        HINTS ${ARG_INSTALL_DIR}
        )

    message(STATUS "${Green}[Found UVM-SystemC-Questa]${ColourReset}: ${UVM-SystemC-Questa_VERSION} in ${UVM-SystemC-Questa_DIR}")

endfunction()


