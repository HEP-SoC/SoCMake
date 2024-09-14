include(CTest)

add_custom_target(check
    COMMAND ctest $(JOBS) --output-on-failure
    )

add_custom_target(check_cdash
    COMMAND ctest $(JOBS) --output-on-failure -D Continuous
    )

add_subdirectory(iverilog)
add_subdirectory(vhier)
add_subdirectory(peakrdl)

include("getcmaketest.cmake")
include(cmake_test/cmake_test)

ct_add_dir(add_ip)
ct_add_dir(ip_include_directories)
ct_add_dir(ip_compile_definitions)
ct_add_dir(alias_dereference)
ct_add_dir(check_languages)
ct_add_dir(ip_sources)
ct_add_dir(ip_link)
