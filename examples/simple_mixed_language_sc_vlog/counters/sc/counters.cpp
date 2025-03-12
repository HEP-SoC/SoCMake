#include "counters.h"
#include <iostream>


#ifndef OSCI
#ifndef VCSSYSTEMC
SC_MODULE_EXPORT(counters);
#endif
#endif

SC_HAS_PROCESS(counters);
counters::counters(sc_core::sc_module_name nm) : 
      sc_core::sc_module(nm)
    , clk("clk")
    , rst("rst")
    , cnt1_out("cnt1_out")
    , cnt2_out("cnt2_out")
{
    cnt1_i = new counter1("cnt1_i");
    cnt2_i = new counter2("cnt2_i");

    cnt1_i->clk(clk);
    cnt1_i->rst(rst);
    cnt1_i->cnt_out(cnt1_out);

    cnt2_i->clk(clk);
    cnt2_i->rst(rst);
    cnt2_i->cnt_out(cnt2_out);
}
