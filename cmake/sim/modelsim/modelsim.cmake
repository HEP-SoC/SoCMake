include_guard(GLOBAL)

function(modelsim IP_LIB)
    cmake_parse_arguments(ARG "TARGET_PER_IP;QUIET" "TOP_MODULE;OUTDIR;ARGS" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    find_modelsim(REQUIRED)

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

    if(ARG_QUIET)
        set(ARG_QUIET QUIET)
    endif()

    unset(__lib_args)
    unset(__comp_tgts)

    get_ip_links(IPS_LIST ${IP_LIB})

    # Get all DPI-C compiler libraies and add to list of libraries
    foreach(ip ${IPS_LIST})
        get_target_property(ip_type ${ip} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND __lib_args -sv_lib $<TARGET_FILE_DIR:${ip}>/lib$<TARGET_FILE_BASE_NAME:${ip}>)
        endif()
    endforeach()

    unset(__libdirs)
    unset(__libnames)
    if(ARG_TARGET_PER_IP)   # In case TARGET_PER_IP is passed, a compile target is created per IP block
        set(list_comp_libs ${IPS_LIST})
        set(__no_deps_arg NO_DEPS)
    else()                 # Else only create target for compiling top level IP 
        set(list_comp_libs ${IP_LIB})
        unset(__no_deps_arg)
    endif()

    list(APPEND __lib_args -Ldir ${OUTDIR})
    foreach(ip ${list_comp_libs})
        get_target_property(ip_name ${ip} IP_NAME)
        if(ip_name) # If IP_NAME IS set, its SoCMake's IP_LIBRARY
            __modelsim_compile_lib(${ip} ${__no_deps_arg} OUTDIR ${OUTDIR} ${ARG_QUIET})
            if(NOT ${MODELSIM_IP_LIB_NAME} IN_LIST __libnames)
                list(APPEND __lib_args -L ${MODELSIM_IP_LIB_NAME})
                list(APPEND __libnames ${MODELSIM_IP_LIB_NAME})
            endif()
            list(APPEND __comp_tgts ${ip}_modelsim_complib)
        endif()
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} VHDL SYSTEMVERILOG VERILOG)

    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG +${def})
    endforeach()

    set(__VSIM_CMD ${MODELSIM_HOME}/bin/vsim
        ${__lib_args}
        ${CMP_DEFS_ARG}
        -c ${LIBRARY}.${ARG_TOP_MODULE}
        -do "run -all\; quit"
        $<$<BOOL:${ARG_QUIET}>:-quiet>
        )
    set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
    add_custom_target(
        run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND  ${__VSIM_CMD} -noautoldlibpath
        DEPENDS ${__comp_tgts}
        WORKING_DIRECTORY ${MODELSIM_IP_LIB_DIR}
        COMMENT ${DESCRIPTION}
        VERBATIM
    )
    set_property(TARGET run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

endfunction()


function(find_modelsim)
    cmake_parse_arguments(ARG "REQUIRED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    find_program(VSIM_EXEC vsim
        HINTS ${MODELSIM_HOME}/*/ $ENV{MODELSIM_HOME}/*/
        )

    if(NOT VSIM_EXEC AND ARG_REQUIRED)
        message(FATAL_ERROR "Modelsim was not found, please set MODELSIM_HOME, ENV{MODELSIM_HOME} or system PATH variable")
    endif()

    if(NOT MODELSIM_HOME)
        cmake_path(GET VSIM_EXEC PARENT_PATH __modelsim_bindir)
        cmake_path(GET __modelsim_bindir PARENT_PATH MODELSIM_HOME)
        set(MODELSIM_HOME ${MODELSIM_HOME} CACHE PATH "Path to Modelsim installation")
        mark_as_advanced(MODELSIM_HOME)
    endif()

endfunction()

function(__modelsim_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "QUIET;NO_DEPS" "OUTDIR;ARGS" "" ${ARGN})
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_modelsim)
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
        set(__VLOG_CMD COMMAND ${MODELSIM_HOME}/bin/vlog
                -nologo
                -sv
                -sv17compat
                $<$<BOOL:${ARG_QUIET}>:-quiet>
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

        set(__VCOM_CMD COMMAND ${MODELSIM_HOME}/bin/vcom
                -nologo
                $<$<BOOL:${ARG_QUIET}>:-quiet>
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
        ${IP_LIB}_modelsim_complib
        DEPENDS ${STAMP_FILE} ${STAMP_FILE_VHDL} ${IP_LIB}
    )
    set_property(TARGET ${IP_LIB}_modelsim_complib PROPERTY 
        DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with modelsim in library ${LIBRARY}")


    set(MODELSIM_IP_LIB_DIR  ${OUTDIR}   PARENT_SCOPE)
    set(MODELSIM_IP_LIB_NAME ${LIBRARY}  PARENT_SCOPE)
endfunction()
