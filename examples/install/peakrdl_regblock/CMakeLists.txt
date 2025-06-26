include("../../../SoCMakeConfig.cmake")

cmake_minimum_required(VERSION 3.25)

project(adder NONE)

add_ip(vendor::ip::simple::0.0.1 NO_ALIAS
    DESCRIPTION "Just a simple generated IP block"
)

ip_sources(${IP} SYSTEMRDL
    ./simple.rdl
    )

peakrdl_regblock(${IP})

ip_install(${IP}
    LANGUAGES SYSTEMVERILOG
)
