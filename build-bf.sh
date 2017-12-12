#!/bin/bash

cd hypervisor/build
cmake -DBFM_DEFAULT_VMM=eapis_static -DBUILD_EXTENDED_APIS=ON -DBUILD_VMM_STATIC=ON -DBUILD_VMM_SHARED=OFF ..
make -j4
