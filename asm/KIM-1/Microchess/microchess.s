; © COPYRIGHT 1976, PETER JENNINGS, MICROCHESS,
; 1612-43 THORNCLIFFE PK DR, TORONTO, CANADA.
; ALL RIGHTS RESERVED.  REPRODUCTION BY   ANY
; MEANS, IN WHOLE OR IN PART, IS PROHIBITED.

        BOARD   = $50
        BK      = $60
        PIECE   = $B0
        SQUARE  = $B1
        SP2     = $B2
        SP1     = $B3
        INCHEK  = $B4
        STATE   = $B5
        MOVEN   = $B6
        OMOVE   = $DC
        WCAP0   = $DD
        COUNT   = $DE
        BCAP2   = $DE
        WCAP2   = $DF
        BCAP1   = $E0
        WCAP1   = $E1
        BCAP0   = $E2
        MOB     = $E3
        MAXC    = $E4
        CC      = $E5
        PCAP    = $E6
        BMOB    = $E3
        BMAXC   = $E4
;        BCC     = $E5
        BMAXP   = $E6
        XMAXC   = $E8
        WMOB    = $EB
        WMAXC   = $EC
        WCC     = $ED
        WMAXP   = $EE
        PMOB    = $EF
        PMAXC   = $F0
        PCC     = $F1
        PCP     = $F2
        OLDKY   = $F3
        BESTP   = $FB
        BESTV   = $FA
        BESTM   = $F9
        DIS3    = $F9
        DIS2    = $FA
        DIS1    = $FB

        SCANDS  = $1F1F
        GETKEY  = $1F6A

;       EXECUTION BEGINS AT ADDRESS 0000
;

CHESS:  CLD                     ; INITIALIZE
        LDX     #$FF            ; TWO STACKS
        TXS
        LDX     #$C8
        STX     SP2
;
;       ROUTINES TO LIGHT LED
;       DISPLAY AND GET KEY
;       FROM KEYBOARD.
;
OUT:    JSR     SCANDS          ; DISPLAY AND
        JSR     GETKEY          ; GET INPUT
        CMP     OLDKY           ; KEY IN ACC
        BEQ     OUT             ; (DEBOUNCE)
        STA     OLDKY
;
        CMP     #$0C            ; [C]
        BNE     NOSET           ; SET UP
        LDX     #$1F            ; BOARD
WHSET:  LDA     SETW,X          ; FROM
        STA     BOARD,X         ; SETW
        DEX
        BPL     WHSET
        STX     OMOVE
        LDA     #$CC
        BNE     CLDSP
;
NOSET:  CMP     #$0E            ; [E]
        BNE     NOREV           ; REVERSE
        JSR     REVERSE         ; BOARD AS
        LDA     #$EE            ; IS
        BNE     CLDSP
;
NOREV:  CMP     #$14            ; [PC]
        BNE     NOGO            ; PLAY CHESS
        JSR     GO
CLDSP:  STA     DIS1            ; DISPLAY
        STA     DIS2            ; ACROSS
        STA     D1S3            ; DISPLAY
        BNE     CHESS
;
NOGO:   CMP     #$0F            ; [F]
        BNE     NOMV            ; MOVE MAN
        JSR     MOVE            ; AS ENTERED
        JMP     DISP
NOMV:   JMP     INPUT


; BLOCK DATA

        .ORG    $0070

SETW:   .BYTE   $03, $04, $00, $07, $02, $05, $01, $06, $10, $17, $11, $16, $12, $15, $14, $13
        .BYTE   $73, $74, $70, $77, $72, $75, $71, $76, $60, $67, $61, $66, $62, $65, $64, $63

MOVEX:  .BYTE   $F0, $FF, $01, $10, $11, $0F, $EF, $F1, $DF, $E1, $EE, $F2, $12, $0E, $1F, $21

POINTS: .BYTE   $0B, $0A, $06, $06, $04, $04, $04, $04, $02, $02, $02, $02, $02, $02, $02, $02

