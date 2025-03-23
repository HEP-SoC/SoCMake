cmake -DSIMULATOR=osci -DTEST_LANG=verilog -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build --target run_test_counters_verilator
rm -rf build

cmake -DSIMULATOR=osci -DTEST_LANG=systemc -DDUT_LANG=systemc  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build
./build/systemc_example
rm -rf build

cmake -DSIMULATOR=osci -DTEST_LANG=systemc -DDUT_LANG=verilog  -S $(pwd) -B $(pwd)/build
cmake --build $(pwd)/build
./build/systemc_example
rm -rf build
