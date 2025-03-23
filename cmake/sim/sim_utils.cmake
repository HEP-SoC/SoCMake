include_guard(GLOBAL)

macro(__check_linked_interface_lib)
    get_target_property(linked_libraries ${IP_LIB} LINK_LIBRARIES)

    if(${__lib_to_check} IN_LIST linked_libraries)
        set(${RESULT} TRUE PARENT_SCOPE)
    else()
        set(${RESULT} FALSE PARENT_SCOPE)
    endif()
endmacro()

function(__is_socmake_systemc_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::SystemC")
    __check_linked_interface_lib()
endfunction()

function(__is_socmake_dpic_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::DPI-C")
    __check_linked_interface_lib()
endfunction()

function(__is_socmake_vhpi_lib RESULT IP_LIB)
    set(__lib_to_check "SoCMake::VHPI")
    __check_linked_interface_lib()
endfunction()

function(__is_socmake_ip_lib RESULT IP_LIB)
    get_target_property(ip_type ${IP_LIB} TYPE)
    get_target_property(ip_name ${IP_LIB} IP_NAME)

    if(ip_type STREQUAL "INTERFACE_LIBRARY" AND ip_name)
        set(${RESULT} TRUE PARENT_SCOPE)
    else()
        set(${RESULT} FALSE PARENT_SCOPE)
    endif()
endfunction()


