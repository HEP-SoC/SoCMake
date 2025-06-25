include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)

project(adder NONE)

foreach(i RANGE 1 10)
    add_ip(vendor::ip::adder::0.0.${i} NO_ALIAS
        DESCRIPTION "Just a simple adder")

    ip_sources(${IP} VERILOG
        ./adder/adder.v
        # HEADERS
        # ./adder/adder.v
        )

# ip_include_directories(${IP} VERILOG
#     ./adder)

    ip_install(${IP})
endforeach()

add_ip(vendor::ip::mult::0.0.1 NO_ALIAS
    DESCRIPTION "Just a simple adder")

ip_sources(${IP} VERILOG
    ./adder/adder.v
    # HEADERS
    # ./adder/adder.v
    )

# ip_include_directories(${IP} VERILOG
#     ./adder)

ip_install(${IP})
