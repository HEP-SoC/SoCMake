cmake_minimum_required(VERSION 3.25)

set(SoCMake_FOUND TRUE)

include("${CMAKE_CURRENT_LIST_DIR}/cmake/rtllib.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/hwip.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/add_subdirs.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/graphviz.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/multi_option.cmake")

# ====================================
# ======== Simulation ================
# ====================================

# ----- Verilator ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verilator/verilate.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verilator/verilate_xml.cmake")

# ----- iverilog ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/iverilog/iverilog.cmake")

# ----- xcelium ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/cadence/xcelium.cmake")

# ----- VeriSC --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verisc/verisc_install.cmake")
# ====================================
# ======== PeakRDL ===================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_regblock.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_halcpp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_ipblocksvg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_html/peakrdl_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_html/peakrdl_html_md.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_socgen/peakrdl_socgen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_print.cmake")

# ====================================
# ======== FPGA ======================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/fpga/uart_programmer/uart_programmer.cmake")

# ------- Vivado --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/fpga/vivado/vivado.cmake")

# ====================================
# ======== SYNTH =====================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/sv2v.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/yosys/yosys.cmake")

# ====================================
# ======== Safety ====================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/tmrg/tmrg/tmrg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/tmrg/tmrv/tmrv.cmake")



# ====================================
# ======== FIRMWARE ==================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/fw_utils.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/add_tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/linker_script/gen_lds.cmake")

set(IBEX_TOOLCHAIN "${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/toolchains/ibex_toolchain.cmake"  CACHE INTERNAL "IBEX_TOOLCHAIN")
set(IBEX_TOOLCHAIN_BASE "${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/toolchains/ibex_toolchain_base.cmake"  CACHE INTERNAL "IBEX_TOOLCHAIN_BASE")

# ====================================
# ======== Documentation =============
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/docs/doxygen/doxygen.cmake")

# ====================================
# ====== Linting, Formatting =========
# =====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/verible/verible.cmake")

# ====================================
# ====== Riscv =======================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/riscv/sail/sail_install.cmake")
