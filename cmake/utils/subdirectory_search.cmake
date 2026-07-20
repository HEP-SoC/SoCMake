#[[[ @module subdirectory_search
#]]

include_guard(GLOBAL)

# https://stackoverflow.com/questions/7787823/cmake-how-to-get-the-name-of-all-subdirectories-of-a-directory
#[[[
# This macro is used to get the name of all the subdirectories of a directory, inspired by `this <https://stackoverflow.com/questions/7787823/cmake-how-to-get-the-name-of-all-subdirectories-of-a-directory>`_
#
# :param output_var: Output variable in which the list of subdirectory names is stored.
# :type output_var: list[string]
# :param dir: Path to the directory
# :type dir: string
#]]
macro(SUBDIRLIST output_var dir)
    file(GLOB _children RELATIVE ${dir} ${dir}/*)
    set(_dirlist "")
    foreach(child ${_children})
        if(IS_DIRECTORY ${dir}/${child})
            list(APPEND _dirlist ${child})
        endif()
    endforeach()
    set(${output_var} ${_dirlist})
endmacro()

#[[[
# This macro can be used to create a filtered list, by selecting patterns to exclude some subdirectories.
#
# :param output_var: Output variable in which the list of subdirectory names is stored.
# :type output_var: list[string]
# :param dir: Path to the directory
# :type dir: string
# :param excluded_patterns: Patterns to exclude subdirectories
# :type excluded_patterns: list[string]
#]]
macro(SUBDIRLIST_EXCLUDE output_var dir excluded_patterns)
    # Get all subdirectories
    subdirlist(_subdirs ${dir})

    set(_filtered_subdirs "")

    foreach(subdir ${_subdirs})
        get_filename_component(_subdir_name ${subdir} NAME)
        set(_exclude_dir FALSE)

        # Check if the subdirectory starts with any of the excluded patterns
        foreach(pattern ${excluded_patterns})
            if(_subdir_name MATCHES "^${pattern}")
                set(_exclude_dir TRUE)
            endif()
        endforeach()

        # If it's not excluded, add to the filtered list
        if(NOT _exclude_dir)
            list(APPEND _filtered_subdirs ${subdir})
        endif()
    endforeach()

    # Return the filtered list
    set(${output_var} ${_filtered_subdirs})
endmacro()
