include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")

set(TEST_NAME ip_sources)

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

# TEST SYSTEMVERILOG include directories

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "svfile1.sv;svfile2.sv")

    ip_sources(${IP} SYSTEMVERILOG
        svfile3.sv
        svfile4.sv
        )

    get_ip_sources(SV_SOURCES ${IP} SYSTEMVERILOG)
    ct_assert_list(SV_SOURCES)
    ct_assert_equal(SV_SOURCES "svfile1.sv;svfile2.sv;svfile3.sv;svfile4.sv")


# TEST VERILOG include directories
    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "vfile1.v;vfile2.v")

    ip_sources(${IP} VERILOG
        vfile3.v
        vfile4.v
        )

    get_ip_sources(V_SOURCES ${IP} VERILOG)
    ct_assert_list(V_SOURCES)
    ct_assert_equal(V_SOURCES "vfile1.v;vfile2.v;vfile3.v;vfile4.v")

# TEST Warning asserted on unknown language
    ip_sources(${IP} FAKELANG
        fakelang.fake
        )
    ct_assert_prints("Language not supported: FAKELANG")

endfunction()