OPNING: .BYTE   $99, $25, $0B, $25, $01, $00, $33, $25, $07, $36, $34, $0D, $34, $34, $0E, $52
        .BYTE   $25, $0D, $45, $35, $04, $55, $22, $06, $43, $33, $0F, $CC

; NOTE THAT 00B7 TO 00BF, 00F4 TO 00F8, AND 00FC TO 00FF ARE
; AVAILABLE FOR USER EXPANSION AND I/O ROUTINES.


;
;       THE ROUTINE JANUS DIRECTS THE
;       ANALYSIS BY DETERMINING WHAT
;       SHOULD OCCUR AFTER EACH MOVE
;       GENERATED BY GNM
;
;

        .ORG    $0100

JANUS:   LDX    STATE
         BMI    NOCOUNT
;
;       THIS ROUTINE COUNTS OCCURRENCES
;       IT DEPENDS UPON STATE TO INDEX
;       THE CORRECT COUNTERS
;
COUNTS:  LDA    PIECE
         BEQ    OVER            ; IF STATE=8
         CPX    #$08            ; DO NOT COUNT
         BNE    OVER            ; BLK MAX CAP
         CMP    BMAXP           ; MOVES FOR
         BEQ    XRT             ; WHITE
;
OVER:    INC    MOB,X           ; MOBILITY
         CMP    #$01            ; + QUEEN
         BNE    NOQ             ; FOR TWO
         INC    MOB,X
;
NOQ:     BVC    NOCAP
         LDY    #$0F            ; CALCULATE
         LDA    SQUARE          ; POINTS
ELOOP:   CMP    BK,Y            ; CAPTURED
         BEQ    FOUN            ; BY THIS
         DEY                    ; MOVE
         BPL    ELOOP
FOUN:    LDA    POINTS,Y
         CMP    MAXC,X
         BCC    LESS            ; SAVE IF
         STY    PCAP,X          ; BEST THIS
         STA    MAXC,X          ; STATE
;
LESS:    CLC
         PHP                    ; ADD TO
         ADC    CC,X            ; CAPTURE
         STA    CC,X            ; COUNTS
         PLP
;
NOCAP:   CPX    #$04
         BEQ    ON4
         BMI    TREE            ; (=00 ONLY)
XRT:     RTS
;
;      GENERATE FURTHER MOVES FOR COUNT
;      AND ANALYSIS
;
ON4:     LDA     XMAXC          ; SAVE ACTUAL
         STA     WCAP0          ; CAPTURE
         LDA     #$00           ; STATE=0
         STA     STATE
         JSR     MOVE           ; GENERATE
         JSR     REVERSE        ; IMMEDIATE
         JSR     GNMHZ          ; REPLY MOVES
         JSR     REVERSE
;
         LDA     #$08           ; STATE=8
         STA     STATE          ; GENERATE
         JSR     GNM            ; CONTINUATION
         JSR     UMOVE          ; MOVES
;
         JMP     STRATGY        ; FINAL EVALUATION
NOCOUNT: CPX     #$F9
         BNE     TREE
;
;      DETERMINE IF THE KING CAN BE
;      TAKEN, USED BY CHKCHK
;
         LDA     BK             ; IS KING
         CMP     SQUARE         ; IN CHECK?
         BNE     RETJ           ; SET INCHEK=0
         LDA     #$00           ; IF IT IS
         STA     INCHEK
RETJ:    RTS
;
;      IF A PIECE HAS BEEN CAPTURED BY 
;      A TRIAL MOVE, GENERATE REPLIES &
;      EVALUATE THE EXCHANGE GAIN/LOSS
;
TREE:    BVC     RETJ           ; NO CAP
         LDY     #$07           ; (PIECES)
         LDA     SQUARE
LOOPX:   CMP     BK,Y
         BEQ     FOUNX
         DEY
         BEQ     RETJ           ; (KING)
         BPL     LOOPX          ; SAVE
FOUNX:   LDA     POINTS,Y       ; BEST CAP
         CMP     BCAP0,X        ; AT THIS
         BCC     NOMAX          ; LEVEL
         STA     BCAP0,X
