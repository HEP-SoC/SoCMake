
include("${CMAKE_CURRENT_LIST_DIR}/utils/socmake_graph.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/utils/alias_dereference.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/utils/safe_get_target_property.cmake")

#[[[
# This function creates an INTERFACE library for a given IP.
#
# This function is a wrapper around the cmake built-in
# `add_library() <https://cmake.org/cmake/help/latest/command/add_library.html>`_ function.
# It generates the library name using the vendor, library, name, and version (VLNV) information passed
# in arguments (see get_ipname()). It creates two alias libraries to the default <vendor>__<library>__<name>__<version>:
#
# * <vendor>::<library>::<name>::<version> ('__' replaced by '::')
# * <vendor>::<library>::<name> (short name without the version)
#
# :param IP_NAME: The name of the IP.
# :type IP_NAME: string
#
# **Keyword Arguments**
#
# :keyword VENDOR: Name of the IP vendor.
# :type VENDOR: string
# :keyword LIBRARY: Name of the IP library.
# :type LIBRARY: string
# :keyword VERSION: Version of the IP following a three-part version number (Major.Minor.Patch, e.g., 1.0.13).
# :type VERSION: string
#]]
function(add_ip IP_NAME)
    cmake_parse_arguments(ARG "" "VERSION;DESCRIPTION;VENDOR;LIBRARY" "" ${ARGN})

    # Vendor and library arguments are expected at the minimum
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                            "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    # Issue a warning if one of the VLNV information is not passed (this triggers an error later anyway)
    if((NOT ARG_VERSION OR NOT ARG_VENDOR OR NOT ARG_LIBRARY) AND NOT SOCMAKE_NOWARN_VLNV)
    message(WARNING "Consider using full VLNV format\n\
                    IP block: ${IP_NAME}\n\
                    VENDOR: ${ARG_VENDOR}\n\
                    LIBRARY: ${ARG_LIBRARY}\n\
                    VERSION: ${ARG_VERSION}")
    endif()
    # Create the IP unique name using VLNV information
    get_ipname(IP_LIB ${IP_NAME} VENDOR "${ARG_VENDOR}" LIBRARY "${ARG_LIBRARY}" VERSION "${ARG_VERSION}")

    if(NOT TARGET ${IP_LIB})
        add_library(${IP_LIB} INTERFACE)

        string(REPLACE "__" "::" ALIAS_NAME "${IP_LIB}")
        if(NOT "${IP_LIB}" STREQUAL "${ALIAS_NAME}")
            add_library(${ALIAS_NAME} ALIAS ${IP_LIB})
            endif()

            # TODO Maybe delete short name without version
            get_ipname(IP_LIB_SHORT ${IP_NAME} VENDOR "${ARG_VENDOR}" LIBRARY "${ARG_LIBRARY}" VERSION "")
            string(REPLACE "__" "::" ALIAS_NAME_SHORT "${IP_LIB_SHORT}")
            if(NOT "${IP_LIB}" STREQUAL "${ALIAS_NAME_SHORT}")
            add_library(${ALIAS_NAME_SHORT} ALIAS ${IP_LIB})
            endif()
            endif()

    if(ARG_VENDOR)
        set(IP_VENDOR ${ARG_VENDOR} PARENT_SCOPE)
        set_target_properties(${IP_LIB} PROPERTIES VENDOR ${ARG_VENDOR})
        endif()
        if(ARG_LIBRARY)
        set(IP_LIBRARY ${ARG_LIBRARY} PARENT_SCOPE)
        set_target_properties(${IP_LIB} PROPERTIES LIBRARY ${ARG_LIBRARY})
        endif()
        set_target_properties(${IP_LIB} PROPERTIES IP_NAME ${IP_NAME})
        if(ARG_VERSION)
        set(IP_VERSION ${ARG_VERSION} PARENT_SCOPE)
        set_target_properties(${IP_LIB} PROPERTIES VERSION ${ARG_VERSION})
        endif()

    set(IP_NAME ${IP_NAME} PARENT_SCOPE)
    set(IP ${IP_LIB} PARENT_SCOPE)
endfunction()

