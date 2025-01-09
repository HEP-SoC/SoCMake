#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium simulation on IP_LIB.
#
# It will create a target **run_<IP_LIB>_xcelium** that will start the xcelium simulation
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword GUI: launch SimVision gui together with the simulation
# :type GUI: boolean
#]]

include_guard(GLOBAL)

function(xcelium IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI" "RUN_TARGET_NAME;TOP_MODULE" "XMVLOG_ARGS;XMVHDL_ARGS;XMELAB_ARGS;RUN_ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    # if(NOT LIBRARY)
        set(LIBRARY worklib)
    # endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_xcelium)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_XMVLOG_ARGS)
        set(ARG_XMVLOG_ARGS XMVLOG_ARGS ${ARG_XMVLOG_ARGS})
    endif()
    if(ARG_XMVHDL_ARGS)
        set(ARG_XMVHDL_ARGS XMVHDL_ARGS ${ARG_XMVHDL_ARGS})
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    unset(__lib_args)
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND __lib_args -sv_lib $<TARGET_FILE_DIR:${ip}>/lib$<TARGET_FILE_BASE_NAME:${ip}>)
        endif()
    endforeach()

    __xcelium_compile_lib(${IP_LIB}
        OUTDIR ${OUTDIR}
        ${ARG_XMVLOG_ARGS}
        ${ARG_XMVHDL_ARGS}
        )
    set(__comp_tgts ${IP_LIB}_xcelium_complib)

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    ### Elaborate with xmelab
    set(__xmelab_cmd COMMAND xmelab
            -64bit
            ${ARG_XMELAB_ARGS}
            worklib.${ARG_TOP_MODULE}
            # -work ${OUTDIR}/${LIBRARY}
        )

    ### Clean files:
    #       * 
    set(__clean_files 
        ${OUTDIR}/xmelab.log
        ${OUTDIR}/xcelium.d
    )

    if(NOT TARGET ${IP_LIB}_xcelium)
        set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION} xmelab")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            # OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            OUTPUT ${STAMP_FILE}
            COMMAND ${__xmelab_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS  ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${__comp_tgts} ${SOURCES}
            COMMAND_EXPAND_LISTS
            )

        add_custom_target(${IP_LIB}_xcelium
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_xcelium PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    ## XMSIM command for running simulation

    ### Clean files:
    #       * 
    set(__clean_files 
        ${OUTDIR}/xmsim.log
        ${OUTDIR}/xcelium.d
    )

    set(__xmsim_cmd xmsim
        -64bit
        ${__lib_args}
        ${ARG_RUN_ARGS}
        ${LIBRARY}.${ARG_TOP_MODULE}
        $<$<BOOL:${ARG_GUI}>:-gui>

        # $<$<BOOL:${ARG_QUIET}>:-quiet>
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${__xmsim_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            COMMENT ${DESCRIPTION}
            DEPENDS ${IP_LIB}_xcelium
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__xmsim_cmd} PARENT_SCOPE)

endfunction()

function(__xcelium_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR;TOP_MODULE" "XMVLOG_ARGS;XMVHDL_ARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    # if(NOT LIBRARY)
        set(LIBRARY worklib)
    # endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_xcelium)
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
            list(APPEND SV_ARG_INCDIRS -INCDIR ${dir})
        endforeach()

        foreach(def ${SV_COMP_DEFS})
            list(APPEND SV_CMP_DEFS_ARG -DEFINE ${def})
        endforeach()

        set(DESCRIPTION "Compile Verilog and SV files of ${IP_LIB} with xcelium xmvlog in library ${LIBRARY}")
        set(__xmvlog_cmd COMMAND xmvlog
                -64bit
                -sv
                ${ARG_XMVLOG_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
                # -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    # VHDL files and arguments
    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_NO_DEPS})
    if(VHDL_SOURCES)
        get_ip_include_directories(VHDL_INC_DIRS  ${IP_LIB} VHDL)
        get_ip_compile_definitions(VHDL_COMP_DEFS ${IP_LIB} VHDL)

        set(__xmvhdl_cmd COMMAND xmvhdl
                -64bit
                ${ARG_XMVHDL_ARGS}
                ${VHDL_SOURCES}
                # -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    ### Clean files:
    #       * xmvlog.log, xmvhdl.log
    set(__clean_files 
        ${OUTDIR}/xmvlog.log
        ${OUTDIR}/xmvhdl.log
        ${OUTDIR}/xcelium.d
    )

    if(NOT TARGET ${IP_LIB}_xcelium_complib)
        set(DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with xcelium in library ${LIBRARY}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} #${OUTDIR}/${LIBRARY}
            # COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
            ${__xmvlog_cmd}
            ${__xmvhdl_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            DEPENDS ${SV_SOURCES} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_xcelium_complib
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_xcelium_complib PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    # set(__XCELIUM_IP_LIB_DIR  ${OUTDIR}   PARENT_SCOPE)
    # set(__XCELIUM_IP_LIB_NAME ${LIBRARY}  PARENT_SCOPE)
endfunction()
