
include("${CMAKE_CURRENT_LIST_DIR}/utils/socmake_graph.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/utils/alias_dereference.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/utils/safe_get_target_property.cmake")
include("${CMAKE_CURRENT_LIST_DIR}//utils/file_paths.cmake")

#[[[
# This function creates an INTERFACE library for a given IP.
#
# This function is a wrapper around the cmake built-in
# `add_library() <https://cmake.org/cmake/help/latest/command/add_library.html>`_ function.
# It generates the library name using the vendor, library, name, and version (VLNV) information passed
# in arguments (see create_ip_vlnv()). It creates two alias libraries to the default <vendor>__<library>__<name>__<version>:
# 
# * <vendor>::<library>::<name>::<version> ('__' replaced by '::')
# * <vendor>::<library>::<name> (short name without the version)
#
# This function can be used in FULL and SHORT form:
# Full form:
# ```
# add_ip(ip
#     VENDOR vendor
#     LIBRARY lib
#     VERSION 1.2.3
#     DESCRIPTION "This is a sample IP"
#     )
# ```
# In full form it is possible to ommit VENDOR, LIBRARY and VERSION, DESCRIPTION, although it is not recommended.
#
# Ommiting them all would have following signature:
# ```
# add_ip(ip2)
# ```
#
# Short form:
# ```
# add_ip(vendor2::lib2::ip2::1.2.2)
# ```
# In short form only the full VLNV format is accepted
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
# :keyword DESCRIPTION: Short description to be associated with the IP library, will appear in `help_ips()` message
# :type DESCRIPTION: string
#]]
function(add_ip IP_NAME)
    cmake_parse_arguments(ARG "" "VENDOR;LIBRARY;VERSION;DESCRIPTION" "" ${ARGN})

    # Vendor and library arguments are expected at the minimum
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument "
                            "${ARG_UNPARSED_ARGUMENTS}")
    endif()
    
    # If none of optional arguments VENDOR, LIBRARY, VERSION are passed expect to receive VLNV format in IP_NAME like vendor::lib::ip::0.0.1
    if(NOT ARG_VENDOR AND NOT ARG_LIBRARY AND NOT ARG_VERSION)
        unset(ARG_VENDOR)
        parse_ip_vlnv(${IP_NAME} VENDOR LIBRARY IP_NAME VERSION)
        set(ARG_VENDOR ${VENDOR})
        set(ARG_LIBRARY ${LIBRARY})
        set(ARG_VERSION ${VERSION})
    endif()
    # Create the IP unique name using VLNV information
    create_ip_vlnv(IP_LIB ${IP_NAME} VENDOR "${ARG_VENDOR}" LIBRARY "${ARG_LIBRARY}" VERSION "${ARG_VERSION}")
 
    if(NOT TARGET ${IP_LIB})
        add_library(${IP_LIB} INTERFACE)

        string(REPLACE "__" "::" ALIAS_NAME "${IP_LIB}")
        if(NOT "${IP_LIB}" STREQUAL "${ALIAS_NAME}")
            add_library(${ALIAS_NAME} ALIAS ${IP_LIB})
        endif()

        # TODO Maybe delete short name without version
        if(ARG_VERSION)
            create_ip_vlnv(IP_LIB_SHORT ${IP_NAME} VENDOR "${ARG_VENDOR}" LIBRARY "${ARG_LIBRARY}" VERSION "")
            string(REPLACE "__" "::" ALIAS_NAME_SHORT "${IP_LIB_SHORT}")
            if(NOT "${IP_LIB}" STREQUAL "${ALIAS_NAME_SHORT}")
                add_library(${ALIAS_NAME_SHORT} ALIAS ${IP_LIB})
            endif()
        endif()
    endif()

    if(ARG_DESCRIPTION)
        set_property(TARGET ${IP_LIB} PROPERTY DESCRIPTION ${ARG_DESCRIPTION})
    endif()

    # Unset the parent variables that might have been set by previous add_ip() call
    unset(IP_VENDOR PARENT_SCOPE)
    unset(IP_LIBRARY PARENT_SCOPE)
    unset(IP_NAME PARENT_SCOPE)
    unset(IP_VERSION PARENT_SCOPE)
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
function(create_ip_vlnv OUTVAR IP_NAME)
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

