include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_include_directories)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_include_directories(${IP} SYSTEMVERILOG
        /svdir1
        /svdir2
        )

    ip_include_directories(${IP} VERILOG
        /vdir1
        /vdir2
        )

# TEST SYSTEMVERILOG include directories

    get_ip_include_directories(SV_INCDIRS ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_INCDIRS)
    ct_assert_equal(SV_INCDIRS "/svdir1;/svdir2")

    ip_include_directories(${IP} SYSTEMVERILOG
        /svdir3
        /svdir4
        )

    get_ip_include_directories(SV_INCDIRS ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_INCDIRS)
    ct_assert_equal(SV_INCDIRS "/svdir1;/svdir2;/svdir3;/svdir4")


# TEST VERILOG include directories
    get_ip_include_directories(V_INCDIRS ${IP} VERILOG)
    ct_assert_list(V_INCDIRS)
    ct_assert_equal(V_INCDIRS "/vdir1;/vdir2")

    ip_include_directories(${IP} VERILOG
        /vdir3
        /vdir4
        )

    get_ip_include_directories(V_INCDIRS ${IP} VERILOG)
    ct_assert_list(V_INCDIRS)
    ct_assert_equal(V_INCDIRS "/vdir1;/vdir2;/vdir3;/vdir4")

# TEST Warning asserted on unknown language
    ip_include_directories(${IP} FAKELANG
        /fakelangdir1
        )
    ct_assert_prints("Language not supported: FAKELANG")

endfunction()
