#include <cstdint>

extern "C" uint32_t hello(uint32_t data);
uint32_t hello(uint32_t data)
{
    return data + 10;
}
