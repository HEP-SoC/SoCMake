include_guard(GLOBAL)

function(modelsim_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "OUTDIR;ARGS" "" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    if(NOT LIBRARY)
        set(LIBRARY work)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_NO_DEPS)
        set(ARG_NO_DEPS NO_DEPS)
    else()
        unset(ARG_NO_DEPS)
    endif()

    # SystemVerilog and Verilog files and arguments
    unset(__VLOG_CMD)
    get_ip_sources(SV_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_NO_DEPS} )
    if(SV_SOURCES)
        get_ip_include_directories(SV_INC_DIRS ${IP_LIB}  SYSTEMVERILOG VERILOG)
        get_ip_compile_definitions(SV_COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)

        foreach(dir ${SV_INC_DIRS})
            list(APPEND SV_ARG_INCDIRS +incdir+${dir})
        endforeach()

        foreach(def ${SV_COMP_DEFS})
            list(APPEND SV_CMP_DEFS_ARG +define+${def})
        endforeach()

        set(DESCRIPTION "Compile Verilog and SV files of ${IP_LIB} with modelsim vlog in library ${LIBRARY}")
        set(__VLOG_CMD COMMAND vlog
                -nologo
                -sv
                -sv17compat
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
                -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    # VHDL files and arguments
    unset(__VCOM_CMD)
    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_NO_DEPS})
    if(VHDL_SOURCES)
        get_ip_include_directories(VHDL_INC_DIRS  ${IP_LIB} VHDL)
        get_ip_compile_definitions(VHDL_COMP_DEFS ${IP_LIB} VHDL)

        foreach(dir ${VHDL_INC_DIRS})
            list(APPEND VHDL_ARG_INCDIRS +incdir+${dir})
        endforeach()

        foreach(def ${VHDL_COMP_DEFS})
            list(APPEND VHDL_CMP_DEFS_ARG +define+${def})
        endforeach()

        set(__VCOM_CMD COMMAND vcom
                -nologo
                ${VHDL_ARG_INCDIRS}
                ${VHDL_CMP_DEFS_ARG}
                ${VHDL_SOURCES}
                -work ${OUTDIR}/${LIBRARY}
            )
    endif()

    set(DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with modelsim in library ${LIBRARY}")
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${OUTDIR}/${LIBRARY}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
            ${__VLOG_CMD}
            ${__VCOM_CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SV_SOURCES} ${VHDL_SOURCES}
        COMMENT ${DESCRIPTION}
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${STAMP_FILE_VHDL} ${IP_LIB}
    )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY 
        DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with modelsim in library ${LIBRARY}")


    set(MODELSIM_IP_LIB_DIR  ${OUTDIR}   PARENT_SCOPE)
    set(MODELSIM_IP_LIB_NAME ${LIBRARY}  PARENT_SCOPE)
endfunction()

function(modelsim IP_LIB)
    # Parse the function arguments
    cmake_parse_arguments(ARG "HIER_TARGETS" "TOP_MODULE;OUTDIR;ARGS" "" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    if(NOT LIBRARY)
        set(LIBRARY work)
    endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(IP_NAME ${IP_LIB} IP_NAME)
        set(ARG_TOP_MODULE ${IP_NAME})
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    unset(LIB_ARGS)
    unset(MODELSIM_COMP_TARGETS)
    if(ARG_HIER_TARGETS)
        get_ip_links(IPS_LIST ${IP_LIB})
        foreach(ip ${IPS_LIST})
            modelsim_compile_lib(${ip} NO_DEPS)
            list(APPEND LIB_ARGS  -Ldir ${MODELSIM_IP_LIB_DIR} -L ${MODELSIM_IP_LIB_NAME})
            list(APPEND MODELSIM_COMP_TARGETS ${ip}_modelsim_compile_lib)
        endforeach()
    else()
        modelsim_compile_lib(${IP_LIB})
        list(APPEND LIB_ARGS  -Ldir ${MODELSIM_IP_LIB_DIR} -L ${MODELSIM_IP_LIB_NAME})
        list(APPEND MODELSIM_COMP_TARGETS ${IP_LIB}_modelsim_compile_lib)
    endif()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} VHDL SYSTEMVERILOG VERILOG)

    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG +${def})
    endforeach()

    set(__VSIM_CMD vsim
        ${LIB_ARGS}
        ${CMP_DEFS_ARG}
        -c ${LIBRARY}.${ARG_TOP_MODULE}
        -do "run -all\; quit"

        )
    set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
    add_custom_target(
        run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND ${__VSIM_CMD}
        DEPENDS ${MODELSIM_COMP_TARGETS}
        COMMENT ${DESCRIPTION}
        VERBATIM
    )
    set_property(TARGET run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

endfunction()

