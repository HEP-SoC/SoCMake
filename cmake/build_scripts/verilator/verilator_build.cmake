#[[[ @module build_scripts
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

#[[[
# Build and install the Verilator binary.
# It might not build a new Verilator binary, if one is found using find_package() cmake function.
#
# **Keyword Arguments**
#
# :keyword VERILATOR_TAG: Verilator tag, branch, or commit to build. If omitted, the current HEAD of the default branch ("master") is built and installed under a "head" subdirectory rather than VERILATOR_TAG's (empty) name.
# :type VERILATOR_TAG: string
# :keyword EXACT_VERSION: If EXACT_VERSION is set, the Verilator given version is build if not found.
# :type EXACT_VERSION: bool
# :keyword INSTALL_DIR: Path to the location where the binary will be installed. The default is ${PROJECT_BINARY_DIR}/verilator/${VERILATOR_TAG} or ${FETCHCONTENT_BASE_DIR}/verilator/${VERILATOR_TAG} if FETCHCONTENT_BASE_DIR is set ("head" in place of VERILATOR_TAG when it is omitted).
#]]
function(verilator_build)
    set(options EXACT_VERSION)
    set(oneValueArgs VERILATOR_TAG INSTALL_DIR)
    set(multiValueArgs)

    cmake_parse_arguments(
        ARG
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")

    enable_language(C CXX)

    # An empty VERILATOR_TAG means "build the current HEAD". Resolve it to
    # an actual git ref (the default branch) instead of leaving it empty and
    # set the directory name passed to ARG_INSTALL_DIR.
    if(NOT ARG_VERILATOR_TAG)
        set(ARG_VERILATOR_TAG "master")
        set(ARG_VERILATOR_TAG_DIR "head")
    else()
        set(ARG_VERILATOR_TAG_DIR "${ARG_VERILATOR_TAG}")
    endif()

    set(CMAKE_ARG_VERILATOR_TAG "-DVERILATOR_TAG=${ARG_VERILATOR_TAG}")

    if(CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD_ARG "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}")
    endif()

    if(NOT ARG_INSTALL_DIR)
        if(FETCHCONTENT_BASE_DIR)
            set(ARG_INSTALL_DIR
                ${FETCHCONTENT_BASE_DIR}/verilator/${ARG_VERILATOR_TAG_DIR}
            )
        else()
            set(ARG_INSTALL_DIR
                ${PROJECT_BINARY_DIR}/verilator/${ARG_VERILATOR_TAG_DIR}
            )
        endif()
    endif()

    # Whether verilator-config-version.cmake keeps a leading 'v' in
    # PACKAGE_VERSION depends on the Verilator version being built: older
    # releases strip it (tag "v5.022" -> PACKAGE_VERSION "5.022"), newer
    # ones don't (tag "v5.024" -> PACKAGE_VERSION "v5.024"). Accept either
    # spelling rather than guessing one fixed transformation. Commit hashes
    # have no 'v' to begin with, so this is a no-op for them.
    set(ARG_VERILATOR_VERSION_CANDIDATES "${ARG_VERILATOR_TAG}")
    if(ARG_VERILATOR_TAG MATCHES "^v(.*)")
        list(APPEND ARG_VERILATOR_VERSION_CANDIDATES "${CMAKE_MATCH_1}")
    endif()

    find_package(
        verilator
        HINTS ${ARG_INSTALL_DIR}
    )

    if(ARG_EXACT_VERSION AND verilator_FOUND)
        # verilator_VERSION is copied verbatim from PACKAGE_VERSION in
        # verilator-config-version.cmake, so it holds the full commit hash
        # when VERILATOR_TAG is a hash. Therefore, STREQUAL is used deliberately
        # instead of VERSION_EQUAL.
        if(NOT "${verilator_VERSION}" IN_LIST ARG_VERILATOR_VERSION_CANDIDATES)
            socmake_message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}: requested version is ${ARG_VERILATOR_TAG} but found ${verilator_VERSION}")
            set(verilator_FOUND FALSE)
            set(verilator_NOT_FOUND_MESSAGE_PRINTED TRUE)
        endif()
    endif()

    if(NOT verilator_FOUND)
        if(NOT verilator_NOT_FOUND_MESSAGE_PRINTED)
            socmake_message(STATUS "${Magenta}[Verilator Not Found]${ColourReset}")
        endif()
        socmake_message(STATUS "${Magenta}[Building Verilator]${ColourReset}")
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -B
                ${CMAKE_BINARY_DIR}/verilator-build/${ARG_VERILATOR_TAG_DIR}
                ${CMAKE_ARG_VERILATOR_TAG} ${CMAKE_CXX_STANDARD_ARG}
                -DCMAKE_INSTALL_PREFIX=${ARG_INSTALL_DIR}
                -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            COMMAND_ECHO STDOUT
        )

        execute_process(
            COMMAND
                ${CMAKE_COMMAND} --build
                ${CMAKE_BINARY_DIR}/verilator-build/${ARG_VERILATOR_TAG_DIR}
                --parallel 4
        )

        # verilator_DIR is a CACHE variable: once the find_package() call
        # above resolves it, later find_package() calls in this same
        # configure reuse it directly and skip searching altogether, even
        # with different HINTS, so clear it.
        unset(verilator_DIR CACHE)
        # NO_DEFAULT_PATH: without it, a cached VERILATOR_ROOT (e.g. from an
        # earlier accepted install) takes priority over HINTS
        find_package(
            verilator
            REQUIRED
            HINTS ${ARG_INSTALL_DIR}
            NO_DEFAULT_PATH
        )

        if(NOT verilator_FOUND)
            socmake_message(FATAL_ERROR "Verilator was not found after building. Please check the build logs for errors.")
        endif()

        if(ARG_EXACT_VERSION AND NOT "${verilator_VERSION}" IN_LIST ARG_VERILATOR_VERSION_CANDIDATES)
            socmake_message(FATAL_ERROR "Built Verilator version is ${verilator_VERSION} but requested version was ${ARG_VERILATOR_TAG}. Please check the build logs for errors.")
        endif()
    endif()

    # Keep VERILATOR_ROOT in sync with wherever verilator_DIR
    # actually resolved. This runs unconditionally, not only when a build
    # just happened above: if the very first find_package() already found a
    # satisfying install, the block above is skipped entirely and these
    # would otherwise be left stale/unset.
    # VERILATOR_ROOT matters for sim/verilator/verilator.cmake function.
    if(NOT "${VERILATOR_ROOT}" STREQUAL "${verilator_DIR}")
        socmake_message(STATUS "${Magenta}[Verilator version updated]${ColourReset}")
        set(VERILATOR_ROOT
            ${verilator_DIR}
            CACHE PATH
            "VERILATOR_ROOT"
            FORCE
        )
    endif()

    socmake_message(STATUS "${Green}[Found Verilator]${ColourReset}: ${verilator_VERSION} in ${verilator_DIR}")
endfunction()
