function(add_ip_from_ipxact COMP_XML)
    cmake_parse_arguments(ARG "GENERATE_ONLY" "IPXACT_SOURCE_DIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    convert_paths_to_absolute(COMP_XML ${COMP_XML})
    
    find_program(xmlstarlet_EXECUTABLE xmlstarlet)
    if(xmlstarlet_EXECUTABLE)
        set(xml_command ${xmlstarlet_EXECUTABLE} tr)
    else()
        find_program(xsltproc_EXECUTABLE xsltproc REQUIRED)
        set(xml_command ${xsltproc_EXECUTABLE})
    endif()

    cmake_path(GET COMP_XML PARENT_PATH ip_source_dir)
    cmake_path(GET COMP_XML FILENAME file_name)

    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_vlnv.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE vlnv_list)
    list(GET vlnv_list 0 ip_vendor)
    list(GET vlnv_list 1 ip_library)
    list(GET vlnv_list 2 ip_name)
    list(GET vlnv_list 3 ip_version)

    set(output_cmake_file ${ip_source_dir}/${ip_vendor}__${ip_library}__${ip_name}Config.cmake)


    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_find_ips.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE find_ips
                )
    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ip_lib_with_filetype_modifier.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE file_lists
                )

    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_ip_links.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE ip_links
                )

    set(file_lists "${file_lists}\nip_sources(\${IP} IPXACT\n    \${CMAKE_CURRENT_LIST_DIR}/${file_name})\n\n")
    write_file(${output_cmake_file} ${find_ips} ${file_lists} ${ip_links})

    if(DEFINED ARG_IPXACT_SOURCE_DIR)
        set(${ip_vendor}__${ip_library}__${ip_name}__${ip_version}_IPXACT_SOURCE_DIR ${ARG_IPXACT_SOURCE_DIR})
    endif()
    if(NOT ARG_GENERATE_ONLY)
        include("${output_cmake_file}")
    endif()
    
    set(IP ${IP} PARENT_SCOPE)
endfunction()
