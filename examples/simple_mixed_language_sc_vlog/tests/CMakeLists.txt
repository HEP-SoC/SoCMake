add_ip(test_counters)


if(TEST_LANG STREQUAL "verilog")
    ip_sources(${IP} VERILOG
        vlog/test_counters.v
        )
elseif(TEST_LANG STREQUAL "systemc")
    ip_sources(${IP} SYSTEMC
        sc/test_counters.cpp
        HEADERS
        sc/test_counters.h
        )
endif()

ip_include_directories(${IP} SYSTEMC
    sc/
    )
target_include_directories(${IP} INTERFACE
    sc/
    )

add_subdirectory(../counters/ "counters")

ip_link(${IP}
        counters)
