#include "test_counters.h"

#ifdef VCSSYSTEMC
#include "systemc_user.h"
SNPS_REGISTER_SC_MODULE(test_counters);
#endif

#ifndef OSCI
SC_MODULE_EXPORT(test_counters);
#endif

