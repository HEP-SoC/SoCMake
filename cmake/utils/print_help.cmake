include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/get_all_targets.cmake)


function(__find_longest_target_name TYPE OUTVAR)
    set(__max_length 0)
    foreach(target ${ARGN})
        get_target_property(type ${target} TYPE)
        if(type STREQUAL ${TYPE})
            string(LENGTH ${target} target_length)
            if(${target_length} GREATER ${__max_length})
                set(__max_length ${target_length})
            endif()
        endif()
    endforeach()
    set(${OUTVAR} ${__max_length} PARENT_SCOPE)
endfunction()

function(__find_longest_string OUTVAR)
    set(__max_length 0)
    foreach(var ${ARGN})
        string(LENGTH ${var} str_length)
        if(${str_length} GREATER ${__max_length})
            set(__max_length ${str_length})
        endif()
    endforeach()
    set(${OUTVAR} ${__max_length} PARENT_SCOPE)
endfunction()

function(__get_target_help OUTVAR TARGET DESCRIPTION COL_WIDTH)

    # Get the length of the target string
    string(LENGTH ${TARGET} target_length)

    # Calculate the number of spaces needed to align the description
    math(EXPR padding_length "${COL_WIDTH} + 20 - ${target_length}")

    # Generate the padding spaces
    string(REPEAT " " ${padding_length} padding)

    if(DESCRIPTION STREQUAL DESCRIPTION-NOTFOUND)
        set(DESCRIPTION "${Red}DESCRIPTION-NOTFOUND${ColourReset}")
    endif()
    # Print the target with description aligned
    set(${OUTVAR} "${Cyan}${TARGET}${ColourReset}${padding}${DESCRIPTION}\n" PARENT_SCOPE)
endfunction()

# [[[
# This function creates a help target for printing target information.
#
# The build subdirectories will be recursively searched for targets.
#
# It should be called only once in the build flow.
#
# Preferably at the end of the CMakeLists.txt
#
# In order to run it only once at the top level, following trick can be used.
#```
# if(PROJECT_IS_TOP_LEVEL)
#   help_targets()
# endif()
#```
#
# **Keyword Arguments**
#
# :keyword PRINT_ON_CONF: Print the help message during configure phase
# :type PRINT_ON_CONF: boolean
# ]]]
function(help_targets)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/colours.cmake)

    unset(OUT_STRING)
    string(APPEND OUT_STRING "${Yellow}Available Targets:${ColourReset}\n")
    string(APPEND OUT_STRING "------------------\n")
    string(APPEND OUT_STRING "\n")

    get_all_targets(ALL_TARGETS)
    __find_longest_target_name(UTILITY MAX_LEN ${ALL_TARGETS})

    math(EXPR padding_length "${MAX_LEN} + 14")
    string(REPEAT " " ${padding_length} padding)
    string(APPEND OUT_STRING "${Yellow}Target${padding}Description${ColourReset}\n")
    math(EXPR line_length "${MAX_LEN} + 50")
    string(REPEAT "-" ${line_length} line)
    string(APPEND OUT_STRING "${line}\n")

    foreach(target ${ALL_TARGETS})
        get_target_property(TYPE ${target} TYPE)
        if(TYPE STREQUAL UTILITY)
            get_target_property(DESCRIPTION ${target} DESCRIPTION)
            __get_target_help(HELP_ROW "${target}" "${DESCRIPTION}" "${MAX_LEN}")
            string(APPEND OUT_STRING ${HELP_ROW}) 
        endif()
    endforeach()
    __get_target_help(HELP_ROW help_targets "Print targets help" "${MAX_LEN}")
    string(APPEND OUT_STRING ${HELP_ROW}) 
    __get_target_help(HELP_ROW help "CMake native help" "${MAX_LEN}")
    string(APPEND OUT_STRING ${HELP_ROW}) 
    string(APPEND OUT_STRING "${line}\n")

    if(ARG_PRINT_ON_CONF)
        message("${OUT_STRING}")
    endif()

    file(WRITE ${PROJECT_BINARY_DIR}/help_targets.txt ${OUT_STRING})
    add_custom_target(help_targets
        COMMAND cat ${PROJECT_BINARY_DIR}/help_targets.txt
        COMMENT "Print targets help"
        )

