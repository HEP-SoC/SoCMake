include_guard(GLOBAL)

function(modelsim IP_LIB)
    cmake_parse_arguments(ARG "TARGET_PER_IP;NO_RUN_TARGET;QUIET" "TOP_MODULE;OUTDIR;RUN_TARGET_NAME" "VCOM_ARGS;VLOG_ARGS;RUN_ARGS" ${ARGN})
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
    file(MAKE_DIRECTORY ${OUTDIR})

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
    
    if(ARG_VLOG_ARGS)
        set(ARG_VLOG_ARGS VLOG_ARGS ${ARG_VLOG_ARGS})
    endif()

    if(ARG_VCOM_ARGS)
        set(ARG_VCOM_ARGS VCOM_ARGS ${ARG_VCOM_ARGS})
    endif()

    list(APPEND __lib_args -Ldir ${OUTDIR})
    foreach(ip ${list_comp_libs})
        get_target_property(ip_name ${ip} IP_NAME)
        if(ip_name) # If IP_NAME IS set, its SoCMake's IP_LIBRARY
            __modelsim_compile_lib(${ip} ${__no_deps_arg} 
                OUTDIR ${OUTDIR}
                ${ARG_QUIET}
                ${ARG_VLOG_ARGS}
                ${ARG_VCOM_ARGS}
                )
            if(NOT ${__MODELSIM_IP_LIB_NAME} IN_LIST __libnames)
                list(APPEND __lib_args -L ${__MODELSIM_IP_LIB_NAME})
                list(APPEND __libnames ${__MODELSIM_IP_LIB_NAME})
            endif()
            list(APPEND __comp_tgts ${ip}_modelsim_complib)
        endif()
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} VHDL SYSTEMVERILOG VERILOG)

    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG +${def})
    endforeach()

    set(__vsim_cmd ${MODELSIM_HOME}/bin/vsim
        ${__lib_args}
        ${CMP_DEFS_ARG}
        ${ARG_RUN_ARGS}
        -c ${LIBRARY}.${ARG_TOP_MODULE}
        -do "run -all\; quit"
        $<$<BOOL:${ARG_QUIET}>:-quiet>
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND  ${__vsim_cmd} -noautoldlibpath
            DEPENDS ${__comp_tgts}
            WORKING_DIRECTORY ${__MODELSIM_IP_LIB_DIR}
            COMMENT ${DESCRIPTION}
            VERBATIM
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__vsim_cmd} PARENT_SCOPE)

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
    cmake_parse_arguments(ARG "QUIET;NO_DEPS" "OUTDIR;LIBRARY" "VLOG_ARGS;VCOM_ARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)


    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_modelsim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # if(ARG_NO_DEPS)
    #     set(ARG_NO_DEPS NO_DEPS)
    # else()
    #     unset(ARG_NO_DEPS)
    # endif()

    get_ip_links(__ips ${IP_LIB})
    unset(all_stamp_files)
    foreach(lib ${__ips})
        get_target_property(__comp_lib_name ${lib} LIBRARY)
        if(NOT __comp_lib_name)
            set(__comp_lib_name work)
        endif()
        if(ARG_LIBRARY)
            set(__comp_lib_name ${ARG_LIBRARY})
        endif()

        # SystemVerilog and Verilog files and arguments
        unset(__vlog_cmd)
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG NO_DEPS)
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG NO_DEPS)

            foreach(dir ${SV_INC_DIRS})
                list(APPEND SV_ARG_INCDIRS +incdir+${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG +define+${def})
            endforeach()

            set(DESCRIPTION "Compile Verilog and SV files of ${lib} with modelsim vlog")
            set(__vlog_cmd COMMAND ${MODELSIM_HOME}/bin/vlog
                    -nologo
                    -work ${OUTDIR}/${__comp_lib_name}
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -sv
                    -sv17compat
                    ${ARG_VLOG_ARGS}
                    ${SV_ARG_INCDIRS}
                    ${SV_CMP_DEFS_ARG}
                    ${SV_SOURCES}
                )
        endif()

        # VHDL files and arguments
        unset(__vcom_cmd)
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS)
        if(VHDL_SOURCES)
            set(__vcom_cmd COMMAND ${MODELSIM_HOME}/bin/vcom
                    -nologo
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -work ${OUTDIR}/${__comp_lib_name}
                    ${ARG_VCOM_ARGS}
                    ${VHDL_SOURCES}
                )
        endif()

        set(DESCRIPTION "Compile VHDL, SV, and Verilog files for ${lib} with modelsim vcom")
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            COMMAND ${__vlog_cmd}
                    ${__vcom_cmd}
            COMMAND touch ${STAMP_FILE}
            BYPRODUCTS ${OUTDIR}/${__comp_lib_name}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${SV_SOURCES} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
        )

        list(APPEND all_stamp_files ${STAMP_FILE})

    endforeach()

    if(NOT TARGET ${IP_LIB}_modelsim_complib)
        add_custom_target(
            ${IP_LIB}_modelsim_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_modelsim_complib PROPERTY 
            DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with modelsim in library ${LIBRARY}")
    endif()


    set(__MODELSIM_IP_LIB_DIR  ${OUTDIR}   PARENT_SCOPE)
    set(__MODELSIM_IP_LIB_NAME ${LIBRARY}  PARENT_SCOPE)
endfunction()
