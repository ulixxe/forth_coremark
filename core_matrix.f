
\ ee_u32 core_init_matrix(ee_u32 blksize, void *memblk, ee_s32 seed, mat_params *p)
\  	Initialize the memory block for matrix benchmarking.
\   Parameters:
\     blksize - Size of memory to be initialized.
\     memblk - Pointer to memory block.
\     seed - Actual values chosen depend on the seed parameter.
\     p - pointers to <mat_params> containing initialized matrixes.
\   Returns:
\     Matrix dimensions.

: core_init_matrix  ( u1 a-addr u2 -- )
   dup 0= if drop 1 then
   >r  ( R: seed )
   2dup !  \ | N | ...
   cell+ dup 3 cells + swap  ( N &A a-addr )
   2dup !  \ | N | &A | ...
   cell+ >r
   over dup * cells  ( N &A size )
   2dup +  ( N &A size &B )
   swap over ( N &A &B size &B )
   dup r@ !  \ | N | &A | &B | ...
   + r> cell+ !  \ | N | &A | &B | &C | A11 ...
   rot dup * 1+ r> swap
   1 do  ( &A &B seed )
      i * $FFFF and
      dup i + $FFFF and
      rot 2dup ! cell+  ( &A seed val &B )
      i swap >r + $00FF and
      rot tuck ! cell+
      swap r> swap
   loop
   2drop drop ;

: .matrix  ( u a-addr -- )
   over
   0 do  ( u a-addr )
      over
      0 do  ( a-addr )
         dup @
         dup $8000 and if $FFFF invert or then
         .
         cell+
      loop
      cr
   loop
   2drop ;
