# VT-x Benchmarks

The benchmarks use a modified STREAM binary in order to measure the impacts of
different virtualization configurations on memory latency and bandwidth. Please
see the files under the `results` directory for raw data and detailed
configuration information from previous benchmarks.

## Hardware dependencies
In order to repeat the benchmarks, you must first ensure that the hardware
supports the `rdtscp` instruction and has an invariant TSC. In addition, the
platform must support the `MSR_PLATFORM_INFO` msr (address `0xCE`), which
contains the "Max Non-Turbo Ratio" field. The current Bareflank code assumes
that the TSC scaling factor (as found in the manual's description of the
`MSR_PLATFORM_INFO`) is 100 MHz. This will be correct for most architectures
(Nehalem and Atom use different values). If you are unsure, you can search for
the `MSR_PLATFORM_INFO` msr for your microarchitecture and look at the
description of the "Max Non-Turbo Ratio" field.

## Building the hypervisor
Once the hardware dependencies are met, you have to setup your development
environment to build the [Bareflank hypervisor](https://github.com/Bareflank/hypervisor).
First, ensure you have installed the following dependencies from your
distro's package manager:

* development essentials (gcc, make, etc)
* clang 4.0
* linux headers
* nasm
* cmake

Once those are installed, you can run `fetch.sh` to fetch the hypervisor and
stream sources. The two scripts `build-bf.sh` and `build-bf-vmxon-only.sh` are
used to build Bareflank. The `build-bf.sh` script will build Bareflank like
normal. The `build-bf-vmxon-only.sh` will build Bareflank to stop the VT-x
bootstrap process immediately after executing VMXON (i.e. no guest is
VMLAUNCHed).

## Building the benchmarks
The bench binaries are built with `build-bench.sh`. This will produce two
binaries, `stream/bench-hyp` and `stream/bench-nohyp`. The former is to be run
only in the *fourth* configuration (see below) because it performs two vmcalls to
tell Bareflank to start/end counting exits. The latter is run for all other
configurations. Each binary performs an equal number of copy operations on a
large and small buffer in memory. The size of each buffer and the number of
copy operations can be modified with compiler flags (see NTIMES,
STREAM_ARRAY_SIZE, and PKT_SIZE in `stream/stream.c`).

The default buffer sizes are ~79MB and 2500B, and the number of copy operations
is 1001 (the first run is discarded, giving a sample of 1000). Each binary
requires two filename arguments to be passed; the binary dumps the large-copy
(i.e. "stream") data into the first and the small-copy (i.e. "packet") data
into the second.

## Running the benchmarks
The following describes the steps needed to repeat tests found under `results`:

1. VT-x disabled in BIOS (denoted "biosoff")
    - Disable VT-x in the BIOS
    - Boot into Linux
    - Run:
    ```bash
    $ cd stream
    $ ./bench-nohyp <stream-biosoff> <packet-biosoff>
    $ reboot
    ```

2. VT-x enabled in BIOS (denoted "bioson")
    - Enable VT-x in the BIOS
    - Boot into Linux
    - Run:
    ```bash
    $ cd stream
    $ ./bench-nohyp <stream-bioson> <packet-bioson>
    $ reboot
    ```

3. VMXON enabled without VMLAUNCH (denoted "vmxon")
    - Boot into Linux
    - Run:
    ```bash
    $ ./build-bf-vmxon-only.sh
    $ cd hypervisor/build
    $ make driver_quick
    $ make quick
    $ cd ../../stream
    $ ./bench-nohyp <stream-vmxon> <packet-vmxon>
    $ reboot
    ```

4. Bareflank with 1GB EPT and no MSR/IO exits (denoted "hyp")
    - Boot into Linux
    - Run:
    ```bash
    $ ./build-bf.sh
    $ cd hypervisor/build
    $ make driver_quick
    $ make quick
    $ cd ../../stream
    $ ./bench-hyp <stream-hyp> <packet-hyp>
    $ make stop
    ```

## Notes
1. In the last configuration, the bench makes a vmcall into Bareflank right
before the copies begin that instructs the hypervisor to start counting exits.
When the copies are done, another vmcall is made to retrieve the exit count,
which is then printed to the console. The results can be kept if the displayed
exit count was 0. Any results from a bench with a displayed exit count higher
than 0 should be discarded and the bench repeated until it is 0 (I say
"displayed" because there will always be at least one exit, the vmcall that
tells the hypervisor to stop counting exits; this occurs after all measurements
have completed and so the returned exit count is decreased by one before being
printed out).

2. You will need to reboot after benchmarking configuration 3. That version of
Bareflank returns control back to Linux after VMXON is executed. While this
works fine for running the benchmarks, if you try to run VMXOFF (i.e via `make
stop`) after the benchmarks complete, an exception is raised due to an invalid
cr4 write. I haven't had time to further debug/fix this issue, so I just reboot
the machine after the bench data is written.
