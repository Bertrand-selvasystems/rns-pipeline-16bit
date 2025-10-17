# 16-bit RNS Pipeline (9 Moduli) for FPGA

**Project:** [Winter FPGAs & Forgotten Arithmetic — Hackaday Log](https://hackaday.io/project/204083-winter-fpgas-and-forgotten-arithmetic)

This repository contains the Verilog sources and testbenches for a 16-bit Residue Number System (RNS) pipeline implemented on FPGA, using 9 coprime moduli for a dynamic range of 2^37.  
The architecture features a full input/output pipeline, Chinese Remainder Theorem (CRT) reconstruction, and high-throughput modular arithmetic — inspired by historical applications such as the Duga OTH radar.

## Features

- **Input:** 8-bit bus (two cycles per word), robust handshake interface
- **RNS Pipeline:** Parallel processing with 9 coprime moduli {7, 11, 13, 15, 17, 19, 23, 29, 31}
- **CRT Reconstruction:** Fully pipelined tree (4 pipeline stages, Fmax up to 109 MHz measured on Cyclone IV)
- **Output:** 16-bit result bus, 1-cycle per valid output after pipeline fill
- **Latency:** 8 cycles end-to-end from MSB input to output
- **Resource Usage:** ~3.5 kB ROMs (CRT tables + binary→RNS LUTs)
- **Testbench:** Provided for full pipeline verification

## Quick Overview

- Input: 2 × 8b words → assembled to 16b
- Each 16b input word is converted to RNS representation, processed (currently simple +2; FIR to come), then reconstructed to binary using pipelined CRT
- Output published every cycle after pipeline fill


## Context

This project is part of a broader exploration of RNS and alternative arithmetic architectures for signal processing on low-cost FPGAs.  
See full design logs and historical background on [Hackaday](https://hackaday.io/project/204083-winter-fpgas-and-forgotten-arithmetic).

## HDL Used: Verilog

This project is written entirely in **Verilog**

## Target Hardware / Board Support

- Intel/Altera Cyclone IV FPGAs (EP4CE, etc.)
    - Designed, simulated, and synthesized using Quartus Prime Lite.
    - Resource/clock figures are based on Cyclone IV compilation results.

## License

MIT License
