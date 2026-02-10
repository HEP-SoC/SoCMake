function(__cmake_to_json_array OUTVAR)
    set(values_array "[]")
    if(ARGN)
        set(val_index 0)
        foreach(val ${ARGN})
            string(JSON values_array SET "${values_array}" "${val_index}" "\"${val}\"")
            math(EXPR val_index "${val_index} + 1")
        endforeach()
    endif()

    set(${OUTVAR} ${values_array} PARENT_SCOPE)
endfunction()

function(_create_help_target HELP_NAME JQ_FILE OUTFILE GROUP_NAME)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(target help_${HELP_NAME})

    set(cmd jq -L ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -r
               -f ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${JQ_FILE} ${outfile})
    set(DESCRIPTION "Help for ${HELP_NAME}")
    add_custom_target(${target}
        COMMAND ${cmd} --argjson termwidth \"$$\(tput cols\)\" --arg group \"${GROUP_NAME}\"
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET ${target} PROPERTY DESCRIPTION ${DESCRIPTION})
    set_property(TARGET ${target} APPEND PROPERTY SOCMAKE_GROUPS help)

    if(ARG_PRINT_ON_CONF)
        execute_process(COMMAND tput cols
            OUTPUT_VARIABLE TERM_WIDTH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE tput_result)
        if(tput_result)
            message(WARNING "tput failed with code ${tput_result}, using default width")
            set(TERM_WIDTH 150)
        endif()

        execute_process(
            COMMAND ${cmd} --argjson termwidth ${TERM_WIDTH} --arg group "${GROUP_NAME}"
        )
    endif()


endfunction()

function(help_options)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    get_property(ALL_OPTIONS GLOBAL PROPERTY SOCMAKE_OPTIONS)
    if(NOT ALL_OPTIONS)
        return()
    endif()
    
    # Start with empty options array
    set(options_array "[]")
    set(index 0)
    
    foreach(option ${ALL_OPTIONS})
        get_property(advanced GLOBAL PROPERTY SOCMAKE_${option}_ADVANCED)
        get_property(type GLOBAL PROPERTY SOCMAKE_${option}_TYPE)
        get_property(description GLOBAL PROPERTY SOCMAKE_${option}_DESCRIPTION)
        get_property(default GLOBAL PROPERTY SOCMAKE_${option}_DEFAULT)
        get_property(values GLOBAL PROPERTY SOCMAKE_${option}_VALUES)
        get_property(groups GLOBAL PROPERTY SOCMAKE_${option}_SOCMAKE_GROUPS)

        set(option_obj "{}")
        string(JSON option_obj SET "${option_obj}" "name" "\"${option}\"")
        string(JSON option_obj SET "${option_obj}" "type" "\"${type}\"")
        string(JSON option_obj SET "${option_obj}" "current" "\"${${option}}\"")
        string(JSON option_obj SET "${option_obj}" "default" "\"${default}\"")
        string(JSON option_obj SET "${option_obj}" "description" "\"${description}\"")
        string(JSON option_obj SET "${option_obj}" "advanced" "\"${advanced}\"")
        __cmake_to_json_array(values_json ${values})
        string(JSON option_obj SET "${option_obj}" "values" "${values_json}")
        __cmake_to_json_array(groups_json ${groups})
        string(JSON option_obj SET "${option_obj}" "groups" "${groups_json}")

        string(JSON options_array SET "${options_array}" "${index}" "${option_obj}")
        math(EXPR index "${index} + 1")
    endforeach()
    
    set(json_output "{}")
    string(JSON json_output SET "${json_output}" "options" "${options_array}")

    set(target help_options)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)
    file(WRITE ${outfile} ${json_output})

    _create_help_target("options" "option.jq" ${outfile} "*" ${ARG_PRINT_ON_CONF})

endfunction()


function(help_ips)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    get_all_ips(ALL_IPS)
    # if(NOT ALL_IPS)
    #     return()
    # endif()

    set(ips_array "[]")
    set(index 0)

    foreach(ip ${ALL_IPS})
        get_target_property(description ${ip} DESCRIPTION)
        if(NOT description)
            set(description "(no description)")
        endif()
        set(ip_obj "{}")

        get_target_property(groups ${ip} SOCMAKE_GROUPS)
        __cmake_to_json_array(groups_json ${groups})
        string(JSON ip_obj SET "${ip_obj}" "groups" "${groups_json}")

        string(JSON ip_obj SET "${ip_obj}" "name" "\"${ip}\"")
        string(JSON ip_obj SET "${ip_obj}" "description" "\"${description}\"")
        string(JSON ips_array SET "${ips_array}" "${index}" "${ip_obj}")
        math(EXPR index "${index} + 1")
    endforeach()

    set(json_output "{}")
    string(JSON json_output SET "${json_output}" "ips" "${ips_array}")

    set(target help_ips)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)
    file(WRITE ${outfile} ${json_output})

    _create_help_target("ips" "ip.jq" ${outfile} "*" ${ARG_PRINT_ON_CONF})
endfunction()

