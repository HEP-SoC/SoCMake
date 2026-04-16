include_guard(GLOBAL)

socmake_add_languages(VCS_SC_PORTMAP)

function(vcs IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI;32BIT" "OUTDIR;EXECUTABLE_NAME;RUN_TARGET_NAME;TOP_MODULE;LIBRARY" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS;FILE_SETS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Optimization to not do topological sort of linked IPs on get_ip_...() calls
    flatten_graph_and_disallow_flattening(${IP_LIB})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

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

    if(ARG_32BIT)
        set(bitness 32)
        set(ARG_BITNESS 32BIT)
    else()
        set(bitness 64)
        unset(ARG_BITNESS)
    endif()

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

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    #######################
    ### Set target names ##
    #######################

    set(compile_target ${IP_LIB}_vcs_complib)
    set(run_target ${ARG_RUN_TARGET_NAME})
    set(elaborate_target ${IP_LIB}_vcs)
    if(NOT ARG_RUN_TARGET_NAME)
        set(run_target run_${IP_LIB}_vcs)
    endif()

    get_ip_links(IPS_LIST ${IP_LIB})

    if(NOT TARGET ${compile_target})
        __vcs_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_BITNESS}
            ${ARG_LIBRARY}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            ${ARG_FILE_SETS}
            )
    endif()

    ### Create arguments for loading SystemC libraries during elaboration
    get_ip_links(__ips ${IP_LIB})
    unset(systemc_lib_args)
    foreach(lib ${__ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        if(is_systemc_lib)
            list(APPEND systemc_lib_args $<TARGET_FILE:${lib}>)
        endif()
    endforeach()
    if(systemc_lib_args)
        set(systemc_lib_args -sysc -ldflags -Wl,--start-group  ${systemc_lib_args}  -syslib -Wl,--end-group)
    endif()


    __is_socmake_systemc_lib(top_is_systemc_lib ${IP_LIB})
    __is_socmake_ip_lib(top_is_ip_lib ${IP_LIB})
    unset(arg_top_sim_module)
    if(top_is_systemc_lib)
        set(arg_top_sim_module sc_main) # If its SystemC it can be only sc_main as top
    elseif(top_is_ip_lib)
        set(arg_top_sim_module ${LIBRARY}.${ARG_TOP_MODULE})
    endif()

    __get_vcs_search_lib_args(${IP_LIB} 
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL ${ARG_FILE_SETS})
    get_ip_sources(HEADERS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL HEADERS ${ARG_FILE_SETS})
    ## VCS command for compiling executable
    if(NOT TARGET ${elaborate_target})
        set(elaborate_cmd vcs
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-full64>
                -nc
                -q
                # $<$<BOOL:${ARG_GUI}>:-gui>
                ${dpi_libs_args}
                -debug_access+r+w+nomemcbk -debug_region+cell
                ${systemc_lib_args}
                ${ARG_ELABORATE_ARGS}
                ${arg_top_sim_module} 
                -o ${SIM_EXEC_PATH}
                )

        ### Clean files:
        #       * 
        set(__clean_files 
            ${OUTDIR}/csrc
            ${OUTDIR}/${ARG_EXECUTABLE_NAME}.daidir
            # ${OUTDIR}/synopsys_sim.setup # Don't delete for now, as its generated at configure time and is necessary to run vcs, in case make clean comes, it will not reconfigure
            ${OUTDIR}/tr_db.log
            ${OUTDIR}/ucli.key
            ${OUTDIR}/vc_hdrs.h
        )

        set(DESCRIPTION "Elaborate ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            COMMAND ${elaborate_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${compile_target} ${SOURCES} ${HEADERS} ${IP_LIB}
            # COMMAND_EXPAND_LISTS
            # VERBATIM
            )

        add_custom_target(${elaborate_target}
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${elaborate_target} PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${elaborate_target} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${__clean_files})
    endif()

    set(run_sim_cmd ${SIM_EXEC_PATH} 
            ${ARG_RUN_ARGS}
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${run_target}
            COMMAND ${run_sim_cmd}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${elaborate_target}
            )
        set_property(TARGET ${run_target} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)

    set(SOCMAKE_SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)
    set(SOCMAKE_COMPILE_TARGET ${compile_target} PARENT_SCOPE)
    set(SOCMAKE_ELABORATE_TARGET ${elaborate_target} PARENT_SCOPE)
    if(NOT ARG_NO_RUN_TARGET)
        set(SOCMAKE_RUN_TARGET ${run_target} PARENT_SCOPE)
    else()
        unset(SOCMAKE_RUN_TARGET PARENT_SCOPE)
    endif()

    # Allow again topological sort outside the function
    socmake_allow_topological_sort(ON)
endfunction()

function(__vcs_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "32BIT" "OUTDIR;LIBRARY;TOP_MODULE" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;FILE_SETS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

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

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    get_target_property(top_ip_type ${IP_LIB} TYPE)

    unset(ARG_BITNESS)
    if(ARG_32BIT)
        set(ARG_BITNESS 32BIT)
    endif()

    get_ip_links(__ips ${IP_LIB})

    foreach(parent ${__ips})
        get_target_property(children_ips ${parent} INTERFACE_LINK_LIBRARIES)

        __is_socmake_systemc_lib(parent_is_systemc_lib ${parent})
        __is_socmake_ip_lib(parent_is_ip_lib ${parent})
 
        if(children_ips)
            foreach(child ${children_ips})
                __is_socmake_systemc_lib(child_is_systemc_lib ${child})
                __is_socmake_ip_lib(child_is_ip_lib ${child})

                if(parent_is_systemc_lib AND child_is_ip_lib)
                    vcs_gen_sc_wrapper(${child} 
                        OUTDIR ${OUTDIR}
                        LIBRARY ${LIBRARY}
                        ${ARG_BITNESS}
                        ${ARG_FILE_SETS})
                    add_dependencies(${parent} ${child}_vcs_gen_sc_wrapper)
                endif()

                if(parent_is_ip_lib AND child_is_systemc_lib)
                    vcs_gen_hdl_wrapper(${child} 
                        OUTDIR ${OUTDIR}
                        LIBRARY ${LIBRARY}
                        ${ARG_BITNESS})
                    add_dependencies(${parent} ${child}_vcs_gen_hdl_wrapper)
                endif()

            endforeach()
        endif()

    endforeach()

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
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS ${ARG_FILE_SETS})
        get_ip_sources(SV_HEADERS ${lib} SYSTEMVERILOG VERILOG HEADERS ${ARG_FILE_SETS})
        unset(sv_compile_cmd)
        unset(SV_ARG_INCDIRS)
        unset(SV_CMP_DEFS_ARG)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})

            foreach(dir ${SV_INC_DIRS})
                list(APPEND SV_ARG_INCDIRS +incdir+${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG +define+${def})
            endforeach()

            set(sv_compile_cmd COMMAND vlogan
                    $<$<NOT:$<BOOL:${ARG_32BIT}>>:-full64>
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
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS ${ARG_FILE_SETS})
        unset(vhdl_compile_cmd)
        if(VHDL_SOURCES)
            set(vhdl_compile_cmd COMMAND vhdlan
                    $<$<NOT:$<BOOL:${ARG_32BIT}>>:-full64>
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
            ${OUTDIR}/vcs.d
        )

        unset(__vcs_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "Compile Verilog and SV sources of ${lib} with vcs in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${SV_HEADERS} ${__vcs_subdep_stamp_files}
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
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__vcs_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __vcs_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(NOT SV_SOURCES AND NOT VHDL_SOURCES)
            set(DESCRIPTION "Creating stamp file for ${lib} for xcelium")
            set(STAMP_FILE "${lib_outdir}/.${lib}_dummy_stamp_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND touch ${STAMP_FILE}
                DEPENDS ${__vcs_subdep_stamp_files}
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
        set_property(TARGET ${IP_LIB}_vcs_complib APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${lib_outdir} ${__clean_files})
    endif()

endfunction()

function(__get_vcs_search_lib_args IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

    # Synopsys requires synopsys_sim.setup files in order to map different libraries
    set(synopsys_sim_setup_str "WORK > DEFAULT\n")
    string(APPEND synopsys_sim_setup_str "DEFAULT: ./work\n")

    get_ip_links(ips ${IP_LIB})
    unset(hdl_libs)
    unset(dpi_libs_args)
    foreach(lib ${ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        __is_socmake_ip_lib(is_ip_lib ${lib})
        __is_socmake_vhpi_lib(is_vhpi_lib ${lib})
        __is_socmake_dpic_lib(is_dpic_lib ${lib})

        get_target_property(ip_type ${lib} TYPE)
        if(is_dpic_lib)
            list(APPEND dpi_libs_args $<TARGET_FILE:${lib}>)
        endif()

        if(is_ip_lib)
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

function(vcs_gen_sc_wrapper IP_LIB)
    cmake_parse_arguments(ARG "32BIT" "OUTDIR;LIBRARY;TOP_MODULE" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
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

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    get_target_property(__comp_lib_name ${IP_LIB} LIBRARY)
    if(NOT __comp_lib_name)
        set(__comp_lib_name work)
    endif()
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()


    get_ip_sources(SV_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG NO_DEPS ${ARG_FILE_SETS})
    list(GET SV_SOURCES -1 last_sv_file) # TODO this is not correct, as the last Verilog file might not be top
    unset(sv_compile_cmd)
    if(SV_SOURCES)
        get_ip_include_directories(SV_INC_DIRS ${IP_LIB}  SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
        get_ip_compile_definitions(SV_COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})

        foreach(dir ${SV_INC_DIRS})
            list(APPEND SV_ARG_INCDIRS +incdir+${dir})
        endforeach()

        foreach(def ${SV_COMP_DEFS})
            list(APPEND SV_CMP_DEFS_ARG +define+${def})
        endforeach()

        get_ip_sources(sc_portmap ${IP_LIB} VCS_SC_PORTMAP NO_DEPS)
        unset(sc_portmap_arg)
        if(sc_portmap)
            set(sc_portmap_arg -sc_portmap ${sc_portmap})
        endif()

        set(sv_compile_cmd COMMAND vlogan
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-full64>
                -nc
                -q
                -sverilog
                -work ${__comp_lib_name}
                ${ARG_SV_COMPILE_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                -cpp g++
                -sysc
                -sc_model ${ARG_TOP_MODULE}
                ${sc_portmap_arg}
                ${last_sv_file}
            )

        set(DESCRIPTION "Generate a SC wrapper file for ${IP_LIB} with VCS vlogan")
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} ${OUTDIR}/csrc/sysc/include/${IP_LIB}.h
            COMMAND touch ${STAMP_FILE}
            ${sv_compile_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${last_sv_file} ${SV_HEADERS}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${OUTDIR})

        target_include_directories(${IP_LIB} INTERFACE ${OUTDIR}/csrc/sysc/include/)

        target_sources(${IP_LIB} INTERFACE
            ${OUTDIR}/csrc/sysc/include/${IP_LIB}.h)
    endif()

endfunction()

function(vcs_gen_hdl_wrapper SC_LIB)
    cmake_parse_arguments(ARG "32BIT" "OUTDIR;LIBRARY;TOP_MODULE" "" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    get_target_property(BINARY_DIR ${SC_LIB} BINARY_DIR)

    if(NOT ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${SC_LIB})
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${SC_LIB}_vcs)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    set(__comp_lib_name work)
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()

    get_ip_sources(sc_portmap ${SC_LIB} VCS_SC_PORTMAP NO_DEPS)
    unset(sc_portmap_arg)
    if(sc_portmap)
        set(sc_portmap_arg -port ${sc_portmap})
    endif()

    set(gen_wrapper_cmd syscan
            $<$<NOT:$<BOOL:${ARG_32BIT}>>:-full64>
            -work ${__comp_lib_name}
            ${sc_portmap_arg}
            $<TARGET_FILE:${SC_LIB}>:${ARG_TOP_MODULE}
            -cflags \" 
                "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},INCLUDE_DIRECTORIES>,PREPEND,-I>" 
                "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},COMPILE_DEFINITIONS>,PREPEND,-D>" 
            \"
        )

    set(GEN_V_FILE ${OUTDIR}/csrc/sysc/${ARG_TOP_MODULE}/${ARG_TOP_MODULE}.v)
    set(DESCRIPTION "Generate a Verilog wrapper file for SystemC lib ${SC_LIB} with VCS syscan")
    set(STAMP_FILE "${OUTDIR}/${SC_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${GEN_V_FILE}
        COMMAND touch ${STAMP_FILE}
        COMMAND ${gen_wrapper_cmd}
        WORKING_DIRECTORY ${OUTDIR}
        DEPENDS ${SC_LIB}
        COMMENT ${DESCRIPTION}
        COMMAND_EXPAND_LISTS
        # VERBATIM
    )

    add_custom_target(
        ${SC_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${GEN_V_FILE} ${SC_LIB}
    )
    set_property(TARGET ${SC_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

    ip_sources(${SC_LIB} VERILOG ${GEN_V_FILE})

endfunction()

function(__find_vcs_home OUTVAR)
    find_program(exec_path vcs REQUIRED)
    get_filename_component(bin_path "${exec_path}" DIRECTORY)
    cmake_path(SET vcs_home NORMALIZE "${bin_path}/..")

    set(${OUTVAR} ${vcs_home} PARENT_SCOPE)
endfunction()

macro(vcs_configure_cxx)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})

    if(NOT DEFINED ENV{VG_GNU_PACKAGE})
        message(FATAL_ERROR "VG_GNU_PACKAGE variable not set for VCS. VCS CXX simulation should be used with GCC suplied by VCS")
    endif()

    if(ARG_LIBRARIES)
        vcs_add_cxx_libs(${ARGV})
    endif()
endmacro()

function(vcs_add_cxx_libs)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries SystemC DPI-C)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            message(FATAL_ERROR "VCS does not support library: ${lib}")
        endif()
    endforeach()

    __find_vcs_home(vcs_home)

    if(SystemC IN_LIST ARG_LIBRARIES)

        add_library(vcs_systemc INTERFACE)
        add_library(SoCMake::SystemC ALIAS vcs_systemc)

        if(ARG_32BIT)
            target_compile_options(vcs_systemc INTERFACE -m32)
            target_link_options   (vcs_systemc INTERFACE -m32)
        endif()
        target_compile_definitions(vcs_systemc INTERFACE VCSSYSTEMC=1)
        target_include_directories(vcs_systemc INTERFACE
            $ENV{VCS_HOME}/include/systemc232 # TODO select version
            $ENV{VCS_HOME}/include/cosim/bf
            $ENV{VCS_HOME}/include
            )

        # In order to be able to generate HDL wrapper with syscan from .so library
        target_compile_options(vcs_systemc INTERFACE -g -fno-eliminate-unused-debug-types)
        target_link_options   (vcs_systemc INTERFACE -g)
    endif()

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(vcs_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS vcs_dpi-c)

        if(ARG_32BIT)
            target_compile_options(vcs_dpi-c INTERFACE -m32)
            target_link_options   (vcs_dpi-c INTERFACE -m32)
        endif()
        target_include_directories(vcs_dpi-c INTERFACE ${vcs_home}/include)
        target_compile_definitions(vcs_dpi-c INTERFACE VCS)
    endif()

endfunction()
