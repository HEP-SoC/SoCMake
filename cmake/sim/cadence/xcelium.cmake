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

    get_ip_links(__ips ${IP_LIB})
    unset(systemc_libs)
    foreach(lib ${__ips})
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY" OR ip_type STREQUAL "OBJECT_LIBRARY")
            get_target_property(socmake_cxx_library_type ${lib} SOCMAKE_CXX_LIBRARY_TYPE)
            if(socmake_cxx_library_type STREQUAL "SYSTEMC")
                list(APPEND systemc_libs ${lib})
            endif()
        endif()
    endforeach()

    unset(systemc_lib_args)
    if(systemc_libs)
        set(systemc_lib_name ${IP_LIB}_xcelium_systemc)

        ## Because shared library without any source files is not possible
        file(WRITE "${OUTDIR}/__null.cpp" "")
        add_library(${systemc_lib_name} SHARED
            "${OUTDIR}/__null.cpp"
            )
        if(ARG_32BIT)
            target_compile_options(${systemc_lib_name} PUBLIC -m32)
            target_link_options(   ${systemc_lib_name} PUBLIC -m32)
        endif()

        if(bitness STREQUAL "64")
            set(libpath "lib/64bit/gnu")
        else()
            set(libpath "lib/gnu")
        endif()

        __find_xcelium_home(xcelium_home)
        target_link_libraries(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_systemc PUBLIC
            ${systemc_libs}
            ${xcelium_home}/tools/systemc/${libpath}/libncscCoSim_sh.so
            ${xcelium_home}/tools/systemc/${libpath}/libncscCoroutines_sh.so 
            ${xcelium_home}/tools/systemc/${libpath}/libsystemc_sh.so
           )

        set(systemc_lib_args -loadsc $<TARGET_FILE:${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_systemc>)
        list(APPEND comp_tgt ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_systemc)
    endif()

    __get_xcelium_search_lib_args(${IP_LIB} 
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(hdl_libs_args ${HDL_LIBS_ARGS})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    get_ip_sources(HEADERS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL HEADERS)
    if(NOT TARGET ${IP_LIB}_xcelium)
        set(elaborate_cmd COMMAND xrun -elaborate
                -64bit
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
        -64bit
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

    # Find the Xcelium tools/include directory, needed for VPI/DPI libraries
    __add_xcelium_cxx_properties_to_libs(${IP_LIB})

    get_ip_links(__ips ${IP_LIB})
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
                    -64bit
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
                    -64bit
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
                COMMAND ${sv_compile_cmd}
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
                COMMAND ${vhdl_compile_cmd}
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
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            list(APPEND dpi_libs_args -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
        else()
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

function(__add_xcelium_cxx_properties_to_libs IP_LIB)
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Find the Xcelium tools/include directory, needed for VPI/DPI libraries
    __find_xcelium_home(xcelium_home)
    set(tools_dir_path "${xcelium_home}/tools")

    get_ip_links(ips ${IP_LIB})
    foreach(lib ${ips})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY" OR ip_type STREQUAL "OBJECT_LIBRARY")
            get_target_property(socmake_cxx_library_type ${lib} SOCMAKE_CXX_LIBRARY_TYPE)

            if(socmake_cxx_library_type STREQUAL "SYSTEMC")
                target_include_directories(${lib} PUBLIC 
                    ${tools_dir_path}/systemc/include
                    ${tools_dir_path}/tbsc/include
                    ${tools_dir_path}/vic/include
                )
            endif()
            # Add tools/include directory to the include directories of DPI libraries
            # TODO do this only when its needed
            target_include_directories(${lib} PUBLIC "${tools_dir_path}/include")
            target_compile_definitions(${lib} PUBLIC INCA)
        endif()
    endforeach()
endfunction()

macro(xcelium_configure_cxx)
    __find_xcelium_home(xcelium_home)
    set(CMAKE_CXX_COMPILER "${xcelium_home}/tools.lnx86/cdsgcc/gcc/bin/g++")
    set(CMAKE_C_COMPILER "${xcelium_home}/tools.lnx86/cdsgcc/gcc/bin/gcc")
endmacro()
