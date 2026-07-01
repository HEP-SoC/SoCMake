#[[[ @module fusesoc
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../utils/socmake_message.cmake")

#[[[
# This function imports an IP fusesoc core file and convert it to an SoCMake HWIP.
#
# This function will convert FuseSoC .core (YAML) files to SoCMake CMakeLists.txt.
# The IP will be added to the IP_LIB, by formatting the information coming from the .core file, to add and link the IP with it different file sets.
# Unfortunately, this function does not resolve dependencies between different .core file, so the IPs that need to be linked with.
#
# :param CORE_FILE: Path to the fusesoc core file
# :type CORE_FILE: string
#]]
function(add_ip_from_fusesoc CORE_FILE)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    convert_paths_to_absolute(CORE_FILE ${CORE_FILE})
    cmake_path(GET CORE_FILE PARENT_PATH ip_source_dir)
    cmake_path(GET CORE_FILE FILENAME file_name)
    cmake_path(
        REPLACE_EXTENSION file_name
        LAST_ONLY
        ".cmake"
        OUTPUT_VARIABLE file_name
    )
    set(output_cmake_file "${ip_source_dir}/${file_name}")

    if(NOT EXISTS ${output_cmake_file} OR FUSESOC_IMPORT)
        socmake_message(STATUS "Generating SoCMake file from fusesoc ${CORE_FILE}")
        find_python3()
        set(__cmd
            ${Python3_EXECUTABLE}
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/fusesoc_to_socmake.py"
            "${CORE_FILE}"
        )

        execute_process(COMMAND ${__cmd} OUTPUT_VARIABLE cmake_content)
        # message("${cmake_content}")
        write_file(${output_cmake_file} "${cmake_content}")
    endif()

    include("${output_cmake_file}")

    set(IP ${IP} PARENT_SCOPE)
endfunction()
