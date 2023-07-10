function(iverilog RTLLIB)
    cmake_parse_arguments(ARG "" "OUTDIR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    get_rtl_target_sources(V_FILES ${RTLLIB})
    get_rtl_target_incdirs(INC_DIRS ${RTLLIB})

    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -I ${dir})
    endforeach()
    set(EXEC "${OUTDIR}/${RTLLIB}_iv")

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${EXEC} ${STAMP_FILE}
        COMMAND iverilog
        ${V_FILES}
        ${ARG_INCDIRS}
        -o ${EXEC}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES}
        COMMENT "Running iverilog on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${EXEC} ${STAMP_FILE} ${RTLLIB}
        )

    add_custom_target(
        run_${RTLLIB}_iv
        COMMAND exec ${EXEC}
        BYPRODUCTS "${OUTDIR}/test1.vcd"
        DEPENDS ${EXEC} ${STAMP_FILE} ${V_FILES} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION}
        )

    # add_dependencies(${RTLLIB} ${RTLLIB}_${CMAKE_CURRENT_FUNCTION})

endfunction()

