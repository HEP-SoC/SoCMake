include_guard(GLOBAL)

function(vcs IP_LIB)
    cmake_parse_arguments(ARG "TARGET_PER_IP;NO_RUN_TARGET;GUI" "OUTDIR;EXECUTABLE_NAME;RUN_TARGET_NAME;TOP_MODULE" "VLOGAN_ARGS;VHDLAN_ARGS;VCS_ARGS;RUN_ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vcs)
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

    if(ARG_VLOGAN_ARGS)
        set(ARG_VLOGAN_ARGS VLOGAN_ARGS ${ARG_VLOGAN_ARGS})
    endif()
    if(ARG_VHDLAN_ARGS)
        set(ARG_VHDLAN_ARGS VHDLAN_ARGS ${ARG_VHDLAN_ARGS})
    endif()
    if(ARG_VCS_ARGS)
        set(ARG_VCS_ARGS VCS_ARGS ${ARG_VCS_ARGS})
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    unset(__lib_args)
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND __lib_args $<TARGET_FILE:${ip}>)
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
            __vcs_compile_lib(${ip} ${__no_deps_arg}
                OUTDIR ${OUTDIR}
                ${ARG_VLOGAN_ARGS}
                ${ARG_VHDLAN_ARGS}
                ${ARG_VCS_ARGS}
                )
            list(APPEND __comp_tgts ${ip}_vcs_complib)
        endif()
    endforeach()

    if(NOT ARG_EXECUTABLE_NAME)
        set(ARG_EXECUTABLE_NAME ${IP_LIB}_vcs_exec)
    endif()
    set(SIM_EXEC_PATH ${OUTDIR}/${ARG_EXECUTABLE_NAME})

    ## VCS command for compiling executable
    if(NOT TARGET ${IP_LIB}_vcs)
        set(__vcs_cmd vcs
                -full64
                -q
                ${__lib_args}
                -o ${SIM_EXEC_PATH}
                ${ARG_VCS_ARGS}
                ${LIBRARY}.${ARG_TOP_MODULE}
                # $<$<BOOL:${ARG_GUI}>:-gui>
                )
        set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_vcs.stamp")
        add_custom_command(
            OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            COMMAND ${__vcs_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS  ${OUTDIR}/csrc ${OUTDIR}/${ARG_EXECUTABLE_NAME}.daidir
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${__comp_tgts} ${VCS_COMPLIB_STAMP_FILE}
            )

        add_custom_target(${IP_LIB}_vcs
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_vcs PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(__vcsrun_cmd ${SIM_EXEC_PATH} ${ARG_RUN_ARGS})
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${__vcsrun_cmd}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${IP_LIB}_vcs
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__vcsrun_cmd} PARENT_SCOPE)

endfunction()

function(__vcs_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR;TOP_MODULE" "VLOGAN_ARGS;VHDLAN_ARGS;VCS_ARGS" ${ARGN})
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vcs)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

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
            list(APPEND SV_ARG_INCDIRS +incdir+${dir})
        endforeach()

        foreach(def ${SV_COMP_DEFS})
            list(APPEND SV_CMP_DEFS_ARG +define+${def})
        endforeach()

        set(DESCRIPTION "Compile Verilog and SV files of ${IP_LIB} with vcs vlogan in library ${LIBRARY}")
        set(__vlogan_cmd COMMAND vlogan
                -full64
                -q
                -sverilog
                ${ARG_VLOGAN_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
                # -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    # VHDL files and arguments
    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_NO_DEPS})
    if(VHDL_SOURCES)
        set(__vhdlan_cmd COMMAND vhdlan
                -full64
                -q
                ${ARG_VHDLAN_ARGS}
                ${VHDL_SOURCES}
                    # -work ${OUTDIR}/${LIBRARY}
                )
    endif()

    if(NOT TARGET ${IP_LIB}_vcs_complib)
        set(DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with vcs in library ${LIBRARY}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            ${__vlogan_cmd}
            ${__vhdlan_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${OUTDIR}/64 ${OUTDIR}/AN.DB
            DEPENDS ${SV_SOURCES} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_vcs_complib
            DEPENDS ${STAMP_FILE} ${STAMP_FILE_VHDL} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_vcs_complib PROPERTY 
            DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with vcs in library ${LIBRARY}")
        set(VCS_COMPLIB_STAMP_FILE ${STAMP_FILE} PARENT_SCOPE)
    endif()

endfunction()
