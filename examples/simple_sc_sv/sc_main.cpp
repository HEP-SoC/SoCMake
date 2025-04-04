#include <iostream>
#include <systemc>

#include "Vadder.h"

using namespace sc_core;
using namespace sc_dt;

SC_MODULE(TESTBENCH) {
  sc_signal<sc_uint<8>> a_in;
  sc_signal<sc_uint<8>> b_in;
  sc_signal<sc_uint<9>> out;

  Vadder dut{"dut"};

  void stimulus() {
    a_in.write(0);
    b_in.write(50);
    while (true) {
      a_in.write(a_in.read() + 1);
      b_in.write(b_in.read() + 2);

      wait(5, SC_NS);
    }
  }

  void checker() {
#ifdef VERBOSE
    std::cout << "Value a_in: " << a_in.read().to_string()
              << " b_in: " << b_in.read().to_string()
              << " Out: " << out.read().to_string() << "\n";
#endif
    if (a_in.read() + b_in.read() != out.read()) {
      std::cout << "Error in verilog\n";
      std::cout << "Value a_in: " << a_in.read().to_string()
                << " b_in: " << b_in.read().to_string()
                << " Out: " << out.read().to_string() << "\n";
      exit(-1);
    }
  }

  SC_CTOR(TESTBENCH) {
    dut.a(a_in);
    dut.b(b_in);
    dut.out(out);

    SC_THREAD(stimulus);

    SC_METHOD(checker);
    sensitive << out;
  }
};

int sc_main(int argc, char **argv) {
  std::cout << "Simple SystemC test with verilator dut\n";

  TESTBENCH tb("tb");

  sc_start(1000, SC_NS);

  return 0;
}
