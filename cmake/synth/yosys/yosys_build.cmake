include_guard(GLOBAL)

function(yosys_build)

    cmake_parse_arguments(ARG 
        ""
        "VERSION;TAG"
        ""
        ${ARGN}
        )
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_MACRO} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_VERSION AND ARG_TAG)
        message(FATAL_ERROR "Cannot use both VERSION and TAG")
    endif()

    if(ARG_VERSION)
        set(ARG_TAG "yosys-${ARG_VERSION}")
    endif()

    CPMAddPackage(
        NAME yosys 
        GIT_TAG ${ARG_TAG}
        GIT_REPOSITORY "https://github.com/YosysHQ/yosys.git"
        )

    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")
    list(APPEND CMAKE_PREFIX_PATH "${FETCHCONTENT_BASE_DIR}/yosys/share/yosys")
    list(APPEND CMAKE_PREFIX_PATH "${FETCHCONTENT_BASE_DIR}/yosys/lib/yosys")
    find_package(Yosys QUIET)

    if(NOT Yosys_FOUND)
        cmake_host_system_information(RESULT nproc QUERY NUMBER_OF_PHYSICAL_CORES)
        execute_process(
            WORKING_DIRECTORY ${yosys_BINARY_DIR}
            COMMAND make install -f ${yosys_SOURCE_DIR}/Makefile
                         -j${nproc}
                         CONFIG=gcc
                         ENABLE_LIBYOSYS=1
                         PREFIX=${FETCHCONTENT_BASE_DIR}/yosys
            )
        find_package(Yosys REQUIRED)
    endif()

endfunction()
