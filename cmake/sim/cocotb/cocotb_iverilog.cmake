include_guard(GLOBAL)

# [[[
# This function runs the Icarus Verilog (iverilog) tool on a specified IP library.
#
# The function is a wrapper around the iverilog tool and generates necessary scripts
# and configurations to compile the specified IP library.
#
# :param IP_LIB: Name of the IP library to run iverilog on.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword OUTDIR: Output directory for iverilog results. Defaults to BINARY_DIR.
# :type OUTDIR: string
# :keyword EXECUTABLE: Name of the output executable generated by iverilog. Defaults to IP_LIB_iv.
# :type EXECUTABLE: string
# ]]]
function(cocotb_iverilog IP_LIB)
    # Parse the function arguments
    cmake_parse_arguments(ARG "" "TOP_MODULE;OUTDIR;EXECUTABLE;IVERILOG_CLI_FLAGS;TIMEUNIT;TIMEPRECISION;TOPLEVEL_LANG;TESTCASE;PATH_MODULE;MODULE" "SIM_ARGS;PLUSARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Include the hardware IP management cmake functions
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    # Assume the IP library is the latest one provided if full name is not given
    ip_assume_last(IP_LIB ${IP_LIB})
    # Get the binary directory of the IP library
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    # Set the output directory for iverilog results
    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR})
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()

    # iverilog top module
    if(ARG_TOP_MODULE)
        set(TOP_MODULE ${ARG_TOP_MODULE})
    else()
        message(FATAL_ERROR "No simulation top module provided. Use the function argument TOP_MODULE.")
    endif()

    # Default parameters based on cocotb Makefile.inc
    # Makefile location, run: cocotb-config --makefiles
    if(ARG_TIMEUNIT)
        set(COCOTB_HDL_TIMEUNIT ${ARG_TIMEUNIT})
    else()
        set(COCOTB_HDL_TIMEUNIT "1ns")
    endif()
    # Default parameters based on cocotb Makefile.inc
    if(ARG_TIMEPRECISION)
        set(COCOTB_HDL_TIMEPRECISION ${ARG_TIMEPRECISION})
    else()
        set(COCOTB_HDL_TIMEPRECISION "1ps")
    endif()
    # Default parameters based on cocotb Makefile.inc
    set(COCOTB_RESULTS_FILE "${OUTDIR}/cocotb_results.xml")

    # Cocotb simulation options
    # Cocotb module to run (python script)
    if(ARG_MODULE)
        set(MODULE ${ARG_MODULE})
    else()
        message(FATAL_ERROR "No cocotb module provided. Use the function argument MODULE.")
    endif()
    if(ARG_PATH_MODULE)
        set(PATH_MODULE ${ARG_PATH_MODULE})
    else()
        message(FATAL_ERROR "No cocotb module path provided. Use the function argument PATH_MODULE.")
    endif()
    # This one is optional:
    if(ARG_TESTCASE)
        set(TESTCASE ${ARG_TESTCASE})
    endif()
    # This one is optional: top level file language
    if(ARG_TOPLEVEL_LANG)
        set(TOPLEVEL_LANG ${ARG_TOPLEVEL_LANG})
    else()
        set(TOPLEVEL_LANG "verilog")
    endif()

    # Get the IP RTL sources
    get_ip_rtl_sources(SOURCES ${IP_LIB})
    # Where is defined V_SOURCES (if it's defined)?
    list(PREPEND SOURCES ${V_SOURCES})
    # Get IP include directories
    get_ip_include_directories(SYSTEMVERILOG_INCLUDE_DIRS ${IP_LIB} SYSTEMVERILOG)
    get_ip_include_directories(VERILOG_INCLUDE_DIRS ${IP_LIB} VERILOG)
    set(INC_DIRS ${SYSTEMVERILOG_INCLUDE_DIRS} ${VERILOG_INCLUDE_DIRS})
    # Prepare include directories arguments for iverilog
    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -I ${dir})
    endforeach()

    # Get IP compile definitions
    get_ip_compile_definitions(COMP_DEFS_SV ${IP_LIB} SYSTEMVERILOG)
    get_ip_compile_definitions(COMP_DEFS_V ${IP_LIB} VERILOG)
    set(COMP_DEFS ${COMP_DEFS_SV} ${COMP_DEFS_V})
    # Prepare compile definitions arguments for iverilog
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    # Set the output executable name
    if(NOT ARG_EXECUTABLE)
        set(ARG_EXECUTABLE "${OUTDIR}/${IP_LIB}_iv")
    endif()

    # A command file as to be created to pass the timescale information to iverilog
    if(ARG_OUTDIR)
        set(CMDS_FILE ${OUTDIR}/cmds.f)
    else()
        set(CMDS_FILE cmds.f)
    endif()
    # Generate the cmds.f file
    execute_process(
        ERROR_VARIABLE ERROR_MSG
        COMMAND touch ${CMDS_FILE}
    )
    write_file(${CMDS_FILE} "+timescale+${COCOTB_HDL_TIMEUNIT}/${COCOTB_HDL_TIMEPRECISION}")
    # Check the file is generated
    if(NOT EXISTS ${CMDS_FILE})
        message(FATAL_ERROR "${CMDS_FILE} file not generated.")
    endif()

    # Set the stamp file path (is the stamp file really needed?)
    set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")

    # Add a custom command to run iverilog
    add_custom_command(
        OUTPUT ${ARG_EXECUTABLE} ${STAMP_FILE}
        # iverilog must be in your path
        COMMAND iverilog
        -s ${TOP_MODULE}
        ${ARG_INCDIRS}
        ${CMP_DEFS_ARG}
        ${ARG_IVERILOG_CLI_FLAGS}
        -DCOCOTB_SIM=1
        -f ${CMDS_FILE}
        -o ${ARG_EXECUTABLE}
        ${SOURCES}
        COMMAND touch ${STAMP_FILE}
        DEPENDS ${SOURCES}
        COMMENT "Running iverilog on ${IP_LIB}"
    )

    # Add a custom target that depends on the executable and stamp file
    add_custom_target(
        ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${ARG_EXECUTABLE} ${STAMP_FILE} ${IP_LIB}
    )

    # Get cocotb lib directory
    set(_CMD ${Python3_VIRTUAL_ENV}/bin/cocotb-config --lib-dir)
    execute_process(
        OUTPUT_VARIABLE COCOTB_LIB_DIR
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${_CMD}
    )
    # Check the lib path is found
    if(NOT COCOTB_LIB_DIR)
        message(FATAL_ERROR "Cocotb lib directory variable not found. Make sure cocotb package is installed in the python venv. Error output: ${ERROR_MSG}.")
    endif()
    # Remove the line feed of the variable otherwise if breaks the below command
    string(STRIP ${COCOTB_LIB_DIR} COCOTB_LIB_DIR)

    # Get cocotb vpi library for icarus verilog
    set(_CMD ${Python3_VIRTUAL_ENV}/bin/cocotb-config --lib-name vpi icarus)
    execute_process(
        OUTPUT_VARIABLE COCOTB_LIB_VPI_ICARUS
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${_CMD}
    )
    # Check the lib is found
    if(NOT COCOTB_LIB_VPI_ICARUS)
        message(FATAL_ERROR "Cocotb lib vpi icarus variable not found. Make sure cocotb package is installed in the python venv. Error output: ${ERROR_MSG}.")
    endif()
    # Remove the line feed of the variable otherwise if breaks the below command
    string(STRIP ${COCOTB_LIB_VPI_ICARUS} COCOTB_LIB_VPI_ICARUS)

    # Add a custom command to run cocotb
    add_custom_command(
        OUTPUT ${COCOTB_RESULTS_FILE}
        COMMAND PYTHONPATH=${PATH_MODULE}
        MODULE=${MODULE}
        TESTCASE=${TESTCASE}
        TOPLEVEL=${TOP_MODULE}
        TOPLEVEL_LANG=${TOPLEVEL_LANG}
        # sim command prefix, e.g., for debugging: 'gdb --args'
        ${ARG_SIM_CMD_PREFIX}
        # iverilog run-time engine must be in your path
        vvp -M${COCOTB_LIB_DIR} -m${COCOTB_LIB_VPI_ICARUS}
        # Arguments to pass to execution of compiled simulation
        ${ARG_SIM_ARGS}
        ${ARG_EXECUTABLE}
        # Plusargs to pass to the simulator
        ${ARG_PLUSARGS}
        DEPENDS ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        COMMENT "Running cocotb simulation on ${IP_LIB}"
    )

    # Add a custom target that depends on the executable and stamp file
    add_custom_target(
        run_${MODULE}_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
        DEPENDS ${COCOTB_RESULTS_FILE}
    )

endfunction()

