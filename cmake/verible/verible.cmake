#[[[ @module verible
#]]

#[[[
# Verible lint tool interface
#
# Verible-lint is a SystemVerilog linter...
#
# Verible can be found on this `link <https://github.com/chipsalliance/verible>`_
#
# Function expects that **IP_LIB** *INTERFACE_LIBRARY* has **SOURCES** property set with a list of System Verilog files to be used as inputs.
# To set the SOURCES property use `target_sources() <https://cmake.org/cmake/help/latest/command/target_sources.html>`_ CMake function:
# 
# .. code-block:: cmake
#
#    target_sources(<your-lib> INTERFACE <sources>...)
#
# Function will create targets for linting or formatting depending on passed option
#
# :param IP_LIB: RTL interface library, it needs to have SOURCES property set with a list of System Verilog files.
# :type IP_LIB: INTERFACE_LIBRARY
#
# **Keyword Arguments**
#
# :keyword REQUIRED: if option REQUIRED is passed, the **IP_LIB** will depend on linting target, meaning that the linting will be done as soon as all the Verilog files are generated. By default only a new target <IP_LIB>_verible_lint is created and can be run optionally.
# :type REQUIRED: boolean
# :keyword OUTDIR: output directory in which the files will be generated, if ommited ${BINARY_DIR}/verible will be used.
# :type OUTDIR: string path
# :keyword AUTOFIX: autofix the linting errors
# :type AUTOFIX: [no|patch-interactive|patch|inplace-interactive|inplace|generate-waiver]
# :keyword RULES: list of rules to enable or disable for reference look at verible documentation `link <https://github.com/chipsalliance/verible/tree/master/verilog/tools/lint#rule-configuration>`_
# :type RULES: List[string]
# :keyword RULES_FILE: Additionally, the RULES_FILE flag can be used to read configuration stored in a file. The syntax is the same as RULES, except the rules can be also separated with the newline character
# :type RULES_FILE: path string
# :keyword WAIVER_FILES: (Path to waiver config files (comma-separated). Please refer to the README file for information about its format.)
# :type WAIVER_FILES: List[path string]
#]]