#[[[
# This function parses IP name from the VLNV format e.g. (vendor::lib::ip::0.0.1)
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
function(parse_ip_vlnv IP_VLNV VENDOR LIBRARY IP_NAME VERSION)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    # Convert IP_VLNV into a list of tokens by replacing :: with ;
    string(REPLACE "::" ";" IP_TOKENS ${IP_VLNV})
    # Remove empty list elements in case something like vendor::::ip::1.2.3 is passed
    list(REMOVE_ITEM IP_TOKENS "")

    # Raise an error if there are different than 4 tokens provided (`add_ip(vendor::lib::ip::0.0.1)`), unless its only 1 (`add_ip(ip)`) 
    list(LENGTH IP_TOKENS TOKEN_CNT)

    # Its alowed for IP_VLNV to have 4 tokens (FULL) `add_ip(vendor::lib::ip::0.0.1)`
    if(TOKEN_CNT EQUAL 4)
        # Get elements of the list
        list(GET IP_TOKENS 0 VENDOR)
        list(GET IP_TOKENS 1 LIBRARY)
        list(GET IP_TOKENS 2 IP_NAME)
        list(GET IP_TOKENS 3 VERSION)
    # Its alowed for IP_VLNV to have 1 token (SHORT) `add_ip(ip)`
    elseif(TOKEN_CNT EQUAL 1)
        set(IP_NAME ${IP_VLNV})
        unset(VENDOR)
        unset(LIBRARY)
        unset(VERSION)
    # Anything else is not allowed and will throw an error
    else()
        message(FATAL_ERROR "Please specify full VLNV format for IP: ${IP_VLNV}")
    endif()

    # Set output variables
    set(VENDOR ${VENDOR} PARENT_SCOPE)
    set(LIBRARY ${LIBRARY} PARENT_SCOPE)
    set(IP_NAME ${IP_NAME} PARENT_SCOPE)
    set(VERSION ${VERSION} PARENT_SCOPE)
endfunction()

