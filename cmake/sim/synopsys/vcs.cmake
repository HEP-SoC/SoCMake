include_guard(GLOBAL)

function(vcs_vlogan IP_LIB)
    cmake_parse_arguments(ARG "" "TOP_MODULE;OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    get_ip_include_directories(INC_DIRS ${IP_LIB})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -incdir ${dir})
    endforeach()

    get_ip_compile_definitions(COMP_DEFS ${IP_LIB})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    if(ARG_TOP_MODULE)
        set(ARG_TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(NOT ARG_OUTDIR)
        set(OUTDIR "${BINARY_DIR}/${IP_LIB}_vcs")
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    set(CMAKE_FIND_DEBUG_MODE TRUE)
    find_program(VLOGAN_EXECUTABLE vlogan REQUIRED
        HINTS ${VCS_HOME} $ENV{VCS_HOME}
        )
    set(CMAKE_FIND_DEBUG_MODE FALSE)

    set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        WORKING_DIRECTORY ${OUTDIR}
        COMMAND ${VLOGAN_EXECUTABLE} 
            -full64 -nc -sverilog
            -sc_model ${ARG_TOP_MODULE}
            ${SOURCES}
            ${COMP_DEFS}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${STAMP_FILE}
        )

    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})
endfunction()

# syscan -full64 -sysc=scv20 sc_main.cpp

function(vcs EXEC)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    get_target_property(BINARY_DIR ${EXEC} BINARY_DIR)

    safe_get_target_property(INTERFACE_SOURCES ${EXEC} INTERFACE_SOURCES "")
    safe_get_target_property(SOURCES ${EXEC} SOURCES "")
    list(APPEND SOURCES ${INTERFACE_SOURCES})
    message("SOURCES: ${SOURCES}")

    if(NOT ARG_OUTDIR)
        set(OUTDIR "${BINARY_DIR}/${EXEC}_vcs")
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    set(CMAKE_FIND_DEBUG_MODE TRUE)
    find_program(_SYSCAN_EXECUTABLE syscan REQUIRED
        HINTS ${VCS_HOME} $ENV{VCS_HOME}
        )
    set(CMAKE_FIND_DEBUG_MODE FALSE)

    set(STAMP_FILE "${OUTDIR}/${EXEC}_syscan.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE}
        WORKING_DIRECTORY ${OUTDIR}
        COMMAND ${_SYSCAN_EXECUTABLE} 
            -full64 -sysc=scv20
            ${SOURCES}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${EXEC}"
        )

    add_custom_target(
        ${EXEC}_syscan
        DEPENDS ${STAMP_FILE}
        )

    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})

# vcs -V -full64 -nc -j16 -sverilog -sysc=scv20 sc_main -timescale=1ns/1ps

    set(CMAKE_FIND_DEBUG_MODE TRUE)
    find_program(_VCS_EXECUTABLE vcs REQUIRED
        HINTS ${VCS_HOME} $ENV{VCS_HOME}
        )
    set(CMAKE_FIND_DEBUG_MODE FALSE)

    set(STAMP_FILE "${OUTDIR}/${EXEC}_vcs.stamp")
    add_custom_command(
        OUTPUT ${STAMP_FILE} ${PROJECT_BINARY_DIR}/${EXEC}
        WORKING_DIRECTORY ${OUTDIR}
        COMMAND ${_VCS_EXECUTABLE} 
            -full64 -nc -sysc=scv20
            sc_main
            -timescale=1ns/1ps

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${EXEC}_syscan
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${EXEC}"
        )

    add_custom_target(
        ${EXEC}_vcs
        DEPENDS ${STAMP_FILE}
        )

    # add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})
endfunction()
