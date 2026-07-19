#[[[ @module ipxact
#]]
include("${CMAKE_CURRENT_LIST_DIR}/../../utils/socmake_message.cmake")

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
# :keyword GENERATE_ONLY: Config.cmake file is written but not included.
# :type GENERATE_ONLY: bool
#]]
function(add_ip_from_ipxact COMP_XML)
    set(options GENERATE_ONLY)
    set(oneValueArgs)
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

    convert_paths_to_absolute(COMP_XML ${COMP_XML})

    if(NOT EXISTS "${COMP_XML}" OR IS_DIRECTORY "${COMP_XML}")
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: ${COMP_XML} is not a file")
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

    string(SHA1 vlnv_key "${COMP_XML}")
    set(vlnv_file
        "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/ipxact_vlnv/${vlnv_key}"
    )

    # Keep .vlnv file as a cache that stores only the VLNV.
    # This is important as it lets us guess the name of
    # <vendor>__<lib>__<name>Config.cmake file.
    set(have_vlnv FALSE)
    if(EXISTS "${vlnv_file}")
        file(TIMESTAMP "${vlnv_file}" vlnv_ts "%s")
        file(TIMESTAMP "${COMP_XML}" xml_ts "%s")
        # If VLNV file timestamp is newer than XML file timestamp
        # We don't need to regenerate the .vlnv file as its up to date
        if(vlnv_ts GREATER_EQUAL xml_ts)
            file(READ "${vlnv_file}" vlnv_list)
            parse_ip_vlnv("${vlnv_list}" vendor library name version)
            set(have_vlnv TRUE)
        endif()
    endif()

    # If there is .vlnv file we can know what the Config.cmake file is called
    if(have_vlnv)
        set(cmake_file ${xml_dir}/${vendor}__${library}__${name}Config.cmake)
        set(dirty TRUE)
        if(EXISTS "${cmake_file}")
            file(TIMESTAMP "${cmake_file}" cmake_ts "%s")
            # If the Config file exists and its newer than xml, its up to date
            if(cmake_ts GREATER_EQUAL xml_ts)
                set(dirty FALSE)
            endif()
        endif()
    else()
        # If there is no .vlnv file we regenerate the Config.cmake also
        set(dirty TRUE)
    endif()

    if(dirty)
        # Parse XML file again, to generate the Config.cmake file
        execute_process(
            COMMAND
                ${xml_command}
                "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ipxact_to_config.xslt"
                ${COMP_XML}
            OUTPUT_VARIABLE config_body
        )
        # Parse the VLNV from the add_ip() line in the generated Config
        string(REGEX REPLACE "\n.*" "" add_ip_line "${config_body}")
        string(
            REGEX REPLACE "^add_ip\\(([^)]+)\\).*"
            "\\1"
            vlnv
            "${add_ip_line}"
        )
        parse_ip_vlnv("${vlnv}" vendor library name version)
        set(cmake_file ${xml_dir}/${vendor}__${library}__${name}Config.cmake)
        # Add the IPXact file we parsed to ip_sources()
        set(config_body
            "${config_body}\nip_sources(\${IP} IPXACT\n    \${CMAKE_CURRENT_LIST_DIR}/${xml_name})\n\n"
        )
        write_file(${cmake_file} ${config_body})

        # Write out also the VLNV file
        if(NOT have_vlnv)
            file(
                WRITE "${vlnv_file}"
                "${vendor}::${library}::${name}::${version}"
            )
        endif()
    endif()

    # Set the _DIR variable in cache, as this variable will be used when
    # find_package() is called to locate the Config.cmake file
    if(NOT DEFINED ${vendor}__${library}__${name}_DIR)
        set(${vendor}__${library}__${name}_DIR
            "${xml_dir}"
            CACHE INTERNAL
            ""
            FORCE
        )
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
    set(options GENERATE_ONLY)
    set(oneValueArgs)
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
    file(GLOB_RECURSE xml_files LIST_DIRECTORIES FALSE "${DIR}/**/*.xml")
    foreach(f ${xml_files})
        if(ARG_GENERATE_ONLY)
            add_ip_from_ipxact(${f} GENERATE_ONLY)
        else()
            add_ip_from_ipxact(${f})
        endif()
    endforeach()
endfunction()
