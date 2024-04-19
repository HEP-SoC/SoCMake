function(peakrdl_regblock_wrap IP_LIB)
    # Parse keyword arguments
    cmake_parse_arguments(ARG "TMR" "OUTDIR;RENAME;INTF" "" ${ARGN})
    # Check for any unknown argument
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Default output directory is regblock/
    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/regblock)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(NOT ARG_RENAME)
        # The default name is the IP name
        get_target_property(IP_NAME ${IP_LIB} IP_NAME)
    else()
        set(IP_NAME ${ARG_RENAME})
    endif()

    # The default interface used is apb3, set another on if the argument exists
    if(ARG_INTF)
        set(INTF_ARG --cpuif ${ARG_INTF})
    endif()
    # Get the SystemRDL sources to generate the register block
    # This function gets the IP sources and the deps
    get_ip_sources(RDL_SOURCES ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_SOURCES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have SYSTEMRDL_SOURCES property set,
                unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    # Generate the regblock and wrapper
    find_python3()
    if(ARG_TMR)
        set(TMR_OPT "--tmr")
    endif()
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock_wrap
            ${TMR_OPT}
            # --rename ${IP_NAME}
            # ${INTF_ARG}
            -o ${OUTDIR}
            ${RDL_SOURCES}
        )

    set(REGBLOCK_SV_GEN ${OUTDIR}/${IP_NAME}_regblock_pkg.sv ${OUTDIR}/${IP_NAME}_regblock.sv)
    set(WRAP_SV_GEN ${OUTDIR}/${IP_NAME}.sv)
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    add_custom_command(
        # The output files are automtically marked as GENERATED (deleted by make clean among other things)
        OUTPUT ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    # This target triggers the systemverilog register block generation using peakRDL regblock tool (_CMD)
    set(TNAME ${IP_LIB}_regblock_wrap)
    add_custom_target(
        ${TNAME}
        DEPENDS ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN} ${STAMP_FILE}
    )
    ip_sources(${IP_LIB} SYSTEMVERILOG PREPEND ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN})

    if(ARG_TMR)
        set_tmrg_sources(${IP_LIB} ${REGBLOCK_SV_GEN})
        set_sv2v_sources(${IP_LIB} ${REGBLOCK_SV_GEN})
    else()
        add_dependencies(${IP_LIB} ${TNAME})
    endif()
endfunction()