#[[[
# This function adds source file(s) to an IP target.
#
# This functions adds source file(s) under a file set to an IP target as a property named after the name of the file set, type of source file(s)
# and the suffix '_SOURCES'. The property is of the following format <LANGUAGE>_<FILE_SET>_SOURCES, in case FILE_SET is not set, DEFAULT is used.
# If source files of the same type already exist they are appended to the existing list. 
# The source files can also be prepended with the optional keyword PREPEND. The source
# files are later used to create the list of files to be compiled (e.g., by a simulator) by a tool to
# execute its tasks. The source files are passed as a list after the parameters and keywords.
# 
# Relative file paths are accepted and will be converted to absolute, relative to ${CMAKE_CURRENT_SOURCE_DIR}
#
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param TYPE: The type of source file(s).
# :type TYPE: string
#
# **Keyword Arguments**
#
# :keyword [PREPEND]: This keyword enable prepending the new source files with respect to the existing ones.
# :type [PREPEND]: boolean
# :keyword [REPLACE]: Replace the existing files.
# :type [REPLACE]: boolean
# :param [FILE_SET]: Specify to which file set to associate the listed files
# :type [FILE_SET]: string
# :param [HEADERS]: List of header files. Header files are stored in separate property ${LANGUAGE}_HEADERS
# :type [HEADERS]: list
#]]
function(ip_sources IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "PREPEND;REPLACE" "FILE_SET" "HEADERS" ${ARGN})
    # Delete PREPEND and REPLACE from argument list, so only sources are left
    list(REMOVE_ITEM ARGN "PREPEND")
    list(REMOVE_ITEM ARGN "REPLACE")

    check_languages(${LANGUAGE})
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})
    if(NOT ARG_FILE_SET)
        set(ARG_FILE_SET DEFAULT)
    endif()

    set(sources_property ${LANGUAGE}_${ARG_FILE_SET}_SOURCES)
    set(headers_property ${LANGUAGE}_${ARG_FILE_SET}_HEADERS)
    set(get_sources_fileset_arg FILE_SETS ${ARG_FILE_SET})

    get_property(filesets TARGET ${_reallib} PROPERTY FILE_SETS)
    if(NOT ARG_FILE_SET IN_LIST filesets)
        set_property(TARGET ${_reallib} APPEND PROPERTY FILE_SETS ${ARG_FILE_SET})
    endif()

    list(REMOVE_ITEM ARGN "${ARG_FILE_SET}")
    list(REMOVE_ITEM ARGN "FILE_SET")

    # If headers are passed, use files until HEADERS as sources, while the rest are HEADERS
    if(ARG_HEADERS)
        list(FIND ARGN "HEADERS" headers_idx)
        list(SUBLIST ARGN 0 ${headers_idx} ARGN)
    endif()

    # Convert all listed files to absolute paths relative to ${CMAKE_CURRENT_SOURCE_DIR}
    convert_paths_to_absolute(file_list ${ARGN})
    convert_paths_to_absolute(header_list ${ARG_HEADERS})

    if(NOT ARG_REPLACE)
        # Get the existing source and header files if any
        get_ip_sources(_sources ${_reallib} ${LANGUAGE} ${get_sources_fileset_arg} NO_DEPS)
        get_ip_sources(_headers ${_reallib} ${LANGUAGE} ${get_sources_fileset_arg} HEADERS NO_DEPS)
    endif()

    # If the PREPEND option is passed prepend the new sources to the old ones
    if(ARG_PREPEND)
        set(_sources ${file_list} ${_sources})
        set(_headers ${header_list} ${_headers})
    else()
        set(_sources ${_sources} ${file_list})
        set(_headers ${_headers} ${header_list})
    endif()
    # Set the target property with the new list of source and header files
    set_property(TARGET ${_reallib} PROPERTY ${sources_property} ${_sources})
    # set_property(TARGET ${_reallib} APPEND PROPERTY EXPORT_PROPERTIES ${sources_property}) # TODO don't add if already there
    if(ARG_HEADERS)
        set_property(TARGET ${_reallib} PROPERTY ${headers_property} ${_headers})
        # set_property(TARGET ${_reallib} APPEND PROPERTY EXPORT_PROPERTIES ${headers_property}) # TODO don't add if already there
    endif()
endfunction()

