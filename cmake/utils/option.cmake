function(__define_socmake_option NAME TYPE DESCRIPTION DEFAULT ADVANCED)
    cmake_parse_arguments(ARG "" "" "POSSIBLE_VALUES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_DESCRIPTION "${DESCRIPTION}")
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_TYPE ${TYPE})
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_DEFAULT ${DEFAULT})
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_ADVANCED ${ADVANCED})
    if(ARG_POSSIBLE_VALUES)
        set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_VALUES ${ARG_POSSIBLE_VALUES})
    endif()
    if(ADVANCED)
        mark_as_advanced(${NAME})
    endif()
    set_property(GLOBAL APPEND PROPERTY SOCMAKE_OPTIONS ${NAME})
endfunction()

#[[[
# Create a CMake integer option that can be modified through CLI.
# Option defined this way will be visible in `cmake-gui` interface as well as SoCMake `help_options()` help menu.
# To override the variable use `cmake -D<VARIABLE>=<VALUE>`
#
# :param VARIABLE: name of the variable.
# :type VARIABLE: string
# :param DESCRIPTION: short description string for the variable
# :type DESCRIPTION: string
# :param ENUM_VALUES: possible values variable can have 
# :type ENUM_VALUES: list[string]
# :param DEFAULT: default value of the variable
# :type DEFAULT: integer 
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type DEFAULT: boolean
#]]
function(option_enum VARIABLE DESCRIPTION ENUM_VALUES DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    __define_socmake_option(${VARIABLE} "Enum" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED} POSSIBLE_VALUES "${ENUM_VALUES}")

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
    set_property(CACHE ${VARIABLE} PROPERTY STRINGS "${ENUM_VALUES}")
    if(NOT ${VARIABLE})
        set(${VARIABLE} ${DEFAULT})
        set(${VARIABLE} ${DEFAULT} PARENT_SCOPE)
    endif()
    if(NOT "${${VARIABLE}}" IN_LIST ENUM_VALUES)
        message(FATAL_ERROR "The VARIABLE \"${VARIABLE}\" has an unknown value: ${${VARIABLE}}\nPossible values are: ${ENUM_VALUES}")
    endif()
endfunction()

#[[[
# Create a CMake integer option that can be modified through CLI.
# Option defined this way will be visible in `cmake-gui` interface as well as SoCMake `help_options()` help menu.
# To override the variable use `cmake -D<VARIABLE>=<VALUE>`
#
# :param VARIABLE: name of the variable.
# :type VARIABLE: string
# :param DESCRIPTION: short description string for the variable
# :type DESCRIPTION: string
# :param DEFAULT: default value of the variable
# :type DEFAULT: string 
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type DEFAULT: boolean
#]]
function(option_string VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "String" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
endfunction()

#[[[
# Create a CMake integer option that can be modified through CLI.
# Option defined this way will be visible in `cmake-gui` interface as well as SoCMake `help_options()` help menu.
# To override the variable use `cmake -D<VARIABLE>=<VALUE>`
#
# :param VARIABLE: name of the variable.
# :type VARIABLE: string
# :param DESCRIPTION: short description string for the variable
# :type DESCRIPTION: string
# :param DEFAULT: default value of the variable
# :type DEFAULT: integer 
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type DEFAULT: boolean
#]]
function(option_integer VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "Integer" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
    if(NOT ${${VARIABLE}} MATCHES "^[0-9]+$")
        message(FATAL_ERROR "The value of option \"${VARIABLE}\" must be a non-negative integer.")
    endif()
endfunction()

#[[[
# Create a CMake boolean option that can be modified through CLI.
# Option defined this way will be visible in `cmake-gui` interface as well as SoCMake `help_options()` help menu.
# To override the variable use `cmake -D<VARIABLE>=<VALUE>`
#
# :param VARIABLE: name of the variable.
# :type VARIABLE: string
# :param DESCRIPTION: short description string for the variable
# :type DESCRIPTION: string
# :param DEFAULT: default value of the variable
# :type DEFAULT: boolean 
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type DEFAULT: boolean
#]]
function(option_boolean VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "Boolean" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED} POSSIBLE_VALUES "ON;OFF")

    option(${VARIABLE} ${DESCRIPTION} ${DEFAULT})
endfunction()