endfunction()

# [[[
# This function creates a help target for printing IPs information.
#
# The build subdirectories will be recursively searched for targets.
#
# It should be called only once in the build flow.
#
# Preferably at the end of the CMakeLists.txt
#
# In order to run it only once at the top level, following trick can be used.
#```
# if(PROJECT_IS_TOP_LEVEL)
#   help_ips()
# endif()
#```
#
# **Keyword Arguments**
#
# :keyword PRINT_ON_CONF: Print the help message during configure phase
# :type PRINT_ON_CONF: boolean
# ]]]
function(help_ips)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/colours.cmake)

    unset(OUT_STRING)
    string(APPEND OUT_STRING "${Yellow}Available IPs:${ColourReset}\n")
    string(APPEND OUT_STRING "------------------\n")
    string(APPEND OUT_STRING "\n")

    get_all_targets(ALL_TARGETS)
    __find_longest_target_name(INTERFACE_LIBRARY MAX_LEN ${ALL_TARGETS})

    math(EXPR padding_length "${MAX_LEN} + 18")
    string(REPEAT " " ${padding_length} padding)
    string(APPEND OUT_STRING "${Yellow}IP${padding}Description${ColourReset}\n")
    math(EXPR line_length "${MAX_LEN} + 50")
    string(REPEAT "-" ${line_length} line)
    string(APPEND OUT_STRING "${line}\n")

    foreach(target ${ALL_TARGETS})
        get_target_property(ip_name ${target} IP_NAME)
        if(ip_name) # IP_NAME property is always set for SoCMakes IP library, to differentiate from INTERFACE_LIBRARIES
            get_target_property(DESCRIPTION ${target} DESCRIPTION)
            __get_target_help(HELP_ROW ${target} ${DESCRIPTION} ${MAX_LEN})
            string(REPLACE "__" "::" HELP_ROW ${HELP_ROW})
            string(APPEND OUT_STRING ${HELP_ROW})
        endif()
    endforeach()
    string(APPEND OUT_STRING "${line}\n")

    if(ARG_PRINT_ON_CONF)
        message("${OUT_STRING}")
    endif()

    set(DESCRIPTION "Print IPs help")
    file(WRITE ${PROJECT_BINARY_DIR}/help_ips.txt ${OUT_STRING})
    add_custom_target(help_ips
        COMMAND cat ${PROJECT_BINARY_DIR}/help_ips.txt
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET help_ips PROPERTY DESCRIPTION ${DESCRIPTION})
endfunction()