#[[[
# This function creates an IP name provided vendor, library, name, and version (VLNV) information.
#
# This functions appends the vendor, library, name, and version (VLNV) information separated by '__'
# to create a unique string representing an IP name. This string is used as the library name when
# when calling the cmake built-in
# `add_library() <https://cmake.org/cmake/help/latest/command/add_library.html>`_ function (see add_ip()).
#
# :param OUTVAR: The generate IP name.
# :type OUTVAR: string
# :param IP_NAME: The name of the IP.
# :type IP_NAME: string
#
# **Keyword Arguments**
#
# :keyword VENDOR: Name of the IP vendor.
# :type VENDOR: string
# :keyword LIBRARY: Name of the IP library.
# :type LIBRARY: string
# :keyword VERSION: Version of the IP following a three-part version number (Major.Minor.Patch, e.g., 1.0.13).
# :type VERSION: string
#]]
function(get_ipname OUTVAR IP_NAME)
    cmake_parse_arguments(ARG "" "VENDOR;LIBRARY;VERSION" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(ARG_VENDOR)
        set(LIB_NAME ${ARG_VENDOR}__)
    endif()
    if(ARG_LIBRARY)
        string(APPEND LIB_NAME ${ARG_LIBRARY}__)
    endif()
    string(APPEND LIB_NAME ${IP_NAME})
    if(ARG_VERSION)
        string(APPEND LIB_NAME __${ARG_VERSION})
    endif()

    set(${OUTVAR} ${LIB_NAME} PARENT_SCOPE)
endfunction()

# IS THIS REALLY NECESSARY?
# If only IP name is given without full VLNV, assume rest from the project variables
function(ip_assume_last VLNV IP_NAME) # TODO check SOURCE DIR if its the same as current
    if(NOT TARGET ${IP_NAME})
        get_ipname(IP_LIB ${IP_NAME} VENDOR "${IP_VENDOR}" LIBRARY "${IP_LIBRARY}" VERSION "${IP_VERSION}")
    endif()
    alias_dereference(IP_LIB ${IP_LIB})
    set(${VLNV} ${IP_LIB} PARENT_SCOPE)
endfunction()

#[[[
# This function adds source file(s) to an IP target.
#
# This functions adds source file(s) to an IP target as a property named after the type of source file(s)
# and the suffix '__SOURCES'. If source files of the same type already exist they are appended to the
# existing list. Ne source files can also be prepended with the optional keyword PREPEND. The source
# files are later used to create the list of files to be compiled (e.g., by a simulator) by a tool to
# execute its tasks. The source files are passed as a list after the parameters and keywords.
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param TYPE: The type of source file(s).
# :type TYPE: string
#
# **Keyword Arguments**
#
# :keyword PREPEND: This keyword enable prepending the new source files with respect to the existing ones.
# :type PREPEND: string
#]]
function(ip_sources IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "PREPEND" "" "" ${ARGN})

    check_languages(${LANGUAGE})
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})
    # Get the existing source files if any
    get_ip_sources(_sources ${_reallib} ${LANGUAGE})

    # If the PREPEND option is passed first remove it from the list of file and prepend the new sources
    if(ARG_PREPEND)
        list(REMOVE_ITEM ARGN "PREPEND")
        set(_sources ${ARGN} ${_sources})
    else()
        set(_sources ${_sources} ${ARGN})
    endif()
    # Set the target property with the new list of source files
    set_property(TARGET ${_reallib} PROPERTY ${LANGUAGE}_SOURCES ${_sources})
endfunction()

#[[[
# This function retrieves the specific source files of a target library.
#
# :param OUT_VAR: The variable containing the retrieved source file.
# :type OUT_VAR: string
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param TYPE: The type of source file(s).
# :type TYPE: string
#
#]]
function(get_ip_sources OUT_VAR IP_LIB LANGUAGE)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})
    get_ip_property(SOURCES ${IP_LIB} ${LANGUAGE}_SOURCES)
    list(REMOVE_DUPLICATES SOURCES)
    set(${OUT_VAR} ${SOURCES} PARENT_SCOPE)
endfunction()

#[[[
# This function adds include directory(ies) to a target library.
#
# This function adds an interface include directory(ies) to a target library. The include directory(ies)
# is added with the INTERFACE option (i.e., passed to targets depending on this one). The include
# directories are passed as a list after the parameter.
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param LANGUAGE: Language of the included files.
# :type LANGUAGE: string
#
#]]
function(ip_include_directories IP_LIB LANGUAGE)
    # Check that the file language is supported by SoCMake
    check_languages(${LANGUAGE})
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})
    # Append the new include directories to the exsiting ones
    set_property(TARGET ${_reallib} APPEND PROPERTY ${LANGUAGE}_INCLUDE_DIRECTORIES ${ARGN})
endfunction()

#[[[
# This function retrieves the included directories of a target library and its dependencies.
#
# :param OUTVAR: The variable containing the retrieved included directory(ies).
# :type OUTVAR: string
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param LANGUAGE: Language of the included files.
# :type LANGUAGE: string
#
#]]
function(get_ip_include_directories OUTVAR IP_LIB LANGUAGE)
    # Check that the file language is supported by SoCMake
    check_languages(${LANGUAGE})
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    flatten_graph(${_reallib})
    get_target_property(DEPS ${_reallib} FLAT_GRAPH)

    foreach(d ${DEPS})
        safe_get_target_property(${LANGUAGE}_INCLUDE_DIRECTORIES ${d} ${LANGUAGE}_INCLUDE_DIRECTORIES "")
        list(PREPEND ${LANGUAGE}_INCDIRS ${${LANGUAGE}_INCLUDE_DIRECTORIES})
    endforeach()

    set(${OUTVAR} ${${LANGUAGE}_INCDIRS} PARENT_SCOPE)
