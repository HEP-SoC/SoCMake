
function(systemc_build)
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
            set(ARG_INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/systemc)
        else()
            set(ARG_INSTALL_DIR ${PROJECT_BINARY_DIR}/systemc)
        endif()
    endif()

    find_package(SystemCLanguage ${ARG_VERSION} CONFIG
        HINTS ${SYSTEMC_HOME} $ENV{SYSTEMC_HOME} ${ARG_INSTALL_DIR} 
        )

    if(ARG_EXACT_VERSION)
        if(NOT "${SystemCLanguage_VERSION_MAJOR}.${SystemCLanguage_VERSION_MINOR}.${SystemCLanguage_VERSION_PATCH}" STREQUAL ${ARG_VERSION})
            set(SystemCLanguage_FOUND FALSE)
        endif()
    endif()

    if(NOT SystemCLanguage_FOUND)
        message(STATUS "${Magenta}[SystemC Not Found]${ColourReset}")
        message(STATUS "${Magenta}[Building SystemC]${ColourReset}")
        execute_process(COMMAND ${CMAKE_COMMAND}
            -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR}
            -B ${CMAKE_BINARY_DIR}/systemc-build 
            ${CMAKE_ARG_VERSION}
            ${CMAKE_CXX_STANDARD_ARG}
            -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
            )

        execute_process(COMMAND ${CMAKE_COMMAND}
                --build ${CMAKE_BINARY_DIR}/systemc-build
                --parallel
            )
    endif()

    find_package(SystemCLanguage ${ARG_VERSION} CONFIG REQUIRED
        HINTS ${ARG_INSTALL_DIR}
        )

    message(STATUS "${Green}[Found SystemC]${ColourReset}: ${SystemCLanguage_VERSION} in ${SystemCLanguage_DIR}")

endfunction()
