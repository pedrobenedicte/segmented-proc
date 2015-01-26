Bypass test

Previous Values
-- r1 = 2
-- r2 = 4
-- r3 = 8
-- r4 = 16

Program execution:
nop
add r3 <- r1, r2
add r4 <- r3, r2
nop

Final values
-- r1 = 2
-- r2 = 4
-- r3 = 6
-- r4 = 10
