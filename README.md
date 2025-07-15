## Description

**SagittariusA_RV32** is a custom softcore CPU built for the **TinyVision AI Pico-ICE** FPGA development board. It is designed with the following characteristics:

- Implements the **RV32I** RISC-V base instruction set
- Follows a **multicycle execution model**
- Written entirely in **Verilog HDL**
- Single-core architecture
- Designed for the **iCE40UP5K** FPGA on the Pico-ICE board
- Planned support for:
  - General-Purpose Input/Output (**GPIO**)
  - **NOR flash** memory via **SPI**
  - **SSRAM** integration via **SPI**
- Intended to be developed using open-source FPGA toolchains such as **Yosys**, **nextpnr**, and **IceStorm**
- The primary goal is to build a lightweight, memory-mapped RISC-V processor that can run entirely on low-cost, open FPGA hardware
