# CNN

A 4-layer neural network on a Digilent Cora Z7-07S. Each layer is built from neurons. The weights and biases are pretrained and stored in memory files, separate from the neuron hardware. The design top, `zyNet`, takes pixels on an AXI-Stream port and is controlled over AXI-Lite.

Tested with Vivado 2023.1. The board part is `digilentinc.com:cora-z7-07s:part0:1.1` (`xc7z007sclg400-1`).

| Layer | Neurons | Weights per neuron | Activation |
| --- | --- | --- | --- |
| 1 | 30 | 784 | sigmoid |
| 2 | 30 | 30 | sigmoid |
| 3 | 10 | 30 | sigmoid |
| 4 | 10 | 10 | sigmoid |
| output | 10 | — | hardmax |

## Layout

| Path | Contents |
| --- | --- |
| `rtl/` | Verilog sources, including the simulation testbench `top_sim.v`, plus the `.mif` weight, bias, and sigmoid files |
| `IP/` | Xilinx IP (`.xci`). This design has none yet. Files added here are imported by the project script |
| `constraints/` | XDC constraints |
| `sim/test_data/` | Test vectors, `test_data_0000.txt` through `test_data_9999.txt` |
| `create_project.tcl` | Recreates the Vivado project |
| `work/` | Generated Vivado project. Not stored in git |

The memory files stay in `rtl/` because the HDL loads names such as `w_1_0.mif` and `sigContent.mif` from the source directory.

## Rebuild the Vivado project

From this directory, with Vivado 2023.1 on `PATH`:

```bat
vivado -mode batch -source create_project.tcl
```

Or, from the Vivado Tcl console after changing to this directory:

```tcl
source create_project.tcl
```

The script creates `work/cnn`. The design top is `zyNet` and the simulation top is `top_sim`. Any `.xci` placed in `IP/` is imported, and any `.xdc` in `constraints/` is added.

`top_sim` checks the first 100 samples (`MaxTestSamples` in `rtl/top_sim.v`). The full set of 10000 vectors is in `sim/test_data/`.
