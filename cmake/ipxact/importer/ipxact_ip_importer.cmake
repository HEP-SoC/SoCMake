function(add_ip_from_ipxact COMP_XML)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    
    find_program(xml_tool xmlstarlet)
    set(xml_command ${xml_tool} tr)
    if(NOT xml_tool)
        find_program(xml_tool xsltproc REQUIRED)
        set(xml_command ${xml_tool})
    endif()

    cmake_path(GET COMP_XML PARENT_PATH ip_source_dir)
    cmake_path(GET COMP_XML FILENAME file_name)

    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_vlnv.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE vlnv_list)
    list(GET vlnv_list 0 ip_vendor)
    list(GET vlnv_list 1 ip_library)
    list(GET vlnv_list 2 ip_name)
    list(GET vlnv_list 3 ip_version)

    set(output_cmake_file ${ip_source_dir}/${ip_vendor}_${ip_library}_${ip_name}_${ip_version}.cmake)

    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ip_lib_with_filetype_modifier.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE file_lists
                )

    execute_process(COMMAND ${xml_command} "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_ip_links.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE ip_links
                )

    set(file_lists "${file_lists}\nip_sources(\${IP} IPXACT\n    \${CMAKE_CURRENT_LIST_DIR}/${file_name})\n\n")
    write_file(${output_cmake_file} ${file_lists} ${ip_links})

    include("${output_cmake_file}")
    
    set(IP ${IP} PARENT_SCOPE)
endfunction()
