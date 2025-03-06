#include "systemc.h"

class counters : public sc_foreign_module {
public:
  sc_in<bool> clk;
  sc_in<bool> rst;

  sc_out<sc_uint<8>> cnt1_out;
  sc_out<sc_uint<8>> cnt2_out;

  counters(sc_module_name nm) : sc_foreign_module(nm, hdl_name()), clk("clk"), rst("rst"), cnt1_out("cnt1_out"), cnt2_out("cnt2_out") 
    { 
        // elaborate_foreign_module(hdl_name()); 
    }
  const char* hdl_name() const { return "counters"; } // NC mode name
};



