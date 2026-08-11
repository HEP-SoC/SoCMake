cmake_minimum_required(VERSION 3.27)
project(iverilog_include_directories NONE)

# --- INCLUDE_DIRECTORIES ---

add_ip(tests::iverilog::iverilog_include_directories::1)

ip_sources(${IP} VERILOG ${PROJECT_SOURCE_DIR}/tb_incdirs.v)

# ip_include_directories adds the inc/ path so iverilog receives -I<inc/>.
# The testbench includes inc_header.vh which defines INC_DIRS_PASS.
ip_include_directories(${IP} VERILOG ${PROJECT_SOURCE_DIR}/inc)

iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb_inc_dirs
)

add_test(
    NAME iverilog_include_directories
    COMMAND ${PROJECT_BINARY_DIR}/tb_inc_dirs
)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)

# --- HEADER FILE_SET ---

add_ip(tests::iverilog::iverilog_header_file_set::1)

ip_sources(${IP}
    VERILOG ${PROJECT_SOURCE_DIR}/tb_incdirs.v
    HEADERS ${PROJECT_SOURCE_DIR}/inc/inc_header.vh
)

iverilog(${IP}
    EXECUTABLE ${PROJECT_BINARY_DIR}/tb_header_file_set
)

add_test(
    NAME iverilog_header_file_set
    COMMAND ${PROJECT_BINARY_DIR}/tb_header_file_set
)

add_dependencies(check ${IP}_iverilog)
add_dependencies(check_cdash ${IP}_iverilog)
