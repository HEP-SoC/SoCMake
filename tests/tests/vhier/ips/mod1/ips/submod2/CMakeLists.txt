add_ip(submod2
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
    )

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/submod2.sv
    )

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
    )
