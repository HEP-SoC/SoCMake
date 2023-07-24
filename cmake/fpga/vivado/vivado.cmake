function(vivado RTLLIB)
    cmake_parse_arguments(ARG "" "TOP" "VERILOG_DEFINES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../rtllib.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    get_target_property(BINARY_DIR ${RTLLIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/vivado)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    get_rtl_target_sources(V_FILES ${RTLLIB})
    list(FILTER V_FILES EXCLUDE REGEX ".vlt$")
    
    if(NOT ARG_TOP)
        set(TOP ${RTLLIB})
    else()
        set(TOP ${ARG_TOP})
    endif()

    foreach(vdef ${ARG_VERILOG_DEFINES})
        string(REPLACE "=" ";" vdef_l ${vdef})
    endforeach()

    get_rtl_target_property(XDC_FILES ${RTLLIB} XDC_FILES)
    get_target_property(FPGA_PART ${RTLLIB} FPGA_PART)

    get_rtl_target_property(INTERFACE_INCLUDE_DIRS ${RTLLIB} INTERFACE_INCLUDE_DIRECTORIES)
    get_rtl_target_property(INCLUDE_DIRS ${RTLLIB} INCLUDE_DIRECTORIES)

    set(BITSTREAM ${OUTDIR}/${RTLLIB}.bit)
    set_source_files_properties(${BITSTREAM} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${RTLLIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${BITSTREAM} ${STAMP_FILE}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/edalize_vivado.py
            --rtl-files ${V_FILES}
            --inc-dirs ${INTERFACE_INCLUDE_DIRS} ${INCLUDE_DIRS}
            --constraint-files ${XDC_FILES}
            --part ${FPGA_PART}
            --name ${RTLLIB}
            --top  ${TOP}
            --outdir ${OUTDIR}
            --verilog-defs ${ARG_VERILOG_DEFINES}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${V_FILES} ${XDC_FILES} ${RTLLIB}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${RTLLIB}"
        )

    add_custom_target(
        ${RTLLIB}_vivado
        DEPENDS ${BITSTREAM} ${STAMP_FILE}
        )
endfunction()



