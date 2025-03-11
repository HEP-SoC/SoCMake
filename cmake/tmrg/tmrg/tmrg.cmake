include_guard(GLOBAL)

function(set_tmrg_sources IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    # Get any prior TMRG sources (only of the IP, not the deps)
    get_tmrg_sources(_tmrg_src ${_reallib} NO_DEPS)

    set(_tmrg_src ${_tmrg_src} ${ARGN})
    # Set the target property with the new list of source files
    set_property(TARGET ${_reallib} PROPERTY TMRG_SOURCES ${_tmrg_src})
endfunction()

function(get_tmrg_sources OUT_VAR IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "" "" ${ARGN})
    set(_no_deps)
    if(ARG_NO_DEPS)
        set(_no_deps "NO_DEPS")
    endif()

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    get_ip_property(_tmrg_src ${_reallib} TMRG_SOURCES ${_no_deps})

    list(REMOVE_DUPLICATES _tmrg_src)
    set(${OUT_VAR} ${_tmrg_src} PARENT_SCOPE)
endfunction()

function(tmrg IP_LIB)
    cmake_parse_arguments(ARG "REPLACE;SED_WOR;NO_COMMON_DEFINITIONS;SDC" "OUTDIR;CONFIG_FILE;TOP_MODULE" "" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    find_python3()
    find_program(TMRG_EXECUTABLE tmrg REQUIRED)

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/tmrg)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR})

    if(ARG_CONFIG_FILE)
        set(ARG_CONFIG_FILE -c ${ARG_CONFIG_FILE})
    else()
        unset(ARG_CONFIG_FILE)
    endif()

    # Get only the IP TMRG sources only (not the dependencies)
    get_tmrg_sources(IP_TMRG_SRC ${IP_LIB} NO_DEPS)
    list(REMOVE_DUPLICATES IP_TMRG_SRC)

    # We also get the non-triplicated sources
    # For example, primitive cells are not all triplicated
    # and instantiating them 3 times is fine

    # Get all the IP sources (ip+dependencies)
    get_ip_rtl_sources(IP_SRC_ALL ${IP_LIB})

    # Only the IP sources (not the dependencies) are triplicated
    # The dependency sources are passed as libraries and it's up
    # to the dependencies to provide triplicated (or not triplicated)
    # module definitions.
    set(SRC_DEPS)
    # Find the deps sources only
    foreach(file ${IP_SRC_ALL})
        list(FIND IP_TMRG_SRC ${file} index)
        if(index EQUAL -1)
            # If the file is not in IP_TMRG_SRC, had it to SRC_DEPS
            list(APPEND SRC_DEPS ${file})
        endif()
    endforeach()

    # Files passed as lib are stripped of their content to avoid
    # missing module definition. For example, if one lib file instantiate
    # a triplicated module of another lib file this creates an undefined module
    # error by tmrg because tmrg tracks the non-triplicated module names.
    set(LIB_STRIP_DIR ${OUTDIR}/lib_strip)
    set(LIB_STRIP_CMD
        ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/lib_module_strip.py --files ${SRC_DEPS} --outdir ${LIB_STRIP_DIR}
    )

    set(SRC_DEPS_STRIPPED)
    foreach(file ${SRC_DEPS})
        get_filename_component(BASE_NAME ${file} NAME)
        set(NEW_FILE_PATH "${LIB_STRIP_DIR}/${BASE_NAME}")
        list(APPEND SRC_DEPS_STRIPPED ${NEW_FILE_PATH})
    endforeach()


    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_lib_strip.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${SRC_DEPS_STRIPPED}
        COMMAND ${LIB_STRIP_CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SRC_DEPS}
        COMMENT "Running module stripping on deps files of ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_lib_strip
        DEPENDS ${STAMP_FILE} ${SRC_DEPS_STRIPPED}
    )

    foreach(vfile ${IP_TMRG_SRC})
        get_filename_component(V_SOURCE_WO_EXT ${vfile} NAME_WE)
        get_filename_component(V_SOURCE_EXT ${vfile} EXT)
        list(APPEND TRMG_GEN "${OUTDIR}/${V_SOURCE_WO_EXT}TMR${V_SOURCE_EXT}")
    endforeach()

    set(TMRG_COMMAND
        ${TMRG_EXECUTABLE} --stats --tmr-dir=${OUTDIR} ${ARG_CONFIG_FILE} ${IP_TMRG_SRC}
    )

    # Add the dependencies as libraries if they exist
    # If a triplicated version of a module exists, it will be used
    # This is enforced by providing the triplicated sources after
    # the not triplicated ones when linking the IPs

    # SRC_DEPS contains non-triplicated and triplicated sources as
    # long as the deps use tmrg with the REPLACE argument.
    # Each dep source is passed as libraries
    if(SRC_DEPS_STRIPPED)
        set(SRC_LIBS)
        # Each file needs to be passed with the '-l' option
        foreach(file ${SRC_DEPS_STRIPPED})
            list(APPEND SRC_LIBS -l ${file})
        endforeach()
        set(TMRG_COMMAND ${TMRG_COMMAND} ${SRC_LIBS})
    endif()

    # Specify the top module if provided
    if(ARG_TOP_MODULE)
        set(SDC_FILE_TOP ${OUTDIR}/${ARG_TOP_MODULE}TMR.sdc)
        set(TMRG_COMMAND ${TMRG_COMMAND} --top-module ${ARG_TOP_MODULE})
    endif()

    if(ARG_SDC)
        set(SDC_FILE ${OUTDIR}/${IP_LIB}_tmrg.sdc)
        set(TMRG_COMMAND ${TMRG_COMMAND} --sdc-generate --sdc-file-name=${SDC_FILE})
    endif()

    if(ARG_NO_COMMON_DEFINITIONS)
        set(TMRG_COMMAND ${TMRG_COMMAND} --no-common-definitions)
    endif()

    if(NOT ARG_HEADER)
        set(TMRG_COMMAND ${TMRG_COMMAND} --no-header)
    endif()

    # To avoid replacing unwanted 'wor' character sequence, assume real wor (i.e., wired-or)
    # sequence is always followed by a space. Otherwise, if 'wor' is used in a name (e.g., word_address)
    # it will also be replaced (e.g., to wird_address).
    if(ARG_SED_WOR)
        set(SED_COMMAND COMMAND sed -i "s/wor /wire /g" ${TRMG_GEN})
    endif()

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${TRMG_GEN} ${STAMP_FILE}
        COMMAND ${TMRG_COMMAND}
        COMMAND /bin/sh -c date > ${STAMP_FILE}
        DEPENDS ${IP_TMRG_SRC} ${SRC_DEPS_STRIPPED}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE} ${TRMG_GEN}
    )

    if(ARG_REPLACE)
        # Get original sources
        get_ip_sources(SV_SRC ${IP_LIB} SYSTEMVERILOG)
        get_ip_sources(V_SRC ${IP_LIB} VERILOG)

        # Remove TMRG files from original sources
        list(REMOVE_ITEM SV_SRC ${IP_TMRG_SRC})
        list(REMOVE_ITEM V_SRC ${IP_TMRG_SRC})

        # Append generated files to correct source lists
        foreach(i ${TRMG_GEN})
            get_filename_component(FILE_EXT ${i} EXT)
            if("${FILE_EXT}" STREQUAL ".sv")
                list(APPEND SV_SRC ${i})
            elseif("${FILE_EXT}" STREQUAL ".v")
                list(APPEND V_SRC ${i})
            endif()
        endforeach()

        # Set the file list properties (overwrite the existing property)
        set_property(TARGET ${IP_LIB} PROPERTY SYSTEMVERILOG_SOURCES ${SV_SRC})
        set_property(TARGET ${IP_LIB} PROPERTY VERILOG_SOURCES ${V_SRC})

    # else()
    #     # Append the triplicated source to the existing ones?

    endif()

    # Add dependency to the IP
    add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

    # Get recursively linked libraries to link to any <>_tmrg target
    # If no recusrive search is done, the dependency is broken as soon as one level
    # does not have any tmrg target
    recursive_get_target_property(LINKED_IP ${IP_LIB} INTERFACE_LINK_LIBRARIES "")
    # Trigger the dependencies tmrg targets if they exist
    message(DEBUG "TMRG: checking linked libraries for IP ${IP_LIB}")
    foreach(linked_lib ${LINKED_IP})
        alias_dereference(linked_lib ${linked_lib})
        # Check if a tmrg target exists
        message(DEBUG "    Found linked library ${linked_lib}")
        if(TARGET ${linked_lib}_${CMAKE_CURRENT_FUNCTION})
            add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${linked_lib}_${CMAKE_CURRENT_FUNCTION})
            message(DEBUG "    └─> Found tmrg target ${linked_lib}_${CMAKE_CURRENT_FUNCTION}")
        endif()
    endforeach()

    # Add additional clean files to project
    set_property(
        TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        APPEND
        PROPERTY ADDITIONAL_CLEAN_FILES
        ${SDC_FILE}
        ${SDC_FILE_TOP}
    )

endfunction()

