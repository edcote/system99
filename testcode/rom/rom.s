.align 4
.set noat
.set noreorder

.text

entry:
/* NODE 0 */
.org    0x000
node_0_entry:
    nop

    break

/* NODE 1 */
.org    0x100
node_1_entry:

    li      $t0, 0x1234abcd
    li      $a0, 0x10000000

    lw      $t0, 0($a0)
    nop

    sw      $t0, 0($a0)
    nop

/*    j       node_1_entry
    nop*/

    break
    
/* END */
delay:
    bne     $a0, $zero, delay
    addi    $a0, $a0, -1
    jr      $ra
    nop

.org    0x200