endfunction()

#[[[
# This function checks the the language is supported by SoCMake.
#
# This function checks the the language is supported by SoCMake and issue a warning/error depending
# on the verbosity level. The supported languages can be augmented using the variable
# SOCMAKE_ADDITIONAL_LANGUAGES.
#
# :param OUT: The variable in which to store the original retrieved name.
# :type OUT: string
# :param LIB: The target IP library name.
# :type LIB: string
#
#]]
function(check_languages LANGUAGE)
    # The default supported languages
    # The user can add addition languages using the SOCMAKE_ADDITIONAL_LANGUAGES variable
    set(SOCMAKE_SUPPORTED_LANGUAGES SYSTEMVERILOG VERILOG VHDL SYSTEMRDL SYSTEMRDL_SOCGEN
        ${SOCMAKE_ADDITIONAL_LANGUAGES})

    if(NOT ${LANGUAGE} IN_LIST SOCMAKE_SUPPORTED_LANGUAGES)
        if(SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL)
            set(_verbosity FATAL_ERROR)
        else()
            set(_verbosity WARNING)
        endif()
        message(${_verbosity} "Language not supported: ${LANGUAGE}")
    endif()
endfunction()

#[[[
# This function adds a target link library and a dependency to an IP target.
#
# This function gets the original target and dependency names in case an alias is given. Then it checks
# if the link library exists and adds it (if it's not already added). Finally, the link library is added
# as a dependency. This last step can be skipped with the keyword NODEPEND. The dependencies are passed
# as a list after the parameters and the keyword.
#
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
#
# **Keyword Arguments**
#
# :keyword NODEPEND: This keyword disable the dependency between the targets.
# :type NODEPEND: string
#
#]]
function(ip_link IP_LIB)
    cmake_parse_arguments(ARG "NODEPEND" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    # Remove the optional NODEPEND argument to keep only a list of dependecies
    if(ARG_NODEPEND)
        list(REMOVE_ITEM ARGN "NODEPEND")
    endif()

    # Get the existing linked libraries
    get_target_property(ALREADY_LINKED ${_reallib} INTERFACE_LINK_LIBRARIES)

    foreach(lib ${ARGN})
        alias_dereference(lib ${lib})
        # Continue if the library is already linked
        if(${lib} IN_LIST ALREADY_LINKED)
            continue()
        endif()
        # Issue an error if the library does not exist
        if(NOT TARGET ${lib})
            message(FATAL_ERROR "Library ${lib} linked to ${IP_LIB} is not defined")
        endif()
        # Link the library to the target
        target_link_libraries(${_reallib} INTERFACE ${lib})
        if(NOT ARG_NODEPEND)
            # Add a build dependency to ensure correct build order
            add_dependencies(${_reallib} ${lib})
        endif()
    endforeach()

endfunction()

#[[[
# This function retrieves a specific property from a target library and its dependencies.
#
# :param OUT_VAR: Variable containing the requested property.
# :type OUT_VAR: string
# :param TARGET: The target IP library name.
# :type TARGET: string
# :param PROPERTY: Property to retrieve from IP_LIB.
# :type PROPERTY: string
#
#]]
function(get_ip_property OUTVAR TARGET PROPERTY)
    # Retrieve the real library name in case an alias is used
    alias_dereference(TARGET ${TARGET})
    # Flatten the target graph to get all the dependencies in the correct order
    flatten_graph(${TARGET})
    # Get all the dependencies
    get_target_property(DEPS ${TARGET} FLAT_GRAPH)

    set(OUT_LIST "")
    # Append the property of all the deps into a single list (e.g., the source files of an IP)
    foreach(d ${DEPS})
        safe_get_target_property(PROP ${d} ${PROPERTY} "")
        list(APPEND OUT_LIST ${PROP})
    endforeach()

    set(${OUTVAR} ${OUT_LIST} PARENT_SCOPE)
endfunction()

#[[[
# This function is a hardcoded version of get_ip_property() for the
# INTERFACE_COMPILE_DEFINITIONS property.
#
# :param OUT_VAR: Variable containing the requested property.
# :type OUT_VAR: string
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
#
#]]
function(get_ip_compile_definitions OUTVAR IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})
    get_ip_property(__comp_defs ${IP_LIB} INTERFACE_COMPILE_DEFINITIONS)
    set(${OUTVAR} ${__comp_defs} PARENT_SCOPE)
endfunction()
