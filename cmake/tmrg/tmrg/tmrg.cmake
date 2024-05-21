include_guard(GLOBAL)

function(set_tmrg_sources IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    # Get any prior TMRG sources
    get_tmrg_sources(_tmrg_src ${IP_LIB})

    set(_tmrg_src ${_tmrg_src} ${ARGN})
    # Set the target property with the new list of source files
    set_property(TARGET ${_reallib} PROPERTY TMRG ${_tmrg_src})
endfunction()

function(get_tmrg_sources OUT_VAR IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})
    get_ip_property(TMRG_SRC ${IP_LIB} TMRG)
    list(REMOVE_DUPLICATES TMRG_SRC)
    set(${OUT_VAR} ${TMRG_SRC} PARENT_SCOPE)
endfunction()

function(tmrg IP_LIB)
    cmake_parse_arguments(ARG "REPLACE;SED_WOR;NO_COMMON_DEFINITIONS" "OUTDIR;CONFIG_FILE" "" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/tmrg)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    if(ARG_CONFIG_FILE)
        set(ARG_CONFIG_FILE -c ${ARG_CONFIG_FILE})
    else()
        unset(ARG_CONFIG_FILE)
    endif()

    get_tmrg_sources(TMRG_SRC ${IP_LIB})
    foreach(vfile ${TMRG_SRC})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        get_filename_component(V_SOURCE_EXT ${vfile} EXT)
        list(APPEND V_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}TMR${V_SOURCE_EXT}")
    endforeach()
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    set(TMRG_COMMAND 
        ${Python3_VIRTUAL_ENV}/bin/tmrg --stats --tmr-dir=${OUTDIR} ${ARG_CONFIG_FILE} ${TMRG_SRC}
    )

    if(ARG_NO_COMMON_DEFINITIONS)
        set(TMRG_COMMAND ${TMRG_COMMAND} --no-common-definitions)
    endif()

    if(ARG_SED_WOR)
        set(SED_COMMAND COMMAND sed -i "s/wor/wire/g" ${V_GEN})
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${STAMP_FILE}
        COMMAND ${TMRG_COMMAND}
        ${SED_COMMAND}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${TMRG_SRC}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${TMRG_SRC} ${V_GEN}
    )

    if(ARG_REPLACE)
        # Replace top module name adding TMR
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
        set_property(TARGET ${IP_LIB} PROPERTY IP_NAME ${TOP_MODULE}TMR)

        # Get original sources
        get_ip_sources(SV_SRC ${IP_LIB} SYSTEMVERILOG)
        get_ip_sources(V_SRC ${IP_LIB} VERILOG)

        # Remove TMRG files from original sources
        list(REMOVE_ITEM SV_SRC ${TMRG_SRC}) 
        list(REMOVE_ITEM V_SRC ${TMRG_SRC}) 

        # Append generated files to correct source lists
        foreach(i ${V_GEN})
            get_filename_component(FILE_EXT ${i} EXT)
            if("${FILE_EXT}" STREQUAL ".sv")
                list(APPEND SV_SRC ${i})
            elseif("${FILE_EXT}" STREQUAL ".v")
                list(APPEND V_SRC ${i})
            endif()
        endforeach()
            
        # Set the file list properties
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES ${SV_SRC})
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_SRC})

        # Add dependency to the IP
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()

