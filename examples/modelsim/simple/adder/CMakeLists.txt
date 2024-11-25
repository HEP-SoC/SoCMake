
add_ip(adder
    DESCRIPTION "Just a simple adder")

ip_sources(${IP} VHDL
    ${CMAKE_CURRENT_LIST_DIR}/adder.vhdl
    )
