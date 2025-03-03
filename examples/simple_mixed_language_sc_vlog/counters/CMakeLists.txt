add_ip(counters)

if(DUT_LANG STREQUAL "verilog")
    ip_sources(${IP} VERILOG
        vlog/counters.v
        )
elseif(DUT_LANG STREQUAL "systemc")
    ip_sources(${IP} SYSTEMC
        sc/counters.cpp
        HEADERS
        sc/counters.h
        )
endif()

ip_include_directories(${IP} SYSTEMC
    sc
    )
target_include_directories(${IP} INTERFACE
    sc
    )


add_subdirectory(../counter1/ "counter1")
add_subdirectory(../counter2/ "counter2")

ip_link(${IP} 
        counter1 
        counter2
    )
