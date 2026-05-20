add_ip(submod1
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
    )

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/submod1.sv
    )

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
    )
