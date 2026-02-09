This table present the examples that are currently available with SoCMake, their current states and the tools that they support:
<div align="center">

|            Example            |    No EDA needed   |       Questa       |         VCS        |       XCelium      |      Verilator     |      Iverilog      |        GHDL        |   Vivado  |
| :---------------------------: | :----------------: | :----------------: | :----------------: | :----------------: | :----------------: | :----------------: | :----------------: | :-------: |
|              cpm              | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|             dpi-c             |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    | :warning: |
|          fecthcontent         | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|          linking_ips          | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|            options            | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|         simple_cocotb         |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |           |
|     simple_mixed_language     |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    |                    | :warning: |
| simple_mixed_language_sc_vlog |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |         :x:        |                    |                    |           |
|          simple_sc_sv         |                    |                    |                    |                    | :white_check_mark: |                    |                    |           |
|         simple_verilog        |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    | :warning: |
|          simple_vhdl          |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    | :white_check_mark: | :warning: |
|            systemc            | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|          uvm-systemc          | :white_check_mark: |                    |                    |                    |                    |                    |                    |           |
|           verilator           |                    |                    |                    |                    | :white_check_mark: |                    |                    |           |
|           vhpidirect          |                    | :white_check_mark: |                    |                    |                    |                    | :white_check_mark: |           |
</div>

:white_check_mark: : the example correctly run with the corresponding tool.\
:x: : the example is currently not working with the corresponding tool.\
:warning: the example can run with the tool but has not been verified.\
blank space : the example does not use the corresponding tool.