NOMAX:   DEC     STATE
         LDA     #$FB           ; IF STATE=FB
         CMP     STATE          ; TIME TO TURN
         BEQ     UPTREE         ; AROUND
         JSR     GENRM          ; GENERATE FURTHER
UPTREE:  INC     STATE          ; CAPTURES
         RTS
;
;      THE PLAYER'S MOVE IS INPUT
;
INPUT:   CMP     #$08           ; NOT A LEGAL
         BCS     ERROR          ; SQUARE #
         JSR     DISMV
DISP:    LDX     #$1F
SEARCH:  LDA     BOARD,X
         CMP     DIS2
         BEQ     HERE           ; DISPLAY
         DEX                    ; PIECE AT
         BPL     SEARCH         ; FROM
HERE:    STX     DIS1           ; SQUARE
         STX     PIECE
ERROR:   JMP     CHESS
;
;      GENERATE ALL MOVES FOR ONE
;      SIDE, CALL JANUS AFTER EACH
;      ONE FOR NEXT STEP
;

GNMZ:    LDX     #$10           ; CLEAR
GNMX:    LDA     #$00           ; COUNTERS
CLEAR:   STA     COUNT,X
         DEX
         BPL     CLEAR
;
GNM:     LDA     #$10           ; SET UP
         STA     PIECE          ; PIECE
NEWP:    DEC     PIECE          ; NEW PIECE
         BPL     NEX            ; ALL DONE?
         RTS                    ; -YES
;
NEX:     JSR     RESET          ; READY
         LDY     PIECE          ; GET PIECE
         LDX     #$08
         STX     MOVEN          ; COMMON START
         CPY     #$08           ; WHAT IS IT?
         BPL     PAWN           ; PAWN
         CPY     #$06
         BPL     KNIGHT         ; KNIGHT
         CPY     #$04
         BPL     BISHOP         ; BISHOP
         CPY     #$01
         BEQ     QUEEN          ; QUEEN
         BPL     ROOK           ; ROOK
;
KING:    JSR     SNGMV          ; MUST BE KING!
         BNE     KING           ; MOVES
         BEQ     NEWP           ; 8 TO 1
QUEEN:   JSR     LINE
         BNE     QUEEN          ; MOVES
         BEQ     NEWP           ; 8 TO 1
;
ROOK:    LDX     #$04
         STX     MOVEN          ; MOVES
AGNR:    JSR     LINE           ; 4 TO 1
         BNE     AGNR
         BEQ     NEWP
;
BISHOP:  JSR     LINE
         LDA     MOVEN          ; MOVES
         CMP     #$04           ; 8 TO 5
         BNE     BISHOP
         BEQ     NEWP
;
KNIGHT:  LDX     #$10
         STX     MOVEN          ; MOVES
AGNN:    JSR     SNGMV          ; 16 TO 9
         LDA     MOVEN
         CMP     #$08
         BNE     AGNN
         BEQ     NEWP
;
PAWN:    LDX     #$06
         STX     MOVEN
P1:      JSR     CMOVE          ; RIGHT CAP?
         BVC     P2
         BMI     P2
         JSR     JANUS          ; YES
P2:      JSR     RESET
         DEC     M0VEN          ; LEFT CAP?
         LDA     MOVEN
         CMP     #$05
         BEQ     P1
P3:      JSR     CMOVE          ; AHEAD
         BVS     NEWP           ; ILLEGAL
         BMI     NEWP
         JSR     JANUS
         LDA     SQUARE         ; GETS TO
         AND     #$F0           ; 3RD RANK?
         CMP     #$20
         BEQ     P3             ; DO DOUBLE
         JMP     NEWP
;
;      CALCULATE SINGLE STEP MOVES
;      FOR K, N
;
SNGMV:   JSR     CMOVE          ; CALC MOVE
         BMI     ILL1           ; -IF LEGAL
         JSR     JANUS          ; -EVALUATE
ILL1:    JSR     RESET
         DEC     MOVEN
         RTS
