if(DUT_LANG STREQUAL "verilog")
    add_ip(counter2)
    ip_sources(${IP} VERILOG
        vlog/counter2.v)

elseif(DUT_LANG STREQUAL "systemc")
        add_library(counter2 INTERFACE)
        target_include_directories(counter2 INTERFACE ./sc)
endif()
