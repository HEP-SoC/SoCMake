include_guard(GLOBAL)

function(vivado_sim IP_LIB)
    cmake_parse_arguments(ARG "TARGET_PER_IP;NO_RUN_TARGET;GUI" "RUN_TARGET_NAME" "XVLOG_ARGS;XVHDL_ARGS;XELAB_ARGS;XSIM_ARGS;RUN_ARGS" ${ARGN})
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vivado_sim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_XVLOG_ARGS)
        set(ARG_XVLOG_ARGS XVLOG_ARGS ${ARG_XVLOG_ARGS})
    endif()
    if(ARG_XVHDL_ARGS)
        set(ARG_XVHDL_ARGS XVHDL_ARGS ${ARG_XVHDL_ARGS})
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    unset(__lib_args)
    unset(__ld_library_paths)
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            get_target_property(DPI_LIB_BINDIR ${ip} BINARY_DIR)
            list(APPEND __lib_args  --sv_root ${DPI_LIB_BINDIR} --sv_lib lib$<TARGET_FILE_BASE_NAME:${ip}>)
            set(__ld_library_paths "${__ld_library_paths}${DPI_LIB_BINDIR}:")
        endif()
    endforeach()

    if(ARG_TARGET_PER_IP)   # In case TARGET_PER_IP is passed, a compile target is created per IP block
        set(list_comp_libs ${IPS_LIST})
        set(__no_deps_arg NO_DEPS)
    else()
        set(list_comp_libs ${IP_LIB})
        unset(__no_deps_arg)
    endif()

    unset(__comp_tgts)
    foreach(ip ${list_comp_libs})
        get_target_property(ip_name ${ip} IP_NAME)
        if(ip_name) # If IP_NAME IS set, its SoCMake's IP_LIBRARY
            __vivado_sim_compile_lib(${ip} ${__no_deps_arg}
                OUTDIR ${OUTDIR}
                ${ARG_XVLOG_ARGS}
                ${ARG_XVHDL_ARGS}
                )
            list(APPEND __comp_tgts ${ip}_vivado_sim_complib)
        endif()
    endforeach()

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    ## Xelab command for elaborating simulation
    set(__xelab_cmd COMMAND xelab
            ${ARG_XELAB_ARGS}
            ${__lib_args}
            work.${IP_NAME}
            # -work ${OUTDIR}/${LIBRARY}
        )

    ### Clean files:
    #       * xelab.log, xelab.pb
    set(__clean_files 
        ${OUTDIR}/xelab.log
        ${OUTDIR}/xelab.pb
        ${OUTDIR}/xsim.dir/${LIBRARY}.${IP_NAME}
    )

    set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION} xelab")
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        # OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
        OUTPUT ${STAMP_FILE}
        COMMAND ${__xelab_cmd}
        COMMAND touch ${STAMP_FILE}
        COMMENT ${DESCRIPTION}
        BYPRODUCTS  ${__clean_files}
        WORKING_DIRECTORY ${OUTDIR}
        DEPENDS ${__comp_tgts} ${SOURCES}
        COMMAND_EXPAND_LISTS
        )

    add_custom_target(${IP_LIB}_vivado_sim
        DEPENDS ${STAMP_FILE} ${IP_LIB}
    )
    set_property(TARGET ${IP_LIB}_vivado_sim PROPERTY DESCRIPTION ${DESCRIPTION})


    ### Clean files:
    #       * xelab.log, xelab.pb
    set(__clean_files 
        ${OUTDIR}/xsim.log
        ${OUTDIR}/xsim.jou
        ${OUTDIR}/xsim.dir/${LIBRARY}.${IP_NAME}
    )

    ## XSIM command for running simulation
    set(__xsim_cmd xsim
        ${ARG_RUN_ARGS}
        ${LIBRARY}.${ARG_TOP_MODULE}
        $<IF:$<BOOL:${ARG_GUI}>,--gui,--R>
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:${__ld_library_paths}" ${__xsim_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            COMMENT ${DESCRIPTION}
            DEPENDS ${IP_LIB}_vivado_sim
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__xsim_cmd} PARENT_SCOPE)

endfunction()

function(__vivado_sim_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR;TOP_MODULE" "XVLOG_ARGS;XVHDL_ARGS" ${ARGN})
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

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vivado_sim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_NO_DEPS)
        set(ARG_NO_DEPS NO_DEPS)
    else()
        unset(ARG_NO_DEPS)
    endif()

    # SystemVerilog and Verilog files and arguments
    get_ip_sources(SV_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_NO_DEPS})
    if(SV_SOURCES)
        get_ip_include_directories(SV_INC_DIRS ${IP_LIB}  SYSTEMVERILOG VERILOG)
        get_ip_compile_definitions(SV_COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)

        foreach(dir ${SV_INC_DIRS})
            list(APPEND SV_ARG_INCDIRS -i ${dir})
        endforeach()

        foreach(def ${SV_COMP_DEFS})
            list(APPEND SV_CMP_DEFS_ARG -d ${def})
        endforeach()

        set(DESCRIPTION "Compile Verilog and SV files of ${IP_LIB} with vivado xvlog in library ${LIBRARY}")
        set(__xvlog_cmd COMMAND xvlog
                --sv
                ${ARG_XVLOG_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
                # -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    # VHDL files and arguments
    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_NO_DEPS})
    if(VHDL_SOURCES)

        set(__xvhdl_cmd COMMAND xvhdl
                ${ARG_XVHDL_ARGS}
                ${VHDL_SOURCES}
                # -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    ### Clean files:
    #       * xvlog.log, xvlog.pb, xvhdl.log, xvhdl.pb
    set(__clean_files 
        ${OUTDIR}/xvlog.log
        ${OUTDIR}/xvlog.pb
        ${OUTDIR}/xvhdl.log
        ${OUTDIR}/xvhdl.pb
        ${OUTDIR}/xsim.dir/${LIBRARY}
    )

    if(NOT TARGET ${IP_LIB}_vivado_sim_complib)
        set(DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with vivado in library ${LIBRARY}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            # COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
            ${__xvlog_cmd}
            ${__xvhdl_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            DEPENDS ${SV_SOURCES} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_vivado_sim_complib
            DEPENDS ${STAMP_FILE} ${STAMP_FILE_VHDL} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_vivado_sim_complib PROPERTY DESCRIPTION ${DESCRIPTION})
    endif() 

endfunction()

