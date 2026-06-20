
add_ip(acme::gates_lib::gates::1.0
    DESCRIPTION "Basic logic gates")

ip_sources(${IP} VHDL
    and_gate.vhdl
    xor_gate.vhdl
    )
