# TODO iterate over linked libraries and replace SYSTEMVERILOG_SOURCES with VERILOG_SOURCES instead
# TODO create a new library instead???
include_guard(GLOBAL)

function(tmrg IP_LIB)
    cmake_parse_arguments(ARG "REPLACE;SED_WOR;NO_COMMON_DEFINITIONS" "OUTDIR;CONFIG_FILE" "" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

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

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})
    list(REMOVE_DUPLICATES SOURCES)

    foreach(vfile ${SOURCES})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        get_filename_component(V_SOURCE_EXT ${vfile} EXT)
        list(APPEND V_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}TMR${V_SOURCE_EXT}")
        # execute_process(COMMAND touch ${V_GEN}) # TODO Needed???
    endforeach()
    set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

    set(TMRG_COMMAND 
        ${Python3_VIRTUAL_ENV}/bin/tmrg --stats --tmr-dir=${OUTDIR} ${ARG_CONFIG_FILE} ${SOURCES};
        )

    if(ARG_SED_WOR)
        set(SED_COMMAND
            COMMAND sed -i "s/wor/wire/g" ${V_GEN}
            )
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${V_GEN} ${STAMP_FILE}
        COMMAND ${TMRG_COMMAND}
        ${SED_COMMAND}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SOURCES} ${V_GEN}
        )

    if(ARG_REPLACE)
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
        set_property(TARGET ${IP_LIB} PROPERTY IP_NAME ${TOP_MODULE}TMR)

        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_GEN})
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES "")
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    endif()

endfunction()

