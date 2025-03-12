include_guard(GLOBAL)

function(modelsim IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;QUIET;GUI;GUI_VISUALIZER;32BIT" "LIBRARY;TOP_MODULE;OUTDIR;RUN_TARGET_NAME" "VHDL_COMPILE_ARGS;SV_COMPILE_ARGS;RUN_ARGS" ${ARGN})
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

    __find_modelsim_home(modelsim_home)

    ### Compile with vcom and vlog
    if(NOT TARGET ${IP_LIB}_modelsim_complib)
        __modelsim_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            ${ARG_BITNESS}
            ${ARG_QUIET}
            ${ARG_LIBRARY}
            ${ARG_SV_COMPILE_ARGS}
            ${ARG_VHDL_COMPILE_ARGS}
            )
    endif()
    set(comp_tgt ${IP_LIB}_modelsim_complib)

    ### Get list of linked libraries marked as SystemC
    get_ip_links(__ips ${IP_LIB})
    unset(systemc_libs)
    unset(ip_libs)
    foreach(lib ${__ips})
        get_target_property(ip_type ${lib} TYPE)
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        __is_socmake_ip_lib(is_ip_lib ${lib})
        if(is_systemc_lib)
            list(APPEND systemc_libs ${lib})
        elseif(is_ip_lib)
            list(APPEND ip_libs ${lib})
        endif()
    endforeach()

    ### Add SystemC library needed includes and defines
    foreach(lib ${systemc_libs})
        if(ARG_32BIT)
            target_compile_options(${lib} PUBLIC -m32)
            target_link_options   (${lib} PUBLIC -m32)
        endif()
        set_property(TARGET ${lib} PROPERTY POSITION_INDEPENDENT_CODE ON)
        target_compile_definitions(${lib} PUBLIC MTI_SYSTEMC)
        target_include_directories(${lib} PUBLIC
            ${modelsim_home}/include/systemc
            ${modelsim_home}/include
            ${modelsim_home}/include/ac_types
            )
    endforeach()

    __get_modelsim_search_lib_args(${IP_LIB} 
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
                -Wl,-rpath,${modelsim_home}/${libpath}
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
            # BYPRODUCTS  ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${comp_tgt} #${SC_SOURCES}
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

    if(NOT ARG_GUI AND NOT ARG_GUI_VISUALIZER)
        list(APPEND run_sim_cmd
            -c 
            -do "run -all\; quit"
        )

    endif()

    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND  ${run_sim_cmd} -noautoldlibpath
            DEPENDS ${comp_tgt} ${sccom_link_tgt}
            WORKING_DIRECTORY ${OUTDIR}
            COMMENT ${DESCRIPTION}
            VERBATIM
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${run_sim_cmd} PARENT_SCOPE)

endfunction()


