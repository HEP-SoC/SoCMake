include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_include_directories_get_multilang)

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

    ip_include_directories(${IP} VHDL
        /vhdldir1
        /vhdldir2
        )

    get_ip_include_directories(INCDIRS ${IP} VERILOG SYSTEMVERILOG)
    ct_assert_list(INCDIRS)
    ct_assert_equal(INCDIRS "/vdir1;/vdir2;/svdir1;/svdir2")

    get_ip_include_directories(INCDIRS ${IP} VHDL SYSTEMVERILOG)
    ct_assert_list(INCDIRS)
    ct_assert_equal(INCDIRS "/vhdldir1;/vhdldir2;/svdir1;/svdir2")

    get_ip_include_directories(INCDIRS ${IP} VERILOG VHDL)
    ct_assert_list(INCDIRS)
    ct_assert_equal(INCDIRS "/vdir1;/vdir2;/vhdldir1;/vhdldir2")

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.4
        )

    ip_include_directories(${IP} VERILOG
        /vdir3
        /vdir4
        )

    ip_include_directories(${IP} VHDL
        /vhdldir3
        /vhdldir4
        )

    ip_link(vendor::lib::ip::1.2.3 vendor::lib::ip2::1.2.4)

    get_ip_include_directories(INCDIRS vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG)
    ct_assert_list(INCDIRS)
    ct_assert_equal(INCDIRS "/vdir3;/vdir4;/vdir1;/vdir2;/vhdldir3;/vhdldir4;/vhdldir1;/vhdldir2;/svdir1;/svdir2")

    get_ip_include_directories(INCDIRS vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG NO_DEPS)
    ct_assert_list(INCDIRS)
    ct_assert_equal(INCDIRS "/vdir1;/vdir2;/vhdldir1;/vhdldir2;/svdir1;/svdir2")
endfunction()


