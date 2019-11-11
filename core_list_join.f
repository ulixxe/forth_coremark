
: copy_info  ( a-addr1 a-addr2 -- )  \ void copy_info(list_data *to,list_data *from)
   over cell+ over cell+ @ swap !
   @ swap ! ;

: core_list_insert_new  ( a-addr1 a-addr2 -- )
;

: data!  ( u1 u2 a-addr -- )  \ idx data16 &elem
   cell+ @
   swap over cell+ !  \ elem->info->data16=u2
   ! ;  \ elem->info->idx=u1

: idx!  ( u a-addr -- )  \ idx &elem
   cell+ @
   ! ;  \ elem->info->idx=u1

: data16!  ( u a-addr -- )  \ data16 &elem
   cell+ @
   cell+ ! ;  \ elem->info->data16=u2

: elem+  ( a-addr1 -- a-addr2 )
   2 cells + ;

: list_new  ( a-addr1 -- a-addr2 )  \ &end_elem -- &newend_elem
   dup cell+ @ elem+  ( &end_elem &newend_data )
   swap elem+  \ &newend_elem
   tuck cell+ ! ; \ newend_elem->info=&newend_data

: list_insert  ( a-addr1 a-addr2 -- )  \ &elem &newend_elem
   over @ over !  \ newtail_elem->next= elem->next
   swap ! ;  \ elem->next=&newend_elem

: core_list_init  ( u1 a-addr1 u2 -- a-addr2 )  \ list_head *core_list_init(ee_u32 blksize, list_head *memblock, ee_s16 seed)
   >r  \ blksize memblock R: seed
   over swap  \ blksize blksize memblock
   $0 over !  \ list->next=NULL
   over 2/ over + over cell+ !  \ list->info=datablock
   dup $0000 $8080 rot data!
   dup list_new
   dup $7FFF $FFFF rot data!
   2dup list_insert  \ &elem &end_elem
   rot 2/ 2/ cell / 3 -
   0 do
      list_new
      j i xor $000F and
      #3 lshift i $0007 and or
      dup #8 lshift or
      over data16!
      2dup list_insert
   loop
   drop swap 2/ 2/ cell / 5 / >r  \ list R: size/5
   1 over
   begin
      @ dup @
   while
         swap  ( list i )
         dup r@ < if
            dup
         else
            dup r> r@ swap >r xor
            over 1+ $0007 and #8 lshift
            or $3FFF and
         then
         swap 1+ rot rot
         over idx!
   repeat
   2drop
   r> r> 2drop
;
