if(DUT_LANG STREQUAL "verilog")
    add_ip(counters)
    ip_sources(${IP} VERILOG
        vlog/counters.v)
    if(SIMULATOR STREQUAL "vcs")
        ip_sources(${IP} VCS_SC_PORTMAP
            ./vcs_sc_map.map)
    endif()

elseif(DUT_LANG STREQUAL "systemc")
        set(IP counters)
        add_library(${IP} SHARED
            ./sc/counters.cpp)

        target_link_libraries(${IP} PRIVATE
            SoCMake::SystemC
        )

        target_include_directories(${IP} PUBLIC ./sc)
endif()

add_subdirectory(../counter1/ "counter1")
add_subdirectory(../counter2/ "counter2")

ip_link(${IP}
        counter1 
        counter2
    )

if(DUT_LANG STREQUAL "systemc")
    target_link_libraries(${IP} PUBLIC
        counter1
        counter2)
endif()
