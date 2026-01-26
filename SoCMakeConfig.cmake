cmake_minimum_required(VERSION 3.25)

set(SoCMake_FOUND TRUE)

# ====================================
# ======== Core functions ============
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/socmake_graph.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/hwip.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/subdirectory_search.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/get_all_targets.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/print_help.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/graphviz.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/option.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/find_python.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/print_list.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/uniquify_files_by_basename.cmake")

# ====================================
# ======== Additional utilities ======
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/copy_rtl_files/copy_rtl_files.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/copy_rtl_files/read_rtl_sources.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/utils/copy_rtl_files/vhier.cmake")

# ====================================
# ======== Simulation ================
# ====================================

# ----- Verilator ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verilator/verilator.cmake")

# ----- iverilog ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/iverilog/iverilog.cmake")

# ----- xcelium ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/cadence/xcelium.cmake")

# ----- vcs ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/synopsys/vcs.cmake")

# ----- siemens ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/siemens/questasim.cmake")

# ----- ghdl ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/ghdl/ghdl.cmake")

# ----- vivado_sim ------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/xilinx/vivado_sim.cmake")

# ----- FC4SC -------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/fc4sc/fc4sc_merge_coverage.cmake")

# ----- VeriSC --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/verisc/verisc_install.cmake")

# ----- Cocotb --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/cocotb/cocotb.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/sim/cocotb/add_cocotb_tests.cmake")

# ====================================
# ======== PeakRDL ===================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_regblock.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_topgen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_halcpp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_ipblocksvg.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_html.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_socgen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_docusaurus.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/peakrdl/peakrdl_print.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/cmake/systemrdl/desyrdl.cmake")

# ====================================
# ======== FPGA ======================
# ====================================

# ------- Vivado --------
include("${CMAKE_CURRENT_LIST_DIR}/cmake/fpga/vivado/vivado.cmake")

# ====================================
# ======== SYNTH =====================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/sv2v.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/yosys/yosys.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/synth/yosys/yosys_build.cmake")

# ====================================
# ======== FIRMWARE ==================
# ====================================
set(IBEX_TOOLCHAIN "${CMAKE_CURRENT_LIST_DIR}/cmake/firmware/toolchains/riscv_toolchain.cmake"  CACHE INTERNAL "IBEX_TOOLCHAIN")

# ====================================
# ====== Linting, Formatting =========
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/lint/verible.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/lint/vhdl_linter.cmake")

# ====================================
# ====== Riscv =======================
# ====================================

include("${CMAKE_CURRENT_LIST_DIR}/cmake/riscv/sail/sail_install.cmake")

# ====================================
# ====== Build scripts ===============
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/build_scripts/systemc/systemc_build.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/build_scripts/uvm-systemc/uvm-systemc_build.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/build_scripts/verilator/verilator_build.cmake")

# ====================================
# ====== IPXact ======================
# ====================================
include("${CMAKE_CURRENT_LIST_DIR}/cmake/ipxact/importer/ipxact_ip_importer.cmake")

# fusesoc importer
include("${CMAKE_CURRENT_LIST_DIR}/cmake/fusesoc/add_ip_from_fusesoc.cmake")
