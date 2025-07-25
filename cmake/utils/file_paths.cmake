#[[[
# This function converts relative paths to absolute paths relative to ${CMAKE_CURRENT_SOURCE_DIR}
# It replicates the behaviour of target_sources() CMake Function
#
# :param OUTPUT_LIST: The variable to store the output file list
# :type OUTPUT_LIST: string
# :param ARGN: list of files to convert
# :type ARGN: path
#
#]]
function(convert_paths_to_absolute OUTPUT_LIST)
    unset(output_list)
    foreach(path ${ARGN})
        if(NOT "${path}" MATCHES "\\$\{_IMPORT_PREFIX\}")
            cmake_path(ABSOLUTE_PATH path 
                BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} NORMALIZE
                OUTPUT_VARIABLE path
            )
        endif()
        list(APPEND output_list ${path} )
    endforeach()

    set(${OUTPUT_LIST} ${output_list} PARENT_SCOPE)
endfunction()
