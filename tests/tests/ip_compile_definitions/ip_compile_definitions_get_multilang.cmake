include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_compile_definitions_get_multilang)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_compile_definitions(${IP} SYSTEMVERILOG
        -DSVDEF1=1
        SVDEF2=2
        )

    ip_compile_definitions(${IP} VERILOG
        VDEF1=1
        VDEF2=2
        )

    ip_compile_definitions(${IP} VHDL
        VHDLDEF1=1
        VHDLDEF2=2
        )

    get_ip_compile_definitions(COMPDEFS ${IP} VERILOG SYSTEMVERILOG)
    ct_assert_list(COMPDEFS)
    ct_assert_equal(COMPDEFS "VDEF1=1;VDEF2=2;SVDEF1=1;SVDEF2=2")

    get_ip_compile_definitions(COMPDEFS ${IP} VHDL SYSTEMVERILOG)
    ct_assert_list(COMPDEFS)
    ct_assert_equal(COMPDEFS "VHDLDEF1=1;VHDLDEF2=2;SVDEF1=1;SVDEF2=2")

    get_ip_compile_definitions(COMPDEFS ${IP} VERILOG VHDL)
    ct_assert_list(COMPDEFS)
    ct_assert_equal(COMPDEFS "VDEF1=1;VDEF2=2;VHDLDEF1=1;VHDLDEF2=2")

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.4
        )

    ip_compile_definitions(${IP} VERILOG
        VDEF3=3
        VDEF4=4
        )

    ip_compile_definitions(${IP} VHDL
        VHDLDEF3=3
        VHDLDEF4=4
        )

    ip_link(vendor::lib::ip::1.2.3 vendor::lib::ip2::1.2.4)

    get_ip_compile_definitions(COMPDEFS vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG)
    ct_assert_list(COMPDEFS)
    ct_assert_equal(COMPDEFS "VDEF3=3;VDEF4=4;VDEF1=1;VDEF2=2;VHDLDEF3=3;VHDLDEF4=4;VHDLDEF1=1;VHDLDEF2=2;SVDEF1=1;SVDEF2=2")

    get_ip_compile_definitions(COMPDEFS vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG NO_DEPS)
    ct_assert_list(COMPDEFS)
    ct_assert_equal(COMPDEFS "VDEF1=1;VDEF2=2;VHDLDEF1=1;VHDLDEF2=2;SVDEF1=1;SVDEF2=2")
endfunction()



