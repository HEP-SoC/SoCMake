include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)

project(adder NONE)

add_ip(adder
    DESCRIPTION "Just a simple adder")

set(gen_file ${CMAKE_BINARY_DIR}/f2.v)
add_custom_command(OUTPUT ${gen_file} 
    COMMAND touch ${gen_file}
    )

add_custom_target(generate
    DEPENDS ${gen_file}
)

ip_sources(${IP} VERILOG
    ./adder/adder.v
    ${gen_file}
    )

ip_sources(${IP} VERILOG FILE_SET synth
    ./adder/f1.v
    )

get_ip_sources(sources ${IP} VERILOG FILE_SETS DEFAULT)
message("${sources}")

# ip_include_directories(${IP} VERILOG
#     ./adder)

ip_install(${IP})
