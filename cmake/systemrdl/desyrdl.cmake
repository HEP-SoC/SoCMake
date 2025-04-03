function(desyrdl IP_LIB)
    # Parse keyword arguments
    cmake_parse_arguments(ARG "" "OUTDIR;INTF;TOP_ADDRMAP" "ARGS" ${ARGN})
    # Check for any unknown argument
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/find_python.cmake")

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)
    get_target_property(ip_name ${IP_LIB} IP_NAME)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    if(ARG_TOP_ADDRMAP)
        set(ip_name ${ARG_TOP_ADDRMAP})
    endif()

    if(NOT ARG_INTF)
        set(ARG_INTF "ibus")
    endif()
    set(supported_intfs "axi4l;ibus")
    if(NOT ARG_INTF IN_LIST supported_intfs)
        message(FATAL_ERROR "Interface not supported: ${ARG_INTF}, supported interfaces are ${supported_intfs}")
    endif()


    # Get the SystemRDL sources to generate the register block
    # This function gets the IP sources and the deps
    get_ip_sources(RDL_SOURCES ${IP_LIB} SYSTEMRDL)

    if(NOT RDL_SOURCES)
        message(FATAL_ERROR "Library ${IP_LIB} does not have SYSTEMRDL_SOURCES property set,
                unable to run ${CMAKE_CURRENT_FUNCTION}")
    endif()

    find_python3()
    set(__CMD ${Python3_EXECUTABLE} -m desyrdl
            -o ${OUTDIR}
            -f vhdl
            -i ${RDL_SOURCES}
            ${ARG_ARGS}
        )

    set(VHDL_GEN
        ${OUTDIR}/vhdl/${ip_name}/pkg_${ip_name}.vhd
        ${OUTDIR}/vhdl/${ip_name}/${ip_name}_decoder_${ARG_INTF}.vhd
        ${OUTDIR}/vhdl/${ip_name}/${ip_name}.vhd
        )
    # Prepend the generated files to the IP sources
    ip_sources(${IP_LIB} VHDL PREPEND ${VHDL_GEN})

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    set(DESCRIPTION "Generate register file for \"${IP_LIB}\" with ${CMAKE_CURRENT_FUNCTION}")
    add_custom_command(
        # The output files are automtically marked as GENERATED (deleted by make clean among other things)
        OUTPUT ${VHDL_GEN} ${STAMP_FILE}
        COMMAND ${__CMD}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${RDL_SOURCES}
        COMMENT ${DESCRIPTION}
        COMMAND_EXPAND_LISTS
    )
    # This target triggers the systemverilog register block generation using peakRDL regblock tool (_CMD)
    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${VHDL_GEN} ${STAMP_FILE}
    )
    set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
    add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})

    add_ip(common
        LIBRARY desyrdl)

    ip_sources(desyrdl::common VHDL
        ${OUTDIR}/vhdl/desyrdl/pkg_desyrdl_common.vhd
        )

    ip_link(${IP_LIB} desyrdl::common)

endfunction()

