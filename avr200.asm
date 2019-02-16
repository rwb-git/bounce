;.include "I2C_inc.asm"


;**** A P P L I C A T I O N   N O T E   A V R 2 0 0 ************************
;*
;* Title:		Multiply and Divide Routines
;* Version:		1.1
;* Last updated:	97.07.04
;* Target:		AT90Sxxxx (All AVR Devices)
;*
;* Support E-mail:	avr@atmel.com
;*  
;* DESCRIPTION
;* This Application Note lists subroutines for the following
;* Muliply/Divide applications:
;*
;* 8x8 bit unsigned
;* 8x8 bit signed
;* 16x16 bit unsigned
;* 16x16 bit signed
;* 8/8 bit unsigned
;* 8/8 bit signed
;* 16/16 bit unsigned
;* 16/16 bit signed
;*
;* All routines are Code Size optimized implementations
;* 
;*************************************************************************** 

;.include "8535def.inc"
;
;	rjmp	RESET	;reset handle
;

;***************************************************************************
;*
;* "mpy8u" - 8x8 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two register variables mp8u and mc8u.
;* The result is placed in registers m8uH, m8uL
;*  
;* Number of words	:9 + return
;* Number of cycles	:58 + return
;* Low registers used	:None
;* High registers used  :4 (mp8u,mc8u/m8uL,m8uH,mcnt8u)	
;*
;* Note: Result Low byte and the multiplier share the same register.
;* This causes the multiplier to be overwritten by the result.
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	mc8u	=r16		;multiplicand
;.set 	mc8u = r_16
.def	mp8u	=r17		;multiplier
.def	m8uL	=r17		;result Low byte
.def	m8uH	=r18		;result High byte
.def	mcnt8u	=r19		;loop counter

;***** Code


mpy8u:	clr	m8uH		;clear result High byte
	ldi	mcnt8u,8	;init loop counter
	lsr	mp8u		;rotate multiplier
	
m8u_1:	brcc	m8u_2		;carry set 
	add 	m8uH,mc8u	;   add multiplicand to result High byte
m8u_2:	ror	m8uH		;rotate right result High byte
	ror	m8uL		;rotate right result L byte and multiplier
	dec	mcnt8u		;decrement loop counter
	brne	m8u_1		;if not done, loop more
	ret


;.undef	mc8u
;.set 	mc8u = r_16
;.undef	mp8u
;.undef	m8uL
;.undef	m8uH	
;.undef	mcnt8u

;***************************************************************************
;*
;* "mpy16u" - 16x16 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two 16-bit register variables 
;* mp16uH:mp16uL and mc16uH:mc16uL.
;* The result is placed in m16u3:m16u2:m16u1:m16u0.
;*  
;* Number of words	:14 + return
;* Number of cycles	:153 + return
;* Low registers used	:None
;* High registers used  :7 (mp16uL,mp16uH,mc16uL/m16u0,mc16uH/m16u1,m16u2,
;*                          m16u3,mcnt16u)	
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	mc16uL	=r16		;multiplicand low byte
.def	mc16uH	=r17		;multiplicand high byte
.def	mp16uL	=r18		;multiplier low byte
.def	mp16uH	=r19		;multiplier high byte
.def	m16u0	=r18		;result byte 0 (LSB)
.def	m16u1	=r19		;result byte 1
.def	m16u2	=r20		;result byte 2
.def	m16u3	=r21		;result byte 3 (MSB)
.def	mcnt16u	=r22		;loop counter

;***** Code

mpy16u:	clr	m16u3		;clear 2 highest bytes of result
	clr	m16u2
	ldi	mcnt16u,16	;init loop counter
	lsr	mp16uH
	ror	mp16uL

m16u_1:	brcc	noad8		;if bit 0 of multiplier set
	add	m16u2,mc16uL	;add multiplicand Low to byte 2 of res
	adc	m16u3,mc16uH	;add multiplicand high to byte 3 of res
noad8:	ror	m16u3		;shift right result byte 3
	ror	m16u2		;rotate right result byte 2
	ror	m16u1		;rotate result byte 1 and multiplier High
	ror	m16u0		;rotate result byte 0 and multiplier Low
	dec	mcnt16u		;decrement loop counter
	brne	m16u_1		;if not done, loop more
	ret

;***************************************************************************
;*
;* "div8u" - 8/8 Bit Unsigned Division
;*
;* This subroutine divides the two register variables "dd8u" (dividend) and 
;* "dv8u" (divisor = denominator). The result is placed in "dres8u" and the remainder in
;* "drem8u".
;*  
;* Number of words	:14
;* Number of cycles	:97
;* Low registers used	:1 (drem8u)
;* High registers used  :3 (dres8u/dd8u,dv8u,dcnt8u)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem8u	=r15		;remainder
.def	dres8u	=r16		;result
.def	dd8u	=r16		;dividend
.def	dv8u	=r17		;divisor
.def	dcnt8u	=r18		;loop counter

;***** Code

div8u:	sub	drem8u,drem8u	;clear remainder and carry
	ldi	dcnt8u,9	;init loop counter
d8u_1:	rol	dd8u		;shift left dividend
	dec	dcnt8u		;decrement counter
	brne	d8u_2		;if done
	ret			;    return
d8u_2:	rol	drem8u		;shift dividend into remainder
	sub	drem8u,dv8u	;remainder = remainder - divisor
	brcc	d8u_3		;if result negative
	add	drem8u,dv8u	;    restore remainder
	clc			;    clear carry to be shifted into result
	rjmp	d8u_1		;else
