cmake_minimum_required(VERSION 3.27)
project(iverilog_compile_args NONE)

# --- SV_COMPILE_ARGS ---

add_ip(tests::iverilog::iverilog_compile_args::1)

ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb.v)

# SV_COMPILE_ARGS are forwarded verbatim to the iverilog command line.
# The testbench checks that -DEXTRA_DEF was received by the preprocessor.
iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb_compile_args
    SV_COMPILE_ARGS -DEXTRA_DEF
)

include(CTest)

add_test(NAME iverilog_compile_args COMMAND ${PROJECT_BINARY_DIR}/tb_compile_args)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)

# --- COMPILE_DEFINITIONS ---

add_ip(tests::iverilog::iverilog_compile_definitions::1)

ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb.v)

ip_compile_definitions(${IP} SYSTEMVERILOG EXTRA_DEF)

# The testbench checks that -DEXTRA_DEF was received by the preprocessor.
iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb_compile_definitions
)

include(CTest)

add_test(NAME iverilog_compile_definitions COMMAND ${PROJECT_BINARY_DIR}/tb_compile_definitions)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
