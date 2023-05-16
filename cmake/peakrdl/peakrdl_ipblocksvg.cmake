function(peakrdl_ipblocksvg RTLLIB)
    cmake_parse_arguments(ARG "TRAVERSE" "OUTDIR;LOGO" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../rtllib.cmake")

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/ipblocksvg)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_LOGO)
        set(ARG_LOGO --logo ${ARG_LOGO})
    endif()

    if(ARG_TRAVERSE)
        set(ARG_TRAVERSE --traverse)
    endif()

    get_rtl_target_property(RDL_FILES ${RTLLIB} RDL_FILES)

    if(RDL_FILES STREQUAL "RDL_FILES-NOTFOUND")
        message(FATAL_ERROR "Library ${RTLLIB} does not have RDL_FILES property set, unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    execute_process(
        OUTPUT_VARIABLE GRAPHIC_FILES
        ERROR_VARIABLE IPLBOCKSVG_ERROR
        COMMAND python3 -m peakrdl ipblocksvg 
            ${RDL_FILES}
            ${ARG_LOGO}
            ${ARG_TRAVERSE}
            --list-files
            -o ${OUTDIR}
        )
    if(GRAPHIC_FILES)
        string(REPLACE " " ";" GRAPHIC_FILES "${GRAPHIC_FILES}")
        string(REPLACE "\n" "" GRAPHIC_FILES "${GRAPHIC_FILES}")
        list(REMOVE_DUPLICATES GRAPHIC_FILES)
    else()
        message(FATAL_ERROR "Error no files generated from ${CMAKE_CURRENT_FUNCTION} for ${RTLLIB}, output of --list-files option: ${GRAPHIC_FILES} error output: ${IPLBOCKSVG_ERROR}")
    endif()

    set_source_files_properties(${GRAPHIC_FILES} PROPERTIES GENERATED TRUE)
    set_property(TARGET ${RTLLIB} APPEND PROPERTY GRAPHIC_FILES ${GRAPHIC_FILES})

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${GRAPHIC_FILES} ${STAMP_FILE}
        COMMAND python3 -m peakrdl ipblocksvg 
            ${RDL_FILES}
            ${ARG_LOGO}
            ${ARG_TRAVERSE}
            -o ${OUTDIR}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_FILES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${GRAPHIC_FILES} ${STAMP_FILE}
        )

    # set_property(TARGET ${RTLLIB} APPEND PROPERTY DEPENDS ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})
    add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION} )
endfunction()

