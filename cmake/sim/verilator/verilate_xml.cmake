include_guard(GLOBAL)

function(verilate_xml IP_LIB)
    set(OPTIONS "GEN_REGPUBLIC")
    set(ONE_PARAM_ARGS "PREFIX;OUTDIR;TOP_MODULE")
    set(MULTI_PARAM_ARGS "VERILATOR_ARGS")

    cmake_parse_arguments(ARG "${OPTIONS}"
        "${ONE_PARAM_ARGS}"
        "${MULTI_PARAM_ARGS}"
        ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../utils/find_python.cmake")

    # frpm hwip.cmake. deferences full name of ip
    ip_assume_last(IP_LIB ${IP_LIB})
    
    # get binary dir location
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/verilate_xml)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INCLUDE_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})

    foreach(INC_DIR ${INCLUDE_DIRS})
        list(APPEND INC_DIRS_ARG -I${INC_DIR})
    endforeach()

    if(ARG_TOP_MODULE)
        set(TOP_MODULE ${ARG_TOP_MODULE})
    else()
        get_target_property(TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    get_ip_property(VERILATOR_ARGS ${IP_LIB} VERILATOR_ARGS)
    list(APPEND VERILATOR_ARGS ${ARG_VERILATOR_ARGS})

    get_ip_rtl_sources(SOURCES ${IP_LIB})
    list(PREPEND SOURCES ${V_SOURCES})

    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    foreach(def ${COMP_DEFS_SV} ${COMP_DEFS_V})
        list(APPEND VERILATOR_ARGS -D${def})
    endforeach()

    if(NOT SOURCES)
        message(FATAL_ERROR "Verilate function needs at least one VERILOG or SYSTEMVERILOG source added to the IP")
    endif()

    set(XML_FILE ${OUTDIR}/${IP_LIB}.xml)

    # taken from verilator github cmake file
    find_program(VERILATOR_BIN NAMES verilator_bin
      HINTS ${VERISC_HOME}/open/* $ENV{VERISC_HOME}/open/* ${VERILATOR_HOME}/bin ENV VERILATOR_HOME
      NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)

    set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    add_custom_command(
        OUTPUT ${XML_FILE} ${STAMP_FILE}
        COMMAND ${VERILATOR_BIN} --xml-output ${XML_FILE}
        ${SOURCES}
        ${INC_DIRS_ARG}
        ${VERILATOR_ARGS}
        --top-module ${TOP_MODULE}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        )

    add_custom_target(
        ${IP_LIB}_verilate_xml
        DEPENDS ${XML_FILE} ${STAMP_FILE} ${IP_LIB}
        )

    if(ARG_GEN_REGPUBLIC)
      set(VLT_CFG_FILE ${OUTDIR}/${IP_LIB}_regpublic.vlt)
      set(REG_LIST ${OUTDIR}/${IP_LIB}_reglist.txt)
      set(REG_H_FILE ${OUTDIR}/${IP_LIB}_seq_vpi_handles.h)
      set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")


      find_python3() # sets Python3_EXECUTABLE 
      add_custom_command(
          OUTPUT ${VLT_CFG_FILE} ${REG_LIST} ${REG_H_FILE} ${STAMP_FILE}
          COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/parse_vlt_xml.py
          ${XML_FILE}
          ${OUTDIR}
          --prefix ${IP_LIB}
          --vlt --reg-list --reg-h
          COMMAND touch ${STAMP_FILE}
          DEPENDS ${IP_LIB}_verilate_xml ${XML_FILE}
          )

      add_custom_target(
          ${IP_LIB}_verilate_xml_regpublic
          DEPENDS ${VLT_CFG_FILE} ${REG_LIST} ${REG_H_FILE} ${STAMP_FILE} ${XML_FILE}
          )
      
      set_property(TARGET ${IP_LIB}_verilate_xml_regpublic PROPERTY VPIREG_LIST ${REG_LIST})
      # add vlt file to sources list
      ip_sources(${IP_LIB} SYSTEMVERILOG ${VLT_CFG_FILE})
      target_sources(${IP_LIB} INTERFACE
          FILE_SET HEADERS 
          BASE_DIRS "${OUTDIR}"
          FILES ${REG_H_FILE}
          )
      
    endif()

endfunction()