;
;     CALCULATE ALL MOVES DOWN A
;     STRAIGHT LINE FOR Q,B,R
;
LINE:    JSR     CMOVE          ; CALC MOVE
         BCC     OVL            ; NO CHK
         BVC     LINE           ; CH,NOCAP
OVL:     BMI     ILL            ; RETURN
         PHP
         JSR     JANUS          ; EVALUATE POSN
         PLP
         BVC     LINE           ; NOT A CAP
ILL:     JSR     RESET          ; LINE STOPPED
         DEC     MOVEN          ; NEXT DIR
         RTS
;
;      EXCHANGE SIDES FOR REPLY
;      ANALYSIS
;
REVERSE: LDX     #$0F
ETC:     SEC
         LDY     BK,X            ; SUBTRACT
         LDA     #$77            ; POSITION
         SBC     BOARD,X         ; FROM 77
         STA     BK,X
         STY     BOARD,X         ; AND
         SEC
         LDA     #$77            ; EXCHANGE
         SBC     BOARD,X         ; PIECES
         STA     BOARD,X
         DEX
         BPL     ETC
         RTS
;
;
;
;
;
;
;
;        CMOVE CALCULATES THE TO SQUARE
;        USING .SQUARE AND THE MOVE
;       TABLE.  FLAGS SET AS FOLLOWS:
;       N - ILLEGAL MOVE
;       V - CAPTURE (LEGAL UNLESS IN CH)
;       C - ILLEGAL BECAUSE OF CHECK
;       [MY THANKS TO JIM BUTTERFIELD
;        WHO WROTE THIS MORE EFFICIENT
;        VERSION OF CMOVE]
;
CMOVE:   LDA     SQUARE          ; GET SQUARE
         LDX     MOVEN           ; MOVE POINTER
         CLC
         ADC     MOVEX,X         ; MOVE LIST
         STA     SQUARE          ; NEW POS'N
         AND     #$88
         BNE     ILLEGAL         ; OFF BOARD
         LDA     SQUARE
;
         LDX     #$20
LOOP:    DEX                     ; IS TO
         BMI     NO              ; SQUARE
         CMP     BOARD,X         ; OCCUPIED?
         BNE     LOOP
;
         CPX     #$10            ; BY SELF?
         BMI     ILLEGAL
;
         LDA     #$7F            ; MUST BE CAP!
         ADC     #$01            ; SET V FLAG
         BVS     SPX             ; (JMP)
;
NO:      CLV                     ; NO CAPTURE
;
SPX:     LDA     STATE           ; SHOULD WE
         BMI     RETL            ; DO THE
         CMP     #$08            ; CHECK CHECK?
         BPL     RETL
;
;        CHKCHK REVERSES SIDES
;       AND LOOKS FOR A KING
;       CAPTURE TO INDICATE
;       ILLEGAL MOVE BECAUSE OF
;       CHECK.  SINCE THIS IS
;       TIME CONSUMING, IT IS NOT
;       ALWAYS DONE.
;
CHKCHK:  PHA                     ; STATE
         PHP
         LDA     #$F9
         STA     STATE          ; GENERATE
         STA     INCHEK         ; ALL REPLY
         JSR     MOVE           ; MOVES TO
         JSR     REVERSE        ; SEE IF KING
         JSR     GNM            ; IS IN
         JSR     RUM            ; CHECK
         PLP
         PLA
         STA     STATE
         LDA     INCHEK
         BMI     RETL           ; NO - SAFE
         SEC                    ; YES - IN CHK
         LDA     #$FF
         RTS
;
RETL:    CLC                    ; LEGAL
         LDA     #$00           ; RETURN
         RTS
;
ILLEGAL: LDA     #$FF
         CLC                    ; ILLEGAL
         CLV                    ; RETURN
         RTS
;
;       REPLACE .PIECE ON CORRECT .SQUARE
;
RESET:   LDX     PIECE          ; GET LOGAT.
         LDA     BOARD,X        ; FOR PIECE
         STA     SQUARE         ; FROM BOARD
         RTS
