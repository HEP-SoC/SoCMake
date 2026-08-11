add_ip(includes
    VENDOR test
    LIBRARY ip
    VERSION 0.0.1
)

ip_include_directories(${IP} SYSTEMVERILOG
    ${CMAKE_CURRENT_LIST_DIR}/rtl
)
