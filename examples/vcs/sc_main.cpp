#include <iostream>
#include <systemc>

#include "adder.h"

using namespace sc_core;
using namespace sc_dt;

SC_MODULE(TESTBENCH) {
  sc_signal<sc_bv<8>> a_in;
  sc_signal<sc_bv<8>> b_in;
  sc_signal<sc_bv<9>> out;

  adder dut{"dut"};

  void stimulus() {
    a_in.write(0);
    b_in.write(50);
    while (true) {
      a_in.write(a_in.read().to_uint() + 1);
      b_in.write(b_in.read().to_uint() + 2);

      wait(5, SC_NS);
    }
  }

  void checker() {
#ifdef VERBOSE
    std::cout << "Value a_in: " << a_in.read().to_uint()
              << " b_in: " << b_in.read().to_uint()
              << " Out: " << out.read().to_uint() << "\n";
#endif
    if (a_in.read().to_uint() + b_in.read().to_uint() != out.read().to_uint()) {
      std::cout << "Error in verilog\n";
      std::cout << "Value a_in: " << a_in.read().to_uint()
                << " b_in: " << b_in.read().to_uint()
                << " Out: " << out.read().to_uint() << "\n";
      exit(-1);
    }
  }


  SC_CTOR(TESTBENCH) {
    dut.a(a_in);
    dut.b(b_in);
    dut.o(out);

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

