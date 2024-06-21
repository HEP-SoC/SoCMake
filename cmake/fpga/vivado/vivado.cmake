function(vivado IP_LIB)
    cmake_parse_arguments(ARG "" "TOP" "VERILOG_DEFINES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")
    find_python3()

    ip_assume_last(IP_LIB ${IP_LIB})
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/vivado)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    get_ip_rtl_sources(SOURCES ${IP_LIB})
    get_ip_fpga_only_sources(FPGA_SOURCES ${IP_LIB})
    list(PREPEND SOURCES ${FPGA_SOURCES})
    list(FILTER SOURCES EXCLUDE REGEX ".vlt$")

    if(NOT ARG_TOP)
        set(TOP ${IP_LIB})
    else()
        set(TOP ${ARG_TOP})
    endif()

    foreach(vdef ${ARG_VERILOG_DEFINES})
        string(REPLACE "=" ";" vdef_l ${vdef})
    endforeach()

    # get_ip_sources(XDC_FILES ${IP_LIB} XDC)
    get_target_property(XDC_FILES ${IP_LIB} XDC)
    get_target_property(FPGA_PART ${IP_LIB} FPGA_PART)

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    get_ip_include_directories(VHDL_INCLUDE_DIRS ${IP_LIB} VHDL)
    set(INCLUDE_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS} ${VHDL_INCLUDE_DIRS})

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG) # TODO Add VHDL??
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    set(BITSTREAM ${OUTDIR}/${IP_LIB}.bit)
    set_source_files_properties(${BITSTREAM} PROPERTIES GENERATED TRUE)

    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    add_custom_command(
        OUTPUT ${BITSTREAM} ${STAMP_FILE}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/edalize_vivado.py
            --rtl-files ${SOURCES}
            --inc-dirs ${INCLUDE_DIRS} ${INCLUDE_DIRS}
            --constraint-files ${XDC_FILES}
            --part ${FPGA_PART}
            --name ${IP_LIB}
            --top  ${TOP}
            --outdir ${OUTDIR}
            --verilog-defs ${ARG_VERILOG_DEFINES} ${CMP_DEFS_ARG}

        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES} ${XDC_FILES} ${IP_LIB}
        COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
        )

    add_custom_target(
        ${IP_LIB}_vivado
        DEPENDS ${BITSTREAM} ${STAMP_FILE}
        )
endfunction()



