#include <systemc>
#include "test_counters.h"

int sc_main(int argc, char* argv[]) {
    test_counters tb("tb");
    sc_core::sc_start(1000, sc_core::SC_NS);

    return 0;
}