;
;
;
GENRM:   JSR     MOVE           ; MAKE MOVE
GENR2:   JSR     REVERSE        ; REVERSE BOARD
         JSR     GNM            ; GENERATE MOVES
RUM:     JSR     REVERSE        ; REVERSE BACK
;
;       ROUTINE TO UNMAKE A MOVE MADE BY
;                MOVE
;
UMOVE:   TSX                    ; UNMAKE MOVE
         STX     SP1
         LDX     SP2            ; EXCHANGE
         TXS                    ; STACKS
         PLA                    ; MOVEN
         STA     MOVEN
         PLA                    ; CAPTURED
         STA     PIECE          ; PIECE
         TAX
401  033E 68                     PLA                      FROM SQUARE
402  033F 95 50                  STAX     .BOARD
403  0341 68                     PLA                      PIECE
404  0342 AA                     TAX
405  0343 68                     PLA                      TO SOUARE
406  0344 85 B1                  STA      .SQUARE
407  0346 95 50                  STAX     .BOARD
408  0348 4C 70 03               JMP       STRV
409                    ;
410                    ;       THIS ROUTINE MOVES .PIECE
411                    ;       TO .SQUARE,  PARAMETERS
412                    ;       ARE SAVED IN A STACK TO UNMAKE
413                    ;       THE MOVE LATER
414                    ;
415  034B BA           MOVE      TSX
416  034C 86 B3                  STXZ      .SPI           SWITCH
417  034E A6 B2                  LDX      .SP2           STACKS
418  0350 9A                     TXS
419  0351 A5 B1                  LDA      .SQUARE
420  0353 48                     PHA                      TO SQUARE
421  0354 A8                     TAY
422  0355 A2 1F                  LDX #     1F
423  0357 D5 50        CHECK     CMPZX     .BOARD         CHECK FOR
424  0359 F0 03                  BEQ       TAKE           CAPTURE
425  035B CA                     DEX
426  035C 10 F9                  BPL       CHECK
427  035E A9 CC        TAKE      LDA #     CC
428  0360 95 50                  STAX     .BOARD
429  0362 8A                     TXA                      CAPTURED
430  0363 48                     PHA                      PIECE
431  0364 A6 B0                  LDX      .PIECE
432  0366 B5 50                  LDAX     .BOARD
433  0368 94 50                  STYZX     .BOARD         FROM
434  036A 48                     PHA                         SQUARE
435  036B 8A                     TXA
436  036C 48                     PHA                      PIECE
437  036D A5 B6                  LDA      .MOVEN
438  036F 48                     PHA                      MOVEN
439  0370 BA           STRV      TSX
440  0371 86 B2                  STXZ      .SP2           SWITCH
441  0373 A6 B3                  LDX      .SPI           STACKS
442  0375 9A                     TXS                      BACK
443  0376 60                     RTS
444                    ;
445                    ;       CONTINUATION OF SUB STRATGY
446                    ;       -CHECKS FOR CHECK OR CHECKMATE
447                    ;       AND ASSIGNS VALUE TO MOVE
448                    ;
449  0377 A6 E4        CKMATE    LDX      .BMAXC         CAN BLK CAP
450  0379 E4 A0                  CPXZ      .POINTS        MY KING?


CHESS                   PAGE 10



