if(DUT_LANG STREQUAL "verilog")
    add_ip(counter1)
    ip_sources(${IP} VERILOG 
        vlog/counter1.v)

elseif(DUT_LANG STREQUAL "systemc")
        add_library(counter1 INTERFACE)
        target_include_directories(counter1 INTERFACE ./sc)
endif()
