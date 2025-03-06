# If its verilog every simulator works the same way
if(TEST_LANG STREQUAL "verilog")
    add_ip(test_counters)
    ip_sources(${IP} VERILOG
        vlog/test_counters.v
        )
elseif(TEST_LANG STREQUAL "systemc")

    # Xcelium uses CMake libraries for systemC
    if(SIMULATOR STREQUAL "xcelium" OR SIMULATOR STREQUAL "osci")
        set(IP test_counters)
        add_library(${IP}  SHARED
            ./sc/test_counters.cpp
            )
        target_include_directories(${IP} PUBLIC ./sc)

        set_target_properties(${IP}
            PROPERTIES 
                SOCMAKE_CXX_LIBRARY_TYPE SYSTEMC
                POSITION_INDEPENDENT_CODE TRUE
            )

        target_link_libraries(${IP} PUBLIC
            counters
            )

    # Questa for now uses SoCMake IPs for SystemC
    elseif(SIMULATOR STREQUAL "mgc")
        add_ip(test_counters)
        ip_sources(${IP} SYSTEMC
            sc/test_counters.cpp
            HEADERS
            sc/test_counters.h
            )
    endif()
endif()

add_subdirectory(../counters/ "counters")

ip_link(${IP}
        counters)
