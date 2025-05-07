
function(verilator_build)
    cmake_parse_arguments(ARG "EXACT_VERSION" "VERSION;INSTALL_DIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    unset(CMAKE_ARG_VERSION)
    if(ARG_VERSION)
        set(CMAKE_ARG_VERSION "-DVERSION=${ARG_VERSION}")
    endif()

    if(CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD_ARG "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    if(NOT ARG_INSTALL_DIR)
        if(FETCHCONTENT_BASE_DIR)
            set(ARG_INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/verilator)
        else()
            set(ARG_INSTALL_DIR ${PROJECT_BINARY_DIR}/verilator)
        endif()
    endif()

    find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})

    if(ARG_EXACT_VERSION)
        if(NOT "${verilator_VERSION_MAJOR}.${verilator_VERSION_MINOR}.${verilator_VERSION_PATCH}" STREQUAL ${ARG_VERSION})
            set(verilator_FOUND FALSE)
        endif()
    endif()

    if(NOT verilator_FOUND)
        message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}")
        message(STATUS "${Magenta}[Building Verilator]${ColourReset}")
        execute_process(COMMAND ${CMAKE_COMMAND}
            -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR}
            -B ${CMAKE_BINARY_DIR}/verilator-build
            ${CMAKE_ARG_VERSION}
            ${CMAKE_CXX_STANDARD_ARG}
            -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
        )

        execute_process(COMMAND ${CMAKE_COMMAND}
            --build ${CMAKE_BINARY_DIR}/verilator-build
            --parallel 4
        )
    endif()

    find_package(verilator 5.012 REQUIRED
        HINTS ${ARG_INSTALL_DIR}
    )

    find_package(verilator REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})

    message(STATUS "${Green}[Found Verilator]${ColourReset}: ${verilator_VERSION} in ${verilator_DIR}")

endfunction()
