include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_sources_get_multilang)

ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    ip_sources(${IP} SYSTEMVERILOG
        svfile1.sv
        svfile2.sv
        )

    ip_sources(${IP} VERILOG
        vfile1.v
        vfile2.v
        )

    ip_sources(${IP} VHDL
        vhdlfile1.vhdl
        vhdlfile2.vhdl
        )

    get_ip_sources(SOURCES ${IP} VERILOG SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "vfile1.v;vfile2.v;svfile1.sv;svfile2.sv")

    get_ip_sources(SOURCES ${IP} VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "vhdlfile1.vhdl;vhdlfile2.vhdl;svfile1.sv;svfile2.sv")

    get_ip_sources(SOURCES ${IP} VERILOG VHDL)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "vfile1.v;vfile2.v;vhdlfile1.vhdl;vhdlfile2.vhdl")

    add_ip(ip2
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.4
        )

    ip_sources(${IP} VERILOG
        vfile3.v
        vfile4.v
        )

    ip_sources(${IP} VHDL
        vhdlfile3.vhdl
        vhdlfile4.vhdl
        )

    ip_link(vendor::lib::ip::1.2.3 vendor::lib::ip2::1.2.4)

    get_ip_sources(SOURCES vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "vfile3.v;vfile4.v;vfile1.v;vfile2.v;vhdlfile3.vhdl;vhdlfile4.vhdl;vhdlfile1.vhdl;vhdlfile2.vhdl;svfile1.sv;svfile2.sv")

    get_ip_sources(SOURCES vendor::lib::ip::1.2.3 VERILOG VHDL SYSTEMVERILOG NO_DEPS)
    ct_assert_list(SOURCES)
    ct_assert_equal(SOURCES "vfile1.v;vfile2.v;vhdlfile1.vhdl;vhdlfile2.vhdl;svfile1.sv;svfile2.sv")
endfunction()

