cmake_minimum_required(VERSION 3.25)
project(simple_verilog_example NONE)

include("../../../../SoCMakeConfig.cmake")

find_package(tb CONFIG REQUIRED
    HINTS ${PROJECT_SOURCE_DIR}/../tb/build/here/*/*/*/*
    )
# add_subdirectory("..//" mult)
# ip_link(${IP} vendor::ip::mult::0.0.1)
#
#
iverilog(tb)
# ip_install(vendor__ip__mult__0.0.1)
# ip_install(tb)

help()