451  037B D0 04                  BNE NOCHEK
452  037D A9 00                  LDA #     00             GULP!
453  037F F0 0A                  BEQ       RETV           DUMB MOVE!
454                    ;
455  0381 A6 E3        NOCHEK    LDX      .BMOB          IS BLACK
456  0383 D0 06                  BNE       RETV           UNABLE TO
457  0385 A6 EE                  LDX      .WMAXP         MOVE AND
458  0387 D0 02                  BNE       RETV           KING IN CH?
459  0389 A9 FF                  LDA #     FF             YES! MATE
460                    ;
461  038B A2 04        RETV      LDX #     04             RESTORE
462  038D 86 B5                  STXZ      .STATE         STATE=4
463                    ;
464                    ;       THE VALUE OF THE MOVE (IN ACCU)
465                    ;       IS COMPARED TO THE BEST MOVE AND
466                    ;       REPLACES IT IF IT IS BETTER
467                    ;
468  038F C5 FA        PUSH      CMPZ      .BESTV         IS THIS BEST
469  0391 90 0C                  BCC       RETP           MOVE SO FAR?
470  0393 F0 0A                  BEQ       RETP
471  0395 85 FA                  STA      .BESTV         YES!
472  0397 A5 B0                  LDA      .PIECE         SAVE IT
473  0399 85 FB                  STA      .BESTP
474  039B A5 B1                  LDA      .SQUARE
475  039D 85 F9                  STA      .BESTM         FLASH DISPLAY
476  039F 4C 1F 1F     RETP      JMP       *OUT           AND RTS
477                    ;
478                    ;       MAIN PROGRAM TO PLAY CHESS
479                    ;       PLAY FROM OPENING OR THINK
480                    ;
481  03A2 A6 DC        GO        LDX      .OMOVE         OPENING?
482  03A4 10 17                  BPL       NOOPEN             -NO
483  03A6 A5 F9                  LDA      .DIS3          -YES WAS
484  03A8 D5 DC                  CMPZX     .OPNING         OPPONENT'S
485  03AA D0 0F                  BNE       END             MOVE OK?
486  03AC CA                     DEX
487  03AD B5 DC                  LDAX     .OPNING        GET NEXT
483  03AF 85 FB                  STA      .DIS1          CANNED
489  03B1 CA                     DEX                      OPENING MOVE
490  03B2 B5 DC                  LDAX     .OPNING
491  03B4 85 F9                  STA      .DIS3          DISPLAY IT
492  03B6 CA                     DEX
493  03B7 86 DC                  STXZ      .OMOVE         MOVE IT
494  03B9 D0 1A                  BNE       MV2            (JMP)
495                    ;
496  03BB 85 DC        END       STA      .OMOVE         FLAG OPENING
497  03BD A2 0C        NOOPEN    LDX #     OC             FINISHED
498  03BF 86 B5                  STXZ      .STATE         STATE=C
499  03C1 86 FA                  STXZ      .BESTV         CLEAR BESTV
500  03C3 A2 14                  LDX #     14             GENERATE P


CHESS                   PAGE 11



501  03C5 20 02 02               JSR       GNMX           MOVES
502                    ;
503  03C8 A2 04                  LDX #     04             STATE=4
504  03CA 86 B5                  STXZ      .STATE         GENERATE AND
505  03CC 20 00 02               JSR       GNMZ           TEST AVAILABLE
506                    ;                                  MOVES
507                    ;
508  03CF A6 FA                  LDX      .BFSTV         GET BEST MOVE
509  03D1 E0 0F                  CPX #     0F             IF NONE
510  03D3 90 12                  BCC       MATE           OH OH!
511                    ;
512  03D5 A6 FB        MV2       LDX      .BESTP         MOVE
513  03D7 B5 50                  LDAX     .BOARD          THE
514  03D9 85 FA                  STA      .BESTV         BEST
515  03DB 86 B0                  STXZ      .PIECE         MOVE
516  03DD A5 F9                  LDA      .BESTM
517  03DF 85 B1                  STA      .SQUARE        AND DISPLAY
518  03E1 20 4B 03               JSR       MOVE             IT
519  03E4 4C 00 00               JMP       CHESS
520                    ;
521  03E7 A9 FF        MATE      LDA #     FF             RESIGN
522  03E9 60                     RTS                      OR STALEMATE
523                    ;
524                    ;       SUBROUTINE TO ENTER THE 
525                    ;       PLAYER'S MOVE
526                    ;
527  03EA A2 04        DISMV     LDX #     04             ROTATE
528  03EC 06 F9        ROL       ASLZ      .DIS3           KEY
529  03EE 26 FA                  ROLZ      .DIS2          INTO
530  03F0 CA                     DEX                      DISPLAY
531  03F1 D0 F9                  BNE       ROL
532  03F3 05 F9                  ORAZ      .DIS3
533  03F5 85 F9                  STA      .DIS3
534  03F7 85 B1                  STA      .SQUARE
535  03F9 60                     RTS
536                    ;
537                    ;       THE FOLLOWING SUBROUTINE ASSIGNS
538                    ;       A VALUE TO THE MOVE UNDER
539                    ;       CONSIDERATION AND RETURNS IT IN
540                    ;         THE ACCUMULATOR
541                    ;
542                              +++
543  1780 18           STRATGY   CLC
544  1781 A9 80                  LDA #      80
545  1783 65 EB                  ADCZ       .WMOB          PARAMETERS
546  1785 65 EC                  ADCZ       .WMAXC         WITH WEIGHT
547  1787 65 ED                  ADCZ       .WCC           OF 0.25
548  1789 65 E1                  ADCZ       .WCAP1
549  178B 65 DF                  ADCZ       .WCAP2
550  178D 38                     SEC


