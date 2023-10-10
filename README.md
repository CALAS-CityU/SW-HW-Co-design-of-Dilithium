# High-Performance and Configurable SW/HW Co-design of Post-Quantum Signature CRYSTALS-Dilithium

Important Notes: Our code has passed the Artifact Evaluation (AE) of ACM TRETS. We have uploaded full code to the [Zendo website](https://zenodo.org/record/7546038), which fixed errors in this repository and provided more details of the paper results calculation.

This repository is for our paper "[High-Performance and Configurable SW/HW Co-design of Post-Quantum Signature CRYSTALS-Dilithium](https://dl.acm.org/doi/10.1145/3569456)" published in ACM Transactions on Reconfigurable Technology and Systems (TRETS). It hosts a hardware accelerator for the post-quantum signature scheme [CRYSTALS-Dilithium](https://pq-crystals.org/dilithium/), including:

- a hybrid NTT/INTT module for polynomial multiplication.
- a point-wise multiplication module.
- a point-wise addition module.
- a PRNG module with an SHA-3 core and a unified sampler.

This repository provides a software/hardware co-design evaluation of CRYSTALS-Dilithium based on the Xilinx Zynq architecture.

## Pre-requisites

Here are the tools and devices we use for implementation and testing.

- Xilinx Vivado 2020.2 for hardware code (Verilog) implementation.
- Xilinx Vitis 2020.2 for software implementation (C/C++) and system verification.
- Xilinx ZedBoard for real board implementation and testing.
- PuTTY (0.67) for serial communication and print out the results.

## Code Organization

1. Hardware code (hardware development files targeting the Zynq7000 XC7Z020 CLG484-1 FPGA)
   - `Code/HW/constrs/` contains the hardware constraint file.
   - `Code/HW/PS_preset.tcl` is the Zynq processing system configuration file.
   - `Code/HW/sources/` 
     - `Code/HW/sources/ip/` contains the used Xilinx IP files.
     - `Code/HW/sources/NTT source/` contains the designed NTT hardware module.
     - `Code/HW/sources/PWM_source/` contains the designed point-wise multiplication module.
     - `Code/HW/sources/SHA_source/` contains the designed PRNG module.
     - `Code/HW/sources/Top_control_source/` contains point-wise addition and top control module.
   - `Code/HW/zetas.COE` is the ROM memory initialization file.
2. Software benchmark code
   -  `Code/SW_benchmark/` contains the reference implementation code (C/C++) of CRYSTALS-Dilithium.
3. SW/HW co-design code
   - `Code/SW-HW-Co-design/Individual_function_test/` contains the code comparing the performance of pure software and calling the hardware accelerator for each function.
   - `Code/SW-HW-Co-design/Overall-design/` contains the overall SW/HW co-design evaluation code of CRYSTALS-Dilithium. 

## Code Implementation and Real Test On FPGAs

1. For the hardware implementation and system generation, please check [Hardware.md](https://github.com/CALAS-CityU/SW-HW-Co-design-of-Dilithium/blob/main/Hardware.md) for further details.
2. For the SW/HW co-design and on-board testing, please check [Co-design.md](https://github.com/CALAS-CityU/SW-HW-Co-design-of-Dilithium/blob/main/Co-design.md) for further details.

## Questions

Please contact "gaoyumao3-c@my.cityu.edu.hk".

