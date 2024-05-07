# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
include_guard(GLOBAL)

function(set_sv2v_sources IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    # Get any prior TMRG sources
    get_sv2v_sources(_sv2v_src ${IP_LIB})

    set(_sv2v_src ${_sv2v_src} ${ARGN})
    # Set the target property with the new list of source files
    set_property(TARGET ${_reallib} PROPERTY SV2V ${_sv2v_src})
endfunction()

function(get_sv2v_sources OUT_VAR IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})
    get_ip_property(SV2V_SRC ${IP_LIB} SV2V)
    list(REMOVE_DUPLICATES SV2V_SRC)
    set(${OUT_VAR} ${SV2V_SRC} PARENT_SCOPE)
endfunction()

function(sv2v IP_LIB)
    cmake_parse_arguments(ARG "REPLACE;TMR;HWIF_WIRE" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/sv2v)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    get_sv2v_sources(SV2V_SRC ${IP_LIB})
    foreach(vfile ${SV2V_SRC})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        if(NOT ${V_SOURCE_WO_EXT} MATCHES ".*regblock_pkg$")
            list(APPEND V_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}.v")
        endif()
    endforeach()
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INCDIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})
    foreach(dir ${INCDIRS})
        list(APPEND INCDIR_ARG -I${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    # HACK ALERT!!
    if(ARG_HWIF_WIRE)
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
        set(AWK_COMMAND
            COMMAND ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/hwif_awk.sh ${OUTDIR}/${TOP_MODULE}_regblock.v ${OUTDIR}/../regblock/${TOP_MODULE}.sv
        )
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${V_GEN}
        COMMAND sv2v ${SV2V_SRC} ${INCDIR_ARG} ${CMP_DEFS_ARG} -w ${OUTDIR}
        ${AWK_COMMAND}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SV2V_SRC}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SV2V_SRC} ${V_GEN}
    )

    if(ARG_REPLACE)
        # Get original sources
        get_ip_sources(SV_SRC ${IP_LIB} SYSTEMVERILOG)
        get_ip_sources(V_SRC ${IP_LIB} VERILOG)

        # Remove SV2V files from original sources
        list(REMOVE_ITEM SV_SRC ${SV2V_SRC}) 
        list(REMOVE_ITEM V_SRC ${SV2V_SRC}) 

        # Append generated files to Verilog source lists
        list(APPEND V_SRC ${V_GEN})
            
        # Set the file list properties
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES ${SV_SRC})
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_SRC})
        
        # If TMR is set, remove original .sv files from TMRG list and replace with .v outputs
        if(ARG_TMR)
            get_tmrg_sources(TMRG_SRC ${IP_LIB})
            foreach(i ${SV2V_SRC})
                if(i IN_LIST TMRG_SRC)
                    list(REMOVE_ITEM TMRG_SRC ${i}) 
                    get_filename_component(V_SOURCE_WO_EXT ${i} NAME_WE)
                    set(_i_v "${OUTDIR}/${V_SOURCE_WO_EXT}.v")
                    if(_i_v IN_LIST V_GEN)
                        list(APPEND TMRG_SRC ${_i_v}) 
                    endif()
                endif()
            endforeach()
            set_property(TARGET ${IP_LIB} PROPERTY TMRG ${TMRG_SRC})
        else()
            # Add dependency to the IP
            add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
    endif()

endfunction()




