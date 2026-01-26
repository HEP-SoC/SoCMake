# Questasim

cmake -DSIMULATOR=questa -DTEST_LANG=systemc -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_questasim
rm -rf build

cmake -DSIMULATOR=questa -DTEST_LANG=systemc -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_questasim
rm -rf build

cmake -DSIMULATOR=questa -DTEST_LANG=verilog -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_questasim
rm -rf build

cmake -DSIMULATOR=questa -DTEST_LANG=verilog -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_questasim
rm -rf build

# Xcelium

cmake -DSIMULATOR=xcelium -DTEST_LANG=systemc -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_xcelium
rm -rf build

cmake -DSIMULATOR=xcelium -DTEST_LANG=systemc -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_xcelium
rm -rf build

cmake -DSIMULATOR=xcelium -DTEST_LANG=verilog -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_xcelium
rm -rf build

cmake -DSIMULATOR=xcelium -DTEST_LANG=verilog -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_xcelium
rm -rf build

## VCS

#cmake -DSIMULATOR=vcs -DTEST_LANG=systemc -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
#cmake --build $(pwd)/build --target run_test_counters_vcs
#rm -rf build
#
#cmake -DSIMULATOR=vcs -DTEST_LANG=systemc -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
#cmake --build $(pwd)/build --target run_test_counters_vcs
#rm -rf build
#
#cmake -DSIMULATOR=vcs -DTEST_LANG=verilog -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
#cmake --build $(pwd)/build --target run_test_counters_vcs
#rm -rf build
#
#cmake -DSIMULATOR=vcs -DTEST_LANG=verilog -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
#cmake --build $(pwd)/build --target run_test_counters_vcs
#rm -rf build
