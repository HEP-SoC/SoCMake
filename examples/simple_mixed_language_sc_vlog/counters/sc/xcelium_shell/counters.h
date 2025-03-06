#include "systemc.h"

class counters : public xmsc_foreign_module {
public:
  sc_in<bool> clk;
  sc_in<bool> rst;

  sc_out<sc_uint<8>> cnt1_out;
  sc_out<sc_uint<8>> cnt2_out;

  SC_CTOR(counters) : clk("clk"), rst("rst"), cnt1_out("cnt1_out"), cnt2_out("cnt2_out") { }
  const char* hdl_name() const { return "counters"; } // NC mode name
};


