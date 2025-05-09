import cocotb
from cocotb.triggers import Timer

class Colors:
    RESET = "\033[0m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    BOLD = "\033[1m"

@cocotb.test()
async def simple_cocotb_example(dut):
  dut._log.info("Running simple cocotb example test...")

  for i in range(10):
    dut._log.info(f"{Colors.YELLOW}{Colors.BOLD}Test iteration {i+1}.{Colors.RESET}")
    # Set adder inputs
    dut.NUM1.value = i
    dut.NUM2.value = i
    expected_result = i + i
    await Timer(5, units="ns")
    result = dut.SUM.value
    if(expected_result == result):
      dut._log.info(f"{Colors.GREEN}{Colors.BOLD}Test passed.{Colors.RESET}")
    else:
      dut._log.info(f"{Colors.RED}{Colors.BOLD}Test failed.{Colors.RESET}")
      raise ValueError(f"{Colors.RED}{Colors.BOLD}Expected: {expected_result} - Obtained: {result}{Colors.RESET}")