#[[[
# This function retrieves the specific source files of a target library.
#
# :param OUTVAR: The variable containing the retrieved source file.
# :type OUTVAR: string
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
# :param LANGUAGE: The type of source file(s).
# :type LANGUAGE: string
#
# **Keyword Arguments**
#
# :keyword [NO_DEPS]: Only return the list off IPs that are immedieate childrean from the current IP
# :type [NO_DEPS]: bool
# :keyword [HEADERS]: Return the list of HEADER files only.
# :type [HEADERS]: bool
# :keyword [FILE_SETS]: Specify list of File sets to retrieve the files from
# :type [FILE_SETS]: list[string]
#]]
function(get_ip_sources OUTVAR IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "NO_DEPS;HEADERS" "" "FILE_SETS" ${ARGN})
    unset(_no_deps)
    if(ARG_NO_DEPS)
        set(_no_deps "NO_DEPS")
        # ARGN contains extra languages passed, it might also include NO_DEPS so remove it from the list
        list(REMOVE_ITEM ARGN NO_DEPS)
    endif()
    if(ARG_HEADERS)
        set(property_type HEADERS)
        # ARGN contains extra languages passed, it might also include HEADERS so remove it from the list
        list(REMOVE_ITEM ARGN HEADERS)
    else()
        set(property_type SOURCES)
    endif()
    
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})

    # In case FILE_SETS function argument is not specified, return all defined file sets
    # Otherwise return only files in listed file sets
    get_ip_property(ip_filesets ${_reallib} FILE_SETS ${_no_deps})
    if(NOT ARG_FILE_SETS)
        set(filesets ${ip_filesets})
    else()
        set(filesets ${ARG_FILE_SETS})
        foreach(fileset ${ARG_FILE_SETS})
            list(REMOVE_ITEM ARGN "${fileset}")
        endforeach()
        list(REMOVE_ITEM ARGN "FILE_SETS")
    endif()

    unset(SOURCES)
    # Get all the <LANGUAGE>_<FILE_SET>_SOURCES or <LANGUAGE>_<FILE_SET>_HEADERS lists in order
    foreach(_lang ${LANGUAGE} ${ARGN})
        check_languages(${_lang})
        foreach(fileset ${filesets})
            get_ip_property(_lang_sources ${_reallib} ${_lang}_${fileset}_${property_type} ${_no_deps})
            list(APPEND SOURCES ${_lang_sources})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES SOURCES)
    set(${OUTVAR} ${SOURCES} PARENT_SCOPE)
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
# **Keyword Arguments**
#
# :param FILE_SET: Specify to which file set to associate the listed include directories 
# :type FILE_SET: string
#]]
function(ip_include_directories IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "" "FILE_SET" "" ${ARGN})
    # Check that the file language is supported by SoCMake
    check_languages(${LANGUAGE})
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})
    # DEFAULT file set is used if not specified
    if(NOT ARG_FILE_SET)
        set(ARG_FILE_SET DEFAULT)
    endif()
    set(incdir_property ${LANGUAGE}_${ARG_FILE_SET}_INCLUDE_DIRECTORIES)
    set(fileset_arg FILE_SETS ${ARG_FILE_SET})

    # Add the file set to the FILE_SETS property
    get_property(filesets TARGET ${_reallib} PROPERTY FILE_SETS)
    if(NOT ARG_FILE_SET IN_LIST filesets)
        set_property(TARGET ${_reallib} APPEND PROPERTY FILE_SETS ${ARG_FILE_SET})
    endif()
    # Remove the FILE_SET argument and its value from ARGN to not interfere with directory list
    list(REMOVE_ITEM ARGN "${ARG_FILE_SET}")
    list(REMOVE_ITEM ARGN "FILE_SET")
    # Convert all listed files to absolute paths relative to ${CMAKE_CURRENT_SOURCE_DIR}
    convert_paths_to_absolute(dir_list ${ARGN})
    # Append the new include directories to the exsiting ones
    set_property(TARGET ${_reallib} APPEND PROPERTY ${incdir_property} ${dir_list})
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
# **Keyword Arguments**
#
# :keyword [NO_DEPS]: Only return the list off IPs that are immediate childrean from the current IP
# :type [NO_DEPS]: bool
# :keyword [FILE_SETS]: Specify list of File sets to retrieve the include directories from
# :type [FILE_SETS]: list[string]
#]]
function(get_ip_include_directories OUTVAR IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "NO_DEPS" "" "FILE_SETS" ${ARGN})
    unset(_no_deps)
    if(ARG_NO_DEPS)
        set(_no_deps "NO_DEPS")
    endif()
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})

    # In case FILE_SETS function argument is not specified, return all defined file sets
    # Otherwise return only directories in listed file sets
    get_ip_property(ip_filesets ${_reallib} FILE_SETS ${_no_deps})
    if(NOT ARG_FILE_SETS)
        set(filesets ${ip_filesets})
    else()
        set(filesets ${ARG_FILE_SETS})
        foreach(fileset ${ARG_FILE_SETS})
            list(REMOVE_ITEM ARGN "${fileset}")
        endforeach()
        list(REMOVE_ITEM ARGN "FILE_SETS")
    endif()

    # ARGN contains extra languages passed, it might also include NO_DEPS so remove it from the list
    list(REMOVE_ITEM ARGN NO_DEPS)
    unset(INCDIRS)
    # Get all the <LANGUAGE>_INCLUDE_DIRECTORIES lists in order
    foreach(_lang ${LANGUAGE} ${ARGN})
        check_languages(${_lang})
        foreach(fileset ${filesets})
            get_ip_property(_lang_incdirs ${_reallib} ${_lang}_${fileset}_INCLUDE_DIRECTORIES ${_no_deps})
            list(APPEND INCDIRS ${_lang_incdirs})
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES INCDIRS)
    set(${OUTVAR} ${INCDIRS} PARENT_SCOPE)
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
    # The user can add addition languages using the SOCMAKE_ADDITIONAL_LANGUAGES variable and global property
    get_socmake_languages(SOCMAKE_SUPPORTED_LANGUAGES)
    
    if(NOT ${LANGUAGE} IN_LIST SOCMAKE_SUPPORTED_LANGUAGES)
        if(SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL)
            set(_verbosity FATAL_ERROR)
        else()
            set(_verbosity WARNING)
        endif()
        message(${_verbosity} "Language not supported: ${LANGUAGE}")
    endif()
