include_guard(GLOBAL)

function(__ghdl_get_standard_arg OUTVAR)
    set(SUPPORTED_VHDL_STANDARDS  87 93c 93 00 02 08)
    if(ARGN)
        if(NOT ${ARGN} IN_LIST SUPPORTED_VHDL_STANDARDS)
            message(FATAL_ERROR "VHDL standard not supported ${ARGN}, supported standards: ${ARGN}")
        endif()
        set(${OUTVAR} ${ARGN} PARENT_SCOPE)
    else()
        set(${OUTVAR} 93 PARENT_SCOPE)
    endif()
endfunction()

function(ghdl IP_LIB)
    cmake_parse_arguments(ARG "NO_RUN_TARGET;" "OUTDIR;TOP_MODULE;EXECUTABLE_NAME;STANDARD" "VHDL_COMPILE_ARGS;ELABORATE_ARGS;RUN_ARGS;FILE_SETS" ${ARGN})
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

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    if(ARG_VHDL_COMPILE_ARGS)
        set(ARG_VHDL_COMPILE_ARGS VHDL_COMPILE_ARGS ${ARG_VHDL_COMPILE_ARGS})
    endif()

    ##### GHDL Analyze
    if(NOT TARGET ${IP_LIB}_ghdl_complib)
        __ghdl_compile_lib(${IP_LIB}
            OUTDIR ${OUTDIR}
            STANDARD ${STANDARD}
            ${ARG_LIBRARY}
            ${ARG_VHDL_COMPILE_ARGS}
            ${ARG_FILE_SETS}
            )
    endif()
    set(__comp_tgt ${IP_LIB}_ghdl_complib)

    __get_ghdl_search_lib_args(${IP_LIB} 
        ${ARG_LIBRARY}
        OUTDIR ${OUTDIR})
    set(hdl_libs_args ${HDL_LIBS_ARGS})
    set(dpi_libs_args ${DPI_LIBS_ARGS})

    ##### GHDL Elaborate
    if(NOT TARGET ${IP_LIB}_ghdl)
        get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL ${ARG_FILE_SETS})
        set(__ghdl_elab_cmd ghdl elaborate
                --std=${STANDARD}
                -fsynopsys
                --workdir=${OUTDIR}/${LIBRARY}
                ${ARG_ELABORATE_ARGS}
                ${hdl_libs_args} ${dpi_libs_args}
                ${LIBRARY}.${ARG_TOP_MODULE}
                )

        ### Clean files
        #       * For elaborate "e~${ARG_EXECUTABLE_NAME}.o" and executable gets created
        # set(__clean_files "${OUTDIR}/e~${ARG_EXECUTABLE_NAME}.o")
        # set(__clean_files "${OUTDIR}/${LIBRARY}-obj${STANDARD}.cf")

        set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_ghdl.stamp")
        add_custom_command(
            OUTPUT ${STAMP_FILE}
            COMMAND ${__ghdl_elab_cmd}
            COMMAND touch ${STAMP_FILE}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${__comp_tgt} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
            )

        add_custom_target(${IP_LIB}_ghdl
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()


    set(__ghdl_run_cmd ghdl run
            --std=${STANDARD}
            -fsynopsys
            --workdir=${OUTDIR}/${LIBRARY}
            ${hdl_libs_args} ${dpi_libs_args}
            ${LIBRARY}.${ARG_TOP_MODULE}
            ${ARG_RUN_ARGS}
            )
    if(NOT ARG_NO_RUN_TARGET)
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run simulation on ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        add_custom_target(${ARG_RUN_TARGET_NAME}
            COMMAND ${__ghdl_run_cmd}
            COMMENT ${DESCRIPTION}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${IP_LIB}_ghdl
            )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__ghdl_run_cmd} PARENT_SCOPE)

endfunction()

