function(doxygen IP_LIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/doxygen)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    find_package(Doxygen REQUIRED)

    get_ip_include_directories(INCLUDE_DIRS ${IP_LIB})
    foreach(dir ${INCLUDE_DIRS})
        set(regex_pattern "^\\$<BUILD_INTERFACE:(.+)>")
        string(REGEX MATCH "${regex_pattern}" extracted_path ${dir})

        if(CMAKE_MATCH_1)
            message("${dir} ${CMAKE_MATCH_1}")
            list(APPEND INCDIRS ${CMAKE_MATCH_1})
        else()
            # list(APPEND INCDIRS ${dir})
        endif()
    endforeach()
    string(REPLACE ";" "," INCDIRS "${INCDIRS}")


    set(DOXYGEN_IN ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Doxyfile.in)
    set(DOXYGEN_OUT ${OUTDIR}/Doxyfile)
    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    add_custom_target( ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${OUTDIR}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        VERBATIM )

endfunction()

