#[[[ @module sim_utils
#]]

include_guard(GLOBAL)

# This macro is used if a given library as been linked to the IP library.
# It is used by the following functions to check some libraries.
macro(__check_linked_interface_lib)
    get_target_property(linked_libraries ${IP_LIB} LINK_LIBRARIES)

    if(${__lib_to_check} IN_LIST linked_libraries)
        set(${RESULT} TRUE PARENT_SCOPE)
    else()
        set(${RESULT} FALSE PARENT_SCOPE)
    endif()
endmacro()

# This function is used to check if the SystemC library has been linked in the project.
#
# :param RESULT: If true, the SystemC library has correctly been linked to the IP library.
# :type RESULT: bool
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
function(__is_socmake_systemc_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::SystemC")
    __check_linked_interface_lib()
endfunction()

# This function is used to check if the DPI-C library has been linked in the project.
#
# :param RESULT: If true, the DPI-C library has correctly been linked to the IP library.
# :type RESULT: bool
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
function(__is_socmake_dpic_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::DPI-C")
    __check_linked_interface_lib()
endfunction()

# This function is used to check if the VHPI library has been linked in the project.
#
# :param RESULT: If true, the VHPI library has correctly been linked to the IP library.
# :type RESULT: bool
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
function(__is_socmake_vhpi_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::VHPI")
    __check_linked_interface_lib()
endfunction()

# This function is used to check if the IP library is of the type : ``INTERFACE_LIBRARY``
#
# :param RESULT: If true, the IP library is of the right type.
# :type RESULT: bool
# :param IP_LIB: The target IP library.
# :type IP_LIB: string
function(__is_socmake_ip_lib RESULT IP_LIB)
    get_target_property(ip_type ${IP_LIB} TYPE)
    get_target_property(ip_name ${IP_LIB} IP_NAME)

    if(ip_type STREQUAL "INTERFACE_LIBRARY" AND ip_name)
        set(${RESULT} TRUE PARENT_SCOPE)
    else()
        set(${RESULT} FALSE PARENT_SCOPE)
    endif()
endfunction()