function(__get_help_option_string OUTSTR VALUE MAX_STR_LEN)
    cmake_parse_arguments(ARG "" "COLOUR" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    string(LENGTH ${VALUE} option_len)
    math(EXPR padding_len "${MAX_STR_LEN} - ${option_len}")
    string(REPEAT " " ${padding_len} padding)

    set(__out_str ${${ARG_COLOUR}}${VALUE}${ColourReset}${padding})

    set(${OUTSTR} ${__out_str} PARENT_SCOPE)
endfunction()

# [[[
# This function creates a help target for printing CMake options information.
# The options need to be added with the SoCMake options_boolean/options_integer/options_string/options_enum functions.
#
# It should be called only once in the build flow.
#
# Preferably at the end of the CMakeLists.txt
#
# In order to run it only once at the top level, following trick can be used.
#```
# if(PROJECT_IS_TOP_LEVEL)
#   help_options()
# endif()
#```
#
# **Keyword Arguments**
#
# :keyword PRINT_ON_CONF: Print the help message during configure phase
# :type PRINT_ON_CONF: boolean
# ]]]
function(help_options)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/colours.cmake)

    unset(OUT_STRING)
    string(APPEND OUT_STRING "${Yellow}Available Options:${ColourReset}\n")
    string(APPEND OUT_STRING "------------------\n")
    string(APPEND OUT_STRING "\n")

    get_property(ALL_OPTIONS GLOBAL PROPERTY SOCMAKE_OPTIONS)
    # get_all_targets(ALL_TARGETS)
    __find_longest_string(MAX_OPTIONS_LEN "Option;${ALL_OPTIONS}")

    unset(list_defaults)
    unset(list_possible_values)
    unset(list_curr_values)
    foreach(option ${ALL_OPTIONS})
        get_property(default GLOBAL PROPERTY SOCMAKE_${option}_DEFAULT)
        list(APPEND list_defaults ${default})

        get_property(values GLOBAL PROPERTY SOCMAKE_${option}_VALUES)
        string(REPLACE ";" "," values "${values}")
        list(APPEND list_possible_values ${values})

        list(APPEND list_curr_values ${${option}})
    endforeach()
    __find_longest_string(MAX_DEFAULT_LEN "Default;${list_defaults}")
    __find_longest_string(MAX_POSSIBLE_VALUES_LEN "Values;${list_possible_values}")
    __find_longest_string(MAX_CURRENT_VALUES_LEN "Current value;${list_curr_values}")

    math(EXPR option_str_space "${MAX_OPTIONS_LEN} + 5") # 5 is spacing
    math(EXPR option_padding_len "${option_str_space} - 6") # 6 is len of "Option"
    string(REPEAT " " ${option_padding_len} padding_option)

    __find_longest_string(MAX_TYPE_LEN "Type;Boolean;String;Integer;Enum")
    math(EXPR type_str_space "${MAX_TYPE_LEN} + 5")
    math(EXPR type_padding_len "${type_str_space} - 4") # 4 is len of "Type"
    string(REPEAT " " ${type_padding_len} padding_type)

    math(EXPR current_value_str_space "${MAX_CURRENT_VALUES_LEN} + 5")
    math(EXPR current_value_padding_len "${current_value_str_space} - 13") # 7 is len of "Current Value"
    string(REPEAT " " ${current_value_padding_len} padding_current_value)

    math(EXPR default_str_space "${MAX_DEFAULT_LEN} + 5")
    math(EXPR default_padding_len "${default_str_space} - 7") # 7 is len of "Default"
    string(REPEAT " " ${default_padding_len} padding_default)

    math(EXPR possible_values_str_space "${MAX_POSSIBLE_VALUES_LEN} + 7")
    math(EXPR possible_values_padding_len "${possible_values_str_space} - 6") # 6 is len of "Values"
    string(REPEAT " " ${possible_values_padding_len} padding_possible_values)

    string(APPEND OUT_STRING "${Yellow}Option${padding_option}Type${padding_type}Current value${padding_current_value}Default${padding_default}Values${padding_possible_values}Description${ColourReset}\n")
    math(EXPR line_length "${MAX_OPTIONS_LEN} + 100")
    string(REPEAT "-" ${line_length} line)
    string(APPEND OUT_STRING "${line}\n")

    foreach(option ${ALL_OPTIONS})
        get_property(advanced GLOBAL PROPERTY SOCMAKE_${option}_ADVANCED)
        if(NOT advanced OR SOCMAKE_ADVANCED_OPTIONS_HELP)
            get_property(type GLOBAL PROPERTY SOCMAKE_${option}_TYPE)
            get_property(description GLOBAL PROPERTY SOCMAKE_${option}_DESCRIPTION)
            get_property(default GLOBAL PROPERTY SOCMAKE_${option}_DEFAULT)
            get_property(values GLOBAL PROPERTY SOCMAKE_${option}_VALUES)

            __get_help_option_string(__out_str ${option} ${option_str_space} COLOUR Cyan)
            string(APPEND OUT_STRING ${__out_str})

            __get_help_option_string(__out_str ${type} ${type_str_space})
            string(APPEND OUT_STRING ${__out_str})

            __get_help_option_string(__out_str ${${option}} ${current_value_str_space})
            string(APPEND OUT_STRING ${__out_str})

            __get_help_option_string(__out_str ${default} ${default_str_space})
            string(APPEND OUT_STRING ${__out_str})

            if(values)
                set(values "[${values}]")
                string(REPLACE ";" "," values "${values}")
            else()
                set(values " ")
            endif()

            __get_help_option_string(__out_str ${values} ${possible_values_str_space})
            string(APPEND OUT_STRING ${__out_str})

            string(APPEND OUT_STRING "${description}\n")
        endif()

    endforeach()
    string(APPEND OUT_STRING "${line}\n")

    if(ARG_PRINT_ON_CONF)
        message("${OUT_STRING}")
    endif()

    set(DESCRIPTION "Print Options help")
    file(WRITE ${PROJECT_BINARY_DIR}/help_options.txt ${OUT_STRING})
    add_custom_target(help_options
        COMMAND cat ${PROJECT_BINARY_DIR}/help_options.txt
        COMMENT ${DESCRIPTION}
        )
    set_property(TARGET help_options PROPERTY DESCRIPTION ${DESCRIPTION})
