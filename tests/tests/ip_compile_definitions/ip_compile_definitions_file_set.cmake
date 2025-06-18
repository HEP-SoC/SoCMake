include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_compile_definitions_file_set_1)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip1)

    ip_compile_definitions(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        -DD1=1
        D2=2
        )

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D1=1;D2=2")

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG FILE_SETS SIMULATION)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D1=1;D2=2")

    get_ip_sources(comp_defs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(comp_defs) 
    ct_assert_equal(comp_defs "")
endfunction()

set(TEST_NAME ip_compile_definitions_file_set_2)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip2)

    ip_compile_definitions(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        D1
        D2
        )

    ip_compile_definitions(${IP} SYSTEMVERILOG FILE_SET SYNTHESIS
        D3
        D4
        )

    ip_compile_definitions(${IP} SYSTEMVERILOG
        D5
        D6
        )

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D1;D2;D3;D4;D5;D6")

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG FILE_SETS SIMULATION)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D1;D2")

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG FILE_SETS SYNTHESIS)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D3;D4")

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D5;D6")

    get_ip_compile_definitions(comp_defs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT SIMULATION SYNTHESIS)
    ct_assert_list(comp_defs) 
    ct_assert_equal(comp_defs "D5;D6;D1;D2;D3;D4")
endfunction()

