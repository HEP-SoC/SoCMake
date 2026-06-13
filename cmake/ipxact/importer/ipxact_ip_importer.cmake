#[[[ @module ipxact
#]]

#[[[
# This function imports an IP-XACT .xml file and converts it to a SoCMake HWIP.
#
# Config.cmake files are only regenerated when the source XML is newer than
# the existing output. A VLNV cache in the build directory avoids process
# spawns on repeated runs.
#
# :param COMP_XML: Path to the ipxact .xml file.
# :type COMP_XML: string
#
# **Keyword Arguments**
#
# :keyword GENERATE_ONLY: Config.cmake file is written but not include()d.
# :type GENERATE_ONLY: bool
#]]
function(add_ip_from_ipxact COMP_XML)
    cmake_parse_arguments(ARG "GENERATE_ONLY" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    convert_paths_to_absolute(COMP_XML ${COMP_XML})

    if(NOT EXISTS "${COMP_XML}" OR IS_DIRECTORY "${COMP_XML}")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: ${COMP_XML} is not a file")
    endif()

    cmake_path(GET COMP_XML PARENT_PATH xml_dir)
    cmake_path(GET COMP_XML FILENAME xml_name)

    find_program(xmlstarlet_EXECUTABLE xmlstarlet)
    if(xmlstarlet_EXECUTABLE)
        set(xml_command ${xmlstarlet_EXECUTABLE} tr)
    else()
        find_program(xsltproc_EXECUTABLE xsltproc REQUIRED)
        set(xml_command ${xsltproc_EXECUTABLE})
    endif()

    string(SHA1 _vlnv_key "${COMP_XML}")
    set(_vlnv_file "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ipxact_vlnv/${_vlnv_key}")

    # Keep .vlnv file as a cache that stores only the VLNV.
    # This is important as it lets us guess the name of 
    # <vendor>__<lib>__<name>Config.cmake file.
    set(_have_vlnv FALSE)
    if(EXISTS "${_vlnv_file}")
        file(TIMESTAMP "${_vlnv_file}" _vlnv_ts "%s")
        file(TIMESTAMP "${COMP_XML}" _xml_ts "%s")
        # If VLNV file timestamp is newer than XML file timestamp
        # We don't need to regenerate the .vlnv file as its up to date
        if(_vlnv_ts GREATER_EQUAL _xml_ts)
            file(READ "${_vlnv_file}" _vlnv_list)
            parse_ip_vlnv("${_vlnv_list}" VENDOR LIBRARY IP_NAME VERSION)
            set(_have_vlnv TRUE)
        endif()
    endif()

    # If there is .vlnv file we can know what the Config.cmake file is called
    if(_have_vlnv)
        set(cmake_file ${xml_dir}/${VENDOR}__${LIBRARY}__${IP_NAME}Config.cmake)
        set(_dirty TRUE)
        if(EXISTS "${cmake_file}")
            file(TIMESTAMP "${cmake_file}" _cmake_ts "%s")
            # If the Config file exists and its newer than xml, its up to date
            if(_cmake_ts GREATER_EQUAL _xml_ts)
                set(_dirty FALSE)
            endif()
        endif()
    else()
        # If there is no .vlnv file we regenerate the Config.cmake also
        set(_dirty TRUE)
    endif()

    if(_dirty)
        # Parse XML file again, to generate the Config.cmake file
        execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ipxact_to_config.xslt" ${COMP_XML}
                        OUTPUT_VARIABLE _config_body)
        # Parse the VLNV from the add_ip() line in the generated Config
        string(REGEX REPLACE "\n.*" "" _add_ip_line "${_config_body}")
        string(REGEX REPLACE "^add_ip\\(([^)]+)\\).*" "\\1" _vlnv "${_add_ip_line}")
        parse_ip_vlnv("${_vlnv}" VENDOR LIBRARY IP_NAME VERSION)
        set(cmake_file ${xml_dir}/${VENDOR}__${LIBRARY}__${IP_NAME}Config.cmake)
        # Add the IPXact file we parsed to ip_sources()
        set(_config_body "${_config_body}\nip_sources(\${IP} IPXACT\n    \${CMAKE_CURRENT_LIST_DIR}/${xml_name})\n\n")
        write_file(${cmake_file} ${_config_body})

        # Write out also the VLNV file
        if(NOT _have_vlnv)
            file(WRITE "${_vlnv_file}" "${VENDOR}::${LIBRARY}::${IP_NAME}::${VERSION}")
        endif()
    endif()

    # Set the _DIR variable in cache, as this variable will be used when
    # find_package() is called to locate the Config.cmake file
    if(NOT DEFINED ${VENDOR}__${LIBRARY}__${IP_NAME}_DIR)
        set(${VENDOR}__${LIBRARY}__${IP_NAME}_DIR "${xml_dir}" CACHE INTERNAL "" FORCE)
    endif()

    if(NOT ARG_GENERATE_ONLY)
        include("${cmake_file}")
    endif()

    set(IP ${IP} PARENT_SCOPE)
endfunction()

#[[[
# Convenience wrapper: imports all IP-XACT .xml files found under a directory.
#
#   add_ipxact_library("/path/to/ipxact" GENERATE_ONLY)
#
# :param DIR: Root directory to search for .xml files recursively.
# :type DIR: string
#
# **Keyword Arguments**
#
# :keyword GENERATE_ONLY: Config.cmake files are written but not include()d.
# :type GENERATE_ONLY: bool
#]]
function(add_ipxact_library DIR)
    cmake_parse_arguments(ARG "GENERATE_ONLY" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    file(GLOB_RECURSE _xml_files LIST_DIRECTORIES FALSE "${DIR}/**/*.xml")
    foreach(_f ${_xml_files})
        if(ARG_GENERATE_ONLY)
            add_ip_from_ipxact(${_f} GENERATE_ONLY)
        else()
            add_ip_from_ipxact(${_f})
        endif()
    endforeach()
endfunction()
