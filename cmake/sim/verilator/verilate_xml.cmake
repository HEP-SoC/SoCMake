include_guard(GLOBAL)

function(_verilate_xml TARGET)
    set(OPTIONS "EXCLUDE_FROM_ALL")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;DIRECTORY")
    set(MULTI_PARAM_ARGS "SOURCES;INCLUDE_DIRS")

    cmake_parse_arguments(VERILATE "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    foreach(inc_dir ${INTERFACE_INCLUDE_DIRECTORIES} ${INCLUDE_DIRECTORIES})
        list(APPEND INC_DIRS_ARG -I${inc_dir})
    endforeach()

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT 
        COMMAND
        )
    add_custom_target(xml
        COMMAND verilator --xml-only 
        ${SOURCES}
        ${INC_DIRS_ARG}
        )
    
endfunction()


function(verilate_xml RTLLIB)
    set(OPTIONS "")
    set(ONE_PARAM_ARGS "PREFIX;TOP_MODULE;DIRECTORY;VERILATOR_ARGS")
    set(MULTI_PARAM_ARGS "")

    cmake_parse_arguments(VERILATE "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    get_rtl_target_property(INTERFACE_INCLUDE_DIRECTORIES ${RTLLIB} INTERFACE_INCLUDE_DIRECTORIES)
    get_rtl_target_property(INCLUDE_DIRECTORIES ${RTLLIB} INCLUDE_DIRECTORIES)
    foreach(INC_DIR ${INTERFACE_INCLUDE_DIRECTORIES} ${INCLUDE_DIRECTORIES})
        list(APPEND INC_DIRS_ARG -I${INC_DIR})
    endforeach()

    if(NOT VERILATE_DIRECTORY)
        set(VERILATE_DIRECTORY ${BINARY_DIR}/vlt_xml)
    endif()

    if(VERILATE_TOP_MODULE)
        set(TOP_MODULE_ARG --top-module ${VERILATE_TOP_MODULE})
    endif()

    get_rtl_target_property(LIB_VERILATOR_ARGS ${RTLLIB} VERILATOR_ARGS)

    get_rtl_target_sources(V_FILES ${RTLLIB} SOURCES)
    list(REMOVE_DUPLICATES V_FILES)

    file(MAKE_DIRECTORY ${VERILATE_DIRECTORY})

    set(XML_FILE ${VERILATE_DIRECTORY}/${RTLLIB}.xml)
    set_source_files_properties(${XML_FILE} PROPERTIES GENERATED TRUE)
    set(STAMP_FILE "${OUTDIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${XML_FILE} ${STAMP_FILE}
        COMMAND verilator --xml-output ${XML_FILE}
        ${V_FILES}
        ${INC_DIRS_ARG}
        ${TOP_MODULE_ARG} ${VERILATE_VERILATOR_ARGS} ${LIB_VERILATOR_ARGS}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES}
        )

    add_custom_target(
        ${RTLLIB}_vlt_xml
        DEPENDS ${XML_FILE} ${STAMP_FILE} ${V_FILES} ${RTLLIB}
        )
endfunction()

function(create_vlt_regpublic RTLLIB)
    set(OPTIONS "")
    set(ONE_PARAM_ARGS "OUTDIR;TOP_MODULE")
    set(MULTI_PARAM_ARGS "")

    cmake_parse_arguments(ARG "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(ARG_OUTDIR ${BINARY_DIR}/regpublic)
    endif()

    if(ARG_TOP_MODULE)
        set(TOP_MODULE ${ARG_TOP_MODULE})
    else()
        set(TOP_MODULE ${RTLLIB})
    endif()

    file(MAKE_DIRECTORY ${ARG_OUTDIR})

    set(XML_FILE ${ARG_OUTDIR}/${RTLLIB}.xml)
    verilator_xml(${RTLLIB}
        TOP_MODULE ${TOP_MODULE}
        VERILATOR_ARGS --Wno-fatal ${VERILATOR_ARGS}
        DIRECTORY ${ARG_OUTDIR}
        )

    set(VLT_CFG_FILE ${ARG_OUTDIR}/${RTLLIB}_regpublic.vlt)
    set(REG_LIST ${ARG_OUTDIR}/${RTLLIB}_reglist.txt)
    set(REG_H_FILE ${ARG_OUTDIR}/${RTLLIB}_seq_vpi_handles.h)
    set_source_files_properties(${VLT_CFG_FILE} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${VLT_CFG_FILE} ${REG_LIST} ${REG_H_FILE} ${STAMP_FILE}
        COMMAND python3 ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/parse_vlt_xml.py
        ${XML_FILE}
        ${ARG_OUTDIR}
        --prefix ${RTLLIB}
        --vlt --reg-list --reg-h
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RTLLIB}_vlt_xml ${XML_FILE}
        )

    add_custom_target(
        ${RTLLIB}_regpublic
        DEPENDS ${VLT_CFG_FILE} ${REG_LIST} ${REG_H_FILE} ${STAMP_FILE} ${XML_FILE}
        )

    target_sources(${RTLLIB} INTERFACE ${VLT_CFG_FILE})
    target_include_directories(${RTLLIB} INTERFACE ${ARG_OUTDIR})
endfunction()
