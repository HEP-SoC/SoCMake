include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_compile_definitions)

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

    get_ip_compile_definitions(COMP_DEFS ${IP} VERILOG)
    ct_assert_equal(COMP_DEFS "AAA=1;BBB=2;CCC=3;DDD")

endfunction()

