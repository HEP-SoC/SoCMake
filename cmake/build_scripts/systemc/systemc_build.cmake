#[[[ @module build_scripts
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# Build and install the SystemC library.
# It might not build a new SystemC library, if one is found using find_package() cmake function.
#
# **Keyword Arguments**
#
# :keyword VERSION: Version of the SystemC library that need to be built.
# :type VERSION: string
# :keyword EXACT_VERSION: If EXACT_VERSION is set, the SystemC library given version is build if not found.
# :type EXACT_VERSION: bool
# :keyword INSTALL_DIR: Path to the location where the library will be installed. The default is ${PROJECT_BINARY_DIR}/systemc or ${FETCHCONTENT_BASE_DIR}/systemc if FETCHCONTENT_BASE_DIR is set.
#]]
function(systemc_build)
    cmake_parse_arguments(ARG "EXACT_VERSION" "VERSION;INSTALL_DIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
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

    if(ARG_INSTALL_DIR)
        set(BUILD_DIR ${ARG_INSTALL_DIR}/../systemc-build)
    elseif(FETCHCONTENT_BASE_DIR)
        set(BUILD_DIR ${FETCHCONTENT_BASE_DIR}/systemc-build)
    else()
        set(BUILD_DIR ${PROJECT_BINARY_DIR}/systemc-build)
    endif()

    find_package(
        SystemCLanguage
        ${ARG_VERSION}
        CONFIG
        HINTS ${SYSTEMC_HOME} $ENV{SYSTEMC_HOME} ${ARG_INSTALL_DIR} ${BUILD_DIR}
    )

    if(ARG_EXACT_VERSION)
        if(
            NOT "${SystemCLanguage_VERSION_MAJOR}.${SystemCLanguage_VERSION_MINOR}.${SystemCLanguage_VERSION_PATCH}"
                STREQUAL
                ${ARG_VERSION}
        )
            set(SystemCLanguage_FOUND FALSE)
        endif()
    endif()

    if(NOT SystemCLanguage_FOUND)
        socmake_message(STATUS "${Magenta}[SystemC Not Found]${ColourReset}")
        socmake_message(STATUS "${Magenta}[Building SystemC]${ColourReset}")
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -B
                ${BUILD_DIR} ${CMAKE_ARG_VERSION} ${CMAKE_CXX_STANDARD_ARG}
                -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
                -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
        )

        execute_process(
            COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR} --parallel
        )
    endif()

    find_package(
        SystemCLanguage
        ${ARG_VERSION}
        CONFIG
        REQUIRED
        HINTS ${ARG_INSTALL_DIR}
    )

    socmake_message(STATUS "${Green}[Found SystemC]${ColourReset}: ${SystemCLanguage_VERSION} in ${SystemCLanguage_DIR}")
endfunction()
