
# GET THE RISCV TOOLCHAIN
if(ENV{RISCV_TOOLCHAIN})
    set(RISCV_GNU_PATH $ENV{RISCV_TOOLCHAIN})
elseif(RISCV_TOOLCHAIN)
    set(RISCV_GNU_PATH ${RISCV_TOOLCHAIN})
else()
    CPMAddPackage(
        NAME toolchain
        URL "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz"
        )
    set(RISCV_GNU_PATH ${toolchain_SOURCE_DIR})
endif()

set(CMAKE_SYSTEM_PROCESSOR riscv)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_ABI elf)

set(TOOLCHAIN_PREFIX "${CMAKE_SYSTEM_PROCESSOR}-none-${CMAKE_SYSTEM_ABI}")

find_program(RISCV_C_COMPILER   ${TOOLCHAIN_PREFIX}-gcc     HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++     HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_AR           ${TOOLCHAIN_PREFIX}-ar      HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_ASM          ${TOOLCHAIN_PREFIX}-as      HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_LINKER       ${TOOLCHAIN_PREFIX}-ld      HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_OBJCOPY      ${TOOLCHAIN_PREFIX}-objcopy HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_OBJDUMP      ${TOOLCHAIN_PREFIX}-objdump HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_RANLIB       ${TOOLCHAIN_PREFIX}-ranlib  HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_SIZE         ${TOOLCHAIN_PREFIX}-size    HINTS ${RISCV_GNU_PATH}/bin)
find_program(RISCV_STRIP        ${TOOLCHAIN_PREFIX}-strip   HINTS ${RISCV_GNU_PATH}/bin)

set(CMAKE_C_COMPILER ${RISCV_C_COMPILER})
set(CMAKE_CXX_COMPILER ${RISCV_CXX_COMPILER})
set(CMAKE_ASM ${RISCV_ASM})
set(CMAKE_AR ${RISCV_AR})
set(CMAKE_LINKER ${RISCV_LINKER})
set(CMAKE_OBJCOPY ${RISCV_OBJCOPY})
set(CMAKE_OBJDUMP ${RISCV_OBJDUMP})
set(CMAKE_RANLIB ${RISCV_RANLIB})
set(CMAKE_SIZE ${RISCV_SIZE})
set(CMAKE_STRIP ${RISCV_STRIP})


get_filename_component(RISCV_TOOLCHAIN_PATH ${RISCV_CXX_COMPILER} DIRECTORY CACHE)
set(RISCV_TOOLCHAIN_PREFIX "${TOOLCHAIN_PREFIX}-" CACHE STRING "")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 17)

set(CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_FLAGS "")
set(CMAKE_C_FLAGS "")
set(CMAKE_EXE_LINKER_FLAGS "")

string(APPEND CMAKE_CXX_FLAGS " -march=rv32imac_zicsr") # RV32 Integer, Compressed instruction set
string(APPEND CMAKE_CXX_FLAGS " -mabi=ilp32")         # int and pointers are 32bit, long 64bit, char 8bit, short 16bit

string(APPEND CMAKE_CXX_FLAGS " -static")
string(APPEND CMAKE_CXX_FLAGS " -nostartfiles")
string(APPEND CMAKE_CXX_FLAGS " -nostdlib") # Do not use the standard system startup files or libraries when linking https://cs107e.github.io/guides/gcc/

if(DEBUG)
    string(APPEND CMAKE_CXX_FLAGS " -g -O0")              # Debug flags
    string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,-g")
else()
    string(APPEND CMAKE_CXX_FLAGS " -Os")                 # Optimize for code size TODO move to release
    # string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,--strip-debug") # https://web.archive.org/web/20220530212919/https://linux.die.net/man/1/ld
    # string(APPEND CMAKE_EXE_LINKER_FLAGS " --strip-debug") # https://web.archive.org/web/20220530212919/https://linux.die.net/man/1/ld
endif()

string(APPEND CMAKE_CXX_FLAGS " -DHOST_BUILD")

string(APPEND CMAKE_CXX_FLAGS " -I${RISCV_GNU_PATH}/${TOOLCHAIN_PREFIX}/include/")
string(APPEND CMAKE_CXX_FLAGS " -I${RISCV_GNU_PATH}/${TOOLCHAIN_PREFIX}/include")

string(APPEND CMAKE_CXX_FLAGS " -specs=nano.specs")

# Until now both C and C++ and Linker have common flag settings
set(CMAKE_C_FLAGS ${CMAKE_CXX_FLAGS})

# Linker specific flags
string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,--print-memory-usage") # Print memory usage
string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,-Map=map_file.map")

string(APPEND CMAKE_EXE_LINKER_FLAGS " -L${RISCV_GNU_PATH}/${TOOLCHAIN_PREFIX}/lib") # TODO Is this needed?
string(APPEND CMAKE_EXE_LINKER_FLAGS " -lc -lm -lgcc -flto")
string(APPEND CMAKE_EXE_LINKER_FLAGS " -ffunction-sections -fdata-sections")


# set(CMAKE_C_FLAGS_DEBUG         <c_flags_for_debug>) # TODO
# set(CMAKE_C_FLAGS_RELEASE       <c_flags_for_release>)
# set(CMAKE_CXX_FLAGS_DEBUG       ${CXX_FLAGS})
# set(CMAKE_CXX_FLAGS_RELEASE     ${CXX_FLAGS})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM     NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY     ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE     ONLY)
