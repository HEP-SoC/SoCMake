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
  file(GLOB children RELATIVE ${dir} ${dir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${dir}/${child})
      list(APPEND dirlist ${child})
      endif()
    endforeach()
  set(${output_var} ${dirlist})
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
    SUBDIRLIST(SUBDIRS ${dir})

    set(filtered_subdirs "")
    
    foreach(subdir ${SUBDIRS})
        get_filename_component(subdir_name ${subdir} NAME)
        set(exclude_dir FALSE)

        # Check if the subdirectory starts with any of the excluded patterns
        foreach(pattern ${excluded_patterns})
            if(subdir_name MATCHES "^${pattern}")
                set(exclude_dir TRUE)
            endif()
        endforeach()

        # If it's not excluded, add to the filtered list
        if(NOT exclude_dir)
            list(APPEND filtered_subdirs ${subdir})
        endif()
    endforeach()

    # Return the filtered list
    set(${output_var} ${filtered_subdirs})
endmacro()