function(verible_lint IP_LIB)
    cmake_parse_arguments(ARG "REQUIRED" "OUTDIR;AUTOFIX;RULES_FILE" "RULES;WAIVER_FILES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../hwip.cmake")

    ip_assume_last(IP_LIB ${IP_LIB})

    get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)
    if(NOT ARG_OUTDIR)
        set(OUTDIR ${BINARY_DIR}/verible)
    else()
        set(OUTDIR ${ARG_OUTDIR})
    endif()
    file(MAKE_DIRECTORY ${OUTDIR})

    set(AUTOFIX_OPTIONS "no;patch-interactive;patch;inplace-interactive;inplace;generate-waiver")
    if(ARG_AUTOFIX AND (NOT ARG_AUTOFIX IN_LIST AUTOFIX_OPTIONS))
        message(FATAL_ERROR "Not valid option for AUTOFIX: ${ARG_AUTOFIX}, valid options are ${AUTOFIX_OPTIONS}")
    endif()

    if(ARG_AUTOFIX)
        set(ARG_AUTOFIX --autofix ${ARG_AUTOFIX})
        set(AUTOFIX_OUTFILE_ARG --autofix_output_file ${OUTDIR}/${IP_LIB}_autofix.patch)
    endif()

    if(ARG_RULES)
        string(REPLACE ";" "," RULES "${ARG_RULES}")
        set(ARG_RULES --rules=${RULES})
    endif()

    if(ARG_RULES_FILE)
        set(ARG_RULES_FILE --rules_config=${ARG_RULES_FILE})
    endif()

    if(ARG_WAIVER_FILES)
        string(REPLACE ";" "," WAIVER_FILES "${ARG_WAIVER_FILES}")
        set(ARG_WAIVER_FILES --waiver_files=${WAIVER_FILES})
    endif()

    get_ip_sources(V_SOURCES ${IP_LIB} VERILOG)          # TODO make merge source files group function
    get_ip_sources(SOURCES ${IP_LIB} SYSTEMVERILOG)
    list(PREPEND SOURCES ${V_SOURCES})

    find_program(VERIBLE_LINTER NAMES verible-verilog-lint)
    set(__CMD ${VERIBLE_LINTER}
            ${ARG_AUTOFIX} ${AUTOFIX_OUTFILE_ARG}
            ${ARG_RULES} ${ARG_RULES_FILE}
            ${ARG_WAIVER_FILES}
            ${SOURCES}
        )

    if(ARG_REQUIRED)
        set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
        add_custom_command(OUTPUT ${STAMP_FILE}
            COMMAND ${__CMD}
            COMMAND touch ${STAMP_FILE}
            DEPENDS ${SOURCES}
            COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
            )

        add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            DEPENDS ${SOURCES} ${STAMP_FILE}
            )
        add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
    else()
        add_custom_target( ${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
            COMMAND ${__CMD}
            COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
            )
        add_dependencies(${IP_LIB}_${CMAKE_CURRENT_FUNCTION} ${IP_LIB})
    endif()


endfunction()


# TODO add formatter

# function(verible_format IP_LIB)
#     cmake_parse_arguments(ARG "" "OUTDIR;AUTOFIX;RULES_FILE" "RULES;WAIVER_FILES" ${ARGN})
#     if(ARG_UNPARSED_ARGUMENTS)
#         message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
#     endif()
#
#     include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../IP_LIB.cmake")
#
#     get_target_property(BINARY_DIR ${IP_LIB} BINARY_DIR)
#     if(NOT ARG_OUTDIR)
#         set(OUTDIR ${BINARY_DIR}/verible)
#     else()
#         set(OUTDIR ${ARG_OUTDIR})
#     endif()
#     file(MAKE_DIRECTORY ${OUTDIR})
#
#     set(AUTOFIX_OPTIONS "no;patch-interactive;patch;inplace-interactive;inplace;generate-waiver")
#     if(ARG_AUTOFIX AND (NOT ARG_AUTOFIX IN_LIST AUTOFIX_OPTIONS))
#         message(FATAL_ERROR "Not valid option for AUTOFIX: ${ARG_AUTOFIX}, valid options are ${AUTOFIX_OPTIONS}")
#     endif()
#
#     if(ARG_AUTOFIX)
#         set(ARG_AUTOFIX --autofix ${ARG_AUTOFIX})
#         set(AUTOFIX_OUTFILE_ARG --autofix_output_file ${OUTDIR}/${IP_LIB}_autofix.patch)
#     endif()
#
#     if(ARG_RULES)
#         string(REPLACE ";" "," RULES "${ARG_RULES}")
#         set(ARG_RULES --rules=${RULES})
#     endif()
#
#     if(ARG_RULES_FILE)
#         set(ARG_RULES_FILE --rules_config=${ARG_RULES_FILE})
#     endif()
#
#     if(ARG_WAIVER_FILES)
#         string(REPLACE ";" "," WAIVER_FILES "${ARG_WAIVER_FILES}")
#         set(ARG_WAIVER_FILES --waiver_files=${WAIVER_FILES})
#     endif()
#
#     get_rtl_target_sources(SOURCES ${IP_LIB})
#
#     set(STAMP_FILE "${BINARY_DIR}/${IP_LIB}_${CMAKE_CURRENT_FUNCTION}.stamp")
#     add_custom_command(OUTPUT ${STAMP_FILE}
#         COMMAND verible-verilog-lint 
#             ${ARG_AUTOFIX} ${AUTOFIX_OUTFILE_ARG}
#             ${ARG_RULES} ${ARG_RULES_FILE}
#             ${ARG_WAIVER_FILES}
#             ${SOURCES}
#         COMMAND touch ${STAMP_FILE}
#         DEPENDS ${SOURCES}
#         COMMENT "Running ${CMAKE_CURRENT_FUNCTION} on ${IP_LIB}"
#         )
#
#     add_custom_target(${IP_LIB}_${CMAKE_CURRENT_FUNCTION}
#         DEPENDS ${SOURCES} ${STAMP_FILE}
#         )
#
#     add_dependencies(${IP_LIB} ${IP_LIB}_${CMAKE_CURRENT_FUNCTION})
#
# endfunction()
#
