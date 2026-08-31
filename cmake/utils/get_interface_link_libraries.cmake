#[[[ @module get_interface_link_libraries
#]]

include_guard(GLOBAL)

#[[[
# Read a target's ``INTERFACE_LINK_LIBRARIES`` property with CMake's internal cross-directory
# markers stripped out and duplicates removed.
#
# When ``target_link_libraries()`` is called on a target from a different directory than the one
# it was created in, CMake wraps the linked entry as ``::@(directory-id);<lib>;::@`` so generators
# can resolve the name in the caller's scope (see
# https://cmake.org/cmake/help/latest/prop_tgt/INTERFACE_LINK_LIBRARIES.html). Since IPs are
# routinely linked across directories in this codebase, reading the raw property can surface these
# marker tokens as literal (bogus) list entries; this function filters them out so callers don't
# each have to repeat the workaround.
#
# :param OUTVAR: Variable that receives the cleaned list of linked libraries.
# :type OUTVAR: string
# :param TARGET: The target whose ``INTERFACE_LINK_LIBRARIES`` should be read.
# :type TARGET: string
#]]
function(get_interface_link_libraries OUTVAR TARGET)
    get_target_property(libs ${TARGET} INTERFACE_LINK_LIBRARIES)
    if(libs)
        list(FILTER libs EXCLUDE REGEX "::@")
        list(REMOVE_DUPLICATES libs)
    endif()
    set(${OUTVAR} ${libs} PARENT_SCOPE)
endfunction()
