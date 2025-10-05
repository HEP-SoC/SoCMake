function(add_ip_from_fusesoc CORE_FILE)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    convert_paths_to_absolute(CORE_FILE ${CORE_FILE})
    cmake_path(GET CORE_FILE PARENT_PATH ip_source_dir)
    cmake_path(GET CORE_FILE FILENAME file_name)
    cmake_path(REPLACE_EXTENSION file_name LAST_ONLY ".cmake"
                             OUTPUT_VARIABLE file_name)
    set(output_cmake_file "${ip_source_dir}/${file_name}")
    
    if(NOT EXISTS ${output_cmake_file} OR FUSESOC_IMPORT)
        find_python3()
        set(__cmd ${Python3_EXECUTABLE}
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/fusesoc_to_socmake.py"
            "${CORE_FILE}"
        )

        execute_process(COMMAND ${__cmd}
                        OUTPUT_VARIABLE cmake_content)
        # message("${cmake_content}")
        write_file(${output_cmake_file} "${cmake_content}")
    endif()

    include("${output_cmake_file}")
    
    set(IP ${IP} PARENT_SCOPE)
endfunction()
