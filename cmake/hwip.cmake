include("${CMAKE_CURRENT_LIST_DIR}/rtllib.cmake")

function(add_ip IP_NAME)
    cmake_parse_arguments(ARG "" "VERSION;DESCRIPTION;VENDOR;LIBRARY" "" ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if((NOT ARG_VERSION OR NOT ARG_VENDOR OR NOT ARG_LIBRARY) AND NOT SOCMAKE_NOWARN_VLNV)
        message(WARNING "Consider using full VLNV format\nIP block: ${IP_NAME}\n    VENDOR: ${ARG_VENDOR}\n    LIBRARY: ${ARG_LIBRARY}\n    VERSION: ${ARG_VERSION}")
    endif()

    set(IP_NAME ${IP_NAME} PARENT_SCOPE)

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

    set(IP ${IP_LIB} PARENT_SCOPE)

endfunction()

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

function(ip_assume_last VLNV IP_NAME) # TODO check SOURCE DIR if its the same as current
    if(NOT TARGET ${IP_NAME})
        get_ipname(IP_LIB ${IP_NAME} VENDOR "${IP_VENDOR}" LIBRARY "${IP_LIBRARY}" VERSION "${IP_VERSION}")
    endif()
    alias_dereference(IP_LIB ${IP_LIB})
    set(${VLNV} ${IP_LIB} PARENT_SCOPE)
endfunction()

function(ip_sources IP_LIB TYPE)
    cmake_parse_arguments(ARG "PREPEND" "" "" ${ARGN})
    # if(ARG_UNPARSED_ARGUMENTS)
    #     message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} passed unrecognized argument " "${ARG_UNPARSED_ARGUMENTS}")
    # endif()

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})
    get_ip_sources(_sources ${_reallib} ${TYPE})

    if(ARG_PREPEND)
        list(REMOVE_ITEM ARGN "PREPEND")
        set(_sources ${ARGN} ${_sources})
    else()
        set(_sources ${_sources} ${ARGN})
    endif()
    set_property(TARGET ${_reallib} PROPERTY ${TYPE}_SOURCES ${_sources})

endfunction()

function(get_ip_sources OUT_VAR IP_LIB TYPE)
    ip_assume_last(IP_LIB ${IP_LIB})
    get_rtl_target_property(SOURCES ${IP_LIB} ${TYPE}_SOURCES)
    list(REMOVE_DUPLICATES SOURCES)
    set(${OUT_VAR} ${SOURCES} PARENT_SCOPE)

endfunction()


function(ip_include_directories IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})
    target_include_directories(${_reallib} INTERFACE ${ARGN})

endfunction()

function(get_ip_include_directories OUTVAR IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})
    get_rtl_target_incdirs(INC_DIRS ${IP_LIB})
    set(${OUTVAR} ${INC_DIRS} PARENT_SCOPE)
endfunction()

function(alias_dereference OUT LIB)
    if(NOT TARGET ${LIB})
        message(FATAL_ERROR "Library ${LIB} is not defined")
    endif()
    get_target_property(_reallib ${LIB} ALIASED_TARGET)

    if(NOT _reallib)
        set(${OUT} ${LIB} PARENT_SCOPE)
        return()
    endif()

    while(_reallib)


        set(_oldlib ${_reallib})
        get_target_property(_reallib ${_reallib} ALIASED_TARGET)
    endwhile()
    if(_oldlib)
        set(${OUT} ${_oldlib} PARENT_SCOPE)
        return()
    endif()

endfunction()

function(ip_link IP_LIB)
    cmake_parse_arguments(ARG "NODEPEND" "" "" ${ARGN})

    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(_reallib ${IP_LIB})

    if(ARG_NODEPEND)
        list(REMOVE_ITEM ARGN "NODEPEND")
    endif()

    get_target_property(ALREADY_LINKED ${_reallib} INTERFACE_LINK_LIBRARIES)
    foreach(lib ${ARGN})
        alias_dereference(lib ${lib})

        if(${lib} IN_LIST ALREADY_LINKED)
            continue()
        endif()
        if(NOT TARGET ${lib})
            message(FATAL_ERROR "Library ${lib} linked to ${IP_LIB} is not defined")
        endif()
        target_link_libraries(${_reallib} INTERFACE ${lib})
        if(NOT ARG_NODEPEND)
            add_dependencies(${_reallib} ${lib})
        endif()
    endforeach()

endfunction()

# This one is recursive
function(get_ip_property OUTVAR IP_LIB PROPERTY)
    # ip_assume_last(_reallib ${IP_LIB})
    alias_dereference(IP_LIB ${IP_LIB})
    get_rtl_target_property(out ${IP_LIB} ${PROPERTY})
    set(${OUTVAR} ${out} PARENT_SCOPE)
endfunction()

function(ip_compile_definitions IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})

    target_compile_definitions(${IP_LIB} INTERFACE ${ARGN})
endfunction()

function(get_ip_compile_definitions OUTVAR IP_LIB)
    # If only IP name is given without full VLNV, assume rest from the project variables
    ip_assume_last(IP_LIB ${IP_LIB})
    get_rtl_target_property(__comp_defs ${IP_LIB} INTERFACE_COMPILE_DEFINITIONS)
    set(${OUTVAR} ${__comp_defs} PARENT_SCOPE)
endfunction()
