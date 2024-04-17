function(peakrdl_regblock_wrap IP_LIB)
    # Parse keyword arguments
    cmake_parse_arguments(ARG "SV2V" "OUTDIR;RENAME;INTF" "" ${ARGN})
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
    set(__CMD ${Python3_EXECUTABLE} -m peakrdl regblock_wrap
            # --rename ${IP_NAME}
            # ${INTF_ARG}
            -o ${OUTDIR}
            ${RDL_SOURCES}
        )

    set(SV_GEN
        ${OUTDIR}/${IP_NAME}_regblock_pkg.sv
        ${OUTDIR}/${IP_NAME}_regblock.sv
        ${OUTDIR}/${IP_NAME}.sv
        )

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        # The output files are automtically marked as GENERATED (deleted by make clean among other things)
        OUTPUT ${SV_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    # This target triggers the systemverilog register block generation using peakRDL regblock tool (_CMD)
    set(WRAP_TNAME ${IP_LIB}_regblock_wrap)
    add_custom_target(
        ${WRAP_TNAME}
        DEPENDS ${SV_GEN} ${STAMP_FILE}
    )

    # Add command to convert to simple Verilog
    if(ARG_SV2V)
        set(V_GEN ${OUTDIR}/${IP_NAME}.v)
        set_source_files_properties(${V_GEN} PROPERTIES GENERATED TRUE)

        add_custom_command(
            OUTPUT ${STAMP_FILE} ${V_GEN}
            COMMAND  sv2v ${SV_GEN} -w ${V_GEN}

            COMMAND touch ${STAMP_FILE}
            DEPENDS ${SV_GEN}
            COMMENT "Running sv2v for regblock_wrap on ${IP_LIB}"
        )

        set(SV2V_TNAME ${IP_LIB}_regblock_wrap_sv2v)
        add_custom_target(
            ${SV2V_TNAME}
            DEPENDS ${V_GEN} ${STAMP_FILE}
        )

        ip_sources(${IP_LIB} VERILOG PREPEND ${V_GEN})
        add_dependencies(${IP_LIB} ${SV2V_TNAME})
    else()
        ip_sources(${IP_LIB} SYSTEMVERILOG PREPEND ${SV_GEN})
        add_dependencies(${IP_LIB} ${WRAP_TNAME})
    endif()
endfunction()

