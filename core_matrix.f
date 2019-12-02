
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

\ Calculate a function that depends on the values of elements in the matrix: &C clipval N --
\ For each element, accumulate into a temporary variable.
\ As long as this value is under the parameter clipval, 
\ add 1 to the result if the element is bigger then the previous.
\ Otherwise, reset the accumulator and add 10 to the result.
\ ee_s16 matrix_sum(ee_u32 N, MATRES *C, MATDAT clipval)
: matrix_sum  ( a-addr n1 u -- n2 )
   >r >r >r
   0 0 0 0 r> r> 0 r>
   dup *
   0 do  \ dprev dtmp &C clipval ret 
      >r >r dup >r
      2@ d+ 2dup  \ dprev dtmp dtmp R: ret clipval &C
      r> r@ swap >r #-1  \ clipval is always negative
      d> if  \ dprev dtmp
         2drop 2drop
         r@ 2@ 0 0
         #10
      else
         2swap r@ 2@ 2swap
         d> if
            r@ 2@ 2swap #1
         else
            r@ 2@ 2swap 0
         then
      then
      r> cell+ cell+
      r> rot r> +
   loop
   >r 2drop 2drop 2drop r> ;

\ Multiply a matrix by a constant: N &C &A val
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

\ Add a constant value to all elements of a matrix: N &A val
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

\ Multiply a matrix by a vector: N &C &A &B
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

: bit_extract  ( x1 u1 u2 -- x2 )
   >r rshift #-1 r> lshift invert and ;

\ Bitextract scalar product of A row by B column: &A &B N -- res
: scalar_product_bitextract  ( a-addr1 a-addr2 u -- d )
   >r >r >r
   0 0 r> r> r> dup
   0 do  \ d &A &B N
      >r 2dup >r >r
      @ swap @ m*
      drop dup #2 #4 bit_extract
      swap #5 #7 bit_extract
      m* d+
      r> cell+
      r> r@ cells +
      r>
   loop
   2drop drop ;

\ Multiply a matrix by a matrix, and extract some bits from the result: &A &B &C N --
\ Basic code is used in many algorithms, mostly with minor changes such as scaling.
\ void matrix_mul_matrix_bitextract(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B)
: matrix_mul_matrix_bitextract  ( a-addr1 a-addr2 a-addr3 u -- )
   dup
   0 do  \ &A &B &C N
      dup
      0 do  \ &A &B &C N
         dup >r swap >r  \ R: N &C
         >r 2dup r> scalar_product_bitextract
         r@ 2!
         cell+ r> cell+ cell+ r>
      loop
      tuck >r >r
      cells tuck -
      >r + r> r> r>
   loop
   2drop 2drop ;

: matrix_big  ( n1 -- n2 )
   $-1000 or ;

: p->n  ( a-addr -- u )
   @ ;
: p->a  ( a-addr1 -- a-addr2 )
   cell+ @ ;
: p->b  ( a-addr1 -- a-addr2 )
   cell+ cell+ @ ;
: p->c  ( a-addr1 -- a-addr2 )
   cell+ cell+ cell+ @ ;

\ Perform matrix manipulation: &p val -- crc
\ Parameters:
\ N - Dimensions of the matrix.
\ C - memory for result matrix.
\ A - input matrix
\ B - operator matrix (not changed during operations)
\ Returns:
\ A CRC value that captures all results calculated in the function.
\ In particular, crc of the value calculated on the result matrix 
\ after each step by <matrix_sum>.
\ Operation:
\ 1 - Add a constant value to all elements of a matrix.
\ 2 - Multiply a matrix by a constant.
\ 3 - Multiply a matrix by a vector.
\ 4 - Multiply a matrix by a matrix.
\ 5 - Add a constant value to all elements of a matrix.
\ After the last step, matrix A is back to original contents.
\ ee_s16 matrix_test(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B, MATDAT val)
: matrix_test  ( a-addr n -- u )
   s16>n tuck  \ val &p val
   2dup >r dup p->n swap p->a r> matrix_add_const
   2dup >r dup p->n swap dup p->c swap p->a r> matrix_mul_const
   matrix_big  \ val &p clipval
   2dup over p->c swap rot p->n matrix_sum
   0 crc16 >r  \ R: crc
   over dup p->n swap dup p->c swap dup p->a swap p->b matrix_mul_vect
   2dup over p->c swap rot p->n matrix_sum
   r> crc16 >r  \ R: crc
   over dup p->a swap dup p->b swap dup p->c swap p->n matrix_mul_matrix
   2dup over p->c swap rot p->n matrix_sum
   r> crc16 >r  \ R: crc
   over dup p->a swap dup p->b swap dup p->c swap p->n matrix_mul_matrix_bitextract
   2dup over p->c swap rot p->n matrix_sum
   r> crc16 >r  \ R: crc
   drop dup p->n swap p->a rot negate matrix_add_const
   r> ;

\ Benchmark function: &p seed crc
\ Iterate <matrix_test> N times, 
\ changing the matrix values slightly by a constant amount each time.
\ ee_u16 core_bench_matrix(mat_params *p, ee_s16 seed, ee_u16 crc)
: core_bench_matrix  ( a-addr n u1 -- u2 )
   >r matrix_test r> crc16 ;
