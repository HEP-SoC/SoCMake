
add_ip(acme::counter_lib::counter::1.0
    DESCRIPTION "2-bit counter using gates from gates_lib")

ip_sources(${IP} VHDL
    counter.vhdl
    )

ip_link(${IP} acme::gates_lib::gates)
