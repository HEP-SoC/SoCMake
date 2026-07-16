#[[[ @module build_scripts
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# Build and install the Verilator binary.
# It might not build a new Verilator binary, if one is found using find_package() cmake function.
#
# **Keyword Arguments**
#
# :keyword VERILATOR_TAG: Verilator tag, branch, or commit to build.
# :type VERILATOR_TAG: string
# :keyword EXACT_VERSION: If EXACT_VERSION is set, the Verilator given version is build if not found.
# :type EXACT_VERSION: bool
# :keyword INSTALL_DIR: Path to the location where the binary will be installed. The default is ${PROJECT_BINARY_DIR}/verilator/${VERILATOR_TAG} or ${FETCHCONTENT_BASE_DIR}/verilator/${VERILATOR_TAG} if FETCHCONTENT_BASE_DIR is set.
#]]
function(verilator_build)
    cmake_parse_arguments(
        ARG
        "EXACT_VERSION"
        "VERILATOR_TAG;INSTALL_DIR"
        ""
        ${ARGN}
    )
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    enable_language(C CXX)

    unset(CMAKE_ARG_VERILATOR_TAG)
    if(ARG_VERILATOR_TAG)
        set(CMAKE_ARG_VERILATOR_TAG "-DVERILATOR_TAG=${ARG_VERILATOR_TAG}")
    endif()

    if(CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD_ARG "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    if(NOT ARG_INSTALL_DIR)
        if(FETCHCONTENT_BASE_DIR)
            set(ARG_INSTALL_DIR
                ${FETCHCONTENT_BASE_DIR}/verilator/${ARG_VERILATOR_TAG}
            )
        else()
            set(ARG_INSTALL_DIR
                ${PROJECT_BINARY_DIR}/verilator/${ARG_VERILATOR_TAG}
            )
        endif()
    endif()

    find_package(
        verilator
        HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT} ${ARG_INSTALL_DIR}
    )

    if(ARG_EXACT_VERSION)
        if(
            NOT "${verilator_VERSION_MAJOR}.${verilator_VERSION_MINOR}"
                VERSION_EQUAL
                "${ARG_VERILATOR_TAG}"
        )
            socmake_message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}: requested version is ${ARG_VERILATOR_TAG} but found ${verilator_VERSION_MAJOR}.${verilator_VERSION_MINOR}")
            set(verilator_FOUND FALSE)
        endif()
    endif()

    if(NOT verilator_FOUND)
        socmake_message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}")
        socmake_message(STATUS "${Magenta}[Building Verilator]${ColourReset}")
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -B
                ${CMAKE_BINARY_DIR}/verilator-build/${ARG_VERILATOR_TAG}
                ${CMAKE_ARG_VERILATOR_TAG} ${CMAKE_CXX_STANDARD_ARG}
                -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
                -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
        )

        execute_process(
            COMMAND
                ${CMAKE_COMMAND} --build
                ${CMAKE_BINARY_DIR}/verilator-build/${ARG_VERILATOR_TAG}
                --parallel 4
        )

        find_package(
            verilator
            ${ARG_VERSION}
            EXACT
            REQUIRED
            HINTS ${ARG_INSTALL_DIR}
        )

        if(NOT verilator_FOUND)
            socmake_message(FATAL_ERROR "Verilator was not found after building. Please check the build logs for errors.")
        endif()

        # Update cached variable if a new version is required
        if(NOT ${VERILATOR_ROOT} STREQUAL ${ARG_INSTALL_DIR})
            socmake_message(STATUS "${Magenta}[Verilator version updated]${ColourReset}")
            set(VERILATOR_ROOT
                ${ARG_INSTALL_DIR}
                CACHE PATH
                "VERILATOR_ROOT"
                FORCE
            )
            set(VERILATOR_BIN
                ${ARG_INSTALL_DIR}/bin/verilator_bin
                CACHE PATH
                "Path to a program."
                FORCE
            )
        endif()
    endif()

    socmake_message(STATUS "${Green}[Found Verilator]${ColourReset}: ${verilator_VERSION} in ${verilator_DIR}")
endfunction()
