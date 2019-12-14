
\ ee_s16 calc_func(ee_s16 *pdata, core_results *res)
: calc_func  ( a-addr -- n )
   dup @  \ &pdata data
   dup $80 and if
      $7F and nip
      exit
   else
      dup $06 and if
         dup
      else
         dup #3 rshift $0F and
         dup #4 lshift or  \ &pdata data dtype
         over $01 and if
            matrix_data swap crc @ core_bench_matrix
            crcmatrix @ if
            else
               dup crcmatrix !
            then
         else
            dup $22 < if  \ positive numbers
               drop $22
            then
            >r crc @ seed2 @ seed1 @ r> state_data core_bench_state
            crcstate @ if
            else
               dup crcstate !
            then
         then
      then
      dup crc @ crcu16 crc !
      $7F and  \ &pdata data retval
      >r $FF00 and $80 or r@ or
      swap !
      r>
   then ;

\ re-generate data16 = (data16 & 0xFF00) | (data16>>8 & 0x00FF)
: dataregen  ( a-addr -- )  \ &data
   cell+
   dup @  ( data16 )
   $FF00 and
   dup #8 rshift $00FF and
   or swap ! ;

\ compare idx and re-generate data16
\ ee_s32 cmp_idx(list_data *a, list_data *b, core_results *res)
: cmp_idx_dr  ( a-addr1 a-addr2 -- n )  \ &elem_a &elem_b
   cell+ @
   dup dataregen
   swap cell+ @
   dup dataregen
   @ swap @ - ;  \ s16 is enough

\ compare idx
\ ee_s32 cmp_idx(list_data *a, list_data *b, core_results *res)
: cmp_idx  ( a-addr1 a-addr2 -- n )  \ &elem_a &elem_b
   cell+ @
   swap cell+ @
   @ swap @ - ;  \ s16 is enough

\ Compare the data item in a list cell.
\ Can be used by mergesort.
\ ee_s32 cmp_complex(list_data *a, list_data *b, core_results *res)
: cmp_complex  ( a-addr1 a-addr2 -- n )  \ &elem_a &elem_b
   swap
   cell+ @ cell+ calc_func
   swap
   cell+ @ cell+ calc_func
   - ;  \ s16 is enough

\  update tail to b and advance to next b
: next_elem  ( a-addr1 a-addr2 a-addr3 -- a-addr3 a-addr2 a-addr4 )
   \ &tail &a &b -- &b &a &b->next
   rot over swap ! tuck @
;

: mergesort  ( a-addr1 a-addr2 a-addr3 xt -- a-addr4 )  \ &tail p q cmp
   \ p is <> 0
   >r  \ &tail p q
   begin
      dup if
         over if
            2dup r@ execute
            0> if
               next_elem
            else
               swap next_elem swap
            then
         else
            next_elem
         then
      else
         over if
            swap next_elem
         else
            2drop r> drop exit
         then
      then
   again ;

\ split first u elements from list by
\ putting 0 on last element next
\ and returns following element
: split  ( a-addr1 u -- a-addr2 )
   over swap
   0 do  ( an-1 an )
      nip
      dup if
         dup @
      else
         unloop exit
      then
   loop
   0 rot ! ;

\ Sort the list in place without recursion.
\   Use mergesort, as for linked list this is a realistic solution. 
\   Also, since this is aimed at embedded, care was taken to use iterative rather then recursive algorithm.
\   The sort can either return the list to original order (by idx),
\   or use the data item to invoke other other algorithms and change the order of the list.
\   Parameters:
\   list - list to be sorted.
\   cmp - cmp function to use
: core_list_mergesort  ( a-addr1 xt -- )  \ &head &cmp
   >r dup 1
   begin  ( &head &tail insize )
      0 rot rot
      over @ swap
      begin  ( nmerges &tail &next insize )
         2dup split
         2dup swap split
         r@ swap >r rot >r  ( R: xt &next insize )
         mergesort  ( nmerges &tail )
         swap 1+ swap
         r> r>
         dup
      while
            swap
      repeat
      drop nip  ( nmerges insize )
      over #2 < if r> 2drop 2drop exit then
      2*  \ insize * 2
      nip over swap
   again ;

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

