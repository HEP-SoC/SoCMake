
if(DUT_LANG STREQUAL "verilog")
    add_ip(counter2)
    ip_sources(${IP} VERILOG
        vlog/counter2.v
        )
elseif(DUT_LANG STREQUAL "systemc")
    if(SIMULATOR STREQUAL "xcelium" OR SIMULATOR STREQUAL "osci" OR SIMULATOR STREQUAL "vcs")
        set(IP counter2)
        add_library(${IP} INTERFACE)
        target_include_directories(${IP} INTERFACE ./sc)

    # For now Questa uses SoCMake IP block for SystemC
    elseif(SIMULATOR STREQUAL "mgc")
        add_ip(counter2)
        ip_sources(${IP} SYSTEMC
            HEADERS
            sc/counter2.h
            )
        ip_include_directories(${IP} SYSTEMC ./sc)
    endif()
endif()
