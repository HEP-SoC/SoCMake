#[[[
# Generates a filtered and organized list of RTL (Register Transfer Level) source files for a specified IP library target.
#
# This function collects all relevant RTL source files (excluding simulation, testbench, and FPGA-specific files) associated
# with the given ~IP_LIB~ target. It produces a file containing:
#  * All source files required for synthesis, preserving their directory hierarchy.
#  * All include directories and files needed for compilation.
#  * Only the files instantiated in the design hierarchy, as determined by the `slang` tool.
#
# The hierarchy is parsed using `slang` (https://github.com/MikePopoloski/slang), ensuring that only the necessary
# files for the specified top module (if provided) and its dependencies are included.
#
# :param IP_LIB: Name of the IP library target to analyze.
# :type IP_LIB: string
#
# **Keyword Arguments**
# :keyword SYNTHESIS: (Optional) If specified, defines SYNTHESIS macro while parsing the HDL sources.
# :type SYNTHESIS: boolean
# :keyword OUTDIR: (Optional) Output directory for the generated file lists. Defaults to ${CMAKE_BINARY_DIR}/ip_sources
# :type OUTDIR: string
# :keyword TOP_MODULE: (Optional) Name of the top module to use as the root of the hierarchy. Only modules below this point are included. An error is reported if the specified module does not exist.
# :type TOP_MODULE: string
#]]
function(generate_sources_list IP_LIB)
  cmake_parse_arguments(ARG "SYNTHESIS" "OUTDIR;TOP_MODULE" "" ${ARGN})
  if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
  endif()

  # Find slang executable
  find_program(SLANG_EXECUTABLE slang)
  if(NOT SLANG_EXECUTABLE)
    message(FATAL_ERROR "slang executable not found! Please install slang or set SLANG_EXECUTABLE.")
  endif()

  # Initialize variables
  set(INCDIR_ARG "")
  set(TOP_MODULE_ARG "")
  set(SYNTHESIS_ARG "")

  include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../hwip.cmake")
  alias_dereference(IP_LIB ${IP_LIB})

  if(NOT ARG_OUTDIR)
    set(OUTDIR ${CMAKE_BINARY_DIR}/ip_sources)
  else()
    set(OUTDIR ${ARG_OUTDIR})
  endif()

  # If a top module is provided, only modules in its hierarchy are included.
  if(ARG_TOP_MODULE)
    list(APPEND TOP_MODULE_ARG --top ${ARG_TOP_MODULE})
  endif()

  # Get the list of RTL sources
  get_ip_sources(RTL_SOURCES ${IP_LIB} SYSTEMVERILOG VERILOG)
  get_ip_include_directories(RTL_INCDIRS ${IP_LIB} SYSTEMVERILOG)
  foreach(_i ${RTL_INCDIRS})
    list(APPEND INCDIR_ARG -I${_i})
  endforeach()

  if(ARG_SYNTHESIS)
    list(APPEND SYNTHESIS_ARGS -DSYNTHESIS)
  endif()

  set(RTL_FILE ${OUTDIR}/rtl_sources.f)
  set(INCLUDE_FILE ${OUTDIR}/include_sources.f)
  file(MAKE_DIRECTORY ${OUTDIR})

  set(SLANG_CMD
    ${SLANG_EXECUTABLE}
    --depfile-trim --Mmodule ${RTL_FILE} --Minclude ${INCLUDE_FILE}
    ${TOP_MODULE_ARG}
    ${SYNTHESIS_ARG}
    ${INCDIR_ARG}
    ${RTL_SOURCES}
  )

  get_ip_links(DEPENDENT_TARGETS ${IP_LIB})

  add_custom_command(
    OUTPUT ${RTL_FILE} ${INCLUDE_FILE}
    COMMAND ${SLANG_CMD}
    DEPENDS ${DEPENDENT_TARGETS} ${RTL_SOURCES}
    COMMENT "Generating list of the RTL source files in ${OUTDIR}"
    VERBATIM
  )

  add_custom_target(
    ${IP_LIB}_source_list
    DEPENDS ${RTL_FILE} ${INCLUDE_FILE}
    COMMENT "Target for generating filtered RTL source list for ${IP_LIB}"
    VERBATIM
  )

  message(STATUS "To generate RTL source list for ${IP_LIB}, build the target: ${IP_LIB}_source_list")

endfunction()
