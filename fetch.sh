#!/bin/bash

git clone -b zov-bench https://github.com/connojd/STREAM.git stream
git clone -b zov-bench https://github.com/connojd/hypervisor.git

cd hypervisor
git clone -b zov-bench https://github.com/connojd/extended_apis.git
mkdir build
