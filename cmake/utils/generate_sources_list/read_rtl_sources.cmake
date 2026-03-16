#[[[ @module read_rtl_sources
#]]

#[[[
# This function reads a file listing RTL files and return a list of paths.
#
# By default, this function returns 3 lists, one per RTL source file type (i.e., Verilog, SystemVerilog, and VHDL):
# READ_RTL_SOURCES_V, READ_RTL_SOURCES_SV, READ_RTL_SOURCES_VHDL. IF the CONCAT keyword is passed, only
# READ_RTL_SOURCES_ALL is returned.
#
# :param RTL_SOURCES_FILE: Path to the file to read.
# :type RTL_SOURCES_FILE: string
#
# **Keyword Arguments**
#
# :keyword CONCAT: Concatenate the different RTL source files (i.e., Verilog, SystemVerilog, and VHDL) and return a single list.
# :type CONCAT: string
#]]
function(read_rtl_sources RTL_SOURCES_FILE)
    # Check the file exists
    if(NOT EXISTS ${RTL_SOURCES_FILE})
        message(FATAL_ERROR "${RTL_SOURCES_FILE} file does not exists.")
    endif()

    cmake_parse_arguments(ARG "CONCAT" "" "" ${ARGN})

    # Check for any unexpected arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                            "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Read the content of the .f file
    file(READ ${RTL_SOURCES_FILE} RTL_CONTENT)

    # Split the content into lines
    string(REPLACE "\n" ";" RTL_LINES "${RTL_CONTENT}")

    # Define lists to store classified RTL files
    set(VERILOG_FILES "")
    set(SYSTEMVERILOG_FILES "")
    set(VHDL_FILES "")

    # Iterate through the lines and classify the files
    foreach(RTL_FILE ${RTL_LINES})
        # Ignore empty lines or lines starting with comments
        if(RTL_FILE MATCHES "^\\s*$" OR RTL_FILE MATCHES "^\\s*#")
            continue()
        endif()

        # Determine the absolute path (assuming the paths in .f are relative)
        get_filename_component(RTL_FILE_ABS "${RTL_SOURCES_FILE}/../${RTL_FILE}" ABSOLUTE)

        # Classify based on file extension
        if(RTL_FILE_ABS MATCHES "\\.v$")
            list(APPEND VERILOG_FILES ${RTL_FILE_ABS})
        elseif(RTL_FILE_ABS MATCHES "\\.sv$")
            list(APPEND SYSTEMVERILOG_FILES ${RTL_FILE_ABS})
        elseif(RTL_FILE_ABS MATCHES "\\.vhdl$|\\.vhd$")
            list(APPEND VHDL_FILES ${RTL_FILE_ABS})
        else()
            message(WARNING "Unrecognized file extension: ${RTL_FILE_ABS}")
        endif()
    endforeach()

    if(ARG_CONCAT)
        list(APPEND VHDL_FILES ${VERILOG_FILES})
        list(APPEND VHDL_FILES ${SYSTEMVERILOG_FILES})
        set(READ_RTL_SOURCES_ALL ${VHDL_FILES} PARENT_SCOPE)
    elseif()
        set(READ_RTL_SOURCES_VHDL ${VHDL_FILES} PARENT_SCOPE)
        set(READ_RTL_SOURCES_V ${VERILOG_FILES} PARENT_SCOPE)
        set(READ_RTL_SOURCES_SV ${SYSTEMVERILOG_FILES} PARENT_SCOPE)
    endif()
endfunction()
