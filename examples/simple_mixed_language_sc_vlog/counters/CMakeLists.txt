
if(DUT_LANG STREQUAL "verilog")
    add_ip(counters)
    ip_sources(${IP} VERILOG
        vlog/counters.v
        )
    if(SIMULATOR STREQUAL "xcelium")
        target_include_directories(${IP} INTERFACE ./sc/xcelium_shell/)
    elseif(SIMULATOR STREQUAL "mgc")
        ip_include_directories(${IP} SYSTEMC ./sc/mgc_shell/)
    endif()

elseif(DUT_LANG STREQUAL "systemc")

    if(SIMULATOR STREQUAL "xcelium" OR SIMULATOR STREQUAL "osci")
        set(IP counters)
        add_library(${IP}  OBJECT
            ./sc/counters.cpp
            )

        # This is Verilog shell for SystemC module, can be generated with xmshell
        ip_sources(${IP} VERILOG
            ./vlog/xcelium_shell/counters.v
            )

        set_target_properties(${IP}
            PROPERTIES 
                SOCMAKE_CXX_LIBRARY_TYPE SYSTEMC
                POSITION_INDEPENDENT_CODE TRUE
            )

        target_include_directories(${IP} INTERFACE ./sc)
    elseif(SIMULATOR STREQUAL "mgc")
        add_ip(counters)
        ip_sources(${IP} SYSTEMC
            sc/counters.cpp
            HEADERS
            sc/counters.h
            )
        ip_include_directories(${IP} SYSTEMC ./sc)
    endif()
endif()

add_subdirectory(../counter1/ "counter1")
add_subdirectory(../counter2/ "counter2")

ip_link(${IP}
        counter1 
        counter2
    )

if(DUT_LANG STREQUAL "systemc" AND (SIMULATOR STREQUAL "xcelium" OR SIMULATOR STREQUAL "osci"))
    target_link_libraries(${IP} PUBLIC
        counter1
        counter2)
endif()
