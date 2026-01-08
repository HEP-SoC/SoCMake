#[[[
# This function uniquify a list of files based on the basename (name + extension) of the files.
#
# This function take a list of file as input and uniquify it by checking the basenames of the entries. For example,
# /home/user/file1.sv and /home/user/dir/file1.sv are recognized as a unique file and only the first occurrence is kept.
# This function also check the files have the same content and throws an error if this is not the case.
#
# :param INPUT_LIST: Input ist of files.
# :type INPUT_LIST: string
# :param OUTPUT_LIST: Output variable used to store the list of uniquify files.
# :type OUTPUT_LIST: string
#
#]]
function(uniquify_files_by_basename OUTPUT_LIST INPUT_LIST MESSAGE_MODE)
    # Define a dictionary to keep track of seen basenames
    # set(_seen_basenames "")
    set(_unique_files "")

    message(DEBUG "UNIQUIFY: INPUT_LIST ${INPUT_LIST}")

    foreach(file ${INPUT_LIST})
        # Get the basename of the file (name + extension)
        get_filename_component(basename ${file} NAME)

        message(DEBUG "UNIQUIFY: checking file ${file}")

        if(NOT _seen_basenames_${basename})
            # If the basename is not yet seen, mark it and store the full path
            set(_seen_basenames_${basename} ${file})
            list(APPEND _unique_files ${file})
            message(DEBUG "    '-> First occurence stored in _unique_files")
        else()
            # If the basename has been seen, compare file contents
            file(READ ${file} CURRENT_CONTENT)
            file(READ ${_seen_basenames_${basename}} ORIGINAL_CONTENT)
            if(NOT "${CURRENT_CONTENT}" STREQUAL "${ORIGINAL_CONTENT}")
                message(${MESSAGE_MODE} "Files ${file} and ${_seen_basenames_${basename}} have the same basename (${basename}) but different content.")
            endif()
        endif()
    endforeach()

    message(DEBUG "UNIQUIFY: OUTPUT_LIST ${_unique_files}")

    # Return the list of unique files
    set(${OUTPUT_LIST} ${_unique_files} PARENT_SCOPE)
endfunction()
