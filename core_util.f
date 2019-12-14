\ typedef unsigned char  ee_u8  -> char
\ typedef signed short   ee_s16 -> n
\ typedef unsigned short ee_u16 -> u
\ typedef signed int     ee_s32 -> d
\ typedef unsigned int   ee_u32 -> ud

\ Convert s16 to n
: s16>n  ( n1 -- n2 )
   dup $8000 and  \ get sign
   if $FFFF invert or then ;

\ Print n with s16 format
: s16.  ( n -- )
   s16>n . ;

\ Print d with s32 format
: s32.  ( d -- )
   1 cells #2
   > if
      drop
      dup $8000 #16 lshift and  \ get sign
      if $FFFF #16 lshift $FFFF or invert or then
      .
   else
      d.
   then ;

: (array)  ( u a-addr1 -- a-addr2 )
   over over @ u< invert abort" Out of bound!"
   swap 1+ cells + ;
: array  ( u "<spaces>name" -- )
   create
   dup ,
   cells allot  \ double cell data
  does>  ( u -- x )  \ '0' is the first element
   (array) @ ;
: array_set  ( x u a-addr -- )
   (array) ! ;
: array_to  ( x u "<spaces>name" -- )
   ' >body array_set ;
: array_init  ( x0 ... xn "<spaces>name" -- )
   ' >body dup >r
   @ 1- 0 swap do
      i j array_set
   #-1 +loop
   r> drop ;

: (2array)  ( u a-addr1 -- a-addr2 )
   over over @ u< invert abort" Out of bound!"
   swap 2* 1+ cells + ;
: 2array  ( u "<spaces>name" -- )
   create
   dup ,
   2* cells allot  \ double cell data
  does>  ( u -- x1 x2 )  \ '0' is the first element
   (2array) 2@ ;
: 2array_set  ( x1 x2 u a-addr -- )
   (2array) 2! ;
: 2array_to  ( x1 x2 u "<spaces>name" -- )
   ' >body 2array_set ;
: 2array_init  ( x10 x20 ... x1n x2n "<spaces>name" -- )
   ' >body dup >r
   @ 1- 0 swap do
      i j 2array_set
   #-1 +loop
   r> drop ;

: 2value  ( x1 x2 "<spaces>name" -- )
   create , ,
  does>  ( -- x1 x2 )
   2@ ;
: 2to  ( x1 x2 "<spaces>name" -- )
   ' >body 2! ;

\ Get a values that cannot be determined at compile time.
\ ee_s32 get_seed_32(int i)
#5 2array get_seed_32


\ Service functions to calculate 16b CRC code.
\ ee_u16 crcu8(ee_u8 data, ee_u16 crc)
: crcu8  ( char u1 -- u2 )
   #8 #0 do
      2dup xor
      $1 and  \ carry
      if
         $4002 xor
         2/ $8000 or
      else
         2/ $7FFF and
      then
      swap 2/ swap  \ data >>= 1
   loop
   nip ;

\ ee_u16 crcu16(ee_u16 newval, ee_u16 crc)
: crcu16  ( u1 u2 -- u3 )
   over #8 rshift
   rot rot
   crcu8 crcu8 ;

\ ee_u16 crc16(ee_s16 newval, ee_u16 crc)
: crc16  ( n u1 -- u2 )
   crcu16 ;

\ ee_u16 crcu32(ee_u32 newval, ee_u16 crc)
: crcu32  ( ud u1 -- u2 )
   rot swap
   crc16 crc16 ;
