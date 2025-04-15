function(add_ip_from_ipxact COMP_XML)

    execute_process(COMMAND xmlstarlet tr "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/get_vlnv.xslt" ${COMP_XML}
                    OUTPUT_VARIABLE vlnv_list)
    list(GET vlnv_list 0 ip_vendor)
    list(GET vlnv_list 1 ip_library)
    list(GET vlnv_list 2 ip_name)
    list(GET vlnv_list 3 ip_version)

    set(outdir ${CMAKE_BINARY_DIR}/${ip_vendor}__${ip_library}__${ip_name})
    set(output_cmake_file ${outdir}/${ip_name}.cmake)
    make_directory(${outdir})

    execute_process(COMMAND xmlstarlet tr "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ip_lib_with_filetype_modifier.xslt" ${COMP_XML}
                OUTPUT_FILE ${output_cmake_file} 
                )

    cmake_path(GET COMP_XML PARENT_PATH ${ip_name}_SOURCE_DIR)

    include("${output_cmake_file}")
    
    set(IP ${IP} PARENT_SCOPE)
endfunction()
