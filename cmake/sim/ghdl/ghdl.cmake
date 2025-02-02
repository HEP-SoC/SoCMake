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
    cmake_parse_arguments(ARG "NO_RUN_TARGET;" "OUTDIR;TOP_MODULE;EXECUTABLE_NAME;STANDARD" "ANALYZE_ARGS;ELABORATE_ARGS;RUN_ARGS" ${ARGN})
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

    get_target_property(LIBRARY ${IP_LIB} LIBRARY)
    if(NOT LIBRARY)
        set(LIBRARY work)
    endif()

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    if(ARG_ANALYZE_ARGS)
        set(ARG_ANALYZE_ARGS ANALYZE_ARGS ${ARG_ANALYZE_ARGS})
    endif()

    if(NOT ARG_EXECUTABLE_NAME)
        set(ARG_EXECUTABLE_NAME "${IP_LIB}_ghdl_exec")
    endif()
    set(SIM_EXEC_PATH "${OUTDIR}/${ARG_EXECUTABLE_NAME}")

    ##### GHDL Analyze
    __ghdl_compile_lib(${IP_LIB}
        OUTDIR ${OUTDIR}
        STANDARD ${STANDARD}
        ${ARG_ANALYZE_ARGS}
        )
    set(__comp_tgt ${IP_LIB}_ghdl_complib)

    ##### GHDL Elaborate
    if(NOT TARGET ${IP_LIB}_ghdl)
        get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL)
        set(__ghdl_elab_cmd ghdl elaborate
                --std=${STANDARD}
                -fsynopsys
                -o ${SIM_EXEC_PATH}
                --workdir=${OUTDIR}/${LIBRARY}
                ${ARG_ELABORATE_ARGS}
                ${LIB_SEARCH_DIRS}
                ${LIBRARY}.${ARG_TOP_MODULE}
                )

        ### Clean files
        #       * For elaborate "e~${ARG_EXECUTABLE_NAME}.o" and executable gets created
        set(__clean_files "${OUTDIR}/e~${ARG_EXECUTABLE_NAME}.o")

        set(DESCRIPTION "Compile testbench ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_ghdl.stamp")
        add_custom_command(
            OUTPUT ${SIM_EXEC_PATH} ${STAMP_FILE}
            COMMAND ${__ghdl_elab_cmd}
            COMMAND touch ${STAMP_FILE}
            BYPRODUCTS  ${__clean_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${__comp_tgt} ${VHDL_SOURCES}
            COMMENT ${DESCRIPTION}
            )

        add_custom_target(${IP_LIB}_ghdl
            DEPENDS ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(__ghdl_run_cmd ${SIM_EXEC_PATH} ${ARG_RUN_ARGS})
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
    cmake_parse_arguments(ARG "" "LIBRARY;OUTDIR;STANDARD" "ANALYZE_ARGS" ${ARGN})
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

    __ghdl_get_standard_arg(STANDARD ${ARG_STANDARD})

    get_ip_links(__ips ${IP_LIB})
    unset(lib_search_dirs)
    unset(all_obj_files)
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

        # VHDL files and arguments
        get_ip_sources(VHDL_SOURCES ${lib} VHDL NO_DEPS)
        set(__ghdl_analyze_cmd ghdl analyze
                --std=${STANDARD}
                -fsynopsys
                --work=${__comp_lib_name}
                --workdir=${OUTDIR}/${__comp_lib_name}
                ${ARG_ANALYZE_ARGS}
                ${lib_search_dirs} # This is not correct, as it should include only SUBIPs search directories TODO
                ${VHDL_SOURCES}
                )


        # Create output directoy for the VHDL library
        set(lib_outdir ${OUTDIR}/${__comp_lib_name})
        file(MAKE_DIRECTORY ${lib_outdir})

        # Append current library outdir to list of search directories
        list(APPEND lib_search_dirs -P${lib_outdir})

        # GHDL creates an object (.o) file for each VHDL source file
        # GHDL creates a .cf file for each VHDL library
        unset(obj_files)
        unset(cf_files)
        foreach(source ${VHDL_SOURCES})
            get_filename_component(source_basename ${source} NAME_WLE)
            list(APPEND obj_files "${lib_outdir}/${source_basename}.o")
        endforeach()
        list(APPEND cf_files "${lib_outdir}/${__comp_lib_name}-obj${STANDARD}.cf")

        # Create a list that stores current IP block obj files
        # This list persists when compiling higher level IP blocks, to be used as DEPENDS files
        set(__ghdl_${lib}_obj_files ${obj_files})

        # GHDL Custom command of current IP block should depend on object files of immediate linked IPs
        # Extract the list from __ghdl_<LIB>_obj_files
        get_ip_links(ip_subdeps ${lib} NO_DEPS)
        unset(__ghdl_subdep_obj_files)
        foreach(ip_dep ${ip_subdeps})
            list(APPEND __ghdl_subdep_obj_files ${__ghdl_${ip_dep}_obj_files})
        endforeach()

        set(DESCRIPTION "Compile VHDL for ${lib} with ghdl in library ${__comp_lib_name}")
        set(STAMP_FILE "${BINARY_DIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(
            OUTPUT ${obj_files}
            COMMAND ${__ghdl_analyze_cmd}
            BYPRODUCTS ${cf_files}
            WORKING_DIRECTORY ${OUTDIR}
            DEPENDS ${VHDL_SOURCES} ${__ghdl_subdep_obj_files}
            COMMENT ${DESCRIPTION}
        )

        list(APPEND all_obj_files ${obj_files})
    endforeach()

    if(NOT TARGET ${IP_LIB}_ghdl_complib)
        add_custom_target(
            ${IP_LIB}_ghdl_complib
            DEPENDS ${all_obj_files} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_ghdl_complib PROPERTY DESCRIPTION 
            "Compile VHDL files for ${IP_LIB} with ghdl")
    endif()
    set(LIB_SEARCH_DIRS ${lib_search_dirs} PARENT_SCOPE)

endfunction()

## Parallel analysis
        # unset(obj_files)
        # set(cf_file "${lib_outdir}/${__comp_lib_name}-obj${STANDARD}.cf")
        # foreach(source ${VHDL_SOURCES})
        #     get_filename_component(source_basename ${source} NAME_WLE)
        #     set(obj_file "${lib_outdir}/${source_basename}.o")
        #     message("source: ${obj_file}")
        #
        #     set(__ghdl_analyze_cmd ghdl analyze
        #             --std=${STANDARD}
        #             -fsynopsys
        #             --work=${__comp_lib_name}
        #             --workdir=${OUTDIR}/${__comp_lib_name}
        #             ${ARG_ANALYZE_ARGS}
        #             ${lib_search_dirs}
        #             ${source}
        #             )
        #
        #     set(DESCRIPTION "Compile ${source} with ghdl in library ${__comp_lib_name}")
        #     # set(STAMP_FILE "${BINARY_DIR}/${lib}_${CMAKE_CURRENT_FUNCTION}.stamp")
        #     add_custom_command(
        #         OUTPUT ${obj_file}
        #         COMMAND ${__ghdl_analyze_cmd}
        #         BYPRODUCTS ${cf_file}
        #         WORKING_DIRECTORY ${OUTDIR}
        #         DEPENDS ${all_obj_files}
        #         COMMENT ${DESCRIPTION}
        #     )
        #
        #     list(APPEND all_obj_files ${obj_file})
        # endforeach()
