---
title: Global Variables
sidebar_label: Global Variables
sidebar_position: 1
---

# Global Variables

SoCMake exposes a set of global CMake variables that control its behaviour or communicate results back to the caller.

---

## User-Settable Flags

Set these variables in your `CMakeLists.txt` **before** calling the relevant SoCMake functions to change their behaviour.

### `SOCMAKE_ALLOW_UNDEFINED_TARGETS`

When set, SoCMake will not raise a fatal error if a library listed in `LINK_LIBRARIES` does not correspond to an existing CMake target. Useful when part of the dependency graph is built externally or conditionally.

```cmake
set(SOCMAKE_ALLOW_UNDEFINED_TARGETS TRUE)
ip_link(my_ip some_external_lib)
```

Default behaviour (unset): a `FATAL_ERROR` is emitted for any undefined linked target.

---

### `SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL`

Controls how SoCMake reacts when `ip_sources()` is called with a language not in the supported language list.

| Value | Behaviour |
|-------|-----------|
| unset (default) | `WARNING` is emitted and processing continues |
| set | `FATAL_ERROR` is emitted and configuration stops |

```cmake
set(SOCMAKE_UNSUPPORTED_LANGUAGE_FATAL TRUE)
```

The supported language list can be extended with `socmake_add_languages()`.

---

## Output Variables

These variables are set by SoCMake simulator functions in the **caller's scope** (`PARENT_SCOPE`). Read them after the function call to obtain the names of the created CMake targets or the simulation command.

| Variable | Type | Description |
|----------|------|-------------|
| `SOCMAKE_COMPILE_TARGET` | CMake target name | The compile/elaboration build target created by the simulator function (xcelium, vcs, questasim, verilator). |
| `SOCMAKE_ELABORATE_TARGET` | CMake target name | The separate elaborate target, where applicable (questasim, xcelium, verilator). Unset if no elaborate step is created. |
| `SOCMAKE_RUN_TARGET` | CMake target name | The simulation run target (vcs, verilator). Unset when `NO_RUN_TARGET` is passed to the simulator function. |
| `SOCMAKE_SIM_RUN_CMD` | string | The full command used to launch the simulation (xcelium, vcs, verilator, vivado_sim, iverilog). Useful for creating custom run wrappers. |
| `SOCMAKE_SIM_RUN_DIR` | path | The working directory in which the simulation is executed (xcelium, vcs, questasim). |

Example — reading output variables after calling `xcelium()`:

```cmake
xcelium(IP_LIB my_ip)

message(STATUS "Compile target : ${SOCMAKE_COMPILE_TARGET}")
message(STATUS "Run command    : ${SOCMAKE_SIM_RUN_CMD}")
message(STATUS "Run directory  : ${SOCMAKE_SIM_RUN_DIR}")
```