d8u_3:	sec			;    set carry to be shifted into result
	rjmp	d8u_1


	
;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor = denominator). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:19
;* Number of cycles	:235/251 (Min/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*			    dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem16uL=r14
.def	drem16uH=r15
.def	dres16uL=r16
.def	dres16uH=r17
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19
.def	dcnt16u	=r20

;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1
	
	

;****************************************************************************
;*
;* Test Program
;*
;* This program calls all the subroutines as an example of usage and to 
;* verify correct verification.
;*
;****************************************************************************

;***** Main Program Register variables

;.def	temp	=r16		;temporary storage variable

;***** Code
;RESET:
;---------------------------------------------------------------
;Include these lines for devices with SRAM
;	ldi	temp,low(RAMEND)
;	out	SPL,temp	
;	ldi	temp,high(RAMEND)
;	out	SPH,temp	;init Stack Pointer
;---------------------------------------------------------------

;***** Multiply Two Unsigned 8-Bit Numbers (250 * 4)

;	ldi	mc8u,250
;	ldi	mp8u,4
;	rcall	mpy8u		;result: m8uH:m8uL = $03e8 (1000)

;***** Multiply Two Signed 8-Bit Numbers (-99 * 88)
;	ldi	mc8s,-99
;	ldi	mp8s,88
;	rcall	mpy8s		;result: m8sH:m8sL = $ddf8 (-8712)

;***** Multiply Two Unsigned 16-Bit Numbers (5050 * 10,000)
;	ldi	mc16uL,low(5050)
;	ldi	mc16uH,high(5050)
;	ldi	mp16uL,low(10000)
;	ldi	mp16uH,high(10000)
;	rcall	mpy16u		;result: m16u3:m16u2:m16u1:m16u0
				;=030291a0 (50,500,000)
	
;***** Multiply Two Signed 16-Bit Numbers (-12345*(-4321))
;	ldi	mc16sL,low(-12345)
;	ldi	mc16sH,high(-12345)
;	ldi	mp16sL,low(-4321)
;	ldi	mp16sH,high(-4321)
;	rcall	mpy16s		;result: m16s3:m16s2:m16s1:m16s0
				;=$032df219 (53,342,745)

;***** Divide Two Unsigned 8-Bit Numbers (100/3)
;	ldi	dd8u,100
;	ldi	dv8u,3
;	rcall	div8u		;result: 	$21 (33)
				;remainder:	$01 (1)

;***** Divide Two Signed 8-Bit Numbers (-110/-11)
;	ldi	dd8s,-110
;	ldi	dv8s,-11
;	rcall	div8s		;result:	$0a (10)
				;remainder	$00 (0)


;***** Divide Two Unsigned 16-Bit Numbers (50,000/60,000)
;	ldi	dd16uL,low(50000)
;	ldi	dd16uH,high(50000)
;	ldi	dv16uL,low(60000)
;	ldi	dv16uH,high(60000)
;	rcall	div16u		;result:	$0000 (0)
;				;remainder:	$c350 (50,000)


;***** Divide Two Signed 16-Bit Numbers (-22,222/10)
;	ldi	dd16sL,low(-22222)
;	ldi	dd16sH,high(-22222)
;	ldi	dv16sL,low(10)
;	ldi	dv16sH,high(10)
;	rcall	div16s		;result:	$f752 (-2222)
				;remainder:	$0002 (2)

;forever:rjmp	forever



;-----------------------------------------------------------------------------:
; 32bit/32bit Unsigned Division
;
; Register Variables
;  Call:  var1[3:0] = dividend (0x00000000..0xffffffff)
;         var2[3:0] = divisor (0x00000001..0x7fffffff)
;         mod[3:0]  = <don't care>
;         lc        = <don't care> (high register must be allocated)
;
;  Result:var1[3:0] = var1[3:0] / var2[3:0]
;         var2[3:0] = <not changed>
;         mod[3:0]  = var1[3:0] % var2[3:0]
;         lc        = 0
;
; Size  = 26 words
; Clock = 549..677 cycles (+ret)
; Stack = 0 bytes
;
;on exit, this is var1 modulo var2. does that mean remainder? lol
.def mod0 = r19
.def mod1 = r20
.def mod2 = r21
.def mod3 = r22

;on entry, this is dividend, numerator; on exit this is quotient
.def var10 = r23
.def var11 = r24
.def var12 = r25
.def var13 = r26

;on entry, this is divisor, denominator; not changed
.def var20 = r27
.def var21 = r28
.def var22 = r29
.def var23 = r30

.def lc = r31

div32u:	clr	mod0		;initialize variables
		clr	mod1		;  mod = 0;
		clr	mod2		;  lc = 32;
		clr	mod3		;
		ldi	lc,32		;/
					;---- calculating loop
		lsl	var10		;var1 = var1 << 1;
		rol	var11		;
		rol	var12		;
		rol	var13		;/
		rol	mod0		;mod = mod << 1 + carry;
		rol	mod1		;
		rol	mod2		;
		rol	mod3		;/
		cp	mod0,var20	;if (mod => var2) {
		cpc	mod1,var21	; mod -= var2; var1++;
		cpc	mod2,var22	; }
		cpc	mod3,var23	;
		brcs	PC+6		;
		inc	var10		;
		sub	mod0,var20	;
		sbc	mod1,var21	;
		sbc	mod2,var22	;
		sbc	mod3,var23	;/
		dec	lc		;if (--lc > 0)
		brne	PC-19		; continue loop;
		ret

                                    
