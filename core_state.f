
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


\ Initialize the input data for the state machine: size &p seed --
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
   nip nip 2 +
   over swap 0 fill  \ fill the rest with 0
   over cell+ - swap !
   r> drop ;

: ee_isdigit  ( char -- flag )
   [char] 0 -
   #9 swap u<
   invert ;

0 constant CORE_START
1 constant CORE_INVALID
2 constant CORE_S1
3 constant CORE_S2
4 constant CORE_INT
5 constant CORE_FLOAT
6 constant CORE_EXPONENT
7 constant CORE_SCIENTIFIC
8 constant NUM_CORE_STATES

\ The state machine will continue scanning until either:
\ 1 - an invalid input is detcted.
\ 2 - a valid number has been detected.
\ The input pointer is updated to point to the end of the token, and the end state is returned (either specific format determined or invalid).
\ enum CORE_STATE core_state_transition( ee_u8 **instr , ee_u32 *transition_count)
: core_state_transition  ( c-addr1 a-addr -- c-addr2 u )
   >r CORE_START
   begin  \ &str state R: &transition_count
      over c@
      2dup swap CORE_INVALID <> and
   while  \ &str state char R: &transition_count
         dup [char] ,
         <> if
            over CORE_START = if
               dup ee_isdigit if
                  nip CORE_INT swap
               else
                  dup [char] + =
                  over [char] - =
                  or if
                     nip CORE_S1 swap
                  else
                     dup [char] . = if
                        nip CORE_FLOAT swap
                     else
                        nip CORE_INVALID swap
                        CORE_INVALID cells r@ +
                        dup @ 1+ swap !
                     then
                  then
               then
               CORE_START cells r@ +
               dup @ 1+ swap !
            else
               over CORE_S1 = if
                  dup ee_isdigit if
                     nip CORE_INT swap
                  else
                     dup [char] . = if
                        nip CORE_FLOAT swap
                     else
                        nip CORE_INVALID swap
                     then
                  then
                  CORE_S1 cells r@ +
                  dup @ 1+ swap !
               else
                  over CORE_INT = if
                     dup [char] . = if
                        nip CORE_FLOAT swap
                        CORE_INT cells r@ +
                        dup @ 1+ swap !
                     else
                        dup ee_isdigit if
                        else
                           nip CORE_INVALID swap
                           CORE_INT cells r@ +
                           dup @ 1+ swap !
                        then
                     then
                  else
                     over CORE_FLOAT = if
                        dup [char] E =
                        over [char] e =
                        or if
                           nip CORE_S2 swap
                           CORE_FLOAT cells r@ +
                           dup @ 1+ swap !
                        else
                           dup ee_isdigit if
                           else
                              nip CORE_INVALID swap
                              CORE_FLOAT cells r@ +
                              dup @ 1+ swap !
                           then
                        then
                     else
                        over CORE_S2 = if
                           dup [char] + =
                           over [char] - =
                           or if
                              nip CORE_EXPONENT swap
                           else
                              nip CORE_INVALID swap
                           then
                           CORE_S2 cells r@ +
                           dup @ 1+ swap !
                        else
                           over CORE_EXPONENT = if
                              dup ee_isdigit if
                                 nip CORE_SCIENTIFIC swap
                              else
                                 nip CORE_INVALID swap
                              then
                              CORE_EXPONENT cells r@ +
                              dup @ 1+ swap !
                           else
                              over CORE_SCIENTIFIC = if
                                 dup ee_isdigit if
                                 else
                                    nip CORE_INVALID swap
                                    CORE_INVALID cells r@ +
                                    dup @ 1+ swap !
                                 then
                              then
                           then
                        then
                     then
                  then
               then
            then
         else
            r> 2drop
            swap 1+ swap
            exit
         then
         drop swap 1+ swap
   repeat
   r> 2drop ;

\ Simple state machines like this one are used in many embedded products.
\ For more complex state machines, sometimes a state transition table implementation is used instead, 
\ trading speed of direct coding for ease of maintenance.
\ Since the main goal of using a state machine in CoreMark is to excercise the switch/if behaviour,
\ we are using a small moore machine. 
\ In particular, this machine tests type of string input,
\ trying to determine whether the input is a number or something else.
\ (see core_state.png).

create final_counts  NUM_CORE_STATES cells allot  \ no need for ee_u32, ee_u16 is enough
create track_counts  NUM_CORE_STATES cells allot  \ no need for ee_u32, ee_u16 is enough

: reset_counts  ( a-addr1 a-addr2 u -- )
   0 do
      0 over !
      cell+ swap
      0 over !
      cell+
   loop
   2drop ;

\ Benchmark function: crc seed2 seed1 step &state_data
\ Go over the input twice, once direct, and once after introducing some corruption. 
\ ee_u16 core_bench_state(ee_u32 blksize, ee_u8 *memblock, 
\  	ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc) 
: core_bench_state  ( u1 n1 n2 n3 a-addr -- u2 )
   >r  \ R: &state_data
   final_counts track_counts NUM_CORE_STATES reset_counts
   track_counts r@ cell+
   begin  \ track_counts &str
      dup c@
   while
         over core_state_transition
         cells final_counts +
         dup @ 1+ swap !
   repeat
   2drop
   swap $FF and r@ swap >r
   dup cell+ swap @ over +  \ step &str &str+blksize
   >r
   begin  \ step &str R: seed1 &str+blksize
      dup r@ u<
   while
         dup c@ [char] ,
         <> if
            dup c@
            r> r@ swap >r
            xor over c!
         then
         over +
   repeat
   r> drop r> 2drop  \ crc seed2 step
   track_counts r@ cell+
   begin  \ track_counts &str
      dup c@
   while
         over core_state_transition
         cells final_counts +
         dup @ 1+ swap !
   repeat
   2drop
   swap $FF and r@ swap >r
   dup cell+ swap @ over +  \ step &str &str+blksize
   >r
   begin  \ step &str R: seed2 &str+blksize
      dup r@ u<
   while
         dup c@ [char] ,
         <> if
            dup c@
            r> r@ swap >r
            xor over c!
         then
         over +
   repeat
   r> 2drop r> 2drop  \ crc
   track_counts final_counts rot NUM_CORE_STATES
   0 do  \ &track_counts &final_counts crc
      >r dup @ 0 r> crcu32
      >r cell+ swap
      dup @ 0 r> crcu32
      >r cell+ swap r>
   loop
   nip nip r> drop ;
