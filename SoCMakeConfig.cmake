cmake_minimum_required(VERSION 3.25)

set(SoCMake_FOUND TRUE)

include("${CMAKE_CURRENT_LIST_DIR}/cmake/hwip.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/socmake_graph.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/add_subdirs.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/graphviz.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/multi_option.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/find_python.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/copy_rtl_files/copy_rtl_files.cmake")

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

# ----- vcs ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/synopsys/vcs.cmake")

# ----- ghdl ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/ghdl/ghdl.cmake")

# ----- FC4SC -------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/fc4sc/fc4sc_merge_coverage.cmake")

# ----- VeriSC --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verisc/verisc_install.cmake")

# ----- Cocotb --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/cocotb/cocotb_iverilog.cmake")

# ====================================
# ======== PeakRDL ===================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_regblock.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_regblock_wrap.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_halcpp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_ipblocksvg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_html/peakrdl_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_html/peakrdl_html_md.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_socgen/peakrdl_socgen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_docusaurus.cmake")
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
include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/yosys/yosys_build.cmake")

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
include("${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/linker_script/src/lds_props.cmake")

set(IBEX_TOOLCHAIN "${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/toolchains/riscv_toolchain.cmake"  CACHE INTERNAL "IBEX_TOOLCHAIN")

# ====================================
# ======== Documentation =============
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/docs/doxygen/doxygen.cmake")

# ====================================
# ====== Linting, Formatting =========
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/verible/verible.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/ghdl/vhdl_linter.cmake")

# ====================================
# ====== Riscv =======================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/riscv/sail/sail_install.cmake")

# ====================================
# ====== Tmake =======================
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/tmake/tmake.cmake")