\ list_head *core_list_init(ee_u32 blksize, list_head *memblock, ee_s16 seed)
\   Initialize list with data.
\   Parameters:
\     blksize - Size of memory to be initialized.
\     memblock - Pointer to memory block.
\     seed -  Actual values chosen depend on the seed parameter.
: core_list_init  ( u1 a-addr u2 -- )
   over >r  \ save list head
   >r  \ blksize memblock R: seed
   cell+  \ skip list head
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
   r@ !
   r> ['] cmp_idx_dr core_list_mergesort ;

\ Print list
: .list  ( a-addr -- )
   base @ swap hex
   begin
      @ dup
   while
         dup cell+ @
         ." ["
         dup @ $FFFF and 0 <# # # # # #> type
         ." ,"
         cell+ @ $FFFF and 0 <# # # # # #> type
         ." ]"
   repeat
   drop
   base ! ;

: core_list_find_idx  ( x a-addr1 -- a-addr2|0 )
   begin
      @ dup if
         2dup cell+ @ @
         = if nip exit then
      else
         nip exit
      then
   again ;

: core_list_find_data16  ( x a-addr1 -- a-addr2|0 )
   begin
      @ dup if
         2dup cell+ @ cell+ @
         $00FF and
         = if nip exit then
      else
         nip exit
      then
   again ;

\ Find an item in the list
\ Operation:
\ Find an item by idx (if not 0) or specific data value
\ Parameters:
\ list - list head
\ info - idx or data to find
\ Returns:
\ Found item, or NULL if not found.
\ list_head *core_list_find(list_head *list,list_data *info)
: core_list_find  ( n1 n2 a-addr1 -- a-addr2|0 )  \ data16 idx &head
   over 0< if
      nip
      core_list_find_data16
   else
      core_list_find_idx
      nip
   then ;

\ Reverse a list
\ Operation:
\ Rearrange the pointers so the list is reversed.
\ Parameters:
\ list - list head
\ Returns:
\ Found item, or NULL if not found.
\ list_head *core_list_reverse(list_head *list)
: core_list_reverse  ( a-addr -- )
   0 over @
   begin  ( a-addr a-addr0 a-addr1 )
      dup if
         dup @ >r
         swap over !
         r>
      else
         drop swap !
         exit
      then
   again ;

\ Remove an item from the list.
\ Operation:
\ For a singly linked list, remove by copying the data from the next item 
\ over to the current cell, and unlinking the next item.
\ Note: 
\ since there is always a fake item at the end of the list, no need to check for NULL.
\ Returns:
\ Removed item.
\ list_head *core_list_remove(list_head *item)
: core_list_remove  ( a-addr1 -- a-addr2 )
   dup @  ( a-addr1 a-addr2 )
   over cell+ over cell+
   dup @ >r
   over @ swap !
   r> swap !
   tuck @ swap !
   0 over ! ;

\ Undo a remove operation.
\ Operation:
\ Since we want each iteration of the benchmark to be exactly the same,
\ we need to be able to undo a remove. 
\ Link the removed item back into the list, and switch the info items.
\ Parameters:
\ item_removed - Return value from the <core_list_remove>
\ item_modified - List item that was modified during <core_list_remove>
\ Returns:
\ The item that was linked back to the list.
\ list_head *core_list_undo_remove(list_head *item_removed, list_head *item_modified)
: core_list_undo_remove  ( a-addr1 a-addr2 -- )  \ modified removed
   over cell+ over cell+
   dup @ >r
   over @ swap !
   r> swap !
   over @ over !
   swap ! ;

\ Benchmark for linked list:
\ - Try to find multiple data items.
\ - List sort
\ - Operate on data from list (crc)
\ - Single remove/reinsert
\ At the end of this function, the list is back to original state
\ ee_u16 core_bench_list(core_results *res, ee_s16 finder_idx)
: core_bench_list  ( n -- u )
   dup
   >r 0 0 0 r>
   seed3 @
   0 do  \ finder_idx missed found retval idx
      i $FF and
      swap dup >r  \ R: idx
      list_head core_list_find  \ missed found retval this_find R: idx
      list_head core_list_reverse
      dup if
         dup cell+ @ cell+ @  \ data16
         dup $0001 and if
            $0200 and if swap 1+ swap then
         else
            drop
         then
         dup @ if  \ this_find
            dup @  \ this_find->next
            tuck @ swap !
            list_head @ @ over !
            list_head @ !
         else
            drop
         then
         swap 1+ swap  \ found++
      else
         drop
         list_head @ @ cell+ @ cell+ @  \ data16
         $0100 and if 1+ then
         >r swap 1+ swap r>  \ missed++
      then
      r> dup 0< if else 1+ then  \ idx++
   loop
   >r swap #4 * + swap -  \ retval+=found*4-missed
   swap 0> if
      list_head ['] cmp_complex core_list_mergesort
   then
   list_head @ @ core_list_remove  \ retval remover
   swap  \ remover retval
   seed3 @ 1- $FF and r>
   list_head core_list_find  \ finder
   dup if else drop list_head @ @ then
   list_head @ cell+ @ cell+ @ >r  \ R: list->info->data16
   begin  \ retval finder
      dup
   while
         swap r@ swap crc16
         swap @
   repeat
   r> 2drop swap  \ retval remover
   list_head @ @ swap core_list_undo_remove
   list_head ['] cmp_idx_dr core_list_mergesort
   list_head @ @  \ finder
   list_head @ cell+ @ cell+ @ >r  \ R: list->info->data16
   begin  \ retval finder
      dup
   while
         swap r@ swap crc16
         swap @
   repeat
   r> 2drop ;  \ retval
