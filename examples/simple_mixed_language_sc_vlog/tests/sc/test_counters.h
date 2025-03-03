#include <iostream>

#include <systemc>
#include "counters.h"


SC_MODULE(test_counters) {
    sc_core::sc_clock  clk;
    sc_core::sc_signal<bool> rst;

    sc_core::sc_signal<sc_dt::sc_uint<8>> cnt1_out;
    sc_core::sc_signal<sc_dt::sc_uint<8>> cnt2_out;

    counters *counters_i;

    void rst_gen();
    void monitor_cnt();

    SC_CTOR(test_counters) : 
        clk("clk", 10, sc_core::SC_NS),
        rst("rst"),
        cnt1_out("cnt1_out"),
        cnt2_out("cnt2_out") 
    {
        // counters_i = new counters("counters_i", "counters");
        counters_i = new counters("counters_i");

        counters_i->clk(clk);
        counters_i->rst(rst);
        counters_i->cnt1_out(cnt1_out);
        counters_i->cnt2_out(cnt2_out);

        SC_THREAD(rst_gen);
        SC_CTHREAD(monitor_cnt, clk);

    }

    ~test_counters(){
        delete counters_i;
    }

};

void test_counters::rst_gen(){
    rst.write(1);
    sc_core::wait(clk.posedge_event());
    sc_core::wait(clk.posedge_event());
    sc_core::wait(clk.posedge_event());
    rst.write(0);
}

void test_counters::monitor_cnt(){
    while(1){
        std::cout << "Current simulation time is: " << sc_core::sc_time_stamp() << "\n";
        std::cout << "CNT1: " << cnt1_out.read() << "\n";
        std::cout << "CNT2: " << cnt2_out.read() << "\n";

        if(cnt2_out.read() == 208)
            sc_core::sc_stop();

        sc_core::wait();

    }
}
