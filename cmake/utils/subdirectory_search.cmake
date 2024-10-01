include_guard(GLOBAL)

# https://stackoverflow.com/questions/7787823/cmake-how-to-get-the-name-of-all-subdirectories-of-a-directory

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
