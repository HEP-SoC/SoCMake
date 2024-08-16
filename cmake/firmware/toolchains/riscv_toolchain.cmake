
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

set(CMAKE_C_FLAGS "")
set(CMAKE_CXX_FLAGS "")
set(CMAKE_EXE_LINKER_FLAGS "")

#############################
# Machine-Dependent Options #
#############################
# RV32
# i : Integer
# m : Integer Multiplication and Division
# a : Atomic instructions
# c : Compressed instructions
# zicsr : CSR Instructions (explicitely required with latest specs)
string(APPEND CMAKE_C_FLAGS " -march=rv32imc_zicsr")
# int and pointers are 32bit, long 64bit, char 8bit, short 16bit
string(APPEND CMAKE_C_FLAGS " -mabi=ilp32")

################################
# Options for Directory Search #
################################
# Add the directory dir to the list of directories to be searched for header files during preprocessing
# string(APPEND CMAKE_C_FLAGS " -I${RISCV_GNU_PATH}/${TOOLCHAIN_PREFIX}/include/")

#####################################
# Options that Control Optimization #
#####################################
# Place each function or data item into its own section in the output file
# if the target supports arbitrary sections. The name of the function or
# the name of the data item determines the section name in the output file.
# string(APPEND CMAKE_C_FLAGS " -ffunction-sections")
# string(APPEND CMAKE_C_FLAGS " -fdata-sections")

# Optimize for size by default
string(APPEND CMAKE_C_FLAGS " -Os")

# Pass common flags for c++ compilation flow
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})

#######################
# Options for Linking #
#######################
# Do not use the standard system startup
string(APPEND CMAKE_EXE_LINKER_FLAGS " -nostartfiles")
# Prevents linking with the shared libraries
string(APPEND CMAKE_EXE_LINKER_FLAGS " -static")

# Print memory usage
string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,--print-memory-usage")
# Generate executable map file
string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,-Map=map_file.map")

##########################################
# Options Controlling the Kind of Output #
##########################################
# Use embedded class libnano_c
string(APPEND CMAKE_EXE_LINKER_FLAGS " -specs=nano.specs")

################################
# Options for Directory Search #
################################
# Add directory dir to the list of directories to be searched for -l
# string(APPEND CMAKE_EXE_LINKER_FLAGS " -L${RISCV_GNU_PATH}/${TOOLCHAIN_PREFIX}/lib")

# Search the library named library when linking.
# string(APPEND CMAKE_EXE_LINKER_FLAGS " -lc -lgcc -lm")


# set(CMAKE_C_FLAGS_DEBUG         <c_flags_for_debug>) # TODO
# set(CMAKE_C_FLAGS_RELEASE       <c_flags_for_release>)
# set(CMAKE_CXX_FLAGS_DEBUG       ${CXX_FLAGS})
# set(CMAKE_CXX_FLAGS_RELEASE     ${CXX_FLAGS})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM     NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY     ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE     ONLY)
