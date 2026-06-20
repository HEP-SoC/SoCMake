#[[[ @module nvc
#]]

include_guard(GLOBAL)

function(nvc IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET" "OUTDIR;RUN_TARGET_NAME;TOP_MODULE;LIBRARY" "COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS;FILE_SETS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Optimization to not do topological sort of linked IPs on get_ip_...() calls
    flatten_graph_and_disallow_flattening(${IP_LIB})

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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_nvc)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

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

    #######################
    ### Set target names ##
    #######################

    set(compile_target ${IP_LIB}_nvc_complib)
    set(elaborate_target ${IP_LIB}_) 
    set(run_target ${ARG_RUN_TARGET_NAME})
    if(NOT ARG_RUN_TARGET_NAME)
        set(run_target run_${IP_LIB}_) 
    endif()

    if(NOT TARGET ${compile_target})
        __nvc_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_LIBRARY}
            ${ARG_COMPILE_ARGS}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            ${ARG_FILE_SETS}
            )
    endif()

    ### Get list of linked SystemC libraries
    get_ip_links(__ips ${IP_LIB})

    __get_nvc_search_lib_args(${IP_LIB}
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(hdl_libs_args ${HDL_LIBS_ARGS})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL ${ARG_FILE_SETS})
    get_ip_sources(HEADERS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL HEADERS ${ARG_FILE_SETS})
    if(NOT TARGET ${elaborate_target})
        set(elaborate_cmd COMMAND nvc
                ${hdl_libs_args}
                --work=${LIBRARY}
                -e
                ${ARG_ELABORATE_ARGS}
                ${ARG_TOP_MODULE}
            )

        ### Clean files:
        string(TOUPPER ${LIBRARY} _nvc_lib)
        string(TOUPPER ${ARG_TOP_MODULE} _nvc_top_module)
        set(__clean_files #TODO
            ${OUTDIR}/${_nvc_lib}.${_nvc_top_module}.elab
            ${OUTDIR}/_index
            ${OUTDIR}/_NVC_LIB
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
    # set(__clean_files
    #     xmsim.log
    # )

    set(run_sim_cmd nvc
        ${hdl_libs_args}
        ${dpi_libs_args}
        -r
        ${ARG_RUN_ARGS}
        ${ARG_TOP_MODULE}
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
    set(SOCMAKE_SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)
    set(SOCMAKE_SIM_RUN_DIR ${OUTDIR} PARENT_SCOPE)
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

# This function is called by ``nvc``, it shouldn't be used directly in a cmake file.
#
# It will create an intermediary target to compile VDHL and SystemVerilog/Verilog file, using ``xrun -compile``.
#
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog or VDHL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory for the nvc compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword COMPILE_ARGS: Extra arguments to be passed to the compilation step (C, C++).
# :type COMPILE_ARGS: string
# :keyword XRUN_COMPILE_ARGS: Extra arguments to be passed to the xrun -compile command
# :type XRUN_COMPILE_ARGS: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the SystemVerilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword VHDL_COMPILE_ARGS: Extra arguments to be passed to the VHDL compilation step.
# :type VHDL_COMPILE_ARGS: string
# :keyword FILE_SETS: Specify list of File sets to retrieve the sources from
# :type FILE_SETS: list[string]
function(__nvc_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY;TOP_MODULE" "COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}) 
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

    unset(all_stamp_files)
    foreach(lib ${__ips})

        __is_socmake_systemc_lib(lib_is_systemc_lib ${lib})
        if(lib_is_systemc_lib)
            message(FATAL_ERROR "NVC simulator does not support SystemC libraries ${parent}")
        endif()

        # VHDL library of the current IP block, get it from SoCMake library if present
        # If neither LIBRARY property is set, or LIBRARY passed as argument, use "worklib" as default
        __nvc_default_library(__comp_lib_name ${lib})

        # Create output directoy for the VHDL library
        set(lib_outdir ${OUTDIR}/${__comp_lib_name})

        __get_nvc_search_lib_args(${lib}
            OUTDIR ${OUTDIR}
            ${ARG_LIBRARY_FORWARD})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

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
                list(APPEND SV_ARG_INCDIRS -I ${dir})
            endforeach()

            foreach(def ${SV_COMP_DEFS})
                list(APPEND SV_CMP_DEFS_ARG -D ${def})
            endforeach()

            set(sv_compile_cmd COMMAND nvc 
                    --work ${lib_outdir}
                    ${hdl_libs_args}
                    -a
                    ${ARG_COMPILE_ARGS}
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
            set(vhdl_compile_cmd COMMAND nvc
                    --work ${lib_outdir}
                    ${hdl_libs_args}
                    -a
                    ${ARG_COMPILE_ARGS}
                    ${ARG_VHDL_COMPILE_ARGS}
                    ${VHDL_SOURCES}
                )
        endif()

        # nvc custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __nvc_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__nvc_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __nvc_subdep_stamp_files ${__nvc_${ip_dep}_stamp_files})
        endforeach()

        ### Clean files:
        # complib upper and top file upper
        # string(TOUPPER ${__comp_lib_name} _nvc_lib)
        # set(__clean_files
        #     ${lib_outdir}/${_nvc_lib}.${_nvc_top_module}
        # )

        unset(__nvc_${lib}_stamp_files)
        if(SV_SOURCES)
            set(DESCRIPTION "Compile Verilog and SV sources of ${lib} with nvc in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${SV_HEADERS} ${__nvc_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __nvc_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL sources of ${lib} with nvc in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_vhdl_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                ${vhdl_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__nvc_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __nvc_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(NOT SV_SOURCES AND NOT VHDL_SOURCES)
            set(DESCRIPTION "Generate stamp file for ${lib} for nvc")
            set(STAMP_FILE "${lib_outdir}/.${lib}_dummy_stamp_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${lib_outdir}
                COMMAND touch ${STAMP_FILE}
                DEPENDS ${__nvc_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __nvc_${lib}_stamp_files ${STAMP_FILE})
        endif()

    endforeach()

    if(NOT TARGET ${IP_LIB}_nvc_complib)
        add_custom_target(
            ${IP_LIB}_nvc_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_nvc_complib PROPERTY DESCRIPTION ${DESCRIPTION})
        set_property(TARGET ${IP_LIB}_nvc_complib APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${__clean_files} ${lib_outdir})
    endif()

endfunction()

# This function is called by ``nvc``, it shouldn't be used directly in a cmake file.
#
# It will set values for the HDL and DPI library arguments that will be used for compilation, elaboration and simulation.
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory for the nvc compilation and simulation.
# :type OUTDIR: string
# :keyword LIBRARY: replace the default library name (worklib) to be used for elaboration and simulation.
# :type LIBRARY: string
function(__get_nvc_search_lib_args IP_LIB)
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
            message(FATAL_ERROR "NVC simulator does not support SystemC or DPI libraries")
            # list(APPEND dpi_libs_args -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
        endif()

        if(is_ip_lib)
            # Library of the current IP block, get it from SoCMake library if present
            # If neither LIBRARY property is set, or LIBRARY passed as argument, use "work" as default
            __nvc_default_library(__comp_lib_name ${lib})

            set(lib_outdir ${ARG_OUTDIR}/${__comp_lib_name})
            # Append current library outdir to list of search directories
            if(NOT ${lib_outdir} IN_LIST hdl_libs_args)
                list(APPEND hdl_libs_args -L ${lib_outdir})
            endif()
        endif()
    endforeach()

    set(HDL_LIBS_ARGS ${hdl_libs_args} PARENT_SCOPE)
    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

# This function allows to find the path to nvc home directory and to store it in a given variable.
#
# :param OUTVAR: Name of the variable in which nvc_home will be stored
# :type OUTVAR: string
function(__find_nvc_home OUTVAR)
    find_program(exec_path xrun REQUIRED)
    get_filename_component(bin_path "${exec_path}" DIRECTORY)
    cmake_path(SET nvc_home NORMALIZE "${bin_path}/../../")

    set(${OUTVAR} ${nvc_home} PARENT_SCOPE)
endfunction()

#[[[
# This function is called by the ``nvc_configure_cxx`` macro, you shouldn't use it directly.
#
# It will add the needed information to IP_LIB and add some flags for the compilation and linking.
#
# **Keyword Arguments**
#
# :keyword 32BIT: Use 32 bitness.
# :type 32BIT: bool
# :keyword LIBRARIES: libraries that needs to be added, possible choice is SystemC or DPI-C
# :type LIBRARIES: list[string]
#]]
function(nvc_add_cxx_libs)
    cmake_parse_arguments(ARG "32BIT" "" "LIBRARIES" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(allowed_libraries SystemC DPI-C)
    foreach(lib ${ARG_LIBRARIES})
        if(NOT ${lib} IN_LIST allowed_libraries)
            message(FATAL_ERROR "nvc does not support library: ${lib}")
        endif()
    endforeach()

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    __find_nvc_home(nvc_home)

    if(SystemC IN_LIST ARG_LIBRARIES)
        if(bitness STREQUAL "64")
            set(libpath "lib/64bit/gnu")
        else()
            set(libpath "lib/gnu")
        endif()

        add_library(nvc_systemc INTERFACE)
        add_library(SoCMake::SystemC ALIAS nvc_systemc)
        target_link_libraries(nvc_systemc INTERFACE
            ${nvc_home}/tools/systemc/${libpath}/libncscCoSim_sh.so
            ${nvc_home}/tools/systemc/${libpath}/libncscCoroutines_sh.so
            ${nvc_home}/tools/systemc/${libpath}/libsystemc_sh.so
        )

        if(ARG_32BIT)
            target_compile_options(nvc_systemc INTERFACE -m32)
            target_link_options(nvc_systemc    INTERFACE -m32)
        endif()
        target_compile_definitions(nvc_systemc INTERFACE INCA)

        target_include_directories(nvc_systemc INTERFACE
            ${nvc_home}/tools/systemc/include
            ${nvc_home}/tools/tbsc/include
            ${nvc_home}/tools/vic/include
        )
    endif()

    if(DPI-C IN_LIST ARG_LIBRARIES)
        add_library(nvc_dpi-c INTERFACE)
        add_library(SoCMake::DPI-C ALIAS nvc_dpi-c)

        if(ARG_32BIT)
            target_compile_options(nvc_dpi-c INTERFACE -m32)
            target_link_options   (nvc_dpi-c INTERFACE -m32)
        endif()
        target_include_directories(nvc_dpi-c INTERFACE ${nvc_home}/include)
        target_compile_definitions(nvc_dpi-c INTERFACE INCA)
    endif()

endfunction()

# Determine the default nvc compilation library name for a given IP_LIB.
#
# It will resolves the logical compilation library associated with it.
#
# :param OUT_LIB: Name of the variable that will receive the resolved library name.
# :type OUT_LIB: string (output variable)
# :param IP_LIB: The target IP library, it needs to have SOURCES property set with a list of SystemVerilog or VHDL files.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword LIBRARY: Specify the compilation library name to use.
# :type LIBRARY: string
function(__nvc_default_library OUT_LIB IP_LIB)
    cmake_parse_arguments(ARG "" "LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(__comp_lib_name ${IP_LIB} LIBRARY)
    if(NOT __comp_lib_name)
        set(__comp_lib_name work)
    endif()
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()
    # nvc doesnt like some characters in the name of the libraries, sanitize
    string(MAKE_C_IDENTIFIER "${__comp_lib_name}" __comp_lib_name)
    set(${OUT_LIB} ${__comp_lib_name} PARENT_SCOPE)
endfunction()

