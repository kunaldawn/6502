E000R
SCR
10 GOSUB 1000
20 GOSUB 1100
30 PRINT "GOT KEY: ";K
40 IF K <> 81 THEN 20
50 END
1000 REM INIT ML CODE
1010 POKE 768,173:POKE 769,17:POKE 770,208:POKE 771,16:POKE 772,251:POKE 773,173
1020 POKE 774,16:POKE 775,208:POKE 776, 141:POKE 777,12:POKE 778,3:POKE 779,96
1030 RETURN
1100 REM GET KEYBOARD KEY
1110 CALL 768
1120 K = PEEK(780)
1130 IF K > 128 THEN K = K - 128
1140 RETURN
RUN