endfunction()


function(__compare_version RESULT COMPARE_LHS RELATION COMPARE_RHS)

    unset(NEGATION)
    if(RELATION STREQUAL ">=")
        set(RELATION VERSION_GREATER_EQUAL)
    elseif(RELATION STREQUAL ">")
        set(RELATION VERSION_GREATER)
    elseif(RELATION STREQUAL "<=")
        set(RELATION VERSION_LESS_EQUAL)
    elseif(RELATION STREQUAL "<")
        set(RELATION VERSION_LESS)
    elseif(RELATION STREQUAL "==")
        set(RELATION VERSION_EQUAL)
    elseif(RELATION STREQUAL "!=")
        set(RELATION VERSION_EQUAL)
        set(NEGATION NOT)
    endif()

    if(${NEGATION} ${COMPARE_LHS} ${RELATION} ${COMPARE_RHS})
        set(${RESULT} TRUE PARENT_SCOPE)
    else()
        set(${RESULT} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(__ip_link_check_version OUT_IP_WO_VERSION IP_LIB)
    string(REPLACE " " "" ip_lib_str "${IP_LIB}")
    string(REGEX MATCH "(!=|>=|<=|==|<|>)" version_ranges "${ip_lib_str}")

    # If regex did not match, there is no comparison string in the linked IP, so just exit
    if(NOT version_ranges)
        set(${OUT_IP_WO_VERSION} ${IP_LIB} PARENT_SCOPE)
        return()
    endif()

    # extract the VLN from "v::l::ip2>= 1.0.0,<=2.0.0" by getting a substring until first regex match
    # list(GET version_ranges 0 first_range_idx)
    string(FIND "${ip_lib_str}" "${CMAKE_MATCH_1}" first_found)
    string(SUBSTRING "${ip_lib_str}" 0 ${first_found} ip_lib_wo_version)
    set(${OUT_IP_WO_VERSION} ${ip_lib_wo_version} PARENT_SCOPE)

    string(REPLACE "${ip_lib_wo_version}" "" version_ranges "${ip_lib_str}" )
    string(REPLACE "," ";" version_ranges "${version_ranges}")

    get_target_property(ip_version ${ip_lib_wo_version} VERSION)

    set(version_satisfied TRUE)
    foreach(version_range ${version_ranges})
        string(REGEX MATCH "^(!=|>=|<=|==|<|>)([0-9]+\.?[0-9]*\.?[0-9]*)$" version_ranges "${version_range}")

        if(NOT CMAKE_MATCH_1 AND NOT CMAKE_MATCH_2)
            message(FATAL_ERROR "Malformed version condition ${version_range}")
        endif()
        
        __compare_version(satisfies "${ip_version}" "${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")
        if(NOT satisfies)
            set(version_satisfied FALSE)
            message(FATAL_ERROR "Linked IP \"${ip_lib_wo_version}\" version condition \"${ip_version} ${CMAKE_MATCH_1} ${CMAKE_MATCH_2}\" cannot be satisfied")
        endif()
    endforeach()
endfunction()

#[[[
# This function adds a target link library and a dependency to an IP target.
#
# This function gets the original target and dependency names in case an alias is given. Then it checks
# if the link library exists and adds it (if it's not already added). Finally, the link library is added
# as a dependency. This last step can be skipped with the keyword NODEPEND. The dependencies are passed
# as a list after the parameters and the keyword.
#
# It is also allowed to pass version conditions to be checked as following:
#  ```
# ip_link(v::l::ip1::1.1.1
#     "v::l::ip2 >= 1.0.4, <=2.0.0")
#  ```
# If all the comparisons are not satisfied, FATAL_ERROR is issued.
# Allowed comparisons are ==, >=, >, <=, <
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

    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})

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

        # Check the version conditions if present.
        # Also remove the version conditions from the ${lib} string and keep only IP library VLN
        __ip_link_check_version(lib ${lib})

        # Issue an error if the library does not exist
        if(NOT TARGET ${lib})
            message(FATAL_ERROR "Library ${lib} linked to ${_reallib} is not defined")
        endif()
        # In case user tries to link library to itself, raise an error
        if(${lib} STREQUAL ${_reallib})
            message(FATAL_ERROR "Cannot link library ${lib} to ${_reallib} (itself)")
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
# :param OUTVAR: Variable containing the requested property.
# :type OUTVAR: string
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
# :param PROPERTY: Property to retrieve from IP_LIB.
# :type PROPERTY: string
# :keyword [NO_DEPS]: Only return the list off IPs that are immedieate childrean from the current IP
# :type [NO_DEPS]: bool
#
#]]
function(get_ip_property OUTVAR IP_LIB PROPERTY)
    cmake_parse_arguments(ARG "NO_DEPS" "" "" ${ARGN})

    # Retrieve the real library name in case an alias is used
    alias_dereference(_reallib ${IP_LIB})

    set(OUT_LIST "")
    if(ARG_NO_DEPS)
        safe_get_target_property(OUT_LIST ${_reallib} ${PROPERTY} "")
    else()
        # Flatten the target graph to get all the dependencies in the correct order
        flatten_graph(${_reallib})
        # Get all the dependencies
        get_target_property(DEPS ${_reallib} FLAT_GRAPH)

        # Append the property of all the deps into a single list (e.g., the source files of an IP)
        foreach(d ${DEPS})
            safe_get_target_property(PROP ${d} ${PROPERTY} "")
            list(APPEND OUT_LIST ${PROP})
        endforeach()
    endif()

    set(${OUTVAR} ${OUT_LIST} PARENT_SCOPE)