function(help_targets)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    # Create the target first, so it can be discovered by get_all_targets() function
    set(target help_targets)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)

    _create_help_target("targets" "target.jq" ${outfile} "*" ${ARG_PRINT_ON_CONF})

    # Now get all the targets and write to JSON
    get_all_targets(ALL_TARGETS)

    set(targets_array "[]")
    set(index 0)

    foreach(target ${ALL_TARGETS})
        get_target_property(type ${target} TYPE)
        if(NOT type STREQUAL UTILITY)
            continue()
        endif()

        get_target_property(description ${target} DESCRIPTION)
        if(NOT description)
            set(description "(no description)")
        endif()

        set(target_obj "{}")

        get_target_property(groups ${target} SOCMAKE_GROUPS)
        __cmake_to_json_array(groups_json ${groups})
        string(JSON target_obj SET "${target_obj}" "groups" "${groups_json}")

        string(JSON target_obj SET "${target_obj}" "name" "\"${target}\"")
        string(JSON target_obj SET "${target_obj}" "description" "\"${description}\"")
        string(JSON targets_array SET "${targets_array}" "${index}" "${target_obj}")
        math(EXPR index "${index} + 1")
    endforeach()

    set(json_output "{}")
    string(JSON json_output SET "${json_output}" "targets" "${targets_array}")
    file(WRITE ${outfile} ${json_output})

endfunction()


function(help_custom_targets GROUP_NAME)
    cmake_parse_arguments(ARG "DONT_MAKE_GROUP;PRINT_ON_CONF" "PATTERN;DESCRIPTION;HELP_TARGET_NAME" "LIST" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    if(NOT DEFINED ARG_DESCRIPTION)
        set(ARG_DESCRIPTION "Help for ${GROUP_NAME} targets")
    endif()

    if(NOT ARG_DONT_MAKE_GROUP)
        if(DEFINED ARG_PATTERN)
            set(ARG_PATTERN PATTERN ${ARG_PATTERN})
        endif()
        if(DEFINED ARG_LIST)
            set(ARG_LIST LIST ${ARG_LIST})
        endif()

        group_custom_targets("${GROUP_NAME}" ${ARG_PATTERN} ${ARG_LIST})
    endif()

    if(DEFINED ARG_HELP_TARGET_NAME)
        set(help_name ${ARG_HELP_TARGET_NAME})
    else()
        set(help_name ${GROUP_NAME})
    endif()

    set(outfile ${PROJECT_BINARY_DIR}/help/help_targets.json)

    _create_help_target("${help_name}" "target.jq" ${outfile} "${GROUP_NAME}" ${ARG_PRINT_ON_CONF})
endfunction()

function(help_custom_ips GROUP_NAME)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "PATTERN;DESCRIPTION" "LIST" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    if(NOT DEFINED ARG_DESCRIPTION)
        set(ARG_DESCRIPTION "Help for ${GROUP_NAME} IPs")
    endif()

    if(DEFINED ARG_PATTERN)
        set(ARG_PATTERN PATTERN ${ARG_PATTERN})
    endif()
    if(DEFINED ARG_LIST)
        set(ARG_LIST LIST ${ARG_LIST})
    endif()

    group_custom_ips("${GROUP_NAME}" ${ARG_PATTERN} ${ARG_LIST})

    set(outfile ${PROJECT_BINARY_DIR}/help/help_ips.json)

    _create_help_target("${GROUP_NAME}" "ip.jq" ${outfile} "${GROUP_NAME}" ${ARG_PRINT_ON_CONF})

endfunction()

function(help_custom_options GROUP_NAME)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "PATTERN;DESCRIPTION" "LIST" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    if(NOT DEFINED ARG_DESCRIPTION)
        set(ARG_DESCRIPTION "Help for ${GROUP_NAME} Options")
    endif()

    if(DEFINED ARG_PATTERN)
        set(ARG_PATTERN PATTERN ${ARG_PATTERN})
    endif()
    if(DEFINED ARG_LIST)
        set(ARG_LIST LIST ${ARG_LIST})
    endif()

    group_custom_options("${GROUP_NAME}" ${ARG_PATTERN} ${ARG_LIST})

    set(outfile ${PROJECT_BINARY_DIR}/help/help_options.json)

    _create_help_target("${GROUP_NAME}" "option.jq" ${outfile} "${GROUP_NAME}" ${ARG_PRINT_ON_CONF})

endfunction()


function(help)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    if(ARG_PRINT_ON_CONF)
        set(ARG_PRINT_ON_CONF PRINT_ON_CONF)
    endif()

    get_property(ALL_OPTIONS GLOBAL PROPERTY SOCMAKE_OPTIONS)


    help_ips(${ARG_PRINT_ON_CONF})
    help_options(${ARG_PRINT_ON_CONF})

    help_custom_targets("help" PATTERN "help_*" DONT_MAKE_GROUP HELP_TARGET_NAME "list")

    help_targets(${ARG_PRINT_ON_CONF})

    # get_property(HELP_TARGETS GLOBAL PROPERTY SOCMAKE_HELP_TARGETS)
    get_all_targets_of_group(help_targets "help")
    
    add_custom_target(help_all
        DEPENDS ${help_targets} help_ips help_options
        )

endfunction()
