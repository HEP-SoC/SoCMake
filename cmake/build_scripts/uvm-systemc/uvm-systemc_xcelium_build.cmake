
function(uvm_systemc_xcelium_build)
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
            set(ARG_INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/uvm-systemc-xcelium)
        else()
            set(ARG_INSTALL_DIR ${PROJECT_BINARY_DIR}/uvm-systemc-xcelium)
        endif()
    endif()

    # TODO ARG_VERSION cannot be used as its not following major.minor.patch
    find_package(UVM-SystemC-Xcelium CONFIG
        HINTS ${ARG_INSTALL_DIR}
        )

    if(NOT UVM-SystemC-Xcelium_FOUND)
        message(STATUS "${Magenta}[UVM-SystemC-Xcelium Not Found]${ColourReset}")
        message(STATUS "${Magenta}[Building UVM-SystemC-Xcelium]${ColourReset}")
        execute_process(COMMAND ${CMAKE_COMMAND}
            -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/xcelium
            -B ${CMAKE_BINARY_DIR}/uvm-systemc-xcelium-build 
            ${CMAKE_ARG_VERSION}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
            COMMAND_ECHO STDOUT
            )

        execute_process(COMMAND ${CMAKE_COMMAND}
                --build ${CMAKE_BINARY_DIR}/uvm-systemc-xcelium-build
                --parallel
                --target install
            )
    endif()

    find_package(UVM-SystemC-Xcelium CONFIG REQUIRED
        HINTS ${ARG_INSTALL_DIR}
        )

    message(STATUS "${Green}[Found UVM-SystemC-Xcelium]${ColourReset}: ${UVM-SystemC-Xcelium_VERSION} in ${UVM-SystemC-Xcelium_DIR}")

endfunction()


