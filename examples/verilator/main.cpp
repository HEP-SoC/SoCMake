#include <cstdlib>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vadder.h"

int main (int argc, char *argv[]) {
    Verilated::traceEverOn(true);

    Vadder dut;

    VerilatedVcdC* m_trace;
    m_trace = new VerilatedVcdC;
    dut.trace(m_trace, 99);
    m_trace->open("trace.vcd");

    dut.eval();

    for(int i =0; i<30; i++){
        dut.a = i;
        dut.b = i+10;

        dut.eval();
        m_trace->dump(10 * i + 10/2);

        std::cout << (uint32_t)dut.a <<
            " + " << (uint32_t)dut.b <<
            " = " << (uint32_t)dut.o << "\n";

        if(dut.o != 2*i+10){
            std::cerr << "Mismatch\n    DUT: " << dut.o << "\n    REF: " << 2*i+10 << "\n";
            std::exit(EXIT_FAILURE);
        }
    }

    m_trace->close();
    
    return 0;
}
