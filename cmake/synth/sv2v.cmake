include_guard(GLOBAL)

function(set_sv2v_sources IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    # Get any prior SV2V sources
    get_sv2v_sources(_sv2v_src ${IP_LIB})

    set(_sv2v_src ${_sv2v_src} ${ARGN})
    # Set the target property with the new list of source files
    set_property(TARGET ${_reallib} PROPERTY SV2V_SOURCES ${_sv2v_src})
endfunction()

function(get_sv2v_sources OUT_VAR IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "" "" ${ARGN})
    set(_no_deps)
    if(ARG_NO_DEPS)
        set(_no_deps "NO_DEPS")
    endif()

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    get_ip_property(_sv2v_src ${_reallib} SV2V_SOURCES ${_no_deps})

    list(REMOVE_DUPLICATES _sv2v_src)
    set(${OUT_VAR} ${_sv2v_src} PARENT_SCOPE)
endfunction()

function(sv2v IP_LIB)
    cmake_parse_arguments(ARG "REPLACE;TMR;HWIF_WIRE" "OUTDIR;REGBLOCK_OUTDIR;OUT_LIST" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/sv2v_${IP_LIB})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    # Default regblock output directory is regblock/
    if(NOT ARG_REGBLOCK_OUTDIR)
        if(NOT ARG_TMR)
            set(REGBLOCK_OUTDIR_ARG regblock)
        else()
            set(REGBLOCK_OUTDIR_ARG regblock_tmr)
        endif()
    else()
        set(REGBLOCK_OUTDIR_ARG ${ARG_REGBLOCK_OUTDIR})
    endif()


    get_sv2v_sources(SV2V_SRC ${IP_LIB})
    foreach(vfile ${SV2V_SRC})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        if(NOT ${V_SOURCE_WO_EXT} MATCHES ".*regblock_pkg$")
            list(APPEND SV2V_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}.v")
        endif()
    endforeach()
    set_source_files_properties(${SV2V_GEN} PROPERTIES GENERATED TRUE)

    get_ip_include_directories(INCDIRS ${IP_LIB} SYSTEMVERILOG VERILOG)
    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    # HACK ALERT!!
    if(ARG_HWIF_WIRE)
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
        set(SED_COMMAND
            COMMAND ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/hwif_sed.sh ${OUTDIR}/${TOP_MODULE}_regblock.v ${OUTDIR}/../${REGBLOCK_OUTDIR_ARG}/${TOP_MODULE}.sv
        )
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${SV2V_GEN}
        COMMAND sv2v ${SV2V_SRC} ${INCDIR_ARG} ${CMP_DEFS_ARG} -w ${OUTDIR}
        ${SED_COMMAND}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SV2V_SRC}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SV2V_SRC} ${SV2V_GEN}
    )

    if(ARG_OUT_LIST)
        set(${ARG_OUT_LIST} ${SV2V_GEN} PARENT_SCOPE)
    endif()

    if(ARG_REPLACE)
        # Get original sources
        get_ip_sources(SV_SRC ${IP_LIB} SYSTEMVERILOG NO_DEPS)
        get_ip_sources(V_SRC ${IP_LIB} VERILOG NO_DEPS)
        
        # Remove SV2V files from original sources
        list(REMOVE_ITEM SV_SRC ${SV2V_SRC})
        list(REMOVE_ITEM V_SRC ${SV2V_SRC})
        
        # Append generated files to Verilog source lists
        list(APPEND V_SRC ${SV2V_GEN})
        
        # Set the new sources to the IP
        ip_sources(${IP} SYSTEMVERILOG REPLACE ${SV_SRC})
        ip_sources(${IP} VERILOG REPLACE ${V_SRC})
    endif()

endfunction()




