#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium (compilation, elaboration, and simulation) on IP_LIB.
#
# It will create a target **run_<IP_LIB>_xcelium** that will compile, elaborate, and simulate the IP_LIB design.
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword GUI: Run simulation in GUI mode.
# :type GUI: bool
# :keyword 32BIT: Use 32 bit compilation and simulation.
# :type 32BIT: bool
# :keyword OUTDIR: Output directory for the Xcelium compilation and simulation.
# :type OUTDIR: string
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword COMPILE_ARGS: Extra arguments to be passed to the compilation step (C, C++).
# :type COMPILE_ARGS: string
# :keyword XRUN_COMPILE_ARGS: Extra arguments to be passed to the xrun -compile command
# :type XRUN_COMPILE_ARGS: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the System Verilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword VHDL_COMPILE_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type VHDL_COMPILE_ARGS: string
# :keyword ELABORATE_ARGS: Extra arguments to be passed to the elaboration step.
# :type ELABORATE_ARGS: string
# :keyword RUN_ARGS: Extra arguments to be passed to the simulation step.
# :type RUN_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources  from
# :type FILE_SETS: list[string]
#]]

include_guard(GLOBAL)

function(xcelium IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI;32BIT" "OUTDIR;RUN_TARGET_NAME;TOP_MODULE;LIBRARY" "COMPILE_ARGS;XRUN_COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS;FILE_SETS;" ${ARGN})
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
        set(LIBRARY worklib)
    endif()
    if(ARG_LIBRARY)
        set(LIBRARY ${ARG_LIBRARY})
        set(ARG_LIBRARY LIBRARY ${LIBRARY})
    endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_xcelium)
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

    if(ARG_COMPILE_ARGS)
        set(ARG_COMPILE_ARGS COMPILE_ARGS ${ARG_COMPILE_ARGS})
    endif()
    if(ARG_SV_COMPILE_ARGS)
        set(ARG_SV_COMPILE_ARGS SV_COMPILE_ARGS ${ARG_SV_COMPILE_ARGS})
    endif()
    if(ARG_VHDL_COMPILE_ARGS)
        set(ARG_VHDL_COMPILE_ARGS VHDL_COMPILE_ARGS ${ARG_VHDL_COMPILE_ARGS})
    endif()

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    if(ARG_XRUN_COMPILE_ARGS)
        set(ARG_XRUN_COMPILE_ARGS XRUN_COMPILE_ARGS ${ARG_XRUN_COMPILE_ARGS})
    endif()

    #######################
    ### Set target names ##
    #######################

    set(compile_target ${IP_LIB}_xcelium_complib)
    set(elaborate_target ${IP_LIB}_xcelium)
    set(run_target ${ARG_RUN_TARGET_NAME})
    if(NOT ARG_RUN_TARGET_NAME)
        set(run_target run_${IP_LIB}_xcelium)
    endif()

    if(NOT TARGET ${compile_target})
        __xcelium_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_BITNESS}
            ${ARG_LIBRARY}
            ${ARG_COMPILE_ARGS}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            ${ARG_FILE_SETS}
            ${ARG_XRUN_COMPILE_ARGS}
            )
    endif()

    ### Get list of linked SystemC libraries
    get_ip_links(__ips ${IP_LIB})
    unset(systemc_lib_args)
    foreach(lib ${__ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        if(is_systemc_lib)
            list(APPEND systemc_lib_args -loadsc $<TARGET_FILE:${lib}>)
        endif()
    endforeach()

    __get_xcelium_search_lib_args(${IP_LIB}
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(hdl_libs_args ${HDL_LIBS_ARGS})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL ${ARG_FILE_SETS})
    get_ip_sources(HEADERS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL HEADERS ${ARG_FILE_SETS})
    if(NOT TARGET ${elaborate_target})
        set(elaborate_cmd COMMAND xrun -elaborate
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                -q
                -nocopyright
                -l xmelab.log
                ${hdl_libs_args}
                ${systemc_lib_args}
                ${ARG_ELABORATE_ARGS}
                -top ${LIBRARY}.${ARG_TOP_MODULE}
            )

        ### Clean files:
        #       *
        set(__clean_files
            ${OUTDIR}/xmelab.log
            ${OUTDIR}/xmelab.history
            ${OUTDIR}/xcelium.d
        )

        set(DESCRIPTION "Elaborate ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            COMMAND ${elaborate_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${compile_target} ${SOURCES} ${HEADERS}
            COMMAND_EXPAND_LISTS
            )

        add_custom_target(${elaborate_target}
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${elaborate_target} PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${elaborate_target} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${__clean_files})
    endif()

    ## XMSIM command for running simulation

    ### Clean files:
    #       *
    set(__clean_files
        xmsim.log
    )

    set(run_sim_cmd xrun -R
        -l xmsim.log
        -xmlibdirpath ${OUTDIR}
        $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
        $<$<BOOL:${ARG_GUI}>:-gui>
        ${hdl_libs_args}
        ${dpi_libs_args}
        ${ARG_RUN_ARGS}
    )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${run_sim_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            COMMENT ${DESCRIPTION}
            DEPENDS ${elaborate_target}
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${ARG_RUN_TARGET_NAME} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${__clean_files})
    endif()
    set(SOCMAKE_SIM_RUN_CMD cd ${OUTDIR} && ${run_sim_cmd} PARENT_SCOPE)
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

function(__xcelium_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY;TOP_MODULE" "COMPILE_ARGS;XRUN_COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_xcelium)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    if(ARG_LIBRARY)
        set(ARG_LIBRARY_FORWARD LIBRARY ${LIBRARY})
    endif()

    get_ip_links(__ips ${IP_LIB})

    foreach(parent ${__ips})
        get_target_property(children_ips ${parent} INTERFACE_LINK_LIBRARIES)

        __is_socmake_systemc_lib(parent_is_systemc_lib ${parent})
        __is_socmake_ip_lib(parent_is_ip_lib ${parent})

        # If parent is neither a SystemC library, nor IP library, not possible to generate wrappers
        if(NOT parent_is_ip_lib AND NOT parent_is_systemc_lib)
            continue()
        endif()

        if(children_ips)
            foreach(child ${children_ips})
                __is_socmake_systemc_lib(child_is_systemc_lib ${child})
                __is_socmake_ip_lib(child_is_ip_lib ${child})

                if(parent_is_systemc_lib AND child_is_ip_lib)
                    set_property(TARGET ${child} PROPERTY SOCMAKE_HDL_BOUNDARY_LIB TRUE)
                    xcelium_gen_sc_wrapper(${child}
                        OUTDIR ${OUTDIR}
                        ${ARG_LIBRARY_FORWARD}
                        ${ARG_BITNESS}
                    )
                    add_dependencies(${parent} ${child}_xcelium_gen_sc_wrapper)
                endif()

                if(parent_is_ip_lib AND child_is_systemc_lib)
                    set_property(TARGET ${child} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
                    xcelium_gen_hdl_wrapper(${child}
                        OUTDIR ${OUTDIR}
                        ${ARG_LIBRARY_FORWARD}
                        ${ARG_BITNESS}
                    )
                    add_dependencies(${parent} ${child}_xcelium_gen_hdl_wrapper)
                endif()
            endforeach()
        endif()
    endforeach()

    unset(all_stamp_files)
    foreach(lib ${__ips})

        # VHDL library of the current IP block, get it from SoCMake library if present
        # If neither LIBRARY property is set, or LIBRARY passed as argument, use "worklib" as default
        __xcelium_default_library(__comp_lib_name ${lib})


        message(STATUS "Xcelium compile library: ${lib} in library ${__comp_lib_name}")

        # Create output directoy for the VHDL library
        set(lib_outdir ${OUTDIR}/xcelium.d/${__comp_lib_name})

        __get_xcelium_search_lib_args(${lib}
            OUTDIR ${OUTDIR}
            ${ARG_LIBRARY_FORWARD})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS ${ARG_FILE_SETS})
        get_ip_sources(SV_HEADERS ${lib} SYSTEMVERILOG VERILOG HEADERS ${ARG_FILE_SETS})
        unset(sv_compile_cmd)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})

            foreach(dir ${SV_INC_DIRS})
                list(APPEND SV_ARG_INCDIRS -INCDIR ${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG -DEFINE ${def})
            endforeach()

            set(sv_compile_cmd COMMAND xrun -compile
                    $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                    -q
                    -nocopyright
                    -sv
                    -l xmvlog.log
                    ${ARG_XRUN_COMPILE_ARGS}
                    -makelib ${lib_outdir}
                    ${ARG_COMPILE_ARGS}
                    ${ARG_SV_COMPILE_ARGS}
                    ${SV_ARG_INCDIRS}
                    ${SV_CMP_DEFS_ARG}
                    ${SV_SOURCES}
                    -endlib
                    ${hdl_libs_args}
                )
        endif()

        # VHDL files and arguments
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS ${ARG_FILE_SETS})
        unset(vhdl_compile_cmd)
        if(VHDL_SOURCES)
            set(vhdl_compile_cmd COMMAND xrun -compile
                    $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                    -q
                    -nocopyright
                    -l xmvhdl.log
                    ${ARG_XRUN_COMPILE_ARGS}
                    -makelib ${lib_outdir}
                    ${ARG_COMPILE_ARGS}
                    ${ARG_VHDL_COMPILE_ARGS}
                    ${VHDL_SOURCES}
                    -endlib
                    ${hdl_libs_args}
                )
        endif()

        # Xcelium custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __xcelium_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__xcelium_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __xcelium_subdep_stamp_files ${__xcelium_${ip_dep}_stamp_files})
        endforeach()

        ### Clean files:
        set(__clean_files
            ${OUTDIR}/xmvlog.log
            ${OUTDIR}/xmvlog.history
            ${OUTDIR}/xmvhdl.log
            ${OUTDIR}/xmvhdl.history
            ${OUTDIR}/xcelium.d
        )

        unset(__xcelium_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "Compile Verilog and SV sources of ${lib} with xcelium in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${SV_HEADERS} ${__xcelium_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __xcelium_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL sources of ${lib} with xcelium in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_vhdl_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                ${vhdl_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__xcelium_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __xcelium_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(NOT SV_SOURCES AND NOT VHDL_SOURCES)
            set(DESCRIPTION "Generate stamp file for ${lib} for xcelium")
            set(STAMP_FILE "${lib_outdir}/.${lib}_dummy_stamp_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${lib_outdir}
                COMMAND touch ${STAMP_FILE}
                DEPENDS ${__xcelium_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __xcelium_${lib}_stamp_files ${STAMP_FILE})
        endif()

    endforeach()

    if(NOT TARGET ${IP_LIB}_xcelium_complib)
        add_custom_target(
            ${IP_LIB}_xcelium_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_xcelium_complib PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${IP_LIB}_xcelium_complib APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${__clean_files} ${lib_outdir})
    endif()

endfunction()

function(__get_xcelium_search_lib_args IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_ip_links(ips ${IP_LIB})
    unset(hdl_libs_args)
    foreach(lib ${ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        __is_socmake_ip_lib(is_ip_lib ${lib})
        __is_socmake_vhpi_lib(is_vhpi_lib ${lib})
        __is_socmake_dpic_lib(is_dpic_lib ${lib})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(is_systemc_lib OR is_dpic_lib)
            list(APPEND dpi_libs_args -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
        endif()

        if(is_ip_lib)
            # Library of the current IP block, get it from SoCMake library if present
            # If neither LIBRARY property is set, or LIBRARY passed as argument, use "worklib" as default
            __xcelium_default_library(__comp_lib_name ${lib})

            set(lib_outdir ${ARG_OUTDIR}/xcelium.d/${__comp_lib_name})
            # Append current library outdhdl_libs_argsir to list of search directories
            if(NOT ${lib_outdir} IN_LIST hdl_libs_args)
                list(APPEND hdl_libs_args -reflib ${lib_outdir})
            endif()
        endif()
    endforeach()

    set(HDL_LIBS_ARGS ${hdl_libs_args} PARENT_SCOPE)
    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

function(__find_xcelium_home OUTVAR)
    find_program(exec_path xrun REQUIRED)
    get_filename_component(bin_path "${exec_path}" DIRECTORY)
    cmake_path(SET xcelium_home NORMALIZE "${bin_path}/../../")

    set(${OUTVAR} ${xcelium_home} PARENT_SCOPE)
endfunction()

function(xcelium_gen_sc_wrapper IP_LIB)
    cmake_parse_arguments(ARG "32BIT;QUIET" "OUTDIR;LIBRARY;TOP_MODULE" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_xcelium)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    __xcelium_default_library(__comp_lib_name ${IP_LIB})
    # Create output directoy for the VHDL library
    set(lib_outdir ${OUTDIR}/${__comp_lib_name})

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

        set(sv_compile_cmd COMMAND xrun -compile
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                -q
                -nocopyright
                -sv
                -makelib ${__comp_lib_name}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${last_sv_file}
                -endlib
            )
        set(xmshell_cmd xmshell
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                -import verilog
                -into systemc
                -sc_uint         # TODO
                -sctype clk:bool # TODO
                -sctype rst:bool # TODO
                -work ${__comp_lib_name}
                ${__comp_lib_name}.${ARG_TOP_MODULE}
            )

        set(generated_files ${OUTDIR}/${ARG_TOP_MODULE}.h ${OUTDIR}/${ARG_TOP_MODULE}.cpp)
        set(DESCRIPTION "Generate a SC wrapper file for ${IP_LIB} with Xcelium xmshell")
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} ${generated_files}
            COMMAND ${sv_compile_cmd}
            COMMAND ${xmshell_cmd}
            COMMAND touch ${STAMP_FILE}
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

        target_include_directories(${IP_LIB} INTERFACE ${OUTDIR})
    endif()

endfunction()

function(xcelium_gen_hdl_wrapper SC_LIB)
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
        set(OUTDIR ${BINARY_DIR}/${SC_LIB}_xcelium)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    __xcelium_default_library(__comp_lib_name ${SC_LIB})

    set(xmsc_cmd xmsc
            $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
            -work ${__comp_lib_name}
            "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET,$<TARGET_PROPERTY:${SC_LIB},SOURCES>,-1>,$<TARGET_PROPERTY:${SC_LIB},SOURCE_DIR>>" # Get Absolute path to the last source file
            -CFLAGS \"
                "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},INCLUDE_DIRECTORIES>,PREPEND,-I>"
                "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},COMPILE_DEFINITIONS>,PREPEND,-D>"
            \"
            -scfrontend
        )

    set(xmshell_cmd xmshell
            $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
            -import systemc
            -into verilog
            -work ${__comp_lib_name}
            ${__comp_lib_name}.${ARG_TOP_MODULE}:sc_module
        )

    set(GEN_V_FILE ${OUTDIR}/${ARG_TOP_MODULE}.vs)
    set(DESCRIPTION "Generate a Verilog wrapper file for SystemC lib ${SC_LIB} with Xcelium xmshell")
    set(STAMP_FILE "${OUTDIR}/${SC_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${GEN_V_FILE}
        COMMAND ${xmsc_cmd}
        COMMAND ${xmshell_cmd}
        COMMAND touch ${STAMP_FILE}
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


macro(xcelium_configure_cxx)
    cmake_parse_arguments(ARG "" "" "LIBRARIES" ${ARGN})

    __find_xcelium_home(xcelium_home)
    set(CMAKE_CXX_COMPILER "${xcelium_home}/tools.lnx86/cdsgcc/gcc/bin/g++")
    set(CMAKE_C_COMPILER "${xcelium_home}/tools.lnx86/cdsgcc/gcc/bin/gcc")

    if(ARG_LIBRARIES)
        xcelium_add_cxx_libs(${ARGV})
    endif()
endmacro()

function(xcelium_add_cxx_libs)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries SystemC DPI-C)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            message(FATAL_ERROR "Xcelium does not support library: ${lib}")
        endif()
    endforeach()

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    __find_xcelium_home(xcelium_home)

    if(SystemC IN_LIST ARG_LIBRARIES)
        if(bitness STREQUAL "64")
            set(libpath "lib/64bit/gnu")
        else()
            set(libpath "lib/gnu")
        endif()

        add_library(xcelium_systemc INTERFACE)
        add_library(SoCMake::SystemC ALIAS xcelium_systemc)
        target_link_libraries(xcelium_systemc INTERFACE
            ${xcelium_home}/tools/systemc/${libpath}/libncscCoSim_sh.so
            ${xcelium_home}/tools/systemc/${libpath}/libncscCoroutines_sh.so
            ${xcelium_home}/tools/systemc/${libpath}/libsystemc_sh.so
        )

        if(ARG_32BIT)
            target_compile_options(xcelium_systemc INTERFACE -m32)
            target_link_options(xcelium_systemc    INTERFACE -m32)
        endif()
        target_compile_definitions(xcelium_systemc INTERFACE INCA)

        target_include_directories(xcelium_systemc INTERFACE
            ${xcelium_home}/tools/systemc/include
            ${xcelium_home}/tools/tbsc/include
            ${xcelium_home}/tools/vic/include
        )
    endif()

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(xcelium_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS xcelium_dpi-c)

        if(ARG_32BIT)
            target_compile_options(xcelium_dpi-c INTERFACE -m32)
            target_link_options   (xcelium_dpi-c INTERFACE -m32)
        endif()
        target_include_directories(xcelium_dpi-c INTERFACE ${xcelium_home}/include)
        target_compile_definitions(xcelium_dpi-c INTERFACE INCA)
    endif()

endfunction()

function(__xcelium_default_library OUT_LIB IP_LIB)
    cmake_parse_arguments(ARG "" "LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(__comp_lib_name ${IP_LIB} LIBRARY)
    if(NOT __comp_lib_name)
        set(__comp_lib_name worklib)
    endif()
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()
    # Xcelium doesnt like some characters in the name of the libraries, sanitize
    string(MAKE_C_IDENTIFIER "${__comp_lib_name}" __comp_lib_name)
    set(${OUT_LIB} ${__comp_lib_name} PARENT_SCOPE)
endfunction()
