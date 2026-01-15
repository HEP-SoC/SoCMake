include_guard(GLOBAL)

# [[[
# This function simulated the IP library with the cocotb library.
#
# The function is a wrapper around supported simulators by cocotb. It is based on the cocotb Makefiles.
#
# :param IP_LIB: Name of the IP library to run iverilog on.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword GUI: Run simulation in GUI mode.
# :type GUI: bool
# :keyword OUTDIR: Output directory for the Icarus verilog compilation and simulation.
# :type OUTDIR: string
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword COCOTB_MODULE: Simulator executable name. Defaults to <IP_LIB>_iverilog_tb.
# :type COCOTB_MODULE: string
# :keyword COCOTB_TESTCASE: Cocotb number of test cases to run (from 1 to N). All test cases are run sequentially if not provided.
# :type COCOTB_TESTCASE: integer
# :keyword SIM: Simulator to use. Supported simulators is: icarus (cocotb also support verilator, xcelium, vcs and modelsim/questasim, not yet supported by SoCMake).
# :type SIM: string
# :keyword TIMESCALE: Simulation timscale. Default is 1ns/1ps.
# :type TIMESCALE: string
# :keyword PYTHONPATH: List of paths to be added to the PYTHONPATH environment variable to include python modules needed for the simulation.
# :type PYTHONPATH: string
# :keyword SV_COMPILE_ARGS: Extra arguments to be passed to the System Verilog / Verilog compilation step.
# :type SV_COMPILE_ARGS: string
# :keyword RUN_ARGS: Extra arguments to be passed to the simulation step.
# :type RUN_ARGS: string
# ]]]
function(cocotb IP_LIB)
    # Parse the function arguments
    cmake_parse_arguments(ARG "NO_RUN_TARGET;GUI" "OUTDIR;RUN_TARGET_NAME;TOP_MODULE;COCOTB_MODULE;COCOTB_TESTCASE;SIM;TIMESCALE" "PYTHONPATH;SV_COMPILE_ARGS;RUN_ARGS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Include the hardware IP management cmake functions
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
    # find_package(Python3 COMPONENTS Interpreter Development)

    alias_dereference(IP_LIB ${IP_LIB})

    if(NOT ARG_TOP_MODULE)
        get_target_property(ARG_TOP_MODULE ${IP_LIB} IP_NAME)
    endif()

    if(ARG_PYTHONPATH)
        # Column separated paths to python files/modules are needed
        string(REPLACE ";" ":" PYTHONPATH "${ARG_PYTHONPATH}")
    endif()

    if(NOT ARG_COCOTB_MODULE)
        message(FATAL_ERROR "No cocotb module provided. Provide the function argument COCOTB_MODULE.")
    endif()

    set(cocotb_sim_build ${CMAKE_BINARY_DIR}/cocotb_sim_build)
    file(MAKE_DIRECTORY ${cocotb_sim_build})

    find_program(COCOTB_CONFIG_EXECUTABLE cocotb-config)
    if(NOT COCOTB_CONFIG_EXECUTABLE)
        message(FATAL_ERROR "Cocotb not found. Please install it or provide the path to the cocotb-config executable.")
    endif()
    execute_process(
        OUTPUT_VARIABLE COCOTB_SHARE_DIR
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${COCOTB_CONFIG_EXECUTABLE} --share
    )
    execute_process(
        OUTPUT_VARIABLE COCOTB_LIB_DIR
        ERROR_VARIABLE ERROR_MSG
        COMMAND ${COCOTB_CONFIG_EXECUTABLE} --lib-dir
    )
    # Remove the line feed of the variable
    string(STRIP ${COCOTB_SHARE_DIR} COCOTB_SHARE_DIR)
    string(STRIP ${COCOTB_LIB_DIR} COCOTB_LIB_DIR)
    # First get all Python files from cocotb
    file(GLOB_RECURSE COCOTB_PY_DEPS ${COCOTB_SHARE_DIR}/../*.py)
    # Get all files in the cocotb library directory
    file(GLOB COCOTB_LIB_DEPS ${COCOTB_LIB_DIR}/*.so)

    # Combine the deps
    set(cocotb_custom_sim_deps ${COCOTB_PY_DEPS} ${COCOTB_LIB_DEPS})

    # If no simulator is provided, try to find one
    if(NOT ARG_SIM)
        find_program(IVERILOG_EXECUTABLE iverilog)
        find_program(VVP_EXECUTABLE vvp)
        if(IVERILOG_EXECUTABLE AND VVP_EXECUTABLE)
            set(ARG_SIM icarus)
        else()
            find_program(XCELIUM_EXECUTABLE xrun)
            if(XCELIUM_EXECUTABLE)
                set(ARG_SIM xcelium)
            else()
                message(FATAL_ERROR "Neither icarus or xcelium simulator found. Please provide a simulator using the SIM argument.")
            endif()
        endif()
    endif()

    if(NOT ARG_TIMESCALE)
        set(ARG_TIMESCALE 1ns/1ps)
    endif()

    if(ARG_GUI)
        set(ARG_GUI GUI)
    endif()

    # Generate the executable based on the simulator
    if(${ARG_SIM} STREQUAL icarus OR ${ARG_SIM} STREQUAL iverilog)
        message(DEBUG "COCOTB: Using Icarus Verilog simulator")
        set(cocotb_sim_build ${cocotb_sim_build}/icarus)
        file(MAKE_DIRECTORY ${cocotb_sim_build})
        # A command file as to be created to pass the timescale information to iverilog
        set(CMDS_FILE ${cocotb_sim_build}/cmds.f)
        file(TOUCH ${CMDS_FILE})
        file(WRITE ${CMDS_FILE} "+timescale+${ARG_TIMESCALE}\n")

        # Get the simulator VPI library
        execute_process(
            OUTPUT_VARIABLE COCOTB_LIB_NAME
            ERROR_VARIABLE ERROR_MSG
            COMMAND ${COCOTB_CONFIG_EXECUTABLE} --lib-name vpi icarus
        )
        # Remove the line feed of the variable
        string(STRIP ${COCOTB_LIB_NAME} COCOTB_LIB_NAME)

        iverilog(${IP_LIB}
            NO_RUN_TARGET
            TOP_MODULE ${ARG_TOP_MODULE}
            OUTDIR ${cocotb_sim_build}
            SV_COMPILE_ARGS -DCOCOTB_SIM=1 -g2012 -f${CMDS_FILE}
            RUN_ARGS -M${COCOTB_LIB_DIR} -m${COCOTB_LIB_NAME}
        )

        set(sim_run_cmd ${SIM_RUN_CMD} ${ARG_RUN_ARGS})
        set(sim_build_dep ${IP_LIB}_iverilog)
        message(DEBUG "COCOTB: Icarus verilog run command: ${sim_run_cmd}")
    elseif(${ARG_SIM} STREQUAL verilator)
        message(DEBUG "COCOTB: Using Verilator simulator")
        set(cocotb_sim_build ${cocotb_sim_build}/verilator)
        file(MAKE_DIRECTORY ${cocotb_sim_build})

        set(EXEC_TARGET cocotb_verilator_${ARG_COCOTB_MODULE}_${IP_LIB})
        add_executable(${EXEC_TARGET}
            ${COCOTB_SHARE_DIR}/lib/verilator/verilator.cpp
        )

        verilator(${IP_LIB}
            NO_RUN_TARGET
            TOP_MODULE ${ARG_TOP_MODULE}
            DIRECTORY ${cocotb_sim_build}
            PREFIX Vtop
            VERILATOR_ARGS -DCOCOTB_SIM=1 --vpi --public-flat-rw
        )

        target_link_libraries(${EXEC_TARGET} PRIVATE ${IP_LIB}__vlt)
        target_link_libraries(${EXEC_TARGET} PRIVATE cocotbvpi_verilator)
        target_link_options(${EXEC_TARGET} PRIVATE -Wl,-rpath,${COCOTB_LIB_DIR} -L${COCOTB_LIB_DIR})

        set(sim_run_cmd ${PROJECT_BINARY_DIR}/${EXEC_TARGET} ${ARG_RUN_ARGS})
        set(sim_build_dep ${EXEC_TARGET})
        message(DEBUG "COCOTB: Verilator run command: ${sim_run_cmd}")
    elseif(${ARG_SIM} STREQUAL xcelium)
        message(DEBUG "COCOTB: Using Xcelium simulator")
        set(cocotb_sim_build ${cocotb_sim_build}/xcelium)
        file(MAKE_DIRECTORY ${cocotb_sim_build})
        # Get the simulator VPI/VHPI library paths
        execute_process(
            OUTPUT_VARIABLE COCOTB_VPI_PATH
            ERROR_VARIABLE ERROR_MSG
            COMMAND ${COCOTB_CONFIG_EXECUTABLE} --lib-name-path vpi xcelium
        )
        execute_process(
            OUTPUT_VARIABLE COCOTB_VHPI_PATH
            ERROR_VARIABLE ERROR_MSG
            COMMAND ${COCOTB_CONFIG_EXECUTABLE} --lib-name-path vhpi xcelium
        )
        # Remove the line feed of the variable
        string(STRIP ${COCOTB_VPI_PATH} COCOTB_VPI_PATH)
        string(STRIP ${COCOTB_VHPI_PATH} COCOTB_VHPI_PATH)

        xcelium(
            ${IP_LIB}
            NO_RUN_TARGET
            ${ARG_GUI}
            TOP_MODULE ${ARG_TOP_MODULE}
            OUTDIR ${cocotb_sim_build}
            ELABORATE_ARGS -access +rwc -timescale ${ARG_TIMESCALE} -loadvpi ${COCOTB_VPI_PATH}:vlog_startup_routines_bootstrap -loadvhpi ${COCOTB_VHPI_PATH}:cocotbvhpi_entry_point
            SV_COMPILE_ARGS -DCOCOTB_SIM=1
        )
        set(sim_run_cmd ${SIM_RUN_CMD} ${ARG_RUN_ARGS})
        set(sim_build_dep ${IP_LIB}_xcelium)
        message(DEBUG "COCOTB: Xcelium run command: ${sim_run_cmd}")
    elseif(${ARG_SIM} STREQUAL modelsim OR ${ARG_SIM} STREQUAL questa)
        message(FATAL_ERROR "Using ModelSim/QuestaSim simulator is not supported by SoCMake yet")
        # TODO: Add support for QuestaSim
    elseif(${ARG_SIM} STREQUAL vcs)
        message(DEBUG "COCOTB: Using VCS simulator")

        # Can't do this using an argument, we have to create a PLI table file
        # enabling write access to the design
        set(PLI_FILE ${cocotb_sim_build}/pli.tab)
        file(TOUCH ${PLI_FILE})
        file(WRITE ${PLI_FILE} "acc+=rw,wn:*\n")

        set(cocotb_sim_build ${cocotb_sim_build}/vcs)
        file(MAKE_DIRECTORY ${cocotb_sim_build})
        # Get the simulator VPI library paths
        execute_process(
            OUTPUT_VARIABLE COCOTB_VPI_PATH
            ERROR_VARIABLE ERROR_MSG
            COMMAND ${COCOTB_CONFIG_EXECUTABLE} --lib-name-path vpi vcs
        )
        # Remove the line feed of the variable
        string(STRIP ${COCOTB_VPI_PATH} COCOTB_VPI_PATH)

        vcs(
            ${IP_LIB}
            NO_RUN_TARGET
            ${ARG_GUI}
            TOP_MODULE ${ARG_TOP_MODULE}
            OUTDIR ${cocotb_sim_build}
            ELABORATE_ARGS -debug_access+r+w-memcbk -P ${PLI_FILE} -debug_region+cell +vpi -sverilog -timescale=${ARG_TIMESCALE} -debug_acc+pp+f+dmptf -debug_region+cell+encrypt -load ${COCOTB_VPI_PATH}
            SV_COMPILE_ARGS +define+COCOTB_SIM=1
            RUN_ARGS +define+COCOTB_SIM=1
        )
        set(sim_run_cmd ${SIM_RUN_CMD} ${ARG_RUN_ARGS})
        set(sim_build_dep ${IP_LIB}_vcs)
        message(DEBUG "COCOTB: VCS run command: ${sim_run_cmd}")
    else()
        message(FATAL_ERROR "Unsupported cocotb simulator: ${ARG_SIM}\nSupported simulators are: icarus/iverilog, verilator, xcelium, questa/modelsim (supported by cocotb but not by SoCMake yet), vcs (supported by cocotb but not by SoCMake yet).")
    endif()

    # If no test cases are provided, all test cases are run sequentially
    if(NOT ARG_COCOTB_TESTCASE)

        # Generator expression for OUTDIR = defined(ARG_OUTDIR) ? ARG_OUTDIR : BINARY_DIR
        set(OUTDIR $<IF:$<BOOL:${ARG_OUTDIR}>,${ARG_OUTDIR},${BINARY_DIR}>)

        # Default parameters based on cocotb Makefile.inc
        set(COCOTB_RESULTS_FILE ${OUTDIR}/results.xml)

        set(__sim_run_cmd
            PYTHONPATH=${PYTHONPATH}
            MODULE=${ARG_COCOTB_MODULE}
            COCOTB_RESULTS_FILE=${COCOTB_RESULTS_FILE}
            ${sim_run_cmd}
        )

        if(NOT ARG_NO_RUN_TARGET)
            if(ARG_RUN_TARGET_NAME)
                set(CUSTOM_TARGET_NAME ${ARG_RUN_TARGET_NAME})
            else()
                set(CUSTOM_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_${ARG_COCOTB_MODULE})
            endif()

            set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} simulation compiled from ${IP_LIB} with ${ARG_SIM}")
            # Add a custom target that depends on the executable and stamp file
            add_custom_target(${CUSTOM_TARGET_NAME}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
                COMMAND ${__sim_run_cmd}
                BYPRODUCTS ${COCOTB_RESULTS_FILE}
                DEPENDS ${sim_build_dep} ${cocotb_custom_sim_deps}
                COMMENT ${DESCRIPTION}
            )
            set_property(TARGET ${CUSTOM_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
        endif()
    else() # ARG_COCOTB_TESTCASE
        foreach(i RANGE 1 ${ARG_COCOTB_TESTCASE})
            # Add leading zeros based on the value of the loop variable
            if(${i} LESS 10)
                set(test_num "00${i}")
            elseif(${i} LESS 100)
                set(test_num "0${i}")
            endif()

            # Generator expression for OUTDIR = defined(ARG_OUTDIR) ? ARG_OUTDIR : BINARY_DIR
            if(ARG_OUTDIR)
                set(OUTDIR ${ARG_OUTDIR}/test_${test_num})
            else()
                set(OUTDIR ${BINARY_DIR}/cocotb/test_${test_num})
            endif()

            # Default parameters based on cocotb Makefile.inc
            set(COCOTB_RESULTS_FILE ${OUTDIR}/results.xml)

            set(__sim_run_cmd
                PYTHONPATH=${PYTHONPATH}
                MODULE=${ARG_COCOTB_MODULE}
                COCOTB_RESULTS_FILE=${COCOTB_RESULTS_FILE}
                ${sim_run_cmd}
            )

            if(NOT ARG_NO_RUN_TARGET)
                if(ARG_RUN_TARGET_NAME)
                    set(CUSTOM_TARGET_NAME ${ARG_RUN_TARGET_NAME})
                else()
                    set(CUSTOM_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION}_${ARG_COCOTB_MODULE}_test_${test_num})
                endif()

                set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} simulation compiled from ${IP_LIB} with ${ARG_SIM}")
                # Add a custom target that depends on the executable and stamp file
                add_custom_target(${CUSTOM_TARGET_NAME}
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
                    COMMAND TESTCASE=${ARG_COCOTB_MODULE}_test_${test_num} ${__sim_run_cmd}
                    BYPRODUCTS ${COCOTB_RESULTS_FILE}
                    DEPENDS ${sim_build_dep} ${cocotb_custom_sim_deps}
                    COMMENT ${DESCRIPTION}
                )
                set_property(TARGET ${CUSTOM_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
            endif() # NOT ARG_NO_RUN_TARGET
        endforeach()
    endif() # ARG_COCOTB_TESTCASE

    set(SIM_RUN_CMD ${sim_run_cmd} PARENT_SCOPE)
    set(SIM_BUILD_DEP ${sim_build_dep} PARENT_SCOPE)

endfunction()
