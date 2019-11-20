
\ Parse ccc delimited by " (double-quote),
\ reserve data space and store ccc
: ,"  ( "ccc<quote>" -- )
   [char] " parse  ( c-addr u )
   here over allot
   swap cmove ;

: create_pat  ( u "<spaces>name" -- )
   create
   ,  \ fixed strings size
  does>  ( u1 -- c-addr u2 )
   swap over @ swap over *
   rot cell+ + swap ;

#4 create_pat intpat
," 50121234-874+122"  \ allot and store strings

#8 create_pat floatpat
," 35.54400.1234500-110.700+0.64400"  \ allot and store strings

#8 create_pat scipat
," 5.500e+3-.123e-2-87e+832+0.6e-12"  \ allot and store strings

#8 create_pat errpat
," T0.3e-1F-T.T++Tq1T3.4e4z34.0e-T^"  \ allot and store strings


\ Initialize the input data for the state machine.
\ void core_init_state(ee_u32 size, ee_s16 seed, ee_u8 *p)
: core_init_state  ( u1 a-addr u2 -- )
   >r
   swap over cell+
   swap 1-  ( a-addr c-addr u1 )
   begin  ( c-addr u1 :R seed )
      r> 1+ dup >r
      dup #3 rshift $0003 and
      swap $0007 and
      dup #3 < if
         drop intpat
      else
         dup #5 < if
            drop floatpat
         else
            #7 < if
               scipat
            else
               errpat
            then
         then
      then  ( c-addr u1 c-addr1 u2 )
      rot 1- 2dup <
   while
         over - >r  ( c-addr c-addr1 u2 )
         rot 2dup + >r
         swap cmove
         r> [char] , over c!
         1+
         r>
   repeat
   2drop drop
   over cell+ - swap !
   r> drop ;
