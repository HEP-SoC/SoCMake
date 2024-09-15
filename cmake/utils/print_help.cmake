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
            __get_target_help(HELP_ROW ${target} ${DESCRIPTION} ${MAX_LEN})
            string(APPEND OUT_STRING ${HELP_ROW}) 
        endif()
    endforeach()
    __get_target_help(HELP_ROW help_targets "Print targets help" ${MAX_LEN})
    string(APPEND OUT_STRING ${HELP_ROW}) 
    __get_target_help(HELP_ROW help "CMake native help" ${MAX_LEN})
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

    math(EXPR padding_length "${MAX_LEN} + 14")
    string(REPEAT " " ${padding_length} padding)
    string(APPEND OUT_STRING "${Yellow}Target${padding}Description${ColourReset}\n")
    math(EXPR line_length "${MAX_LEN} + 50")
    string(REPEAT "-" ${line_length} line)
    string(APPEND OUT_STRING "${line}\n")

    foreach(target ${ALL_TARGETS})
        get_target_property(TYPE ${target} TYPE)

        if(TYPE STREQUAL INTERFACE_LIBRARY)
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

    help_ips(${ARG_PRINT_ON_CONF})
    help_targets(${ARG_PRINT_ON_CONF})

    add_custom_target(help_all
        DEPENDS help_targets help_ips
        )

endfunction()