endfunction()

#[[[
# Set a compile definition on a IP for a given language inside property <LANGUAGE>_COMPILE_DEFINITIONS.
#
# Any leading `-D` on an item will be removed. Empty items are ignored. For example, the following are all equivalent:
#
# ip_compile_definitions(foo VERILOG FOO)
# ip_compile_definitions(foo VERILOG -DFOO)  # -D removed
# ip_compile_definitions(foo VERILOG "" FOO) # "" ignored
# ip_compile_definitions(foo VERILOG -D FOO) # -D becomes "", then ignored.
#
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
# :param LANGUAGE: Language to which the definition should apply.
# :type LANGUAGE: string
#
#]]
function(ip_compile_definitions IP_LIB LANGUAGE)
    check_languages(${LANGUAGE})
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})

    # Strip -D
    set(__comp_defs ${ARGN})
    string(REPLACE "-D" "" __comp_defs "${__comp_defs}")
    list(REMOVE_ITEM __comp_defs "")

    # Append the new compile definitions to the exsiting ones
    set_property(TARGET ${_reallib} APPEND PROPERTY ${LANGUAGE}_COMPILE_DEFINITIONS ${__comp_defs})
endfunction()


#[[[
# This function is a hardcoded version of get_ip_property() for the
# <LANGUAGE>_COMPILE_DEFINITIONS property.
#
# :param OUTVAR: Variable containing the requested property.
# :type OUTVAR: string
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
# :param LANGUAGE: Language to which the definition apply.
# :type LANGUAGE: string
# :keyword [NO_DEPS]: Only return the list off IPs that are immedieate childrean from the current IP
# :type [NO_DEPS]: bool
#
#]]
function(get_ip_compile_definitions OUTVAR IP_LIB LANGUAGE)
    cmake_parse_arguments(ARG "NO_DEPS" "" "" ${ARGN})
    unset(_no_deps)
    if(ARG_NO_DEPS)
        set(_no_deps "NO_DEPS")
    endif()
    # If alias IP is given, dereference it (VENDOR::LIB::IP::0.0.1) -> (VENDOR__LIB__IP__0.0.1)
    alias_dereference(_reallib ${IP_LIB})

    # ARGN contains extra languages passed, it might also include NO_DEPS so remove it from the list
    list(REMOVE_ITEM ARGN NO_DEPS)
    unset(COMPDEFS)
    # Get all the <LANGUAGE>_INCLUDE_DIRECTORIES lists in order
    foreach(_lang ${LANGUAGE} ${ARGN})
        check_languages(${_lang})
        get_ip_property(_lang_compdefs ${_reallib} ${_lang}_COMPILE_DEFINITIONS ${_no_deps})
        list(APPEND COMPDEFS ${_lang_compdefs})
    endforeach()

    list(REMOVE_DUPLICATES COMPDEFS)
    set(${OUTVAR} ${COMPDEFS} PARENT_SCOPE)
