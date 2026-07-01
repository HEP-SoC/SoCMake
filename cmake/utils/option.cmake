#[[[ @module option
#]]
include("${CMAKE_CURRENT_LIST_DIR}/socmake_message.cmake")

# This function is used to easily create new options, and is used in the new options function.
#
# :param NAME: name of the variable.
# :type NAME: string
# :param TYPE: type of the variable
# :type TYPE: string
# :param DESCRIPTION: short description string for the variable
# :type DESCRIPTION: string
# :param DEFAULT: default value of the variable
# :type DEFAULT: integer
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type ADVANCED: boolean
# :param POSSIBLE_VALUES: possible values variable can have
# :type POSSIBLE_VALUES: list[string]
function(
    __define_socmake_option
    NAME
    TYPE
    DESCRIPTION
    DEFAULT
    ADVANCED
)
    cmake_parse_arguments(ARG "" "" "POSSIBLE_VALUES" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_DESCRIPTION "${DESCRIPTION}")
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_TYPE ${TYPE})
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_DEFAULT ${DEFAULT})
    set_property(GLOBAL PROPERTY SOCMAKE_${NAME}_ADVANCED ${ADVANCED})
    if(ARG_POSSIBLE_VALUES)
        set_property(
            GLOBAL
            PROPERTY SOCMAKE_${NAME}_VALUES ${ARG_POSSIBLE_VALUES}
        )
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
# :type ADVANCED: boolean
#]]
function(option_enum VARIABLE DESCRIPTION ENUM_VALUES DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    __define_socmake_option(${VARIABLE} "Enum" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED} POSSIBLE_VALUES "${ENUM_VALUES}")

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
    set_property(CACHE ${VARIABLE} PROPERTY STRINGS "${ENUM_VALUES}")
    if(NOT ${VARIABLE})
        set(${VARIABLE} ${DEFAULT})
        set(${VARIABLE} ${DEFAULT} PARENT_SCOPE)
    endif()
    if(NOT "${${VARIABLE}}" IN_LIST ENUM_VALUES)
        socmake_message(FATAL_ERROR "The VARIABLE \"${VARIABLE}\" has an unknown value: ${${VARIABLE}}\nPossible values are: ${ENUM_VALUES}")
    endif()
endfunction()

#[[[
# Create a CMake string option that can be modified through CLI.
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
# :type ADVANCED: bool
#]]
function(option_string VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "String" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
endfunction()

#[[[
# Create a CMake file path option that can be modified through CLI.
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
# :type ADVANCED: bool
# :param CHECK_EXISTS: optional, check if the file path exists at the time of configuring the project, default FALSE
# :type CHECK_EXISTS: bool
#]]
function(option_file VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED;CHECK_EXISTS" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "File" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE FILEPATH "${DESCRIPTION}")

    if(ARG_CHECK_EXISTS)
        if(NOT EXISTS ${${VARIABLE}})
            socmake_message(FATAL_ERROR "The path \"${${VARIABLE}}\" provided by configuration option ${VARIABLE} does not exist in the filesystem")
        endif()
    endif()
endfunction()

#[[[
# Create a CMake directory path option that can be modified through CLI.
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
# :type ADVANCED: bool
# :param CHECK_EXISTS: optional, check if the directory path exists at the time of configuring the project, default FALSE
# :type CHECK_EXISTS: bool
#]]
function(option_directory VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED;CHECK_EXISTS" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "Directory" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE PATH "${DESCRIPTION}")

    if(ARG_CHECK_EXISTS)
        if(NOT EXISTS ${${VARIABLE}})
            socmake_message(FATAL_ERROR "The path \"${${VARIABLE}}\" provided by configuration option ${VARIABLE} does not exist in the filesystem")
        endif()
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
# :type DEFAULT: integer
# :param ADVANCED: optional, mark options as advanced, it will not show in help menu
# :type ADVANCED: boolean
#]]
function(option_integer VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "Integer" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED})

    set(${VARIABLE} ${DEFAULT} CACHE STRING "${DESCRIPTION}")
    if(NOT ${${VARIABLE}} MATCHES "^[0-9]+$")
        socmake_message(FATAL_ERROR "The value of option \"${VARIABLE}\" must be a non-negative integer.")
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
# :type ADVANCED: boolean
#]]
function(option_boolean VARIABLE DESCRIPTION DEFAULT)
    cmake_parse_arguments(ARG "ADVANCED" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        socmake_message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    __define_socmake_option(${VARIABLE} "Boolean" ${DESCRIPTION} ${DEFAULT} ${ARG_ADVANCED} POSSIBLE_VALUES "ON;OFF")

    option(${VARIABLE} ${DESCRIPTION} ${DEFAULT})
endfunction()
