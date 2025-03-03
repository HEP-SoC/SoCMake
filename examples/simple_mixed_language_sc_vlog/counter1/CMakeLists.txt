
add_ip(counter1)

if(DUT_LANG STREQUAL "verilog")
    ip_sources(${IP} VERILOG
        vlog/counter1.v
        )
elseif(DUT_LANG STREQUAL "systemc")
    ip_sources(${IP} SYSTEMC
        HEADERS
        sc/counter1.h
        )
endif()

ip_include_directories(${IP} SYSTEMC
    sc
    )
target_include_directories(${IP} INTERFACE
    sc
    )
