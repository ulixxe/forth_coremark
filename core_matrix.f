
\ Add a constant value to all elements of a matrix.
: matrix_s16>n  ( u a-addr -- )
   swap
   dup *
   0 do  \ &A
      dup @ s16>n
      over !
      cell+
   loop
   drop ;

\  	Initialize the memory block for matrix benchmarking.
\   Parameters:
\     blksize - Size of memory to be initialized.
\     memblk - Pointer to memory block.
\     seed - Actual values chosen depend on the seed parameter.
\     p - pointers to <mat_params> containing initialized matrixes.
\   Returns:
\     Matrix dimensions.
\ ee_u32 core_init_matrix(ee_u32 blksize, void *memblk, ee_s32 seed, mat_params *p)
: core_init_matrix  ( u1 a-addr u2 -- )
   dup 0= if drop 1 then
   >r tuck ( &memblk blksize &memblk R: seed )
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
   2drop drop ( &memblk )
   dup @ swap cell+  ( N a-addr )
   2dup cell+ @
   matrix_s16>n
   @ matrix_s16>n ;

\ Print s16 matrix of size u located at a-addr
: s16.matrix  ( u a-addr -- )
   over
   0 do  ( u a-addr )
      over
      0 do  ( a-addr )
         dup @
         s16.
         cell+
      loop
      cr
   loop
   2drop ;

\ Print s32 matrix of size u located at a-addr
: s32.matrix  ( u a-addr -- )
   over
   0 do  ( u a-addr )
      over
      0 do  ( a-addr )
         dup 2@
         s32.
         cell+ cell+
      loop
      cr
   loop
   2drop ;

\ Calculate a function that depends on the values of elements in the matrix.
\ For each element, accumulate into a temporary variable.
\ As long as this value is under the parameter clipval, 
\ add 1 to the result if the element is bigger then the previous.
\ Otherwise, reset the accumulator and add 10 to the result.
\ ee_s16 matrix_sum(ee_u32 N, MATRES *C, MATDAT clipval)
: matrix_sum  ( u a-addr n )
   swap rot dup *  \ clipval *C N*N
   0 do

   loop
;

\ Multiply a matrix by a constant.
\ This could be used as a scaler for instance.
\ void matrix_mul_const(ee_u32 N, MATRES *C, MATDAT *A, MATDAT val)
: matrix_mul_const  ( u a-addr1 a-addr2 n -- )
   swap rot  \ N val &A &C
   >r rot r> swap  \ val &A &C N
   dup *
   0 do  \ val &A &C
      >r
      2dup @ m*
      r@ 2!
      cell+
      r> cell+ cell+
   loop
   2drop drop ;

\ Add a constant value to all elements of a matrix.
\ void matrix_add_const(ee_u32 N, MATDAT *A, MATDAT val)
: matrix_add_const  ( u a-addr n -- )
   swap
   rot dup *
   0 do  \ val &A
      2dup @ +
      over !
      cell+
   loop
   2drop ;

\ Multiply a matrix by a vector.
\ This is common in many simple filters (e.g. fir where a vector of coefficients is applied to the matrix.)
\ void matrix_mul_vect(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B)
: matrix_mul_vect  ( u a-addr1 a-addr2 a-addr3 -- )
   rot >r rot >r  \ R: &C N
   tuck  \ &B0 &A &B
   r> r> swap  \ &B0 &A &B &C N
   dup
   0 do  \ &B0 &A &B &C N
      dup >r swap >r
      0 0 rot
      0 do  \ &A &B c  R: N &C
         >r >r
         over cell+ over cell+
         2swap @ swap @ m*
         r> r>
         d+
      loop
      r@ 2!
      drop over  \ reset &B
      r> cell+ cell+ r>
   loop
   2drop 2drop drop ;

\ Scalar product of A row by B column: &A &B N -- res
: scalar_product  ( a-addr1 a-addr2 u -- d )
   >r >r >r
   0 0 r> r> r> dup
   0 do  \ d &A &B N
      >r 2dup >r >r
      @ swap @ m* d+
      r> cell+
      r> r@ cells +
      r>
   loop
   2drop drop ;

\ Row by matrix multiplication: &A &B &C N --
: row_mul_matrix  ( a-addr1 a-addr2 a-addr3 u -- )
   dup
   0 do  \ &A &B &C N
      dup >r swap >r  \ R: N &C
      >r 2dup r> scalar_product
      r@ 2!
      cell+ r> cell+ cell+ r>
   loop
   2drop 2drop ;

\ Multiply a matrix by a matrix: &A &B &C N --
\ Basic code is used in many algorithms, mostly with minor changes such as scaling.
\ void matrix_mul_matrix(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B)
: matrix_mul_matrix  ( a-addr1 a-addr2 a-addr3 u -- )
   dup
   0 do  \ &A &B &C N
      dup
      0 do  \ &A &B &C N
         dup >r swap >r  \ R: N &C
         >r 2dup r> scalar_product
         r@ 2!
         cell+ r> cell+ cell+ r>
      loop
      tuck >r >r
      cells tuck -
      >r + r> r> r>
   loop
   2drop 2drop ;
