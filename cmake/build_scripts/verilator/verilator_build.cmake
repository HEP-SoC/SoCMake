
function(verilator_build)
    cmake_parse_arguments(ARG "EXACT_VERSION" "VERSION;INSTALL_DIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    enable_language(C CXX)

    unset(CMAKE_ARG_VERSION)
    if(ARG_VERSION)
        set(CMAKE_ARG_VERSION "-DVERSION=${ARG_VERSION}")
    endif()

    if(CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD_ARG "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    if(NOT ARG_INSTALL_DIR)
        if(FETCHCONTENT_BASE_DIR)
            set(ARG_INSTALL_DIR ${FETCHCONTENT_BASE_DIR}/verilator/v${ARG_VERSION})
        else()
            set(ARG_INSTALL_DIR ${PROJECT_BINARY_DIR}/verilator/v${ARG_VERSION})
        endif()
    endif()

    find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT} ${ARG_INSTALL_DIR})

    if(ARG_EXACT_VERSION)
        if(NOT "${verilator_VERSION_MAJOR}.${verilator_VERSION_MINOR}" VERSION_EQUAL "${ARG_VERSION}")
            message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}: requested version is ${ARG_VERSION} but found ${verilator_VERSION_MAJOR}.${verilator_VERSION_MINOR}")
            set(verilator_FOUND FALSE)
        endif()
    endif()

    if(NOT verilator_FOUND)
        message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}")
        message(STATUS "${Magenta}[Building Verilator]${ColourReset}")
        execute_process(COMMAND ${CMAKE_COMMAND}
            -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR}
            -B ${CMAKE_BINARY_DIR}/verilator-build/v${ARG_VERSION}
            ${CMAKE_ARG_VERSION}
            ${CMAKE_CXX_STANDARD_ARG}
            -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
        )

        execute_process(COMMAND ${CMAKE_COMMAND}
            --build ${CMAKE_BINARY_DIR}/verilator-build/v${ARG_VERSION}
            --parallel 4
        )

        find_package(verilator ${ARG_VERSION} EXACT REQUIRED HINTS ${ARG_INSTALL_DIR})

        if(NOT verilator_FOUND)
            message(FATAL_ERROR "Verilator was not found after building. Please check the build logs for errors.")
        endif()

        # Update cached variable if a new version is required
        if(NOT ${VERILATOR_ROOT} STREQUAL ${ARG_INSTALL_DIR})
            message(STATUS "${Magenta}[Verilator version updated]${ColourReset}")
            set(VERILATOR_ROOT ${ARG_INSTALL_DIR} CACHE PATH "VERILATOR_ROOT" FORCE)
            set(VERILATOR_BIN ${ARG_INSTALL_DIR}/bin/verilator_bin CACHE PATH "Path to a program." FORCE)
        endif()
    endif()

    set(__version_missing_root 5.012 5.014 5.016 5.018 5.020 5.022 5.024)
    if(${ARG_VERSION} IN_LIST __version_missing_root)
        set(ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
    endif()

    message(STATUS "${Green}[Found Verilator]${ColourReset}: ${verilator_VERSION} in ${verilator_DIR}")

endfunction()