endfunction()

#[[[
# Get the IP link graph in a flat list
#
# :param OUTVAR: Variable containing the link list.
# :type OUTVAR: string
# :keyword [NO_DEPS]: Only return the list off IPs that are immedieate childrean from the current IP
# :type [NO_DEPS]: bool
#]]
function(get_ip_links OUTVAR IP_LIB)
    cmake_parse_arguments(ARG "NO_DEPS" "" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    alias_dereference(_reallib ${IP_LIB})

    if(ARG_NO_DEPS)
        get_property(__flat_graph TARGET ${_reallib} PROPERTY INTERFACE_LINK_LIBRARIES)
    else()
        flatten_graph(${_reallib})

        get_property(__flat_graph TARGET ${_reallib} PROPERTY FLAT_GRAPH)
    endif()

    set(${OUTVAR} ${__flat_graph} PARENT_SCOPE)
endfunction()

#[[[
# This function recursively get the property PROPERTY from the target IP_LIB and
# returns a list stored in OUTVAR.
#
# :param OUT_VAR: Variable containing the requested property.
# :type OUT_VAR: string
# :param IP_LIB: The target IP library name.
# :type IP_LIB: string
# :param PROPERTY: Property to search recursively.
# :type PROPERTY: string
#
#]]
function(recursive_get_target_property OUTVAR IP_LIB PROPERTY)
    set(_seen_values)

    alias_dereference(_reallib ${IP_LIB})

    # Get the value of the specified property for the current target
    get_target_property(_current_value ${_reallib} ${PROPERTY})

    if(_current_value AND NOT _current_value STREQUAL "<${PROPERTY}>-NOTFOUND")
        list(APPEND _seen_values ${_current_value})

        # Check if the property value is a list of targets or a single target
        foreach(_subtarget ${_current_value})
            # Recursively process sub-targets if they exist
            if(TARGET ${_subtarget})
                recursive_get_target_property(_recursive_values ${_subtarget} ${PROPERTY})
                list(APPEND _seen_values ${_recursive_values})
                list(REMOVE_DUPLICATES _seen_values)
            endif()
        endforeach()
    endif()

    # Return the collected values
    set(${OUTVAR} ${_seen_values} PARENT_SCOPE)
endfunction()

function(socmake_add_languages)
    set_property(GLOBAL APPEND PROPERTY SOCMAKE_ADDITIONAL_LANGUAGES ${ARGN})
endfunction()

function(get_socmake_languages OUTVAR)
    get_property(additional_languages GLOBAL PROPERTY SOCMAKE_ADDITIONAL_LANGUAGES)

    set(languages
            SYSTEMVERILOG SYSTEMVERILOG_SIM SYSTEMVERILOG_FPGA
            VERILOG VERILOG_SIM VERILOG_FPGA
            VHDL VHDL_SIM VHDL_FPGA
            SYSTEMRDL SYSTEMRDL_SOCGEN
            VERILATOR_CFG
            ${SOCMAKE_ADDITIONAL_LANGUAGES}
            ${additional_languages})

    set(${OUTVAR} ${languages} PARENT_SCOPE)
endfunction()
