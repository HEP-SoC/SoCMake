#[[[ @module groups
#]]
include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")

# This functions can be used to create a a custom group of selected items, with a selected types. It will mainy be called by other function in this file, to create groups.
#
# One of the argument must be used to fill the group, but, it's not possible to use the argument Pattern and List at the same time.
#
# :param GROUP_NAME: Name of the group that needs to be created.
# :type GROUP_NAME: string
# :param TYPE: Type of group, can be TARGET, IP or OPTION.
# :type TYPE: string
#
# **Keyword Arguments**
#
# :keyword PATTERN: if a pattern is given, the item in the group list will be filtered and they must have the pattern to be included
# :type PATTERN: string
# :keyword LIST: if a list is given, the item in the group list are the one given in the list.
# :type LIST: list[string]
function(_group_custom_items GROUP_NAME TYPE)
    cmake_parse_arguments(ARG "" "PATTERN" "LIST" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_PATTERN AND ARG_LIST)
        socmake_message(FATAL_ERROR "Arguments PATTERN and LIST cannot be used at the same time")
    endif()

    # Filter items based on PATTERN or LIST
    if(ARG_PATTERN)
        if(TYPE STREQUAL "TARGET")
            get_all_targets(all_items)
        elseif(TYPE STREQUAL "IP")
            get_all_ips(all_items)
        elseif(TYPE STREQUAL "OPTION")
            get_property(all_items GLOBAL PROPERTY SOCMAKE_OPTIONS)
        endif()
        list(FILTER all_items INCLUDE REGEX "${ARG_PATTERN}")
        set(items ${all_items})
    elseif(ARG_LIST)
        set(items ${ARG_LIST})
    else()
        socmake_message(FATAL_ERROR "Specify either PATTERN or LIST arguments")
    endif()

    if(NOT items)
        socmake_message(WARNING "No items found for PATTERN: ${ARG_PATTERN} or LIST: ${ARG_LIST}")
        return()
    endif()

    # Append the GROUP_NAME to SOCMAKE_GROUPS property of the item
    foreach(item ${items})
        if(TYPE STREQUAL "OPTION")
            set_property(
                GLOBAL
                PROPERTY SOCMAKE_${item}_SOCMAKE_GROUPS "${GROUP_NAME}"
            )
        else()
            set_property(
                TARGET ${item}
                APPEND
                PROPERTY SOCMAKE_GROUPS ${GROUP_NAME}
            )
        endif()
    endforeach()
endfunction()

#[[[
# This function can be used to create a custom group for targets.
#
# :param GROUP_NAME: Name of the group that needs to be created.
# :type GROUP_NAME: string
#
# **Keyword Arguments**
#
# :keyword PATTERN: if a pattern is given, the targets in the group list will be filtered and they must have the pattern to be included
# :type PATTERN: string
# :keyword LIST: if a list is given, the target in the group list are the one given in the list.
# :type LIST: list[string]
#]]
function(group_custom_targets GROUP_NAME)
    _group_custom_items(${GROUP_NAME} TARGET ${ARGN})
endfunction()

#[[[
# This function can be used to create a custom group for IPs.
#
# :param GROUP_NAME: Name of the group that needs to be created.
# :type GROUP_NAME: string
#
# **Keyword Arguments**
#
# :keyword PATTERN: if a pattern is given, the IPs in the group list will be filtered and they must have the pattern to be included
# :type PATTERN: string
# :keyword LIST: if a list is given, the IPs in the group list are the one given in the list.
# :type LIST: list[string]
#]]
function(group_custom_ips GROUP_NAME)
    _group_custom_items(${GROUP_NAME} IP ${ARGN})
endfunction()

#[[[
# This function can be used to create a custom group for options.
#
# :param GROUP_NAME: Name of the group that needs to be created.
# :type GROUP_NAME: string
#
# **Keyword Arguments**
#
# :keyword PATTERN: if a pattern is given, the options in the group list will be filtered and they must have the pattern to be included
# :type PATTERN: string
# :keyword LIST: if a list is given, the options in the group list are the one given in the list.
# :type LIST: list[string]
#]]
function(group_custom_options GROUP_NAME)
    _group_custom_items(${GROUP_NAME} OPTION ${ARGN})
endfunction()

#[[[
# This function can be used to find all the target belonging to a given group. The output list will be stored in the OUTVAR argument.
#
# :param OUTVAR: List containing the targets found.
# :type OUTVAR: list[string]
# :param GROUP_NAME: Name of the group to get the target from.
# :type GROUP_NAME: string
#]]
function(get_all_targets_of_group OUTVAR GROUP_NAME)
    get_all_targets(all_targets)
    set(filtered_targets)
    foreach(target ${all_targets})
        get_property(target_groups TARGET ${target} PROPERTY SOCMAKE_GROUPS)
        if(${GROUP_NAME} IN_LIST target_groups)
            list(APPEND filtered_targets ${target})
        endif()
    endforeach()
    set(${OUTVAR} ${filtered_targets} PARENT_SCOPE)
endfunction()
