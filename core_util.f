\ ee_u8  -> char
\ ee_s16 -> n
\ ee_u16 -> u
\ ee_s32 -> d
\ ee_u32 -> ud

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

\ Function: get_seed
\	Get a values that cannot be determined at compile time.
#5 2array get_seed_32  \ ee_s32 get_seed_32(int i)


\ Function: crc*
\  Service functions to calculate 16b CRC code.

: crcu8  ( char u1 -- u2 )  \ ee_u16 crcu8(ee_u8 data, ee_u16 crc)
   #8 #0 do
      over over xor
      $1 and  \ carry
      if
         $4002 xor
         2/ $8000 or
      else
         2/
      then
      swap 2/ swap  \ data >>= 1
   loop
   nip ;

: crcu16  ( u1 u2 -- u3 )  \ ee_u16 crcu16(ee_u16 newval, ee_u16 crc)
   over #8 rshift
   rot rot
   crcu8 crcu8 ;

: crc16  ( n u1 -- u2 )  \ ee_u16 crc16(ee_s16 newval, ee_u16 crc)
   crcu16 ;

: crcu32  ( ud u1 -- u2 )  \ ee_u16 crcu32(ee_u32 newval, ee_u16 crc)
   rot swap
   crc16 crc16 ;
