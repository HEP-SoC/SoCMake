include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_compile_definitions_hier)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_compile_definitions(${IP} VERILOG
        -DAAA=1
        -D BBB=2
        CCC=3
        DDD
        )

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_compile_definitions(${IP} VERILOG
        -DQQQ=1
        -D WWW=2
        EEE=3
        TTT
        )
    ip_link(vendor::lib::ip::1.2.3 vendor::lib::ip2::1.2.3)

    get_ip_compile_definitions(COMP_DEFS vendor::lib::ip::1.2.3 VERILOG)
    ct_assert_equal(COMP_DEFS "QQQ=1;WWW=2;EEE=3;TTT;AAA=1;BBB=2;CCC=3;DDD")

endfunction()