endfunction()

# [[[
# This function creates a custom help target called help_<HELP_NAME>.
#
# It can be called multiple times the build flow to create custom help messages
# for a given list of targets.
#
#```
#
# **Keyword Arguments**
#
# :keyword PRINT_ON_CONF: Print the help message during configure phase
# :type PRINT_ON_CONF: boolean
# :keyword TARGET_LIST: List of targets to include in the help message
# :type TARGET_LIST: list
# ]]]
function(help_custom_targets HELP_NAME)
    cmake_parse_arguments(ARG "PRINT_ON_CONF" "" "TARGET_LIST" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/colours.cmake)

    if(NOT ARG_TARGET_LIST)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} requires TARGET_LIST argument")
    endif()

    if (TARGET help_${HELP_NAME})
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called multiple times for the same HELP_NAME: ${HELP_NAME}")
    endif()

    unset(OUT_STRING)
    string(APPEND OUT_STRING "${Yellow}Available ${HELP_NAME} Targets:${ColourReset}\n")
    string(APPEND OUT_STRING "------------------\n")
    string(APPEND OUT_STRING "\n")

    __find_longest_target_name(UTILITY MAX_LEN ${ARG_TARGET_LIST})

    math(EXPR padding_length "${MAX_LEN} + 14")
    string(REPEAT " " ${padding_length} padding)
    string(APPEND OUT_STRING "${Yellow}${HELP_NAME} Target${padding}Description${ColourReset}\n")
    math(EXPR line_length "${MAX_LEN} + 50")
    string(REPEAT "-" ${line_length} line)
    string(APPEND OUT_STRING "${line}\n")

    foreach(target ${ARG_TARGET_LIST})
        get_target_property(TYPE ${target} TYPE)
        if(TYPE STREQUAL UTILITY)
            get_target_property(DESCRIPTION ${target} DESCRIPTION)
            __get_target_help(HELP_ROW ${target} ${DESCRIPTION} ${MAX_LEN})
            string(APPEND OUT_STRING ${HELP_ROW})
        endif()
    endforeach()
    __get_target_help(HELP_ROW help_${HELP_NAME} "Print ${HELP_NAME} targets help" ${MAX_LEN})
    string(APPEND OUT_STRING ${HELP_ROW})
    string(APPEND OUT_STRING "${line}\n")

    if(ARG_PRINT_ON_CONF)
        message("${OUT_STRING}")
    endif()

    file(WRITE ${PROJECT_BINARY_DIR}/help_${HELP_NAME}.txt ${OUT_STRING})
    add_custom_target(help_${HELP_NAME}
        COMMAND cat ${PROJECT_BINARY_DIR}/help_${HELP_NAME}.txt
        COMMENT "Print targets help"
        )

endfunction()

# [[[
# This function creates a help target for printing target and IPs information.
#
# The build subdirectories will be recursively searched for targets.
#
# It should be called only once in the build flow.
#
# Preferably at the end of the CMakeLists.txt
#
# In order to run it only once at the top level, following trick can be used.
#```
# if(PROJECT_IS_TOP_LEVEL)
#   help()
# endif()
#```
#
# **Keyword Arguments**
#
# :keyword PRINT_ON_CONF: Print the help message during configure phase
# :type PRINT_ON_CONF: boolean
# ]]]
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
    help_targets(${ARG_PRINT_ON_CONF})

    add_custom_target(help_all
        DEPENDS help_targets help_ips
        )

    if(ALL_OPTIONS)
        help_options(${ARG_PRINT_ON_CONF})
        add_dependencies(help_all help_options)
    endif()

endfunction()
