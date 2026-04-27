#[[[ @module questasim
#]]

include_guard(GLOBAL)

#[[[
# Create a target for invoking Questasim (compilation, elaboration, and simulation) on IP_LIB.
#
# It will create a target **run_<IP_LIB>_questasim** that will compile, elaborate, and simulate the IP_LIB design.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog or VHDL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword GUI: Run simulation in GUI mode.
# :type GUI: bool
# :keyword GUI_VISUALIZER: Run simulation in GUI, with Visualizer.
# :type GUI_VISUALIZER: bool
# :keyword 32BIT: Use 32 bit compilation and simulation.
# :type 32BIT: bool
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword OUTDIR: Output directory for the Questasim compilation and simulation.
# :type OUTDIR: string
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword VHDL_COMPILE_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type VHDL_COMPILE_ARGS: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword RUN_ARGS: Extra arguments to be passed to the simulation step.
# :type RUN_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
# :keyword DO_FILES: Specify list of do files to run with the run command
# :type DO_FILES: list[string]
#]]
function(questasim IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;QUIET;GUI;GUI_VISUALIZER;32BIT" "LIBRARY;TOP_MODULE;OUTDIR;RUN_TARGET_NAME" "VHDL_COMPILE_ARGS;SV_COMPILE_ARGS;RUN_ARGS;FILE_SETS;DO_FILES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Optimization to not do topological sort of linked IPs on get_ip_...() calls
    flatten_graph_and_disallow_flattening(${IP_LIB})

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/colours.cmake")


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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_QUIET)
        set(ARG_QUIET QUIET)
    endif()

    if(ARG_GUI_VISUALIZER)
        set(ARG_GUI FALSE)
    endif()
    
    if(ARG_32BIT)
        set(bitness 32)
        set(ARG_BITNESS 32BIT)
    else()
        set(bitness 64)
        unset(ARG_BITNESS)
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

    __find_questasim_home(questasim_home)

    #######################
    ### Set target names ##
    #######################

    set(compile_target ${IP_LIB}_questasim_complib)
    set(run_target ${ARG_RUN_TARGET_NAME})
    if(NOT ARG_RUN_TARGET_NAME)
        set(run_target run_${IP_LIB}_questasim)
    endif()
    set(elaborate_target ${run_target})

    ### Compile with vcom and vlog
    if(NOT TARGET ${compile_target})
        __questasim_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_BITNESS}
            ${ARG_QUIET}
            ${ARG_LIBRARY}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            ${ARG_FILE_SETS}
            )
    endif()

    ### Get list of linked libraries marked as SystemC
    get_ip_links(__ips ${IP_LIB})
    unset(systemc_libs)
    foreach(lib ${__ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        if(is_systemc_lib)
            list(APPEND systemc_libs ${lib})
        endif()
    endforeach()

    __get_questasim_search_lib_args(${IP_LIB} 
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(hdl_libs_args ${HDL_LIBS_ARGS})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    ##### SCCOM link
    unset(sccom_link_tgt)
    if(NOT TARGET ${IP_LIB}_sccom_link AND systemc_libs)
    #
        if(bitness STREQUAL "64")
            set(libpath "gcc64/lib64")
        else()
            set(libpath "gcc32/lib")
        endif()

        set(__sccom_link_cmd sccom -link
                -${bitness}
                -nologo
                -Wl,-rpath,${questasim_home}/${libpath}
            )

        ### Clean files
        #       * For elaborate "e~${ARG_EXECUTABLE_NAME}.o" and executable gets created
        # set(__clean_files "${OUTDIR}/e~${ARG_EXECUTABLE_NAME}.o")
        # set(__clean_files "${OUTDIR}/${LIBRARY}-obj${STANDARD}.cf")

        set(DESCRIPTION "Link SystemC objects into systemc.so for ${IP_LIB} with sccom")
        set(STAMP_FILE "${OUTDIR}/${IP_LIB}_sccom_link.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            COMMAND ${__sccom_link_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${compile_target} #${SC_SOURCES}
            COMMENT ${DESCRIPTION}
            )

        add_custom_target(${IP_LIB}_sccom_link
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_sccom_link PROPERTY DESCRIPTION ${DESCRIPTION})
        set(sccom_link_tgt ${IP_LIB}_sccom_link)
    endif()


    set(run_sim_cmd vsim
        -${bitness}
        $<$<BOOL:${ARG_QUIET}>:-quiet>
        $<$<BOOL:${ARG_GUI}>:-gui>
        $<$<BOOL:${ARG_GUI_VISUALIZER}>:-visualizer>
        ${ARG_RUN_ARGS}
        -Ldir ${OUTDIR} ${hdl_libs_args} ${dpi_libs_args}
        ${LIBRARY}.${ARG_TOP_MODULE}
        )

    # If GUI is not used, pass the -do files to CLI argument
    if(NOT ARG_GUI AND NOT ARG_GUI_VISUALIZER)
        list(APPEND run_sim_cmd -c -onfinish stop)
        # Use the default run.do, if not provided
        # This script makes sure the exit code from testbench is passed to the shell
        # Otherwise $fatal(), $error() exit codes are ignored by questasim
        if(NOT DEFINED ARG_DO_FILES)
            list(APPEND run_sim_cmd
                -do ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/run.do
            )
        else()
            # Optionally use custom DO_FILES
            convert_paths_to_absolute(ARG_DO_FILES ${ARG_DO_FILES})
            foreach(do_file ${ARG_DO_FILES})
                list(APPEND run_sim_cmd -do ${do_file})
            endforeach()
        endif()

    endif()

    if(NOT ARG_NO_RUN_TARGET)
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        add_custom_target(
            ${run_target}
            COMMAND  ${run_sim_cmd} -noautoldlibpath
            DEPENDS ${compile_target} ${sccom_link_tgt}
            WORKING_DIRECTORY ${OUTDIR}
            COMMENT ${DESCRIPTION}
            USES_TERMINAL
        )
        set_property(TARGET ${run_target} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(SOCMAKE_SIM_RUN_CMD cd ${OUTDIR} && ${run_sim_cmd} PARENT_SCOPE)
    set(SOCMAKE_COMPILE_TARGET ${compile_target} PARENT_SCOPE)
    if(NOT ARG_NO_RUN_TARGET)
        set(SOCMAKE_ELABORATE_TARGET ${run_target} PARENT_SCOPE)
        set(SOCMAKE_RUN_TARGET ${run_target} PARENT_SCOPE)
    else()
        unset(SOCMAKE_ELABORATE_TARGET PARENT_SCOPE)
        unset(SOCMAKE_RUN_TARGET PARENT_SCOPE)
    endif()

    # Allow again topological sort outside the function
    socmake_allow_topological_sort(ON)
endfunction()

# This function is called by ``questasim``, it shouldn't be used directly in a cmake file.
#
# It will create an intermediary target to compile VDHL and SystemVerilog/Verilog file, using vcom and vlog. It will also compile using sccom if SystemC is a boundary library.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog or VDHL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword QUIET: Disable output for informative messages
# :type QUIET: bool
# :keyword 32BIT: Use 32 bit compilation and simulation.
# :type 32BIT: bool
# :keyword OUTDIR: Output directory for the Questa compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword VHDL_COMPILE_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type VHDL_COMPILE_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
function(__questasim_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "QUIET;32BIT" "OUTDIR;LIBRARY" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)


    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_questasim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    get_ip_links(__ips ${IP_LIB})

    foreach(parent ${__ips})
        get_target_property(children_ips ${parent} INTERFACE_LINK_LIBRARIES)

        __is_socmake_systemc_lib(parent_is_systemc_lib ${parent})
        __is_socmake_ip_lib(parent_is_ip_lib ${parent})

        if(parent_is_systemc_lib)
            set_property(TARGET ${parent} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
        endif()

        if(children_ips)
            foreach(child ${children_ips})
                __is_socmake_systemc_lib(child_is_systemc_lib ${child})
                __is_socmake_ip_lib(child_is_ip_lib ${child})

                if(parent_is_systemc_lib AND child_is_ip_lib)
                    questasim_gen_sc_wrapper(${child} 
                        OUTDIR ${OUTDIR}
                        LIBRARY ${LIBRARY}
                        ${ARG_BITNESS}
                        ${ARG_FILE_SETS}
                    )
                    add_dependencies(${parent} ${child}_questasim_gen_sc_wrapper)
                endif()

                if(parent_is_ip_lib AND child_is_systemc_lib)
                    set_property(TARGET ${child} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
                endif()
            endforeach()
        endif()
    endforeach()

    unset(all_stamp_files)
    foreach(lib ${__ips})
        unset(lib_stamp_files)

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

        __get_questasim_search_lib_args(${lib} LIBRARY ${__comp_lib_name})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS ${ARG_FILE_SETS})
        get_ip_sources(SV_HEADERS ${lib} SYSTEMVERILOG VERILOG NO_DEPS HEADERS ${ARG_FILE_SETS})
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

            set(DESCRIPTION "${Green}Compile Verilog and SV files of ${lib} with questasim vlog${ColourReset}")
            set(sv_compile_cmd vlog
                    -${bitness}
                    -nologo
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -sv
                    -sv17compat
                    -work ${__comp_lib_name}
                    -Ldir ${OUTDIR} ${hdl_libs_args}
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
            set(vhdl_compile_cmd vcom
                    -nologo
                    -${bitness}
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -work ${__comp_lib_name}
                    ${ARG_VHDL_COMPILE_ARGS}
                    ${VHDL_SOURCES}
                )
        endif()

        get_target_property(is_sc_boundary_lib ${lib} SOCMAKE_SC_BOUNDARY_LIB)
        unset(sccom_cmd)
        if(is_sc_boundary_lib)
            get_target_property(cxx_sources ${lib} SOURCES)
            set(sccom_cmd sccom
                    -${bitness}
                    -work ${__comp_lib_name}
                    "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET,$<TARGET_PROPERTY:${lib},SOURCES>,-1>,$<TARGET_PROPERTY:${lib},SOURCE_DIR>>" # Get Absolute path to the last source file
                    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${lib},INCLUDE_DIRECTORIES>,PREPEND,-I>" 
                    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${lib},COMPILE_DEFINITIONS>,PREPEND,-D>" 
                )
        endif()

        # Questasim custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __questasim_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__questasim_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __questasim_subdep_stamp_files ${__questasim_${ip_dep}_stamp_files})
        endforeach()

        unset(__questasim_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "${Green}Compile SV, and Verilog sources of ${lib} with questasim vlog in library ${__comp_lib_name}${ColourReset}")
            set(STAMP_FILE "${OUTDIR}/.${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND vlib "${lib_outdir}" > /dev/null 2>&1 || true
                COMMAND ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${SV_HEADERS} ${__questasim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __questasim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL sources for ${lib} with questasim vcom in library ${__comp_lib_name}")
            set(STAMP_FILE "${OUTDIR}/.${lib}_vcom_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND vlib "${lib_outdir}" > /dev/null 2>&1 || true
                COMMAND ${vhdl_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__questasim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __questasim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(is_sc_boundary_lib)
            set(DESCRIPTION "Compile SystemC language boundary library ${lib} with sccom in library ${__comp_lib_name}")
            set(STAMP_FILE "${OUTDIR}/.${lib}_sc_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${sccom_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${lib}
                COMMENT ${DESCRIPTION}
                COMMAND_EXPAND_LISTS
                # VERBATIM
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __questasim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(NOT SV_SOURCES AND NOT VHDL_SOURCES AND NOT is_sc_boundary_lib)
            set(DESCRIPTION "Generate library ${__comp_lib_name} for ${lib} for questasim")
            set(STAMP_FILE "${OUTDIR}/.${lib}_dummy_stamp_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND vlib "${lib_outdir}" > /dev/null 2>&1 || true
                COMMAND touch ${STAMP_FILE}
                DEPENDS ${__questasim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __questasim_${lib}_stamp_files ${STAMP_FILE})
        endif()

    endforeach()

    if(NOT TARGET ${IP_LIB}_questasim_complib)
        add_custom_target(
            ${IP_LIB}_questasim_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_questasim_complib PROPERTY 
            DESCRIPTION "Compile VHDL, SV, and Verilog files for ${IP_LIB} with questasim in library ${LIBRARY}")

        set_property(TARGET ${IP_LIB}_questasim_complib APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${lib_outdir})
    endif()

endfunction()

# This function is called by ``questasim``, it shouldn't be used directly in a cmake file.
#
# It will set values for the HDL and DPI library arguments that will be used for compilation, elaboration and simulation.
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory for the Questa compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
function(__get_questasim_search_lib_args IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../sim_utils.cmake")

    get_ip_links(ips ${IP_LIB})
    unset(hdl_libs_args)
    unset(dpi_libs_args)
    foreach(lib ${ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        __is_socmake_ip_lib(is_ip_lib ${lib})
        __is_socmake_vhpi_lib(is_vhpi_lib ${lib})
        __is_socmake_dpic_lib(is_dpic_lib ${lib})

        if(is_vhpi_lib)
            list(APPEND dpi_libs_args -vhpi $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
        endif()

        if(is_dpic_lib)
            list(APPEND dpi_libs_args -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
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

            # Append current library outdir to list of search directories
            if(NOT ${__comp_lib_name} IN_LIST hdl_libs_args)
                list(APPEND hdl_libs_args -L ${__comp_lib_name})
            endif()
        endif()
    endforeach()

    set(HDL_LIBS_ARGS ${hdl_libs_args} PARENT_SCOPE)
    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

# This function allows to find the path to questasim home directory and to store it in a given variable.
#
# :param OUTVAR: Name of the variable in which questasim_home will be stored
# :type OUTVAR: string
function(__find_questasim_home OUTVAR)
    find_program(exec_path vsim REQUIRED)
    get_filename_component(bin_path "${exec_path}" DIRECTORY)
    cmake_path(SET questasim_home NORMALIZE "${bin_path}/..")

    set(${OUTVAR} ${questasim_home} PARENT_SCOPE)
endfunction()

#[[[
# This function create a target to generate a SystemC wrapper for the IP library, with Questasim scgenmod, if SystemVerilog or Verilog files are in the IP library.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog or Verilog files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bit compilation and simulation.
# :type 32BIT: bool
# :keyword QUIET: Disable output for informative messages
# :type QUIET: bool
# :keyword OUTDIR: Output directory for the Questa compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword VHDL_COMPILE_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type VHDL_COMPILE_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
#]]
function(questasim_gen_sc_wrapper IP_LIB)
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_questasim)
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
    # Create output directoy for the VHDL library
    set(lib_outdir ${OUTDIR}/${__comp_lib_name})

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
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

        set(sv_compile_cmd vlog
                -${bitness}
                -nologo
                $<$<BOOL:${ARG_QUIET}>:-quiet>
                -sv
                -sv17compat
                -work ${__comp_lib_name}
                ${ARG_SV_COMPILE_ARGS}
                ${SV_ARG_INCDIRS}
                ${SV_CMP_DEFS_ARG}
                ${SV_SOURCES}
            )

        set(scgenmod_cmd scgenmod
            -bool -sc_uint
            ${ARG_TOP_MODULE}
            )

        set(generated_header ${OUTDIR}/${ARG_TOP_MODULE}.h)
        set(DESCRIPTION "Generate a SC wrapper file for ${IP_LIB} with Questasim scgenmod")
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} ${generated_header}
            COMMAND touch ${STAMP_FILE}
            COMMAND ${sv_compile_cmd}
            COMMAND ${scgenmod_cmd} > ${generated_header}
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
        # target_sources(${IP_LIB} INTERFACE ${generated_header})
    endif()

endfunction()

#[[[
# This function create a target to compile SystemC boundary library with sccom
#
# :param SC_LIB: IP library, it needs to have SOURCES property set with a list of SystemC files as **cxx_sources**.
# :type IP_LIB: string
# :type SC_LIB:
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bit compilation and simulation.
# :type 32BIT: bool
# :keyword OUTDIR: Output directory for the Questa compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
#]]
function(questasim_compile_sc_lib SC_LIB)
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
        set(OUTDIR ${BINARY_DIR}/${SC_LIB}_questasim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    set(__comp_lib_name work)
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()
    # Create output directoy for the VHDL library
    set(lib_outdir ${OUTDIR}/${__comp_lib_name})

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    get_ip_sources(sc_portmap ${SC_LIB} VCS_SC_PORTMAP NO_DEPS)
    unset(sc_portmap_arg)
    if(sc_portmap)
        set(sc_portmap_arg -port ${sc_portmap})
    endif()

    get_target_property(cxx_sources ${SC_LIB} SOURCES)

    set(sccom_cmd sccom
            -${bitness}
            -work ${__comp_lib_name}
            "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET,$<TARGET_PROPERTY:${SC_LIB},SOURCES>,-1>,$<TARGET_PROPERTY:${SC_LIB},SOURCE_DIR>>" # Get Absolute path to the last source file
            "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},INCLUDE_DIRECTORIES>,PREPEND,-I>" 
            "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${SC_LIB},COMPILE_DEFINITIONS>,PREPEND,-D>" 
        )

    set(DESCRIPTION "Compile SystemC language boundary library ${SC_LIB} with sccom")
    set(STAMP_FILE "${OUTDIR}/${SC_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND ${sccom_cmd}
        COMMAND touch ${STAMP_FILE}
        WORKING_DIRECTORY ${OUTDIR}
        DEPENDS ${SC_LIB}
        COMMENT ${DESCRIPTION}
        COMMAND_EXPAND_LISTS
        # VERBATIM
    )

    add_custom_target(
        ${SC_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${SC_LIB}
    )
    set_property(TARGET ${SC_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
endfunction()

#[[[
# This macro is used to configure the C and CXX compiler to the one used by the tool.
#
# It can also be used to add some libraries, such as SystemC, DPI-C and VHPI in this case, for example if you want to use dpi, you should use this macro like this :
# 
# .. code-block:: cmake
#
#    questasim_configure_cxx(LIBRARIES DPI-C)
#
# **Keyword Arguments**
#
# :keyword LIBRARIES: Libraries that needs to be added.
# :type LIBRARIES: list[string]
#]]
macro(questasim_configure_cxx)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})

    __find_questasim_home(questasim_home)

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    set(CMAKE_CXX_COMPILER "${questasim_home}/gcc${bitness}/bin/g++")
    set(CMAKE_C_COMPILER "${questasim_home}/gcc${bitness}/bin/gcc")

    if(ARG_LIBRARIES)
        questasim_add_cxx_libs(${ARGV})
    endif()
endmacro()

#[[[
# This function is called by the ``questasim_configure_cxx`` macro, you shouldn't use it directly.
#
# It will add the needed information to IP_LIB and add some flags for the compilation and linking.
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bitness.
# :type 32BIT: bool
# :keyword LIBRARIES: libraries that needs to be added, possible choice are SystemC, DPI-C and/or VHPI
# :type LIBRARIES: list[string]
#]]
function(questasim_add_cxx_libs)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries SystemC DPI-C VHPI)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            message(FATAL_ERROR "Questasim does not support library: ${lib}")
        endif()
    endforeach()

    __find_questasim_home(questasim_home)

    if(SystemC IN_LIST ARG_LIBRARIES)

        add_library(questasim_systemc INTERFACE)
        add_library(SoCMake::SystemC ALIAS questasim_systemc)

        if(ARG_32BIT)
            target_compile_options(questasim_systemc INTERFACE -m32)
            target_link_options   (questasim_systemc INTERFACE -m32)
        endif()
        # set_property(TARGET questasim_systemc PROPERTY POSITION_INDEPENDENT_CODE ON)
        target_compile_definitions(questasim_systemc INTERFACE MTI_SYSTEMC)
        target_include_directories(questasim_systemc INTERFACE
            ${questasim_home}/include/systemc
            ${questasim_home}/include
            ${questasim_home}/include/ac_types
            )
    endif()

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(questasim_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS questasim_dpi-c)

        if(ARG_32BIT)
            target_compile_options(questasim_dpi-c INTERFACE -m32)
            target_link_options   (questasim_dpi-c INTERFACE -m32)
        endif()
        target_include_directories(questasim_dpi-c INTERFACE ${questasim_home}/include)
        target_compile_definitions(questasim_dpi-c INTERFACE QUESTA)
    endif()

    if(VHPI IN_LIST ARG_LIBRARIES)
        add_library(questasim_vhpi INTERFACE)
        add_library(SoCMake::VHPI ALIAS questasim_vhpi)

        if(ARG_32BIT)
            target_compile_options(questasim_vhpi INTERFACE -m32)
            target_link_options   (questasim_vhpi INTERFACE -m32)
        endif()
        target_compile_definitions(questasim_vhpi INTERFACE QUESTA)

        target_include_directories(questasim_vhpi INTERFACE ${questasim_home}/include)
        target_compile_definitions(questasim_vhpi INTERFACE QUESTA)
    endif()

endfunction()

#[[[
# This macro is here in case the old modelsim SoCMake function has been called, due to a change in the function name, made to fit with the changes made in the past years with Modelsim/Questa.
#
# It will print a deprecation message and redirect the arguments used to the questasim SoCMake function.
#]]
macro(modelsim)
    message(DEPRECATION "${Red}modelsim function is deprecated, questasim() is called instead${ColourReset}")
    questasim(${ARGV})
endmacro()
