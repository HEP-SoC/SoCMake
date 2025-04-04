#pragma once

#include <systemc>

#include "counter1.h"
#include "counter2.h"

SC_MODULE(counters) {
    sc_core::sc_in<bool> clk;
    sc_core::sc_in<bool> rst;
    sc_core::sc_out<sc_dt::sc_uint<8>> cnt1_out;
    sc_core::sc_out<sc_dt::sc_uint<8>> cnt2_out;

    counter1 *cnt1_i;
    counter2 *cnt2_i;

    SC_CTOR(counters) : clk("clk"), rst("rst"), cnt1_out("cnt1_out"), cnt2_out("cnt2_out") {
        cnt1_i = new counter1("cnt1_i");
        cnt2_i = new counter2("cnt2_i");

        cnt1_i->clk(clk);
        cnt1_i->rst(rst);
        cnt1_i->cnt_out(cnt1_out);

        cnt2_i->clk(clk);
        cnt2_i->rst(rst);
        cnt2_i->cnt_out(cnt2_out);
    }

    ~counters() {
        delete cnt1_i;
        delete cnt2_i;
    }
};

