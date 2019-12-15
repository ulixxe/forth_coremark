# Introduction
`forth_coremark` provides a port of [CoreMark](https://www.eembc.org/coremark) benchmark to Forth program language.
It allows to benchmark Forth compilers vs. Forth compilers and vs. C compilers on the same machine.
Furthermore, `forth_coremark` allows to benchmark Stack machines programmed in Forth vs. CPUs programmed in C.

I wrote `forth_coremark` using ANS94 to allow an easy porting and optimization on as much as possible Forth environments and Stack machines.
# How to run it
~~~
S" coremark.f" INCLUDED
coremark
~~~
