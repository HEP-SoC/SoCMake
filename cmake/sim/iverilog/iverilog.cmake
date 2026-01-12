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
# :keyword NO_RUN_TARGET: Do not create a run target.
# :type NO_RUN_TARGET: bool
# :keyword OUTDIR: Output directory for the Icarus verilog compilation and simulation.
# :type OUTDIR: string
# :keyword RUN_TARGET_NAME: Replace the default name of the run target.
# :type RUN_TARGET_NAME: string
# :keyword TOP_MODULE: Top module name to be used for elaboration and simulation.
# :type TOP_MODULE: string
# :keyword EXECUTABLE: Simulator executable name. Defaults to <IP_LIB>_iverilog_tb.
# :type EXECUTABLE: string
# :keyword FILE_SETS: list of file sets to use for simulation.
# :type FILE_SETS: list[string] 
# ]]]
function(iverilog IP_LIB)
    # Parse the function arguments
    cmake_parse_arguments(ARG "NO_RUN_TARGET" "TOP_MODULE;OUTDIR;EXECUTABLE;RUN_TARGET_NAME" "IVERILOG_ARGS;RUN_ARGS;FILE_SETS" ${ARGN})
    # Check for any unrecognized arguments
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Include the hardware IP management cmake functions
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")

    # Check the executables are available
    find_program(IVERILOG_EXECUTABLE iverilog)
    if(NOT IVERILOG_EXECUTABLE)
        message(FATAL_ERROR "iverilog not found in PATH. Please install icarus verilog or add it to your PATH.")
    endif()
    find_program(VVP_EXECUTABLE vvp)
    if(NOT VVP_EXECUTABLE)
        message(FATAL_ERROR "vvp not found in PATH. Please install icarus verilog or add it to your PATH.")
    endif()

    # Assume the IP library is the latest one provided if full name is not given
    alias_dereference(IP_LIB ${IP_LIB})
    # Get the binary directory of the IP library
    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)

    if(ARG_FILE_SETS)
        set(ARG_FILE_SETS FILE_SETS ${ARG_FILE_SETS})
    endif()

    # Get the IP RTL sources
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
    # Get IP include directories
    get_ip_include_directories(INC_DIRS ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
    # Prepare include directories arguments for iverilog
    foreach(dir ${INC_DIRS})
        list(APPEND ARG_INCDIRS -I ${dir})
    endforeach()

    # Get IP compile definitions
    get_ip_compile_definitions(COMP_DEFS ${IP_LIB} SYSTEMVERILOG VERILOG ${ARG_FILE_SETS})
    # Prepare compile definitions arguments for iverilog
    foreach(def ${COMP_DEFS})
        list(APPEND CMP_DEFS_ARG -D${def})
    endforeach()

    # Generator expression for OUTDIR = defined(ARG_OUTDIR) ? ARG_OUTDIR : BINARY_DIR
    set(OUTDIR $<IF:$<BOOL:${ARG_OUTDIR}>,${ARG_OUTDIR},${BINARY_DIR}>)
    # Set the output executable name
    set(ARG_EXECUTABLE $<IF:$<BOOL:${ARG_EXECUTABLE}>,${ARG_EXECUTABLE},${OUTDIR}/${IP_LIB}_iverilog_tb>)

    # Set the stamp file path (is the stamp file really needed?)
    set(STAMP_FILE "${OUTDIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
    set(DESCRIPTION "Compile ${IP_LIB} with ${CMAKE_CURRENT_FUNCTION}")

    if(NOT TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        # Add a custom command to run iverilog
        add_custom_command(
            OUTPUT ${ARG_EXECUTABLE} ${STAMP_FILE}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTDIR}
            COMMAND ${IVERILOG_EXECUTABLE}
                $<$<BOOL:${ARG_TOP_MODULE}>:-s${ARG_TOP_MODULE}>
                ${ARG_INCDIRS}
                ${CMP_DEFS_ARG}
                ${ARG_SV_COMPILE_ARGS}
                -o ${ARG_EXECUTABLE}
                ${SOURCES}
            COMMAND touch ${STAMP_FILE}
            DEPENDS ${SOURCES}
            COMMENT ${DESCRIPTION}
        )

        # Add a custom target that depends on the executable and stamp file
        add_custom_target(
            ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            DEPENDS ${ARG_EXECUTABLE} ${STAMP_FILE} ${IP_LIB}
        )
        set_property(TARGET ${IP_LIB}_${CMAKE_CURRENT_FUNCTION} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()

    set(__sim_run_cmd
        ${VVP_EXECUTABLE} ${ARG_RUN_ARGS} ${ARG_EXECUTABLE}
    )
    if(NOT ${ARG_NO_RUN_TARGET})
        if(NOT ARG_RUN_TARGET_NAME)
            set(ARG_RUN_TARGET_NAME run_${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
        endif()
        set(DESCRIPTION "Run ${CMAKE_CURRENT_FUNCTION} testbench compiled from ${IP_LIB}")
        # Add a custom target to run the generated executable
        add_custom_target(
            ${ARG_RUN_TARGET_NAME}
            COMMAND ${__sim_run_cmd}
            DEPENDS ${ARG_EXECUTABLE} ${STAMP_FILE} ${SOURCES} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            COMMENT ${DESCRIPTION}
        )
        set_property(TARGET ${ARG_RUN_TARGET_NAME} PROPERTY DESCRIPTION ${DESCRIPTION})
    endif()
    set(SIM_RUN_CMD ${__sim_run_cmd} PARENT_SCOPE)

endfunction()

