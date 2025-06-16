include("../../../SoCMakeConfig.cmake")
include("../../../cmake/ipxact/importer/ipxact_ip_importer.cmake")

cmake_minimum_required(VERSION 3.25)
project(import_ipxact_lib NONE)

set(SOCMAKE_ALLOW_UNDEFINED_TARGETS TRUE)
add_ip_from_ipxact(/tools/shared/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/i2c/1.0/i2c.xml)

#xcelium(spiritconsortium.org::Leon2RTL::i2c::1.0)

help()
