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

function(help_options_json)
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
        
        set(option_obj "{}")
        string(JSON option_obj SET "${option_obj}" "name" "\"${option}\"")
        string(JSON option_obj SET "${option_obj}" "type" "\"${type}\"")
        string(JSON option_obj SET "${option_obj}" "current" "\"${${option}}\"")
        string(JSON option_obj SET "${option_obj}" "default" "\"${default}\"")
        string(JSON option_obj SET "${option_obj}" "description" "\"${description}\"")
        string(JSON option_obj SET "${option_obj}" "advanced" "\"${advanced}\"")
        __cmake_to_json_array(values_json ${values})
        string(JSON option_obj SET "${option_obj}" "values" "${values_json}")
        
        string(JSON options_array SET "${options_array}" "${index}" "${option_obj}")
        math(EXPR index "${index} + 1")
    endforeach()
    
    set(json_output "{}")
    string(JSON json_output SET "${json_output}" "options" "${options_array}")

    set(target help_options_json)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)
    file(WRITE ${outfile} ${json_output})

    set(cmd jq -L ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -r -f ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/option.jq ${outfile})
    add_custom_target(${target}
        COMMAND ${cmd}
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET ${target} PROPERTY DESCRIPTION ${DESCRIPTION})
    set_property(GLOBAL APPEND PROPERTY SOCMAKE_HELP_TARGETS ${target})
endfunction()


function(help_ips_json)
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

    set(target help_ips_json)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)
    file(WRITE ${outfile} ${json_output})

    set(cmd jq -L ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -r -f ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/ip.jq ${outfile})
    add_custom_target(${target}
        COMMAND ${cmd}
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET ${target} PROPERTY DESCRIPTION ${DESCRIPTION})
    set_property(GLOBAL APPEND PROPERTY SOCMAKE_HELP_TARGETS ${target})
endfunction()

function(help_targets_json)
    get_all_targets(ALL_TARGETS)
    # if(NOT ALL_IPS)
    #     return()
    # endif()

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

    set(target help_targets_json)
    set(outfile ${PROJECT_BINARY_DIR}/help/${target}.json)
    file(WRITE ${outfile} ${json_output})

    set(cmd jq -L ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -r -f ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/target.jq ${outfile})
    add_custom_target(${target}
        COMMAND ${cmd}
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET ${target} PROPERTY DESCRIPTION ${DESCRIPTION})
    set_property(GLOBAL APPEND PROPERTY SOCMAKE_HELP_TARGETS ${target})
endfunction()


function(group_custom_targets GROUP_NAME)
    cmake_parse_arguments(ARG "PRINT_ON_CONF;EXCLUDE_FROM_HELP_ALL" "PATTERN;DESCRIPTION" "TARGET_LIST" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PATTERN AND ARG_TARGET_LIST)
        message(FATAL_ERROR "Arguments PATTERN and TARGET_LIST cannot be used at the same time")
    endif()

    if(ARG_PATTERN)
        get_all_targets(all_targets)
        list(FILTER all_targets INCLUDE REGEX "${ARG_PATTERN}")
        set(targets ${all_targets})
    elseif(ARG_TARGET_LIST)
        set(targets ${ARG_TARGET_LIST})
    else()
        message(FATAL_ERROR "Specify either PATTERN or TARGET_LIST arguments")
    endif()

    if(NOT targets)
        message(WARNING "No targets found for PATTERN: ${ARG_PATTERN} or TARGET_LIST: ${ARG_TARGET_LIST}")
        return()
    endif()

    foreach(target ${targets})
        set_property(TARGET ${target} APPEND PROPERTY SOCMAKE_GROUPS ${GROUP_NAME})
    endforeach()

    set(target help_${GROUP_NAME}_json)
    set(outfile ${PROJECT_BINARY_DIR}/help/help_targets_json.json)

    set(cmd jq -L ${CMAKE_CURRENT_FUNCTION_LIST_DIR} -r
               --arg group \"${GROUP_NAME}\"
               -f ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/target.jq ${outfile})
    add_custom_target(${target}
        COMMAND ${cmd}
        COMMENT ${ARG_DESCRIPTION}
        )
    set_property(TARGET ${target} PROPERTY DESCRIPTION ${DESCRIPTION})
    set_property(TARGET ${target} APPEND PROPERTY SOCMAKE_GROUPS help)

endfunction()