CHESS                   PAGE 12



551  178E B5 F0                  SBCZ       .PMAXC
552  1790 E5 F1                  SBCZ       .PCC
553  1792 E5 E2                  SBCZ       .BCAPO
554  1794 E5 E0                  SBCZ       .BCAP1
555  1796 E5 DE                  SBCZ       .BCAP2
556  1798 E8 EF                  SBCZ       .PMOB
557  179A E5 E3                  SBCZ       .BMOB
558  179C B0 02                  BCS        POS           UNDERFLOW
559  179E A9 00                  LDA #      00            PREVENTION
560  17A0 4A           POS       LSRA
561  17A1 18                     CLC                      **************
562  17A2 69 40                  ADCIM      40
563  17A4 65 EC                  ADCZ       .WMAXC        PARAMETERS
564  17A6 65 ED                  ADCZ       .WCC          WITH WEIGHT
565  17A8 38                     SEC                      OF 0.5
566  17A9 E5 E4                  SBCZ       .BMAXC
567  17AB 4A                     LSRA                     **************
568  17AC 18                     CLC
569  17AD 69 90                  ADCIM      90
570  17AF 65 DD                  ADCZ       .WCAPO        PARAMETERS
571  17B1 65 DD                  ADCZ       .WCAPO        WITH WEIGHT
572  17B3 65 DD                  ADCZ       .WCAP0        OF 1.0
573  17B5 65 DD                  ADCZ       .WCAP0
574  17B7 65 E1                  ADCZ       .WCAP1
575  17B9 38                     SEC                      [UNDER OR OVER-
576  17BA E5 E4                  SBCZ       .BMAXC         FLOW MAY OCCUR
577  17BC E5 E4                  SBCZ       .BMAXC         FROM THIS
578  17BE E5 E5                  SBCZ       .BCC           SECTION]
579  17C0 E5 E5                  SBCZ       .BCC
580  17C2 E5 E0                  SBCZ       .BCAP1
581  17C4 A6 B1                  LDX       .SQUARE       ***************
582  17C6 E0 33                  CPX #      33
583  17C8 F0 16                  BEQ        POSN          POSITION
584  17CA E0 34                  CPX #      34            BONUS FOR
585  17CC F0 12                  BEQ        POSN          MOVE TO
586  17CE E0 22                  CPX #      22            CENTRE
587  17D0 F0 0E                  BEQ        POSN             OR
588  17D2 E0 25                  CPX #      25            OUT OF
589  17D4 F0 0A                  BEQ        POSN          BACK RANK
590  17D6 A6 B0                  LDX       .PIECE
591  17D8 F0 09                  BEQ        NOPOSN
592  17DA B4 50                  LDYZX      .BOARD
593  17DC C0 10                  CPY #      10
594  17DE 10 03                  BPL        NOPOSN
595  17E0 18                     POSN       CLC
596  17E1 69 02                  ADCIM      02
597  17E3 4C 77 03     NOPOSN    JMP        CKMATE        CONTINUE
598                    ;
599                    ;
600                    ;
