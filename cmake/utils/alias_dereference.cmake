#[[[
# This function returns the original library name if the given one is an alias.
#
# :param OUT: The variable in which to store the original retrieved name.
# :type OUT: string
# :param LIB: The target IP library name.
# :type LIB: string
#
#]]
function(alias_dereference OUT LIB)

    # Check if the library is STATIC linked one, the library name will be $<LINK_ONLY:${LIB}> in that case
    if("${LIB}" MATCHES "\\$<LINK_ONLY:")
        return()
    endif()

    # Check the library exists
    if(NOT TARGET ${LIB} AND NOT "${LIB}" MATCHES ".*LINK_ONLY:")
        message(FATAL_ERROR "Library ${LIB} is not defined")
    endif()
    # Retrive the original library name from the library property
    get_target_property(_reallib ${LIB} ALIASED_TARGET)
    # If the ALIASED_TARGET property does not exist, it means we already have the original one
    if(NOT _reallib)
        set(${OUT} ${LIB} PARENT_SCOPE)
    else()
        set(${OUT} ${_reallib} PARENT_SCOPE)
    endif()
endfunction()

# # ORGINAL FUNCTION MOVED INTO utils/alias_dereference.cmake
# function(alias_dereference OUT LIB)
#     # First check the library exists
#     if(NOT TARGET ${LIB})
#         message(FATAL_ERROR "Library ${LIB} is not defined")
#     endif()
#     # Retrive the original library name from the library property
#     get_target_property(_reallib ${LIB} ALIASED_TARGET)
#     # If the ALIASED_TARGET property does not exist, it means we already have the original one
#     if(NOT _reallib)
#         set(${OUT} ${LIB} PARENT_SCOPE)
#         return()
#     endif()

#     # Iterate until no ALIASED_TARGET is found, meaning the original target is found
#     # Is this really needed?
#     while(_reallib)
#         set(_oldlib ${_reallib})
#         get_target_property(_reallib ${_reallib} ALIASED_TARGET)
#     endwhile()
#     # This if should not be needed, no?
#     if(_oldlib)
#         set(${OUT} ${_oldlib} PARENT_SCOPE)
#         return()
#     endif()
# endfunction()
