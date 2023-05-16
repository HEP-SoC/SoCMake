function(doxygen RTLLIB)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/doxygen)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    find_package(Doxygen REQUIRED)

    get_rtl_target_incdirs(INCLUDE_DIRS ${RTLLIB})
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

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    add_custom_target( ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${OUTDIR}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        VERBATIM )

endfunction()

