# include("${CMAKE_CURRENT_LIST_DIR}/../../CMakeLists.txt")
# cmake_minimum_required(VERSION 3.25)
# project(iverilog_test NONE)
#
# add_ip(ip
#     VENDOR vendor
#     LIBRARY lib
#     VERSION 1.2.3
#     )
#
# ip_sources(${IP} VERILOG
#     ${PROJECT_SOURCE_DIR}/tb.v
#     )
#
# iverilog(${IP})
#
# execute_process(COMMAND make help)
# # execute_process(COMMAND ${PROJECT_BINARY_DIR}/${IP}_iv)
#
# # include(CTest)
#
# # add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_BINARY_DIR}/${IP}_iv)
#
#
# # add_dependencies(check ${IP}_iverilog)
