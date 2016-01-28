# Kaldi cu-device.cc memory leak ?

We've come across a memory leak when using nnet-train-simple, we have tracked it 
down to cu-device.cc not calling `cudaDevieReset()` on exit.

The affects of this bug are quite severe, during our training stage we see
around 30MB of memory lost for each nnet iteration.

Over the number of iterations in our training scripts we consume all memory on
the machine (32GB) and cannot complete training.

The very strange thing is that this memory is never reclaimed at program exit
and requires a machine reboot to retrieve. I am seperately trying to isolate
this and report to nvidia if applicable.

Below is extra info, some steps to reproduce and a fix that we have tested
implemented and managed to complete our training with.

## Steps to reproduce ...

### Git LFS

This project uses git lfs (https://git-lfs.github.com/) ...

    git lfs pull

### Git submodules

This project has submodules ...

    git submodule init
    git submodule update

## Compile Kaldi versions

    cd kaldi-upstream/tools
    make -j 8
    cd ../src
    ./configure
    make depend -j 8
    make -j 8

    cd kaldi-fix/tools
    make -j 8
    cd ../src
    ./configure
    make depend -j 8
    make -j 8

### Environment

    $ uname -a

    Linux 3.19.0-47-generic #53~14.04.1-Ubuntu SMP Mon Jan 18 16:09:14 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux

    $ cat /proc/driver/nvidia/version

    NVRM version: NVIDIA UNIX x86_64 Kernel Module  358.16  Mon Nov 16 19:25:55 PST 2015
    GCC version:  gcc version 4.8.4 (Ubuntu 4.8.4-2ubuntu1~14.04)

    $ nvidia-smi --query-gpu=index,name --format=csv

    index, name
    0, GeForce GTX TITAN X
    1, GeForce GTX TITAN X

    $ nvcc --version

    nvcc: NVIDIA (R) Cuda compiler driver
    Copyright (c) 2005-2015 NVIDIA Corporation
    Built on Mon_Feb_16_22:59:02_CST_2015
    Cuda compilation tools, release 7.0, V7.0.27

### Test case

    $ nnet-train-simple --minibatch-size=512 --srand=33 test.mdl ark:egs.ark /dev/null

    # Running ./test.sh will run the above command on kaldi trunk and my branch
    # with fix applied. It runs under valgrind and records lost memory

    $ ./test.sh

    $ tail -n 11 kaldi-*log

    ==> kaldi-fix.log <==
    ==3198== LEAK SUMMARY:
    ==3198==    definitely lost: 0 bytes in 0 blocks
    ==3198==    indirectly lost: 0 bytes in 0 blocks
    ==3198==      possibly lost: 5,469 bytes in 68 blocks
    ==3198==    still reachable: 267,960 bytes in 746 blocks
    ==3198==         suppressed: 0 bytes in 0 blocks
    ==3198== Reachable blocks (those to which a pointer was found) are not shown.
    ==3198== To see them, rerun with: --leak-check=full --show-leak-kinds=all
    ==3198==
    ==3198== For counts of detected and suppressed errors, rerun with: -v
    ==3198== ERROR SUMMARY: 56 errors from 56 contexts (suppressed: 0 from 0)
    
    ==> kaldi-upstream.log <==
    ==2202== LEAK SUMMARY:
    ==2202==    definitely lost: 0 bytes in 0 blocks
    ==2202==    indirectly lost: 0 bytes in 0 blocks
    ==2202==      possibly lost: 25,166,363 bytes in 10,042 blocks
    ==2202==    still reachable: 48,600,667 bytes in 75,728 blocks
    ==2202==         suppressed: 0 bytes in 0 blocks
    ==2202== Reachable blocks (those to which a pointer was found) are not shown.
    ==2202== To see them, rerun with: --leak-check=full --show-leak-kinds=all
    ==2202==
    ==2202== For counts of detected and suppressed errors, rerun with: -v
    ==2202== ERROR SUMMARY: 193 errors from 193 contexts (suppressed: 0 from 0)
