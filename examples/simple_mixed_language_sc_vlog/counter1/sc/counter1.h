#pragma once

#include <systemc>

SC_MODULE(counter1) {
    sc_core::sc_in<bool> clk;
    sc_core::sc_in<bool> rst;
    sc_core::sc_out<sc_dt::sc_uint<8>> cnt_out;

    sc_dt::sc_uint<8> cnt_reg;

    void count_process() {
        if (rst.read()) {
            cnt_reg = 0;
        } else {
            cnt_reg += 1;
        }
        cnt_out.write(cnt_reg);
    }

    SC_CTOR(counter1) {
        SC_METHOD(count_process);
        sensitive << clk.pos();
    }
};
