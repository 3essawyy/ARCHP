# all numbers in hex format
# we always start by reset signal
# this is a commented line
# You should ignore empty lines

# ---------- Don't forget to Reset before you start anything ---------- #

.ORG 0  #this means the the following line would be  at address  0 , and this is the reset address
FF

.ORG FF

IN R1             #add 5 in R1
IN R2             #add 19 in R2
IN R3             #FFFFFFFF
IN R4             #FFFFF320
MOV R5, R3        #R5 = FFFFFFFF , flags no change
ADD R4,R1,R4      #R4 = FFFFF325 , C-->0, N-->1, Z-->0
SUB R6,R5,R4      #R6 = 00000CDA , C-->1, N-->0, Z-->0 carry as not borrow
AND R4,R7,R4      #R4 = 00000000 , C-->no change, N-->0, Z-->1
IADD R2,R2,FFFF   #R2 = 00010018 (C = 0,N,Z= 0) OR R2=18 and C = 1 if implementing sign extend
SWAP R2, R4
ADD R2,R1,R2      #R2 = 5 (C = 0, N = 0, Z = 0)
ADD R6,R4,R2      #R6 = 0001001D
IADD R6, R6, 2    #R6 = 0001001F
AND R3, R2, R6    #R3 = 00000005

HLT