include_guard(GLOBAL)

function(__ghdl_get_standard_arg OUTVAR)
    set(SUPPORTED_VHDL_STANDARDS  87 93c 93 00 02 08)
    if(ARGN)
        if(NOT ${ARGN} IN_LIST SUPPORTED_VHDL_STANDARDS)
            message(FATAL_ERROR "VHDL standard not supported ${ARGN}, supported standards: ${ARGN}")
        endif()
        set(${OUTVAR} ${ARGN} PARENT_SCOPE)
    else()
        set(${OUTVAR} 93 PARENT_SCOPE)
    endif()
endfunction()

function(ghdl IP_LIB)
    cmake_parse_arguments(ARG "TARGET_PER_IP;NO_RUN_TARGET;" "OUTDIR;TOP_MODULE;EXECUTABLE_NAME;STANDARD" "ANALYZE_ARGS;ELABORATE_ARGS;RUN_ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_ghdl)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    # get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    # if(NOT LIBRARY)
        set(LIBRARY work)
    # endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    if(ARG_ANALYZE_ARGS)
        set(ARG_ANALYZE_ARGS ANALYZE_ARGS ${ARG_ANALYZE_ARGS})
    endif()

    if(NOT ARG_EXECUTABLE_NAME)
        set(ARG_EXECUTABLE_NAME "${IP_LIB}_ghdl_exec")
    endif()
    set(SIM_EXEC_PATH "${OUTDIR}/${ARG_EXECUTABLE_NAME}")

    get_ip_links(IPS_LIST ${IP_LIB})

    if(ARG_TARGET_PER_IP)   # In case TARGET_PER_IP is passed, a compile target is created per IP block
        set(list_comp_libs ${IPS_LIST})
        set(__no_deps_arg NO_DEPS)
    else()
        set(list_comp_libs ${IP_LIB})
        unset(__no_deps_arg)
    endif()

    ##### GHDL Analyze

    unset(__comp_tgts)
    foreach(ip ${list_comp_libs})
        get_target_property(ip_name ${ip} IP_NAME)
        if(ip_name) # If IP_NAME IS set, its SoCMake's IP_LIBRARY
            __ghdl_compile_lib(${ip} ${__no_deps_arg}
                OUTDIR ${OUTDIR}
                STANDARD ${STANDARD}
                ${ARG_ANALYZE_ARGS}
                )
            list(APPEND __comp_tgts ${ip}_ghdl_complib)
        endif()
    endforeach()

    ##### GHDL Elaborate
    if(NOT TARGET ${IP_LIB}_ghdl)
        get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL)
        set(__ghdl_elab_cmd ghdl elaborate
                --std=${STANDARD}
                -fsynopsys
                -o ${SIM_EXEC_PATH}
                ${ARG_ELABORATE_ARGS}
                # -P${OUTDIR}
                ${__lib_args}
                ${LIBRARY}.${ARG_TOP_MODULE}
                )

        ### Clean files
        #       * For elaborate "e~${ARG_EXECUTABLE_NAME}.o" and executable gets created
        set(__clean_files "${OUTDIR}/e~${ARG_EXECUTABLE_NAME}.o")

        set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_ghdl.stamp")
        add_custom_command(
            OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            COMMAND ${__ghdl_elab_cmd}
            COMMAND touch ${STAMP_FILE}
            BYPRODUCTS  ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${__comp_tgts} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
            )

        add_custom_target(${IP_LIB}_ghdl
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(__ghdl_run_cmd ${SIM_EXEC_PATH} ${ARG_RUN_ARGS})
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${__ghdl_run_cmd}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${IP_LIB}_ghdl
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__ghdl_run_cmd} PARENT_SCOPE)

endfunction()

function(__ghdl_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR;STANDARD" "ANALYZE_ARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    # if(NOT LIBRARY)
        set(LIBRARY work)
    # endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_ghdl)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_NO_DEPS)
        set(ARG_NO_DEPS NO_DEPS)
    else()
        unset(ARG_NO_DEPS)
    endif()

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    # VHDL files and arguments
    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_NO_DEPS})
    set(__ghdl_analyze_cmd COMMAND ghdl analyze
            --std=${STANDARD}
            -fsynopsys
            ${ARG_ANALYZE_ARGS}
            --work=${LIBRARY}
            --workdir=${OUTDIR}
            ${VHDL_SOURCES}
            )

    ### Clean files:
    #       * All .o files from vhdl sources
    unset(__clean_files)
    foreach(source ${VHDL_SOURCES})
        get_filename_component(source_basename ${source} NAME_WLE)
        list(APPEND __clean_files "${OUTDIR}/${source_basename}.o")
    endforeach()
    list(APPEND __clean_files "${OUTDIR}/${LIBRARY}-obj${STANDARD}.cf")

    if(NOT TARGET ${IP_LIB}_ghdl_complib)
        set(DESCRIPTION "Compile VHDL for ${IP_LIB} with ghdl in library ${LIBRARY}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            ${__ghdl_analyze_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            DEPENDS ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_ghdl_complib
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl_complib PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

endfunction()
