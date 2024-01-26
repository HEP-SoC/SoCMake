include_guard(GLOBAL)

function(ghdl IP_LIB)
    cmake_parse_arguments(ARG "" "OUTDIR;TOP_MODULE;EXECUTABLE;STANDARD" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/ghdl)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    set(SUPPORTED_VHDL_STANDARDS  87 93c 93 00 02 08)
    if(ARG_STANDARD)
        if(${ARG_STANDARD} IN_LIST SUPPORTED_VHDL_STANDARDS)
        else()
            message(FATAL_ERROR "VHDL standard not supported ${ARG_STANDARD}, supported standards: ${ARG_STANDARD}")
        endif()
        set(ARG_STANDARD --std=${ARG_STANDARD})
    else()
        set(ARG_STANDARD --std=93)
    endif()

    if(NOT ARG_EXECUTABLE)
        set(ARG_EXECUTABLE "${OUTDIR}/${IP_LIB}_ghdl_tb")
    endif()
    get_filename_component(ARG_EXECUTABLE ${ARG_EXECUTABLE} ABSOLUTE)

    get_ip_sources(VHDL_SOURCES ${IP_LIB} VHDL)
    list(PREPEND SOURCES ${VHDL_SOURCES})

    get_ip_include_directories(VHDL_INCLUDE_DIRS ${IP_LIB} VHDL)
    set(INC_DIRS ${VHDL_INCLUDE_DIRS})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -P${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    find_program(GHDL_EXECUTABLE ghdl
        HINTS ${GHDL_HOME}/bin/ $ENV{GHDL_HOME}/bin/
        PATHS ${GHDL_EXECUTABLE} $ENV{GHDL_EXECUTABLE}
        )

    get_target_property(IPS ${IP_LIB} FLAT_GRAPH)

    unset(_ghdl_analyze_commands)
    foreach(_ip ${IPS})
        get_target_property(_lib ${_ip} LIBRARY)
        get_target_property(_lib_sources ${_ip} VHDL_SOURCES)

        list(APPEND _ghdl_analyze_commands 
            COMMAND ${GHDL_EXECUTABLE} analyze
            --work=${_lib}
            --workdir=${OUTDIR}
            ${ARG_STANDARD}
            -P${OUTDIR}
            ${_lib_sources}
            )
    endforeach()
    get_target_property(WORK_LIB ${IP_LIB} LIBRARY)

    # TODO split custom_command into analysis commands per IP block, so only analysis of a IP block is done for the files changed of the given IP block, this should speed up for big designs
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${ARG_EXECUTABLE} ${STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
        ${_ghdl_analyze_commands}
        COMMAND ${GHDL_EXECUTABLE} elaborate 
            -P${OUTDIR}
            -o ${ARG_EXECUTABLE}
            --work=${WORK_LIB}
            --workdir=${OUTDIR}
            ${ARG_STANDARD}
            ${ARG_TOP_MODULE}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${ARG_EXECUTABLE} ${IP_LIB} ${STAMP_FILE}
        )

    get_filename_component(EXEC_FN ${ARG_EXECUTABLE} NAME)
    get_filename_component(EXEC_DIR ${ARG_EXECUTABLE} DIRECTORY)

    set_property(
        TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        APPEND PROPERTY ADDITIONAL_CLEAN_FILES 
            ${OUTDIR}
            ${ARG_EXECUTABLE}
            ${EXEC_DIR}/e~${EXEC_FN}.o
        )

    # add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()
