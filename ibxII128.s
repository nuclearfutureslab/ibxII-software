;;; Information Barrier ][ (Software)
;;; for template based nuclear warhead verification
;;;
;;; It currently holds many routines to output data and demo
;;; the data acquisition on an Apple II. For actual
;;; verification, these should be removed.
;;; 
;;; Copyright 2017, Moritz Kütt, Alexander Glaser
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

.import __STARTUP_LOAD__, __BSS_LOAD__ ; Linker generated

.segment "EXEHDR"
.addr __STARTUP_LOAD__ ; Start address
.word __BSS_LOAD__ - __STARTUP_LOAD__ ; Size

.segment "RODATA"
PROMPT: .ASCIIZ " INFORMATION BARRIER EXPERIMENTAL ][ "
HVON:   .ASCIIZ "1 HV ON "
HVOFF:  .ASCIIZ "1 HV OFF"
THVON:  .ASCIIZ "RAMPING HV UP - LEVEL: "
THVOFF:  .ASCIIZ "RAMPING HV DOWN - LEVEL: "
TEM:    .ASCIIZ "2 TEMPLATE"
INS:    .ASCIIZ "3 INSPECTION"
CHCK:   .ASCIIZ "4 CHECK"
COUNTS: .ASCIIZ "TOTAL COUNTS: 0x"
CHI:    .ASCIIZ "CHI SQUARE STATISTIC: 0x"
PBIG:   .ASCIIZ "####    #   ##### ######   #  # #  #     #    ####  ##### ##### ######     #   #     #     ##     #   # ##### #####"
FBIG:   .ASCIIZ "#####   #     #   #    #      # #    #   #    ####  #####   #   #    #     #   #   #   #    #     #   #   #   #####"
IBX:    .ASCIIZ "#  ####  #   #  ### ####  #   #  # #     # #  #  ####    #      # #  #  #   #  # #     # #  #  ####  #   #  ### ###"
WEL:    .ASCIIZ "WELCOME!"
MSG:    .ASCIIZ "HAVE YOU INSPECTED A WARHEAD TODAY?"
BINBOR: .BYTE $11, $27, $3D, $53, $69, $7F, $95, $AB, $C1, $D7, $ED, $00

.segment "DATA"
SUBR:   .BYTE $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00
MULR:    .BYTE $00,$00,$00
OSQR:    .BYTE $00,$00,$00,$00,$00,$00,$00,$00 ;64bit for division
REMAIND: .BYTE $00,$00,$00,$00,$00,$00,$00,$00 ;for division
DIVTMP:  .BYTE $00,$00,$00,$00,$00,$00,$00,$00
CHIS:    .BYTE $00,$00,$00,$00,$00,$00,$00,$00 ;will hold chi square result
;;; Template and Inspection result memory
;;; Zero Values
;; TEMP:   .BYTE $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00
;; INSP:   .BYTE $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00
;;; Some test values
;;; Measurements with IBX for talk (0x20000 counts)
;; INSP:   .BYTE $e9,$47,$00,$e4,$a3,$00,$8c,$86,$00,$20,$5d,$00,$37,$5d,$00,$a6,$48,$00,$ea,$22,$00,$8a,$21,$00,$15,$18,$00,$51,$16,$00,$81,$15,$00,$4f,$02,$00
;; TEMP:   .BYTE $74,$46,$00,$2e,$a0,$00,$0f,$88,$00,$c7,$5a,$00,$4c,$5f,$00,$3c,$3f,$00,$4e,$25,$00,$ca,$25,$00,$e4,$18,$00,$f1,$18,$00,$47,$18,$00,$cc,$02,$00
;;; Some random values from older spectrum
TEMP:   .BYTE $85,$1a,$00, $f1,$3c,$00, $79,$28,$00, $da,$2a,$00, $39,$2c,$00, $39,$1d,$00, $d1,$03,$00, $c6,$02,$00, $6a,$02,$00, $47,$01,$00, $5a,$01,$00, $23,$00,$00
INSP:   .BYTE $19,$1b,$00, $6c,$3c,$00, $7d,$28,$00, $20,$2b,$00, $4b,$2c,$00, $be,$1c,$00, $cc,$03,$00, $a6,$02,$00, $92,$02,$00, $4c,$01,$00, $6b,$01,$00, $1a,$00,$00

;;; --------------------------------------------------------------------------------
;;; Main routine
;;; --------------------------------------------------------------------------------

.segment "STARTUP"

        ;; Memory addresses
        ;; --------------------------------------------------------------------------------
        ;; Hardware addresses of cards (depend on slots)
        ;; usually HV in 2, ADC in 4
        adcbaseaddress = 49344
        hvbaseaddress = 49312

        ;; Some memory for operation
        memorylowbyte = $8000
        memoryhighbyte = $8100
        plotbuffer = $8800
        hvstatus = $8900
        hvlevel = $8901

        ;; Memory in Zero Page
        totcount0 = $41
        totcount1 = $42
        totcount2 = $43
        p1 = $44
        p2 = $46
        p3 = $48
        bincount = $4A

        ;; Configuration related to measurement
        ;; --------------------------------------------------------------------------------
        ;; count limit template
        templatelimit = $02    ; reference is totcount2
        ;; set hv (approx.: Vout = 1000 / 233 * hvset)
        hvset = 233
        ;; vertical plot offset
        plotoffset = $9F
        ;; threshold for pass/fail (pass when chisquare < passthreshold)
        passthreshold = $20
        ;;bitmask for count b8-b15 (plots every (plotevery+1) * 256 counts)
        plotevery = $0F

        ;; Save HV status and level as off to memory
        LDA #$00
        STA hvstatus
        STA hvlevel

        ;; Clear screen and display friendly welcome
        JSR $FC58               ; HOME (clear screen)
        JSR WELC

        ;; Output prompt loop
OUT:    LDX #0
        STX $24
        LDX #19
        STX $25
        LDA #$8D ; next line
        JSR $FDED

        ;; Main prompt
        LDX #0
        LDA PROMPT,X ; load initial char
@LP:    ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA PROMPT,X
        BNE @LP
        LDA #$8D ; next line
        JSR $FDED

        ;; HV Text
        LDA hvstatus
        BNE DHVOFF

        LDX #0
        STX $24
        LDX #0
        LDA HVON,X ; load initial char
@LP2:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA HVON,X
        BNE @LP2
        JMP NEXT

DHVOFF: 
        LDX #0
        STX $24
        LDX #0
        LDA HVOFF,X ; load initial char
@LP2:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA HVOFF,X
        BNE @LP2

        ;; Template text
NEXT:   
        LDX #9
        STX $24
        LDX #0
        LDA TEM,X ; load initial char
@LP3:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA TEM,X
        BNE @LP3

        ;; Inspection text
        LDX #20
        STX $24
        LDX #0
        LDA INS,X ; load initial char
@LP5:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA INS,X
        BNE @LP5

        ;; Check text
        LDX #33
        STX $24
        LDX #0
        LDA CHCK,X ; load initial char
@LP6:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA CHCK,X
        BNE @LP6
        LDA #$8D ; next line
        JSR $FDED

        ;; Look for key input
@WK:    LDA #$80
        AND $C000
        BEQ @WK
        LDA $C000
        LDX $C010

        ;; switch to right subroutine for 1-4 (beep for other keys)
        SBC #$B0                ; Substract Flag & ASCII Offset
        TAX
        DEX
        BNE N1
        LDA hvstatus
        BEQ NHVON
        JSR TGHVOFF
        JMP OUT
NHVON:  JSR TGHVON
        JMP OUT
N1:     DEX
        BNE N2
        JSR TEMPLATE
        JMP OUT
N2:     DEX
        BNE N3
        JSR INSPECT
        JMP OUT
N3:     DEX
        BNE N4
        JSR SHOWR
        JMP OUT
N4:     JSR $FBDD               ; Beep
        JMP OUT

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE MEASURE
;;; --------------------------------------------------------------------------------
MEASURE:

        ;; Addresses for 12-Bit ADC board
        ledaddress = adcbaseaddress
        resetaddress = adcbaseaddress + 1
        adclowaddress = adcbaseaddress + 2
        adchighaddress = adcbaseaddress + 3
        statusaddress = adcbaseaddress + 4

        ;; Prepare output
        JSR $F3E2               ; HGR
        LDX #$05                ; Color 
        JSR $F6F0               ; HCOLOR
        JSR GRIDL
        LDA #$8D ; next line
        JSR $FDED
        LDA #$8D ; next line
        JSR $FDED
        LDA #$8D ; next line
        JSR $FDED

        ;; 
        LDA #$00
        STA totcount0
        STA totcount1
        STA totcount2

        ;; JSR $FDDA               ; Print Accumulator
        ;; LDA #$8D ; next line
        ;; JSR $FDED

        ;; Clear some memory
        LDX #$0
LPL:    LDA #$0
        STA memorylowbyte, X
        INX
        BNE LPL

        LDX #$0
LPH:    LDA #$0
        STA memoryhighbyte, X
        INX
        BNE LPH

;;; Begin of main readout loop
RSADC:  LDA resetaddress        ; ADC reset by read specific address
        ;; Wait for LSB=1 in status (PD&H circuit triggered)
LS:     LDA #$01
        AND statusaddress
        BEQ LS
        ;; Wait for Bit1=0 in status (conversion done)
LI:     LDA #$02
        AND statusaddress
        BNE LI

        LDA adchighaddress
        ASL                     ; Move out highest bit
        TAX
        LDA #$80
        AND adclowaddress       ; take highest bit from low (only 4 anyway)
        BEQ NOIN
        INX

NOIN:   INC memorylowbyte, X
        BNE NOHIGH
        ;; Add something to highbit

        INC memoryhighbyte, X
        ;; Check for break
        ;; LDA #$3
        ;; CMP memoryhighbyte, X
        ;; BEQ ENDREC
NOHIGH: 

        INC totcount0
        BNE CTDONE
        ;; Incrementing totcount1, same time check if need to plot
        INC totcount1
        BNE CHPLOT
        INC totcount2
CHPLOT: LDA #plotevery
        AND totcount1         ; Plot whenever totcount1 AND plotevery returns zero
        BNE NOPLOT
        JSR PLBFS
        JSR DRAWS
NOPLOT:
        ;; check if count limit reached
        LDA #templatelimit
        CMP totcount2
        BEQ ENDREC
CTDONE:
        JMP RSADC

ENDREC:
        ;; one more plot
        JSR PLBFS
        JSR DRAWS
;;; end of main readout loop

        ;; clear output
        LDA #$8D ; next line
        JSR $FDED
        LDA #$8D ; next line
        JSR $FDED
        LDA #$8D ; next line
        JSR $FDED

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE TEMPLATE
;;; carries out measurement, stores big bin data in TEMP
;;; --------------------------------------------------------------------------------
TEMPLATE:

        JSR MEASURE

        ;; Set p1 to Template storage
        LDA #<TEMP
        STA p1
        LDA #>TEMP
        STA p1 + 1

        JSR ANALY
        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE INSPECT
;;; carries out measurement, stores big bin data in INSP
;;; --------------------------------------------------------------------------------
INSPECT:
        JSR MEASURE

        ;; Set p1 to Inspection result storage
        LDA #<INSP
        STA p1
        LDA #>INSP
        STA p1 + 1

        JSR ANALY

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE TGHVON
;;; (toggle HV on)
;;; --------------------------------------------------------------------------------
TGHVON:
RMPON:  LDA #$00
        STA hvbaseaddress
        LDA #$01
        STA hvstatus

        LDA hvbaseaddress + 1   ; Enable HV

        ;; Ramp HV
        LDX #0
        STX $24
        LDX #0
        LDA THVON,X ; load initial char
@LP:    ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA THVON,X
        BNE @LP

        INC hvlevel
        LDA hvlevel
        STA hvbaseaddress
        ;; Output Level
        JSR $FDDA

        LDY #$20
@LY:    LDX #$FF
@LX:    DEX
        BNE @LX
        DEY
        BNE @LY

        LDA hvlevel
        CMP #hvset
        BNE RMPON

        LDY #$FF
@LYE:   LDX #$FF
@LXE:   DEX
        BNE @LXE
        DEY
        BNE @LYE

        LDX #0
        STX $24
        LDX #$20
@LP7:   LDA #$A0
        JSR $FDF0 ; cout
        DEX
        BNE @LP7

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE TGHVOFF
;;; (toggle HV off)
;;; --------------------------------------------------------------------------------
TGHVOFF:
RMPOFF: LDX #0
        STX $24
        LDX #0
        LDA THVOFF,X ; load initial char
@LP:    ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA THVOFF,X
        BNE @LP

        DEC hvlevel
        LDA hvlevel
        STA hvbaseaddress
        ;; Output Level
        JSR $FDDA

        LDY #$20
@LY:    LDX #$FF
@LX:    DEX
        BNE @LX
        DEY
        BNE @LY

        LDA hvlevel
        BNE RMPOFF

        LDA #$00
        STA hvstatus

        LDA hvbaseaddress + 2   ; Disable HV

        LDY #$FF
@LYE:   LDX #$FF
@LXE:   DEX
        BNE @LXE
        DEY
        BNE @LYE

        LDX #0
        STX $24
        LDX #$20
@LP7:   LDA #$A0
        JSR $FDF0 ; cout
        DEX
        BNE @LP7

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE PLBFS
;;; prepares plot buffer from last recorded spectrum
;;; (divides count rates by 2^3)
;;; --------------------------------------------------------------------------------
PLBFS:
        LDX #$0
LPS:    LDA memorylowbyte, X
        LSR
        LSR
        LSR
        ;; LSR                     ; remove comment for 2^4 division
        STA plotbuffer, X
        LDA memoryhighbyte, X
        ASL
        ASL
        ASL
        ASL
        ASL   ; comment out this line for 2^4 division
        ; additional "delete high bit", not used anymore
        ;; ASL
        ;; LSR
        ADC plotbuffer, X
        STA plotbuffer, X
        LDA #plotoffset
        SEC
        SBC plotbuffer, X
        STA plotbuffer, X
        INX
        BNE LPS
        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE DRAWS
;;; plot spectrum from plot buffer
;;; --------------------------------------------------------------------------------
DRAWS:
        LDX #0
        STX $24
        LDX #0
        LDA COUNTS,X ; load initial char
@LP3:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA COUNTS,X
        BNE @LP3
        LDA totcount2
        JSR $FDDA
        LDA totcount1
        LDX totcount0
        JSR $F941
        ;; ;; DEBUG
        ;; RTS
        ;; ;; DEBUG

        LDX #$0
DRAWLP: LDA plotbuffer, X
        BEQ ZEROLP
        TXA
        PHA

        ;; Point
        LDY #$0                 ; Horizontal Hi
        ;; X is Horizontal Low (and st)
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        PLA                     ; Load and
        PHA                     ; Store again
        TAX
        LDY plotbuffer, X       ; Vertical
        ;; A is H Low (from store)
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        PLA
        TAX
ZEROLP: INX
        BNE DRAWLP

        RTS

BINS:

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE GRIDL
;;; draws grid lines
;;; --------------------------------------------------------------------------------
GRIDL:  LDY #$0                 ; H Hi
        LDX #$40                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$40                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$41                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$41                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$80                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$80                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$81                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$81                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$C0                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$C0                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$C1                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$C1                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$00                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$00                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$0                 ; H Hi
        LDX #$01                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$01                ; H Lo
        LDX #$0                 ; H Hi
        JSR $F53A               ; HLINE

        LDY #$01                ; H Hi
        LDX #$00                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$00                ; H Lo
        LDX #$01                ; H Hi
        JSR $F53A               ; HLINE

        LDY #$01                ; H Hi
        LDX #$01                ; X is H Low
        LDA #plotoffset         ; V
        JSR $F457               ; HPLOT

        LDY #$0                 ; V
        LDA #$01                ; H Lo
        LDX #$01                ; H Hi
        JSR $F53A               ; HLINE

        ;; vertical lines
        LDY #$00                ; H Hi
        LDX #$00                ; X is H Low
        LDA #$35                ; V
        JSR $F457               ; HPLOT

        LDY #$35                ; V
        LDA #$01                ; H Lo
        LDX #$01                ; H Hi
        JSR $F53A               ; HLINE

        LDY #$00                ; H Hi
        LDX #$00                ; X is H Low
        LDA #$6A                ; V
        JSR $F457               ; HPLOT

        LDY #$6A                ; V
        LDA #$01                ; H Lo
        LDX #$01                ; H Hi
        JSR $F53A               ; HLINE

        LDY #$00                ; H Hi
        LDX #$00                ; X is H Low
        LDA #$00                ; V
        JSR $F457               ; HPLOT

        LDY #$00                ; V
        LDA #$01                ; H Lo
        LDX #$01                ; H Hi
        JSR $F53A               ; HLINE

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE ANALY
;;; needs p1 to be set!
;;; 
;;; summarizes last recorded spectrum in memory at the address in p1
;;; --------------------------------------------------------------------------------
ANALY:  LDA #$00                ; reset values
        LDY #$00
@RLP:   STA (p1), Y
        INY
        CPY #$24
        BNE @RLP

        LDX #$00                ; X counts channels
        LDA #$00
        STA bincount            ; counts big bins

@LP:    LDY #$00
        LDA (p1), Y
        CLC
        ADC memorylowbyte, X
        STA (p1), Y
        INY
        LDA (p1), Y
        ADC memoryhighbyte, X
        STA (p1), Y
        INY
        LDA (p1), Y
        ADC #$00                ; only add carry if necessary
        STA (p1), Y

        LDY bincount
        INX
        TXA
        CMP BINBOR, Y
        BNE @LP
        ;; move pointer to next 24bit value
        LDA #$03
        CLC
        ADC p1
        STA p1
        LDA #$00
        ADC p1 + 1
        STA p1 + 1
        LDY bincount
        INY
        STY bincount
        CPY #$0C
        BNE @LP
        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE SHOWR
;;; shows both big bins
;;; --------------------------------------------------------------------------------
SHOWR:  JSR $FB2F               ; TEXT Mode
        JSR $FC58               ; HOME (clear screen)

        ;; Reset chi square result memory
        LDA #$00
        LDX #$07
@LP:    STA CHIS, X
        DEX
        BPL @LP

        ;; Set p1 to Template storage
        LDA #<TEMP
        STA p1
        LDA #>TEMP
        STA p1 + 1

        ;; Set p2 to inspection storage
        LDA #<INSP
        STA p2
        LDA #>INSP
        STA p2 + 1

        ;; substraction 24bit
        ;; Set p3 to inspection storage
        LDA #<SUBR
        STA p3
        LDA #>SUBR
        STA p3 + 1

        LDX #$00
        TXA
        PHA
BLP:    JSR OBINA

        ;; only add when template count in this channel not zero
        LDY #$02
        LDA (p1), Y
        BNE ADD
        DEY
        LDA (p1), Y
        BNE ADD
        DEY
        LDA (p1), Y
        BEQ NOADD

ADD:    
        LDX #$00
        CLC
@SLP:   LDA CHIS, X
        ADC OSQR, X
        STA CHIS, X
        INX
        TXA
        EOR #$08
        BNE @SLP

NOADD:  
        ;; move pointers to next 24bit value
        LDA #$03
        CLC
        ADC p1
        STA p1
        LDA #$00
        ADC p1 + 1
        STA p1 + 1
        LDA #$03
        CLC
        ADC p2
        STA p2
        LDA #$00
        ADC p2 + 1
        STA p2 + 1
        LDA #$03
        CLC
        ADC p3
        STA p3
        LDA #$00
        ADC p3 + 1
        STA p3 + 1

        PLA
        TAX
        INX
        TXA
        PHA
        CPX #$0C
        BNE BLP
        PLA

        ;; check higher bytes. should be zero - otherwise fail
        LDX #$07
@LP:    LDA CHIS, X
        BNE FAILL
        DEX
        CPX #$02
        BNE @LP

        ;; byte 02 needs to be compared to passthreshold - lowest significant integer value
        LDA CHIS, X
        CMP #passthreshold
        BCS FAILL

        ;; set p1 to pass string address
        LDA #<PBIG
        STA p1
        LDA #>PBIG
        STA p1 + 1

        JMP SEND

FAILL:   
        ;; set p1 to fail string address
        LDA #<FBIG
        STA p1
        LDA #>FBIG
        STA p1 + 1

        ;; Output string
SEND:   
        LDX #$17
        STX bincount
        LDX #7
        STX $25
        LDA #$8D ; next line (somehow $25 is only active after another output?)
        JSR $FDED
        LDX #8
        STX $24
        LDY #0
        LDA (p1),Y ; load initial char
BL:     ORA #$80
        JSR $FDF0 ; cout
        INY
        CPY bincount
        BNE NL
        LDA #$16
        ADC bincount
        STA bincount
        LDA #$8D ; next line
        JSR $FDED
        LDA #8
        STA $24
NL:     LDA (p1),Y
        BNE BL
        LDA #$8D ; next line
        JSR $FDED

        ;; Output chi text header
        LDX #4
        STX $24
        LDX #0
        LDA CHI,X ; load initial char
@LP4:   ORA #$80
        JSR $FDF0 ; cout
        INX
        LDA CHI,X
        BNE @LP4

        ;; output chi result
        LDX #$07
CSHLP:  LDA CHIS, X
        BEQ CNSH
        JSR $FDDA
CNSH:   DEX
        CPX #$01
        BNE CSHLP
        LDA #$AE ; period
        JSR $FDED
        LDA CHIS, X
        JSR $FDDA
        DEX
        LDA CHIS, X
        JSR $FDDA

        LDA #19
        STA $25
        LDA #$8D ; next line (somehow $25 is only active after another output?)
        JSR $FDED

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE OBINA
;;; "OneBINAnalysis"
;;; calculates (t_x - i_x)^2 / t_x for bin x with t_x being template value and
;;; i_x inspection value.
;;; --------------------------------------------------------------------------------
OBINA:
        ;; Substraction
        LDY #$00
        SEC
        LDA (p1), Y
        SBC (p2), Y
        STA (p3), Y
        INY
        LDA (p1), Y
        SBC (p2), Y
        STA (p3), Y
        INY
        LDA (p1), Y
        SBC (p2), Y
        STA (p3), Y

        ;; absolute of value if negative
        LDY #$02
        LDA (p3), Y
        BPL ISPOS
        LDA #$FF
        EOR (p3), Y
        STA (p3), Y
        DEY
        LDA #$FF
        EOR (p3), Y
        STA (p3), Y
        DEY
        LDA #$FF
        EOR (p3), Y
        SEC
        SBC #$FF
        STA (p3), Y
ISPOS:   

        LDA #$00                ; use bincount again
        STA bincount

        ;; Square the difference
        LDY #$00
        LDA (p3), Y
        STA MULR, Y
        INY
        LDA (p3), Y
        STA MULR, Y
        INY
        LDA (p3), Y
        STA MULR, Y

        LDA #$00
        STA OSQR+3              ; clear upper half of product
        STA OSQR+4
        STA OSQR+5
        LDX #$18                ; set binary count to 24
SHIR:   LSR MULR + 2
        ROR MULR + 1
        ROR MULR
        BCC ROTR
        LDA OSQR + 3
        CLC
        LDY #$00
        ADC (p3), Y
        STA OSQR + 3
        LDA OSQR + 4
        INY
        ADC (p3), Y
        STA OSQR + 4
        LDA OSQR + 5
        INY
        ADC (p3), Y
ROTR:   ROR
        STA OSQR + 5
        ROR OSQR + 4
        ROR OSQR + 3
        ROR OSQR + 2
        ROR OSQR + 1
        ROR OSQR
        DEX
        BNE SHIR

        ;; Multiply OSQR by $10000 for integer division
        LDX #$07
        LDY #$05
BMUL:   LDA OSQR, Y
        STA OSQR, X
        DEX
        DEY
        BPL BMUL
        LDA #$00
        STA OSQR, X
        DEX
        STA OSQR, X

        ;; Division
        lda #0          ; preset REMAIND to 0
        LDY #$08
@LP1:   STA REMAIND, Y
        DEY
        BPL @LP1
        ldx #(8 * 8)    ; repeat for each bit
        stx bincount    ; use additional register (ZP) for bitcount

DIL:    ASL OSQR        ; dividend lb & hb*2, msb -> Carry
        LDX #$01
@LP:    ROL OSQR, X
        INX
        TXA
        EOR #$08        ; loop includes 1-6
        BNE @LP
        LDX #$00
@LP2:   ROL REMAIND, X
        INX
        TXA
        EOR #$08
        BNE @LP2

        LDY #$00        ; Only divide at maximum by three significant
        LDA REMAIND, Y  ; bytes, loop with 00 for others
        SEC                     
        SBC (p1), Y     
        STA DIVTMP, Y   ; we might need result later
        INY             ; Y = 1
        LDA REMAIND, Y
        SBC (p1), Y
        STA DIVTMP, Y
        INY             ; Y = 2
        LDA REMAIND, Y
        SBC (p1), Y
        BCC skip
        STA DIVTMP, Y
        INY             ;
@LP3:   LDA REMAIND, Y
        SBC #$00
        STA DIVTMP, Y
        INY
        TYA
        EOR #$08 - 1
        BNE @LP3
        LDA REMAIND, Y
        SBC #$00
        BCC skip

DSL:    STA REMAIND, Y  ; else save substraction result as new REMAIND,
        DEY             ; Y goes down again
        lda DIVTMP, Y
        sta REMAIND, Y
        CPY #$00
        BNE DSL
        inc OSQR        ; and INCrement result cause divisor fit in 1 times

skip:   dec bincount
        bne DIL

        RTS

;;; --------------------------------------------------------------------------------
;;; SUBROUTINE WELC
;;; Displays welcome screen
;;; --------------------------------------------------------------------------------

WELC:   LDA #<IBX
        STA p1
        LDA #>IBX
        STA p1 + 1

        LDX #$17
        STX bincount
        LDX #7
        STX $25
        LDA #$8D        ; next line (somehow $25 is only active after another output?)
        JSR $FDED
        LDX #8
        STX $24
        LDY #0
        LDA (p1),Y      ; load initial char
WBL:    ORA #$80
        JSR $FDF0       ; cout
        INY
        CPY bincount
        BNE WNL
        LDA #$16
        ADC bincount
        STA bincount
        LDA #$8D        ; next line
        JSR $FDED
        LDA #8
        STA $24
WNL:    LDA (p1),Y
        BNE WBL
        LDA #$8D        ; next line
        JSR $FDED
        LDA #$8D        ; next line
        JSR $FDED

        LDX #15
        STX $24
        LDX #0
        LDA WEL,X       ; load initial char
@LP:    ORA #$80
        JSR $FDF0       ; cout
        INX
        LDA WEL,X
        BNE @LP
        LDA #$8D        ; next line
        JSR $FDED
        LDA #$8D        ; next line
        JSR $FDED

        LDX #3
        STX $24
        LDX #0
        LDA MSG,X       ; load initial char
@LP2:   ORA #$80
        JSR $FDF0       ; cout
        INX
        LDA MSG,X
        BNE @LP2
        LDA #$8D        ; next line
        JSR $FDED
        LDA #$8D        ; next line
        JSR $FDED

        RTS
