#[[[ @module fpga
#]]

#[[[
# Generate a vivado FPGA project and create a target to generate the bitstream.
#
# The python script, edalize_vivado, using edalize library is used to correctly run vivado with the given informations.
# The different arguments are parsed and formatted to be properly given to vivado. 
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword TOP: Top-level module name used for elaboration. The default is the IP_LIB ``IP_NAME`` property.
# :type TOP: string
# :keyword VERILOG_DEFINES: Additional SV/Verilog define flags to be passed to the Vivado project.
# :type VERILOG_DEFINES: list[string]
# :keyword OUTDIR: Output directory for generated files. Defaults to ``${BINARY_DIR}/vivado``.
# :type OUTDIR: string
#]]
function(vivado IP_LIB)
    cmake_parse_arguments(ARG "" "TOP;OUTDIR" "VERILOG_DEFINES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    alias_dereference(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/vivado)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG_FPGA VERILOG_FPGA VHDL_FPGA SYSTEMVERILOG VERILOG VHDL)
    list(FILTER SOURCES EXCLUDE REGEX ".vlt$")

    if(NOT ARG_TOP)
        get_target_property(TOP ${IP_LIB} IP_NAME)
    else()
        set(TOP ${ARG_TOP})
    endif()

    get_target_property(XDC_FILES ${IP_LIB} XDC)
    get_target_property(FPGA_PART ${IP_LIB} FPGA_PART)

    get_ip_include_directories(INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG VHDL)
    list(APPEND COMP_DEFS ${ARG_VERILOG_DEFINES})

    set(BITSTREAM ${OUTDIR}/${IP_LIB}.bit)
    set_source_files_properties(${BITSTREAM} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${BITSTREAM} ${STAMP_FILE}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/edalize_vivado.py
            --rtl-files ${SOURCES}
            --inc-dirs ${INCLUDE_DIRS}
            --constraint-files ${XDC_FILES}
            --part ${FPGA_PART}
            --name ${IP_LIB}
            --top  ${TOP}
            --outdir ${OUTDIR}
            --verilog-defs ${COMP_DEFS}

        COMMAND /bin/sh -c date > ${STAMP_FILE}
        DEPENDS ${SOURCES} ${XDC_FILES} ${IP_LIB}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
    )

    add_custom_target(
        ${IP_LIB}_vivado
        DEPENDS ${BITSTREAM} ${STAMP_FILE}
    )
endfunction()
