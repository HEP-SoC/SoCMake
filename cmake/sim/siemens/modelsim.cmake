include_guard(GLOBAL)

function(modelsim IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;QUIET" "TOP_MODULE;OUTDIR;RUN_TARGET_NAME" "VCOM_ARGS;VLOG_ARGS;RUN_ARGS" ${ARGN})
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

    if(ARG_VLOG_ARGS)
        set(ARG_VLOG_ARGS VLOG_ARGS ${ARG_VLOG_ARGS})
    endif()

    if(ARG_VCOM_ARGS)
        set(ARG_VCOM_ARGS VCOM_ARGS ${ARG_VCOM_ARGS})
    endif()

    ### Compile with vcom and vlog
    __modelsim_compile_lib(${IP_LIB}
        OUTDIR ${OUTDIR}
        ${ARG_QUIET}
        ${ARG_VLOG_ARGS}
        ${ARG_VCOM_ARGS}
        )
    set(__comp_tgt ${IP_LIB}_modelsim_complib)

    set(__vsim_cmd vsim
        $<$<BOOL:${ARG_QUIET}>:-quiet>
        ${ARG_RUN_ARGS}
        -Ldir ${OUTDIR} ${LIB_SEARCH_DIRS}
        -c ${LIBRARY}.${ARG_TOP_MODULE}
        -do "run -all\; quit"
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND  ${__vsim_cmd} -noautoldlibpath
            DEPENDS ${__comp_tgt}
            WORKING_DIRECTORY ${OUTDIR}
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
    cmake_parse_arguments(ARG "QUIET" "OUTDIR;LIBRARY" "VLOG_ARGS;VCOM_ARGS" ${ARGN})
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

    get_ip_links(__ips ${IP_LIB})
    unset(all_stamp_files)
    unset(lib_search_dirs)
    foreach(lib ${__ips})

        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND lib_search_dirs -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
            continue()
        endif()

        # VHDL library of the current IP block, get it from SoCMake library if present
        # If neither LIBRARY property is set, or LIBRARY passed as argument, use "work" as default
        get_target_property(__comp_lib_name ${lib} LIBRARY)
        if(NOT __comp_lib_name)
            set(__comp_lib_name work)
        endif()
        if(ARG_LIBRARY)
            set(__comp_lib_name ${ARG_LIBRARY})
        endif()

        # Create output directoy for the VHDL library
        set(lib_outdir ${OUTDIR}/${__comp_lib_name})
        # Append current library outdir to list of search directories
        if(NOT ${lib_outdir} IN_LIST lib_search_dirs)
            list(APPEND lib_search_dirs -L ${lib_outdir})
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
            set(__vlog_cmd vlog
                    -nologo
                    -work ${lib_outdir}
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
            set(__vcom_cmd vcom
                    -nologo
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -work ${lib_outdir}
                    ${ARG_VCOM_ARGS}
                    ${VHDL_SOURCES}
                )
        endif()

        # Modelsim custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __modelsim_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__modelsim_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __modelsim_subdep_stamp_files ${__modelsim_${ip_dep}_stamp_files})
        endforeach()

        unset(__modelsim_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "Compile SV, and Verilog files for ${lib} with modelsim vlog")
            set(STAMP_FILE "${lib_outdir}/${lib}_vlog_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${__vlog_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${__modelsim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __modelsim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL files for ${lib} with modelsim vcom")
            set(STAMP_FILE "${lib_outdir}/${lib}_vcom_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${__vcom_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__modelsim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __modelsim_${lib}_stamp_files ${STAMP_FILE})
        endif()

    endforeach()

    if(NOT TARGET ${IP_LIB}_modelsim_complib)
        add_custom_target(
            ${IP_LIB}_modelsim_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_modelsim_complib PROPERTY 
            DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with modelsim in library ${LIBRARY}")
    endif()


    set(LIB_SEARCH_DIRS ${lib_search_dirs} PARENT_SCOPE)
endfunction()
