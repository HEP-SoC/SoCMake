include("../../../SoCMakeConfig.cmake")
include("../../../cmake/ipxact/importer/ipxact_ip_importer.cmake")

cmake_minimum_required(VERSION 3.25)
project(import_ipxact_lib NONE)

# add_ip(common
#     LIBRARY work)
#
# ip_sources(work::common VHDL
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/types.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/target.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/device.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/config.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/amba.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/sparcv8.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/iface.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/ambacomp.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/macro.vhd
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_generic.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_atc35.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_proasic.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/multlib.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_axcel.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_tsmc25.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_fs90.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_umc18.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_virtex.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_atc25.vhd
#     # /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/common/tech_map.vhd
# )
#
# # add_ip_from_ipxact(/tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/dac/1.2/dac.xml)

set(SOCMAKE_ALLOW_UNDEFINED_TARGETS TRUE)
add_ip_from_ipxact(/tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/i2c/1.0/i2c.xml)

# ip_sources(${IP} VERILOG PREPEND
#     /tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/i2c/1.0/data/i2c/RTL/i2c_defs.v
#     
#     )
#
# # add_ip_from_ipxact(/tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/creg/1.0/creg.xml)
#
# # add_ip_from_ipxact(/tools/work/ipxact/Leon2/spiritconsortium.org/Leon2RTL/ahbram/1.2/ahbram.xml)
# # set_property(TARGET ${IP} PROPERTY LIBRARY leon2ahbram_lib)
#
# # ip_link(${IP}
# #     work::common
# # )
#
# # ghdl(${IP})
# modelsim(${IP})