function(__modelsim_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "QUIET;32BIT" "OUTDIR;LIBRARY" "SV_COMPILE_ARGS;VHDL_COMPILE_ARGS" ${ARGN})
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

    if(ARG_32BIT)
        set(bitness 32)
    else()
        set(bitness 64)
    endif()

    # Find the modelsim tools/include directory, needed for VPI/DPI libraries
    __add_modelsim_cxx_properties_to_libs(${IP_LIB})

    get_ip_links(__ips ${IP_LIB})

    foreach(parent ${__ips})
        get_target_property(children_ips ${parent} INTERFACE_LINK_LIBRARIES)
        message("Parent: ${parent}: Children: ${children_ips}")

        __is_socmake_systemc_lib(parent_is_systemc_lib ${parent})
        __is_socmake_ip_lib(parent_is_ip_lib ${parent})

        if(parent_is_systemc_lib)
            message("It is boundary before: ${parent}")
            set_property(TARGET ${parent} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
            # modelsim_compile_sc_lib(${parent} 
            #     OUTDIR ${OUTDIR}
            #     LIBRARY ${LIBRARY}
            #     ${ARG_BITNESS}
            # )
            # add_dependencies(${parent} ${child}_modelsim_compile_sc_lib)
        endif()

        if(children_ips)
            foreach(child ${children_ips})
                __is_socmake_systemc_lib(child_is_systemc_lib ${child})
                __is_socmake_ip_lib(child_is_ip_lib ${child})

                if(parent_is_systemc_lib AND child_is_ip_lib)
                    modelsim_gen_sc_wrapper(${child} 
                        OUTDIR ${OUTDIR}
                        LIBRARY ${LIBRARY}
                        ${ARG_BITNESS}
                    )
                    add_dependencies(${parent} ${child}_modelsim_gen_sc_wrapper)
                    # set_property(TARGET ${child} APPEND PROPERTY SOCMAKE_SYSTEMC_PARENTS ${parent})
                    # target_include_directories(${parent} PUBLIC ${OUTDIR}/csrc/sysc/include/)
                endif()

                if(parent_is_ip_lib AND child_is_systemc_lib)
                    set_property(TARGET ${child} PROPERTY SOCMAKE_SC_BOUNDARY_LIB TRUE)
                    # modelsim_compile_sc_lib(${child} 
                    #     OUTDIR ${OUTDIR}
                    #     LIBRARY ${LIBRARY}
                    #     ${ARG_BITNESS}
                    # )
                    # add_dependencies(${parent} ${child}_modelsim_compile_sc_lib)
                endif()
            endforeach()
        endif()
    endforeach()

    unset(all_stamp_files)
    foreach(lib ${__ips})

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

        __get_modelsim_search_lib_args(${lib})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

        # SystemVerilog and Verilog files and arguments
        get_ip_sources(SV_SOURCES ${lib} SYSTEMVERILOG VERILOG NO_DEPS)
        get_ip_sources(SV_HEADERS ${lib} SYSTEMVERILOG VERILOG VHDL HEADERS)
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

            set(DESCRIPTION "Compile Verilog and SV files of ${lib} with modelsim vlog")
            set(sv_compile_cmd vlog
                    -${bitness}
                    -nologo
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -sv
                    -sv17compat
                    -work ${lib_outdir}
                    -Ldir ${OUTDIR} ${hdl_libs_args}
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
            set(vhdl_compile_cmd vcom
                    -nologo
                    -${bitness}
                    $<$<BOOL:${ARG_QUIET}>:-quiet>
                    -work ${lib_outdir}
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
                    -work ${lib_outdir}
                    "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<LIST:GET,$<TARGET_PROPERTY:${lib},SOURCES>,-1>,$<TARGET_PROPERTY:${lib},SOURCE_DIR>>" # Get Absolute path to the last source file
                    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${lib},INCLUDE_DIRECTORIES>,PREPEND,-I>" 
                    "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${lib},COMPILE_DEFINITIONS>,PREPEND,-D>" 
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
            set(DESCRIPTION "Compile SV, and Verilog sources of ${lib} with modelsim vlog in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sv_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${sv_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${SV_SOURCES} ${SV_HEADERS} ${__modelsim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __modelsim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL sources for ${lib} with modelsim vlog in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_vcom_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${vhdl_compile_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__modelsim_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __modelsim_${lib}_stamp_files ${STAMP_FILE})
        endif()

        if(is_sc_boundary_lib)
            set(DESCRIPTION "Compile SystemC language boundary library ${lib} with sccom in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_sc_compile_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${sccom_cmd}
                COMMAND touch ${STAMP_FILE}
                BYPRODUCTS ${lib_outdir}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${lib}
                COMMENT ${DESCRIPTION}
                COMMAND_EXPAND_LISTS
                # VERBATIM
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

endfunction()


function(__get_modelsim_search_lib_args IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_ip_links(ips ${IP_LIB})
    unset(hdl_libs_args)
    foreach(lib ${ips})
        __is_socmake_systemc_lib(is_systemc_lib ${lib})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY" AND NOT is_systemc_lib)
            # list(APPEND dpi_libs_args -sv_lib $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
            list(APPEND dpi_libs_args -vhpi $<TARGET_FILE_DIR:${lib}>/lib$<TARGET_FILE_BASE_NAME:${lib}>)
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

            # Append current library outdir to list of search directories
            if(NOT ${__comp_lib_name} IN_LIST hdl_libs_args)
                list(APPEND hdl_libs_args -L ${__comp_lib_name})
            endif()
        endif()
    endforeach()

    set(HDL_LIBS_ARGS ${hdl_libs_args} PARENT_SCOPE)
    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

function(__find_modelsim_home OUTVAR)
    find_program(exec_path vsim REQUIRED)
    get_filename_component(bin_path "${exec_path}" DIRECTORY)
    cmake_path(SET modelsim_home NORMALIZE "${bin_path}/..")

    set(${OUTVAR} ${modelsim_home} PARENT_SCOPE)
endfunction()

function(__add_modelsim_cxx_properties_to_libs IP_LIB)
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Find the modelsim tools/include directory, needed for VPI/DPI libraries
    __find_modelsim_home(modelsim_home)
    set(vpi_inc_path "${modelsim_home}/include")

    get_ip_links(ips ${IP_LIB})
    foreach(lib ${ips})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            # Add tools/include directory to the include directories of DPI libraries
            # TODO do this only when its needed
            target_include_directories(${lib} PUBLIC ${vpi_inc_path})
            target_compile_definitions(${lib} PUBLIC QUESTA)
        endif()
    endforeach()
endfunction()

function(modelsim_gen_sc_wrapper IP_LIB)
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
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_modelsim)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

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

        set(sv_compile_cmd vlog
                -${bitness}
                -nologo
                $<$<BOOL:${ARG_QUIET}>:-quiet>
                -sv
                -sv17compat
                -work ${lib_outdir}
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
        set(DESCRIPTION "Generate a SC wrapper file for ${IP_LIB} with Modelsim scgenmod")
        set(STAMP_FILE "${OUTDIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE} ${generated_header}
            COMMAND touch ${STAMP_FILE}
            COMMAND ${sv_compile_cmd}
            COMMAND ${scgenmod_cmd} > ${generated_header}
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
        # target_sources(${IP_LIB} INTERFACE ${generated_header})
    endif()

endfunction()

function(modelsim_compile_sc_lib SC_LIB)
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
        set(OUTDIR ${BINARY_DIR}/${SC_LIB}_modelsim)
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
    message("cxx_sources: ${cxx_sources}")

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