function(__ghdl_compile_lib IP_LIB)
    cmake_parse_arguments(ARG "" "LIBRARY;OUTDIR;STANDARD" "VHDL_COMPILE_ARGS;FILE_SETS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_ghdl)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    # Find the GHDL tools/include directory, needed for VPI/VHPI libraries
    __add_ghdl_cxx_properties_to_libs(${IP_LIB})

    get_ip_links(__ips ${IP_LIB})
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
        file(MAKE_DIRECTORY ${lib_outdir})

        __get_ghdl_search_lib_args(${lib}
            OUTDIR ${OUTDIR})
        set(hdl_libs_args ${HDL_LIBS_ARGS})

        # VHDL files and arguments
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS ${ARG_FILE_SETS})
        set(ghdl_analyze_cmd ghdl analyze
                --std=${STANDARD}
                -fsynopsys
                --work=${__comp_lib_name}
                --workdir=${OUTDIR}/${__comp_lib_name}
                ${ARG_VHDL_COMPILE_ARGS}
                ${hdl_libs_args}
                ${VHDL_SOURCES}
                )


        # GHDL creates an object (.o) file for each VHDL source file
        # GHDL creates a .cf file for each VHDL library
        unset(obj_files)
        unset(cf_files)
        foreach(source ${VHDL_SOURCES})
            get_filename_component(source_basename ${source} NAME_WLE)
            list(APPEND obj_files "${lib_outdir}/${source_basename}.o")
        endforeach()
        list(APPEND cf_files "${lib_outdir}/${__comp_lib_name}-obj${STANDARD}.cf")

        # Modelsim/Questasim custom command of current IP block should depend on stamp files of immediate linked IPs
        # Extract the list from __ghdl_<LIB>_stamp_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__ghdl_subdep_stamp_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __ghdl_subdep_stamp_files ${__ghdl_${ip_dep}_stamp_files})
        endforeach()

        if(VHDL_SOURCES)
            set(DESCRIPTION "Compile VHDL for ${lib} with ghdl in library ${__comp_lib_name}")
            set(STAMP_FILE "${lib_outdir}/${lib}_ghdl_${CMAKE_CURRENT_FUNCTION}.stamp")
            add_custom_command(
                OUTPUT ${STAMP_FILE}
                COMMAND ${ghdl_analyze_cmd}
                COMMAND touch ${STAMP_FILE}
                WORKING_DIRECTORY ${OUTDIR}
                DEPENDS ${VHDL_SOURCES} ${__ghdl_subdep_stamp_files}
                COMMENT ${DESCRIPTION}
            )
            list(APPEND all_stamp_files ${STAMP_FILE})
            list(APPEND __ghdl_${lib}_stamp_files ${STAMP_FILE})
        endif()

    endforeach()

    if(NOT TARGET ${IP_LIB}_ghdl_complib)
        add_custom_target(
            ${IP_LIB}_ghdl_complib
            DEPENDS ${all_stamp_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl_complib PROPERTY DESCRIPTION 
            "Compile VHDL files for ${IP_LIB} with ghdl")
        set_property(TARGET ${IP_LIB}_ghdl_complib APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${cf_files} ${obj_files})
    endif()

endfunction()

function(__get_ghdl_search_lib_args IP_LIB)
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
            list(APPEND dpi_libs_args -Wl,$<TARGET_FILE:${lib}>)
            if(ip_type STREQUAL "SHARED_LIBRARY")
                message(WARNING "Shared library linked to simulation executable, set LD_LIBRARY_PATH")
            endif()
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

            set(lib_outdir ${ARG_OUTDIR}/${__comp_lib_name})
            # Append current library outdhdl_libs_argsir to list of search directories
            if(NOT "-P${lib_outdir}" IN_LIST hdl_libs_args)
                list(APPEND hdl_libs_args -P${lib_outdir})
            endif()
        endif()
    endforeach()

    set(HDL_LIBS_ARGS ${hdl_libs_args} PARENT_SCOPE)
    set(DPI_LIBS_ARGS ${dpi_libs_args} PARENT_SCOPE)
endfunction()

function(__add_ghdl_cxx_properties_to_libs IP_LIB)
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Find the GHDL tools/include directory, needed for VPI/DPI libraries
    find_program(ghdl_exec_path ghdl)
    get_filename_component(vpi_inc_path "${ghdl_exec_path}" DIRECTORY)
    cmake_path(SET vpi_inc_path NORMALIZE "${vpi_inc_path}/../include/ghdl")

    get_ip_links(ips ${IP_LIB})
    foreach(lib ${ips})
        # In case linked library is C/C++ shared/static object, dont try to compile it, just append its path to -sv_lib arg
        get_target_property(ip_type ${lib} TYPE)
        if(ip_type STREQUAL "SHARED_LIBRARY" OR ip_type STREQUAL "STATIC_LIBRARY")
            if(NOT ghdl_exec_path)
                message(FATAL_ERROR "GHDL executable xrun was not found, cannot set include directory on DPI library")
            endif()
            # Add tools/include directory to the include directories of DPI libraries
            # TODO do this only when its needed
            target_include_directories(${lib} PUBLIC ${vpi_inc_path})
            target_compile_definitions(${lib} PUBLIC GHDL)
        endif()
    endforeach()
endfunction()
