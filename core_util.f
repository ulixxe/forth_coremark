
: array_s32  ( u "<spaces>name" -- )
   create 2* cells allot  \ s32 is double cell data
  does>  ( u -- d )  \ '1' is the first element
   swap 1- 2* cells + 2@ ;
: array_s32_init  ( d1 ... dn n "<spaces>name" -- )
   ' >body swap  ( a-addr n )
   1- 2* cells over +
   do
      i 2!
   #-2 cells +loop ;
      

\ Function: get_seed
\	Get a values that cannot be determined at compile time.
#5 array_s32 get_seed_32  \ ee_s32 get_seed_32(int i)


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
