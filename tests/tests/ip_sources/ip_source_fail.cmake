include("${CMAKE_CURRENT_LIST_DIR}/../../../CMakeLists.txt")

set(TEST_NAME ip_sources_fail)

ct_add_test(NAME ${TEST_NAME} EXPECTFAIL)
function(${${TEST_NAME}})
    add_ip(ip
        VENDOR vendor
        LIBRARY lib
        VERSION 1.2.3
        )

    set(SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL TRUE)
    ip_sources(${IP} FAKELANG
        file1.fakelang
        svfile2.sv
        )
endfunction()

