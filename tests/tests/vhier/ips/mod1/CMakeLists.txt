add_ip(mod1
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
    )

add_subdirectory("./ips/submod1/")
add_subdirectory("./ips/submod2/")

ip_sources(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl/mod1.sv
    )

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
    )

ip_link(${IP} test::ip::submod1 test::ip::submod2)
