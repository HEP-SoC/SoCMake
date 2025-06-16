include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")
set(CDIR ${CMAKE_CURRENT_LIST_DIR})

set(TEST_NAME ip_include_directories)

set(TEST_NAME ip_sources_file_set_1)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip1)

    ip_include_directories(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        ${CDIR}/dir1
        ${CDIR}/dir2
        )

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir1;${CDIR}/dir2")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG FILE_SETS SIMULATION)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir1;${CDIR}/dir2")

    get_ip_sources(incdirs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_not_list(incdirs)
    ct_assert_equal(incdirs "")
endfunction()

set(TEST_NAME ip_sources_file_set_2)
ct_add_test(NAME ${TEST_NAME})
function(${${TEST_NAME}})
    add_ip(ip2)

    ip_include_directories(${IP} SYSTEMVERILOG FILE_SET SIMULATION
        ${CDIR}/dir1
        ${CDIR}/dir2
        )

    ip_include_directories(${IP} SYSTEMVERILOG FILE_SET SYNTHESIS
        ${CDIR}/dir3
        ${CDIR}/dir4
        )

    ip_include_directories(${IP} SYSTEMVERILOG
        ${CDIR}/dir5
        ${CDIR}/dir6
        )

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir1;${CDIR}/dir2;${CDIR}/dir3;${CDIR}/dir4;${CDIR}/dir5;${CDIR}/dir6")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG FILE_SETS SIMULATION)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir1;${CDIR}/dir2")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG FILE_SETS SYNTHESIS)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir3;${CDIR}/dir4")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir5;${CDIR}/dir6")

    get_ip_include_directories(incdirs ${IP} SYSTEMVERILOG FILE_SETS DEFAULT SIMULATION SYNTHESIS)
    ct_assert_list(incdirs)
    ct_assert_equal(incdirs "${CDIR}/dir5;${CDIR}/dir6;${CDIR}/dir1;${CDIR}/dir2;${CDIR}/dir3;${CDIR}/dir4")
endfunction()
