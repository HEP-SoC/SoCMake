include_guard(GLOBAL)

function(vcs IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI" "OUTDIR;EXECUTABLE_NAME;RUN_TARGET_NAME;TOP_MODULE;LIBRARY" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS" ${ARGN})
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
    if(ARG_LIBRARY)
        set(LIBRARY ${ARG_LIBRARY})
        set(ARG_LIBRARY LIBRARY ${LIBRARY})
    endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vcs)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(NOT ARG_EXECUTABLE_NAME)
        set(ARG_EXECUTABLE_NAME ${IP_LIB}_vcs_exec)
    endif()
    set(SIM_EXEC_PATH ${OUTDIR}/${ARG_EXECUTABLE_NAME})


    if(ARG_SV_COMPILE_ARGS)
        set(ARG_SV_COMPILE_ARGS SV_COMPILE_ARGS ${ARG_SV_COMPILE_ARGS})
    endif()
    if(ARG_VHDL_COMPILE_ARGS)
        set(ARG_VHDL_COMPILE_ARGS VHDL_COMPILE_ARGS ${ARG_VHDL_COMPILE_ARGS})
    endif()
    if(ARG_ELABORATE_ARGS)
        set(ARG_ELABORATE_ARGS ELABORATE_ARGS ${ARG_ELABORATE_ARGS})
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    if(NOT TARGET ${IP_LIB}_vcs_complib)
        __vcs_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_LIBRARY}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            )
    endif()
    set(comp_tgt ${IP_LIB}_vcs_complib)

    __get_vcs_search_lib_args(${IP_LIB} 
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(dpi_libs_args ${DPI_LIBS_ARGS})


    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    ## VCS command for compiling executable
    if(NOT TARGET ${IP_LIB}_vcs)
        set(elaborate_cmd vcs
                -full64
                -nc
                -q
                # $<$<BOOL:${ARG_GUI}>:-gui>
                ${dpi_libs_args}
                ${ARG_ELABORATE_ARGS}
                ${LIBRARY}.${ARG_TOP_MODULE}
                -o ${SIM_EXEC_PATH}
                )

        ### Clean files:
        #       * 
        set(__clean_files 
            ${OUTDIR}/csrc
            ${OUTDIR}/${ARG_EXECUTABLE_NAME}.daidir
        )

        set(DESCRIPTION "Elaborate ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            COMMAND ${elaborate_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${comp_tgt} ${IP_LIB}
            )

        add_custom_target(${IP_LIB}_vcs
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_vcs PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(run_sim_cmd ${SIM_EXEC_PATH} 
            ${ARG_RUN_ARGS}
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${run_sim_cmd}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${IP_LIB}_vcs
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)

endfunction()

function(__vcs_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY;TOP_MODULE" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_vcs)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    # Find the VCS include directory, needed for VPI/DPI libraries
    __add_vcs_cxx_properties_to_libs(${IP_LIB})

    get_ip_links(__ips ${IP_LIB})
    unset(all_stamp_files)
    foreach(lib ${__ips})
        # Library of the current IP block, get it from SoCMake library if present
        # If neither LIBRARY property is set, or LIBRARY passed as argument, use "work" as default
        get_target_property(__comp_lib_name ${lib} LIBRARY)
        if(NOT __comp_lib_name)
            set(__comp_lib_name work)
        endif()
        if(ARG_LIBRARY)
            set(__comp_lib_name ${ARG_LIBRARY})
        endif()

        # Create output directory for the library
        set(lib_outdir ${OUTDIR}/${__comp_lib_name})

        __get_vcs_search_lib_args(${lib}
            OUTDIR ${OUTDIR})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS)
        unset(sv_compile_cmd)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG)
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG)

            foreach(dir ${SV_INC_DIRS})
                list(APPEND SV_ARG_INCDIRS +incdir+${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG +define+${def})
            endforeach()

            set(sv_compile_cmd COMMAND vlogan
                    -full64
                    -nc
                    -q
                    -sverilog
                    -work ${__comp_lib_name}
                    ${ARG_SV_COMPILE_ARGS}
                    ${SV_ARG_INCDIRS}
                    ${SV_CMP_DEFS_ARG}
                    ${SV_SOURCES}
                    )
        endif()

        # VHDL files and arguments
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS)
        unset(vhdl_compile_cmd)
        if(VHDL_SOURCES)
            set(vhdl_compile_cmd COMMAND vhdlan
                    -full64
                    -nc
                    -q
                    -work ${__comp_lib_name}
                    ${ARG_VHDL_COMPILE_ARGS}
                    ${VHDL_SOURCES}
                    )
        endif()

        # VCS custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __vcs_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__vcs_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __vcs_subdep_stamp_files ${__vcs_${ip_dep}_stamp_files})
        endforeach()

        ### Clean files:
        set(__clean_files  # TODO What goes here???
            ${OUTDIR}/xrun.log
            ${OUTDIR}/xrun.history
            ${OUTDIR}/vcs.d
        )

        unset(__vcs_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "Compile Verilog and SV sources of ${lib} with vcs in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir} ${__clean_files}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${__vcs_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __vcs_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL sources of ${lib} with vcs in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_vhdl_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${vhdl_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir} ${__clean_files}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__vcs_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __vcs_${lib}_stamp_files ${STAMP_FILE})
        endif()


    endforeach()

    if(NOT TARGET ${IP_LIB}_vcs_complib)
        add_custom_target(
            ${IP_LIB}_vcs_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_vcs_complib PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

endfunction()

function(__get_vcs_search_lib_args IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Synopsys requires synopsys_sim.setup files in order to map different libraries
    set(synopsys_sim_setup_str "WORK > DEFAULT\n")
    string(APPEND synopsys_sim_setup_str "DEFAULT: ./work\n")

    get_ip_links(ips ${IP_LIB})
    unset(hdl_libs)
    foreach(lib ${ips})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND dpi_libs_args $<TARGET_FILE:${lib}>)
        else()
            # Library of the current IP block, get it from SoCMake library if present
            # If neither LIBRARY property is set, or LIBRARY passed as argument, use "work" as default
            get_target_property(__comp_lib_name ${lib} LIBRARY)
            if(NOT __comp_lib_name)
                set(__comp_lib_name work)
            endif()
            if(ARG_LIBRARY)
                set(__comp_lib_name ${ARG_LIBRARY})
            endif()

            set(lib_outdir ${OUTDIR}/${__comp_lib_name})
            file(MAKE_DIRECTORY ${lib_outdir})
            # Append current library outdhdl_libs_argsir to list of search directories
            if(NOT ${__comp_lib_name} IN_LIST hdl_libs)
                list(APPEND hdl_libs ${__comp_lib_name})
                string(APPEND synopsys_sim_setup_str "${__comp_lib_name}: ./${__comp_lib_name}\n")
            endif()
        endif()
    endforeach()

    file(WRITE "${ARG_OUTDIR}/synopsys_sim.setup" ${synopsys_sim_setup_str})

    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

function(__add_vcs_cxx_properties_to_libs IP_LIB)
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Find the Xcelium tools/include directory, needed for VPI/DPI libraries
    find_program(vcs_exec_path vcs)
    get_filename_component(vpi_inc_path "${vcs_exec_path}" DIRECTORY)
    cmake_path(SET vpi_inc_path NORMALIZE "${vpi_inc_path}/../include")

    get_ip_links(ips ${IP_LIB})
    foreach(lib ${ips})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            if(NOT vcs_exec_path)
                message(FATAL_ERROR "VCS executable vcs was not found, cannot set include directory on DPI library")
            endif()
            # Add tools/include directory to the include directories of DPI libraries
            # TODO do this only when its needed
            target_include_directories(${lib} PUBLIC ${vpi_inc_path})
            target_compile_definitions(${lib} PUBLIC VCS)
        endif()
    endforeach()
endfunction()
