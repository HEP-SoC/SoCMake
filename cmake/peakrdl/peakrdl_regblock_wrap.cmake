function(peakrdl_regblock_wrap IP_LIB)
    # Parse keyword arguments
    cmake_parse_arguments(ARG "TMR" "OUTDIR;RENAME;INTF;RESET" "" ${ARGN})
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
        if(NOT ARG_TMR)
            set(OUTDIR ${BINARY_DIR}/regblock)
        else()
            set(OUTDIR ${BINARY_DIR}/regblock_tmr)
        endif()
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

    # The default reset is active-high and synchronous
    if(ARG_RESET)
        set(RESET_ARG --default-reset ${ARG_RESET})
    endif()

    # Activate the triplication if TMR option is passed
    if(ARG_TMR)
        set(TMR_OPT "--tmr")
    endif()

    if(NOT ARG_RENAME)
        # The default name is the IP name
        get_target_property(REGBLOCK_NAME ${IP_LIB} IP_NAME)
        if(NOT REGBLOCK_NAME)
            message(FATAL_ERROR "IP_NAME not set for ${IP_LIB}, check if the IP was added with
                    add_ip function from SoCMake")
        endif()
        set(REGBLOCK_NAME ${REGBLOCK_NAME}_regblock)
    else()
        set(REGBLOCK_NAME ${ARG_RENAME})
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

    # Create the reblog_wrap python command
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock_wrap
            --rename ${REGBLOCK_NAME}
            ${INTF_ARG}
            ${RESET_ARG}
            ${TMR_OPT}
            -o ${OUTDIR}
            ${RDL_SOURCES}
        )

    set(REGBLOCK_SV_GEN ${OUTDIR}/${IP_NAME}_pkg.sv ${OUTDIR}/${IP_NAME}.sv)
    set(WRAP_SV_GEN ${OUTDIR}/${IP_NAME}.sv)
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    # Regblock generated files (pkg + logic)
    set(REGBLOCK_SV_GEN
        ${OUTDIR}/${REGBLOCK_NAME}_pkg.sv
        ${OUTDIR}/${REGBLOCK_NAME}.sv
    )
    # Top module wraper file generate
    set(WRAP_SV_GEN ${OUTDIR}/${IP_NAME}.sv)

    # Add the custom command to call the peakrdl regblock_wrap plugin
    add_custom_command(
        # The output files are automtically marked as GENERATED (deleted by make clean among other things)
        OUTPUT ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    # This target triggers the custom command generating the top wrapper and the register file block
    set(TNAME ${IP_LIB}_regblock_wrap)
    add_custom_target(
        ${TNAME}
        DEPENDS ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN} ${STAMP_FILE}
    )

    # Add the generated sources to the IP sources
    ip_sources(${IP_LIB} SYSTEMVERILOG PREPEND ${REGBLOCK_SV_GEN} ${WRAP_SV_GEN})

    if(ARG_TMR)
        set_tmrg_sources(${IP_LIB} ${REGBLOCK_SV_GEN})
        set_sv2v_sources(${IP_LIB} ${REGBLOCK_SV_GEN})
    else()
        add_dependencies(${IP_LIB} ${TNAME})
    endif()
endfunction()

