add_ip(counter2)

if(DUT_LANG STREQUAL "verilog")
    ip_sources(${IP} VERILOG
        vlog/counter2.v
        )
elseif(DUT_LANG STREQUAL "systemc")
    ip_sources(${IP} SYSTEMC
        HEADERS
        sc/counter2.h
        )
endif()

ip_include_directories(${IP} SYSTEMC
    sc
    )
target_include_directories(${IP} INTERFACE
    sc
    )

