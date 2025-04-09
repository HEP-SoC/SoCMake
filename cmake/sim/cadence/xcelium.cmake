#[[[ @module xcelium
#]]

#[[[
# Create a target for invoking Xcelium simulation on IP_LIB.
#
# It will create a target **run_<IP_LIB>_xcelium** that will start the xcelium simulation
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword GUI: launch SimVision gui together with the simulation
# :type GUI: boolean
#]]

include_guard(GLOBAL)

function(xcelium IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI;32BIT" "RUN_TARGET_NAME;TOP_MODULE;LIBRARY" "COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

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

    if(NOT TARGET ${IP_LIB}_xcelium_complib)
        __xcelium_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_BITNESS}
            ${ARG_LIBRARY}
            ${ARG_COMPILE_ARGS}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            )
    endif()
    set(comp_tgt ${IP_LIB}_xcelium_complib)

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

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    get_ip_sources(HEADERS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL HEADERS)
    if(NOT TARGET ${IP_LIB}_xcelium)
        set(elaborate_cmd COMMAND xrun -elaborate
                $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                -q
                -nocopyright
                ${hdl_libs_args}
                ${systemc_lib_args}
                ${ARG_ELABORATE_ARGS}
                -top ${LIBRARY}.${ARG_TOP_MODULE}
            )

        ### Clean files:
        #       * 
        set(__clean_files 
            ${OUTDIR}/xmelab.log
            ${OUTDIR}/xcelium.d
        )

        set(DESCRIPTION "Elaborate ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            COMMAND ${elaborate_cmd}
            COMMAND touch ${STAMP_FILE}
            COMMENT ${DESCRIPTION}
            BYPRODUCTS  ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${comp_tgt} ${SOURCES} ${HEADERS}
            COMMAND_EXPAND_LISTS
            )

        add_custom_target(${IP_LIB}_xcelium
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_xcelium PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    ## XMSIM command for running simulation

    ### Clean files:
    #       * 
    set(__clean_files 
        ${OUTDIR}/xmsim.log
        ${OUTDIR}/xcelium.d
    )

    set(run_sim_cmd xrun -R
        $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
        $<$<BOOL:${ARG_GUI}>:-gui>
        ${hdl_libs_args}
        ${dpi_libs_args}
        ${ARG_RUN_ARGS}
        -top ${LIBRARY}.${ARG_TOP_MODULE}
        )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${run_sim_cmd}
            WORKING_DIRECTORY ${OUTDIR}
            BYPRODUCTS ${__clean_files}
            COMMENT ${DESCRIPTION}
            DEPENDS ${IP_LIB}_xcelium
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)

endfunction()

function(__xcelium_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY;TOP_MODULE" "COMPILE_ARGS;SV_COMPILE_ARGS;VHDL_COMPILE_ARGS" ${ARGN})
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
                        LIBRARY ${LIBRARY}
                        ${ARG_BITNESS}
                    )
                    add_dependencies(${parent} ${child}_xcelium_gen_sc_wrapper)
                endif()

                if(parent_is_ip_lib AND child_is_systemc_lib)
                    set_property(TARGET ${child} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
                    xcelium_gen_hdl_wrapper(${child} 
                        OUTDIR ${OUTDIR}
                        LIBRARY ${LIBRARY}
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
        get_target_property(__comp_lib_name ${lib} LIBRARY)
        if(NOT __comp_lib_name)
            set(__comp_lib_name worklib)
        endif()
        if(ARG_LIBRARY)
            set(__comp_lib_name ${ARG_LIBRARY})
        endif()

        # Create output directoy for the VHDL library
        set(lib_outdir ${OUTDIR}/xcelium.d/${__comp_lib_name})

        __get_xcelium_search_lib_args(${lib}
            OUTDIR ${OUTDIR})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS)
        get_ip_sources(SV_HEADERS ${lib} SYSTEMVERILOG VERILOG HEADERS)
        unset(sv_compile_cmd)
        if(SV_SOURCES)
            get_ip_include_directories(SV_INC_DIRS ${lib}  SYSTEMVERILOG VERILOG)
            get_ip_compile_definitions(SV_COMP_DEFS ${lib} SYSTEMVERILOG VERILOG)

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
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS)
        unset(vhdl_compile_cmd)
        if(VHDL_SOURCES)
            set(vhdl_compile_cmd COMMAND xrun -compile
                    $<$<NOT:$<BOOL:${ARG_32BIT}>>:-64bit>
                    -q
                    -nocopyright
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
            ${OUTDIR}/xrun.log
            ${OUTDIR}/xrun.history
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
                BYPRODUCTS ${lib_outdir} ${__clean_files}
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
                BYPRODUCTS ${lib_outdir} ${__clean_files}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__xcelium_subdep_stamp_files}
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
            get_target_property(__comp_lib_name ${lib} LIBRARY)
            if(NOT __comp_lib_name)
                set(__comp_lib_name worklib)
            endif()
            if(ARG_LIBRARY)
                set(__comp_lib_name ${ARG_LIBRARY})
            endif()

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
    cmake_parse_arguments(ARG "32BIT;QUIET" "OUTDIR;LIBRARY;TOP_MODULE" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS" ${ARGN})
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

    get_target_property(__comp_lib_name ${IP_LIB} LIBRARY)
    if(NOT __comp_lib_name)
        set(__comp_lib_name worklib)
    endif()
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()
    # Create output directoy for the VHDL library
    set(lib_outdir ${OUTDIR}/${__comp_lib_name})

    get_ip_sources(SV_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG NO_DEPS)
    list(GET SV_SOURCES -1 last_sv_file) # TODO this is not correct, as the last Verilog file might not be top
    unset(sv_compile_cmd)
    if(SV_SOURCES)
        get_ip_include_directories(SV_INC_DIRS ${IP_LIB}  SYSTEMVERILOG VERILOG)
        get_ip_compile_definitions(SV_COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG)

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
            BYPRODUCTS ${OUTDIR}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${last_sv_file} ${SV_HEADERS}
            COMMENT ${DESCRIPTION}
        )

        add_custom_target(
            ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})

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

    set(__comp_lib_name worklib)
    if(ARG_LIBRARY)
        set(__comp_lib_name ${ARG_LIBRARY})
    endif()

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

    set(allowed_libraries SystemC DPI-C TLM2)
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

    if(bitness STREQUAL "64")
        set(libpath "lib/64bit/gnu")
    else()
        set(libpath "lib/gnu")
    endif()

    if(SystemC IN_LIST ARG_LIBRARIES)
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

    if(TLM2 IN_LIST ARG_LIBRARIES)
        add_library(xcelium_tlm2 INTERFACE)
        add_library(SoCMake::TLM2 ALIAS xcelium_tlm2)

        if(ARG_32BIT)
            target_compile_options(xcelium_tlm2 INTERFACE -m32)
            target_link_options   (xcelium_tlm2 INTERFACE -m32)
        endif()
        target_include_directories(xcelium_tlm2 INTERFACE ${xcelium_home}/tools.lnx86/systemc/include/tlm2)
        target_link_libraries(xcelium_tlm2 INTERFACE
            ${xcelium_home}/tools/systemc/${libpath}/libxmsctlm2_sh.so
        )
    endif()


endfunction()
