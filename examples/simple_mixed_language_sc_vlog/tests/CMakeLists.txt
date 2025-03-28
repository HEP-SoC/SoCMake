# If its verilog every simulator works the same way
if(TEST_LANG STREQUAL "verilog")
    add_ip(test_counters)
    ip_sources(${IP} VERILOG
        vlog/test_counters.v
        )
elseif(TEST_LANG STREQUAL "systemc")

    set(IP test_counters)
    add_library(${IP} SHARED
        ./sc/test_counters.cpp
        # ./sc_main.cpp
        )
    set_property(TARGET ${IP} PROPERTY IP_NAME test_counters)
    target_include_directories(${IP} PUBLIC ./sc)

    target_link_libraries(${IP} PRIVATE
        SoCMake::SystemC
    )

    target_link_libraries(${IP} PUBLIC
        counters)
endif()

add_subdirectory(../counters/ "counters")

ip_link(${IP}
        counters)

