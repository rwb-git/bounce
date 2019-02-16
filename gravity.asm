; >>>>>>>>> try to get bounce to use all 36 leds: 2 at bottom and 1 at top are not used







;   2-4-2019 use nano and a string of rgb leds to simulate physics of an object falling and accelerating due to gravity
;            and bouncing at the bottom
;
;      first, get 36 leds to light up using code from rgb20_nano.asm
;
;      gravity_1.asm lights 36 leds blue
;
;      gravity_2.asm lights the last led blue
;
;      gravity_3.asm one led drops at linear rate
;
;      gravity_4.asm one led drops at linear rate leaving a fading tail, bright blue
;
;      gravity_5.asm one led drops at linear rate leaving a fading tail, light blue, light red, light green. pretty nice
;
;         saved as falling.asm for github
;
;      gravity_6.asm is simple motion top to bottom and back
;
;      gravity_7.asm is bounce development - crude approximation
;
;      gravity_8.asm is bounce development - gravity equation - see gravity.ods
;
;      gravity_9.asm seems to fall and rise correctly; now i need to reduce rebound velocity so that it slowly comes to
;        a halt, and then re-starts at the top
;
;      gravity_10.asm is decent inelastic, except top 1 and bottom 2 leds are not used
;

.include "m328def.inc"


; defs used in adafruit code
.def hi = r16
.def lo = r17
.def next = r18
.def bit = r19
.def byet = r20

.equ fade_tail_length = 20       ; smaller value = longer tail

.cseg

.org $0000
	jmp RESET      ;Reset handle
	


;this looks wrong; spec says 0x0016. so I guess it puts 0xFF or 0x00 from 0x0016 to 0x0022, and somehow worked?

.org $0022
   jmp t1compa


.include "avr200.asm"


;.equ led_struct_size       = 9         ; colors come first, in slots 0..5: rl rh gl gh bl bh
;
;; >>>>>>>>> if led_struct_size changes, fix this >>> calc_soft_start   and   soft   <<<<<<<<<<<<<<<<<
;
;.equ led_color_off         = 6
;.equ led_state_off         = 7
;.equ led_frame_off         = 8
;
;.equ color_state_size     = 11        ; remember that color state structs start AFTER ONE BYTE which is number of states
;
;; hold colors rgb come first, in slots 0 1 2
;
;.equ color_blend_off       = 3         ; drl drh, etc, to align with led color bytes, slots 3..8
;.equ color_frames_off      = 9
;.equ color_hold_off        = 10
;



; 2560 sram is 0x0200 - 0x21ff

.equ my_sram_start = SRAM_START     ; SRAM_SIZE

; begin_awk_here        this is a flag for script audit_sram


.DSEG



.org SRAM_START


color:                                             .BYTE 1

current_led:                                       .BYTE 1
current_led_cnt:                                   .BYTE 2
fade:                                              .BYTE 1
red:                                               .BYTE 1
green:                                             .BYTE 1
blue:                                              .BYTE 1

dir:                                               .BYTE 1
time_cnt:                                          .BYTE 1
accel_cnt:                                         .BYTE 1
velocity:                                          .BYTE 1

; make all these BYTE 4 just to be safe in case I change something and forget to update here

dv:                                                .BYTE 4
dt:                                                .BYTE 4

v:                                                 .BYTE 4
vt:                                                .BYTE 4
v0:                                                .BYTE 4

h:                                                 .BYTE 4
h0:                                                .BYTE 4

time:                                              .BYTE 4

anim_mode:                                         .BYTE 1

rgb_flag:                                          .BYTE 1   
led_cnt:                                           .BYTE 1   
rgb_led_bytes:                                     .BYTE 2   
last_sram:                                         .BYTE 1

;  end_awk_here   = 1     ; this is a flag for script audit_sram


.CSEG
;
;   color_addr and rgb_led_bytes are filled in with addresses when design is sent from app
;
;      the address in color_addr is where the addresses for one or more color_schemes are stored. the
;      color schemes follow that address block
;
;      the address in rgb_led_bytes is where adafruit rgb data is located
;
;   led_block is where first led struct begins






;------------------------

init_ports:		;uses no regs

; 328 only has ports b c d

; atmel says set all unused pins input with pullups to avoid floating pins
;
;  ports are A B C D E F G H J K L = 11 x 8 = 88 
;            1 2 3 4 5 6 7 8 9 0 1

   clr r16                             ; input mode

   sts ddrb,r16
   sts ddrc,r16
   sts ddrd,r16
   
   ldi r16,0xFF                        ; enable pullup

   sts portb,r16
   sts portc,r16
   sts portd,r16
   
;   cbi porta,pa1
;	sbi ddra,pa1	                     ; pa1 is key/enable on hc-05 to enter AT mode; i don't think it's used in this file
;   cbi porta,pa1
	
   sbi 	ddrd,pd2	                     ; pd2 is rgb_led pin = pin D2


   sbi ddrb,pb5                        ; pb7 is the led builtin to my mega (pb5 on uno) . if i don't do this it stays on
   cbi portb,pb5                       ; due to the pullup i enabled, i guess


   sbi ddrb,pb4                        ; scope
   sbi portb,pb4


   ret



;----------------------

t1compa:                               ; timer_1 timer_1_interrupt

   push r28

   in r28,sreg

   push r16

   ldi r16,1
   sts rgb_flag,r16

   pop r16

   out sreg,r28
   pop r28
   
   reti

;----------------------------

cycle_colors:

   lds r22,color
   inc r22
   cpi r22,3
   brlo line175

   ldi r22,0

line175:

   sts color,r22

   ret

;-------------------------

inc_r21:

   add r21,r22

   

   ret

   

;----------------------------

store_color:                           ; green = r22  red = r23   blue = r24


   ; see if this led is off

   cpi r22,0
   brne on_208

   cpi r23,0
   brne on_208

   cpi r24,0
   brne on_208

   rjmp off_208

on_208:

   ; r24 has the value

   mov r22,r24
   lsr r22
   lsr r22
   lsr r22

   mov r23,r24
   lsr r23
   lsr r23
   lsr r23

   rjmp line224

off_208:


line224:



   clr r25

   lds r21,color

   cpi r21,0
   brne line192

   st X+,r22                           ; green
   st X+,r23                           ; red
   st X+,r24                           ; blue

   ret

line192:
   
   cpi r21,1
   brne line1912

   st X+,r24                           ; green
   st X+,r22                           ; red
   st X+,r23                           ; blue

   ret

line1912:
   
   cpi r21,2
   brne line1922

   st X+,r23                           ; green
   st X+,r24                           ; red
   st X+,r22                           ; blue

   ret

line1922:
   
   ret

;--------------------------

setup_gravity:

   ldi r16,35                          ; do this again here for debug reset
   sts current_led,r16


                                       ; dt here = actual irq seconds * 16384
                                       ;
                                       ; irq secs = t1compare * 1024 / 16e6  assuming prescale is 1024
                                       ;
                                       ; irq secs = 42 * 1024 / 16e6 = 0.002688

   ldi r16,44                          ; if dt is changed due to irq compare value change, dv = g * dt must be changed 
   sts dt,r16

   ldi r16,0xB1
   sts dv,r16                          ; dv = delta velocity = gravity * delta t 
                                       ;
                                       ; 0x00B1 = irq secs * 32.174 * 2048
                                       ;
                                       ; irq compare value = 42d
                                       ;
                                       ; irq secs = 42 x 1024 / 16e6 = 0.002688 secs
                                       ;
                                       ; 0.002688 * 32.174 * 2048 = 0x00B1

   ldi r16,0x00
   sts dv+1,r16

   ldi r16,0x55                        ; 35 / 12 * 8192 = 0x5D55 = 35 inches convert to feet then scale x 8192
   sts h0,r16

   ldi r16,0x5D
   sts h0+1,r16

   clr r16

   sts time,r16
   sts time+1,r16

   sts v,r16
   sts v+1,r16

   ldi r16,1
   sts dir,r16

   ret

;----------------------------

calc_led:

;   led = h * 12 / 8192
   
   lds r17,h+1
   lds r16,h

   clr r19
   ldi r18,12
   
   rcall mpy16u                        ; r17:r16 x r19:r18 = r21..r18
   
   ; move r21..r18 to numerator r26..r23

   mov r23,r18
   mov r24,r19
   mov r25,r20
   mov r26,r21

   clr r30
   clr r29
   clr r27

   ldi r28,0x20                        ; 8192 = 0x2000

   rcall div32u                        ; r26..r23 / r30..r27 = r26..r23 rem r22..r19    uses r31   r27..r30 are not changed

   sts current_led,r23

   ret

;-------------------------------------

load_rgb_bounce_with_accel_calc:       ; see spreadsheet gravity.ods

; this is called on every IRQ so we know the time and need to calculate the new position
;
; when falling the initial velocity is zero. when rising the initial velocity is the negative of what
; it was when it hit bottom, or a reduced value for inelastic collision;
;
; when falling we subtract from the height, and when rising we add to it
;
; when falling we add to the velocity, and when rising we subtract from it
;
; so maybe just have two separate blocks of code
;
;   hard-code delta velocity = dv based on gravity and time per irq; see setup_gravity for details
;
;   falling: 
;   
;      v = v + dv
;
;      vt = v * t / 8192            it's ok to divide after multiply, using 32 bits for vt and 35 inch length
;                                   if the led string is much longer either use more bits or scale something down
;                                   before multiplying, and compensate for that in led calc
;
;                                   8192 = 4096 x 2; the 2 is from the next equation
;
;      h = h0 - vt / 2              this division by 2 is done above
;
;   rising: 
;
;      v = v - dv
;
;      vt = (v0 + v) * t / 8192
;
;      h = h0 + vt / 2
;
;   led = h * 12 / 8192
;
;
;  scaling summary:
;
;      dt is scaled up by 16384 which affects t
;
;      dv is scaled up by 2048 which affects v
;
;      vt is therefore scaled up by 16384 * 2048 but it's divided by 4096 (times 2 but that's from the h equation)
;      so vt is scaled by 16384 * 2048 / 4096 = 8192 which affects h
;
;      led calc gets rid of that 8192 and converts h from feet to inches since led spacing is 1 inch

     


   rcall zero_all_the_leds

; t = t + dt

   lds r16,time
   lds r17,dt                          ; dt is one byte

   add r16,r17
   sts time,r16

   lds r16,time+1
   clr r17
   adc r16,r17

   sts time+1,r16



   lds r16,dir
   cpi r16,1

   brne line515

   cbi portb,pb4
   
   rjmp going_down3



line515:
   
   sbi portb,pb4

;      v = v - dv

   lds r16,v
   lds r17,dv

   sub r16,r17
   sts v,r16

   lds r16,v+1
   lds r17,dv+1

   sbc r16,r17
   sts v+1,r16


;      vt = (v0 + v) * t / 8192    8192 = 0x2000 


   lds r16,v
   lds r17,v0

   add r16,r17

   lds r17,v+1
   lds r18,v0+1

   adc r17,r18

   lds r18,time
   lds r19,time+1

   rcall mpy16u                        ; r17:r16 x r19:r18 = r21..r18

   ; move r21..r18 to numerator r26..r23

   mov r23,r18
   mov r24,r19
   mov r25,r20
   mov r26,r21

   clr r30
   clr r29
   clr r27

   ldi r28,0x20                        ; divide by 0x1000 (and 2 from the next equation)

   rcall div32u                        ; r26..r23 / r30..r27 = r26..r23 rem r22..r19    uses r31   r27..r30 are not changed

   sts vt,r23
   sts vt+1,r24                        ; v * t / 16384 is 16 bits for 35 inch drop



;      h = h0 + vt / 2 (i already divided by 2 in the preceding div32u)
;

   lds r16,vt
   lds r17,vt+1

;   clr r19
;   ldi r18,2
;
;   rcall div16u                        ; r17:r16 / r19:r18 = r17:r16  rem r15:r14   uses r20

   lds r19,h0
   add r19,r16

   sts h,r19

   lds r19,h0+1
   adc r19,r17

   sts h+1,r19

   rcall calc_led

   ; when rising, check for low velocity close to dv 

   lds r16,v+1
   cpi r16,2
   brsh sline588

;   lds r16,v
;   cpi r16,240
;   brsh sline588

   ;---------- check to see if inelastic is done

   lds r16,current_led
   cpi r16, 4

   brsh still_bouncing

   rjmp setup_gravity

still_bouncing:



   ldi r16,1
   sts dir,r16

   clr r16

   sts time,r16
   sts time+1,r16

   sts v,r16
   sts v+1,r16

   sts v0,r16
   sts v0+1,r16

   lds r16,h
   sts h0,r16

   lds r16,h+1,
   sts h0+1,r16

sline588:

   rjmp show_led
   ;rjmp show_led_red

going_down3:
    
;      v = v + dv

   lds r16,v
   lds r17,dv

   add r16,r17
   sts v,r16

   lds r16,v+1
   lds r17,dv+1

   adc r16,r17
   sts v+1,r16

;
;      vt = v * t / 16384           it's ok to divide after multiply, using 32 bits for vt and 35 inch length
;                                   if the led string is much longer either use more bits or scale something down
;                                   before multiplying, and compensate for that in led calc

   lds r16,v
   lds r17,v+1

   lds r18,time
   lds r19,time+1

   rcall mpy16u                        ; r17:r16 x r19:r18 = r21..r18

   ; move r21..r18 to numerator r26..r23

   mov r23,r18
   mov r24,r19
   mov r25,r20
   mov r26,r21

   clr r30
   clr r29
   clr r27

   ldi r28,0x20                        ; divide by 0x1000 (and 2 from the next equation) = 4096 x 2 = 8192

   rcall div32u                        ; r26..r23 / r30..r27 = r26..r23 rem r22..r19    uses r31   r27..r30 are not changed

   sts vt,r23
   sts vt+1,r24                        ; v * t / 16384 is 16 bits for 35 inch drop

;      h = h0 - vt / 2 ( i already divided by 2 in the preceding div32u

   lds r16,vt
   lds r17,vt+1
;
;   clr r19
;   ldi r18,2
;
;   rcall div16u                        ; r17:r16 / r19:r18 = r17:r16  rem r15:r14   uses r20

   lds r19,h0
   sub r19,r16

   sts h,r19

   lds r19,h0+1
   sbc r19,r17

   sts h+1,r19

   rcall calc_led

   cpi r23,3                           ; current led is in r23

   brsh line588

   clr r16
   sts time,r16
   sts time+1,r16

   lds r16,h
   sts h0,r16

   lds r16,h+1
   sts h0+1,r16

   ldi r16,2
   sts dir,r16

   ;-------------- use same velocity. for some reason something gradually changes and the top led reached
   ;-------------- slowly decreases
;
;   lds r16,v
;   sts v0,r16
;
;   lds r16,v+1
;   sts v0+1,r16
;

   ;-------- this section reduces the rebound velocity like a real-world inelastic collision

   lds r16,v
   lds r17,v+1

   ldi r18,92                          ; multiply by 92 then divide by 100 == same as multiply by 0.92
   ldi r19,0

   rcall mpy16u                        ; r17:r16 x r19:r18 = r21..r18

   ; move r21..r18 to numerator r26..r23

   mov r23,r18
   mov r24,r19
   mov r25,r20
   mov r26,r21

   clr r30
   clr r29
   clr r28
   

   ldi r27,100

   rcall div32u                        ; r26..r23 / r30..r27 = r26..r23 rem r22..r19    uses r31   r27..r30 are not changed

   sts v,r23
   sts v+1,r24 

   sts v0,r23
   sts v0+1,r24 


line588:

   rjmp show_led

;---------------------

move_the_led:

   lds r16,dir
   cpi r16,1
   breq going_down

going_up:

   lds r16,current_led

   inc r16

   sts current_led,r16

   cpi r16,35

   brsh need_to_go_down

   ret

need_to_go_down:

   ldi r16,1

   sts dir,r16

   ret

need_to_go_up:

   ldi r16,2

   sts dir,r16

   ret

going_down:

   lds r16,current_led

   dec r16

   sts current_led,r16

   cpi r16,0

   breq need_to_go_up

   ret

;---------------------------

handle_decel:

   lds r16,velocity

   cpi r16,20
   
   brsh linews698

   inc r16

   sts velocity,r16

   ret

linews698:


   ldi r16,1                           ; go down
   sts dir,r16


ret666:
   ret

;-------------------------

reset_accel_cnt:

   ldi r16,16

   sts accel_cnt,r16

   ret

;-------------------------

handle_accel2:

   lds r16,accel_cnt

   dec r16

   sts accel_cnt,r16

   brne ret666

   rcall reset_accel_cnt

   lds r16,dir
   cpi r16,1
   breq going_down2

   rjmp handle_decel

going_down2:

   rjmp handle_accel

;---------------------------

handle_accel:

   lds r16,velocity

   cpi r16,2
   
   brlo lines698

   dec r16

   sts velocity,r16


lines698:

   ret

;---------------------

reset_time_cnt:

   lds r16,velocity                    ; led does not move for this many timer interrupts
   ;ldi r16,6                           ; led does not move for this many timer interrupts

   sts time_cnt,r16

ret403:

   ret

;------------------------

zero_all_the_leds:

   ;-------------------- zero all the leds. this could be optimized to just zero the ones lit last time

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1

   ldi r16,36
   
   clr r22

loopa330:

   st X+,r22                           ; green
   st X+,r22                           ; red
   st X+,r22                           ; blue


   dec r16
   brne loopa330



   ret

;------------------------

load_rgb_bounce_with_accel:   

   ; dir 1 = falling    2 = rising
   ; top led is number 35, bottom is number 0. i thought falling was 1..36, which should be wrong. 0..35 makes sense
   ;
   ; while falling, increase speed. while rising, decrease speed

   rcall handle_accel2

   rcall zero_all_the_leds

   lds r16,time_cnt                    ; time_cnt controls the speed

   dec r16

   sts time_cnt,r16

   brne ret403

   rcall reset_time_cnt                ; time_cnt controls the speed

   rcall move_the_led

show_led:

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1
  
   ldi r22,3                           ; add led number 3 times since 3 bytes per led

add3a:

   lds r16,current_led

   add r26,r16
   clr r16
   adc r27,r16

   dec r22
   brne add3a

   ldi r22,255
   clr r23

   st X+,r23                           ; green
   st X+,r23                           ; red
   st X+,r22                           ; blue

   ret

;------------------------------

show_led_red:

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1
  
   ldi r22,3                           ; add led number 3 times since 3 bytes per led

add3ar:

   lds r16,current_led

   add r26,r16
   clr r16
   adc r27,r16

   dec r22
   brne add3ar

   ldi r22,255
   clr r23

   st X+,r23                           ; green
   st X+,r22                           ; red
   st X+,r23                           ; blue

   ret

;------------------------------


light_all:

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1

   ldi r16,36
   
   clr r22

   ldi r23,255

lootp330:

   st X+,r22                           ; green
   st X+,r23                           ; red
   st X+,r22                           ; blue


   dec r16
   brne lootp330

ret4403:

   ret



;------------------------

load_rgb_simple_bounce:                ; constant speed top to bottom

   ; dir 1 = falling    2 = rising
   ; top led is number 35, bottom is number 0. i thought falling was 1..36, which should be wrong. 0..35 makes sense



   ;-------------------- zero all the leds. this could be optimized to just zero the ones lit last time

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1

   ldi r16,36
   
   clr r22
loop330:

   st X+,r22                           ; green
   st X+,r22                           ; red
   st X+,r22                           ; blue


   dec r16
   brne loop330

   lds r16,time_cnt

   dec r16

   sts time_cnt,r16

   brne ret4403

   rcall reset_time_cnt

   rcall move_the_led

   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1
  
   ldi r22,3                           ; add led number 3 times since 3 bytes per led

add3:

   lds r16,current_led

   add r26,r16
   clr r16
   adc r27,r16

   dec r22
   brne add3

   ldi r22,255
   clr r23

   st X+,r23                           ; green
   st X+,r23                           ; red
   st X+,r22                           ; blue

   ret


;----------------------------

load_rgb_simple_falling:
 
   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1

   ldi r20,0
   sts fade,r20                        ; fade will draw a tail behind the moving led
   
   ldi r16,36

   ldi r17,255
   clr r18

   lds r19,current_led

loop442:

   cp r16,r19                          ; led closest to nano end of string is #36
                                       ; led at far end is #1
                                       ;
                                       ; why not 0..35? bug? 

   brne line176

   mov r22,r18
   mov r23,r18
   mov r24,r17

   ldi r20,255
   sts fade,r20                        ; fade will draw a tail behind the moving led
 
   rjmp line179

line176:

   mov r22,r18
   mov r23,r18

   lds r20,fade
   cpi r20,fade_tail_length                          ; change this smaller for longer tail ( 2 places)
   brlo line180

   ldi r21,fade_tail_length            ; change this smaller for longer tail ( 2 places)
   sub r20,r21
   sts fade,r20

   mov r24,r20                         ; this is the fading color

   rjmp line179

line180:
   
   mov r24,r18

line179:

   rcall store_color                   ; green = r22  red = r23   blue = r24

   dec r16
   brne loop442

   lds r19,current_led_cnt             ; this sets the falling speed. lower = faster
   inc r19
   cpi r19,8                           ; 9 is nice
   brlo line2088

   clr r19
line2088:

   sts current_led_cnt,r19
   brne line208

   lds r19,current_led

   inc r19
   sts current_led,r19

   cpi r19,67                          ; last led is 36, but allow tail plus a pause. note that this does not
                                       ; make it write past end of data block in sram
   brlo line208

   ldi r19,1
   sts current_led,r19

   rcall cycle_colors

line208:


   ret



;----------------------------

init_timer_1_interrupt_mode_4:

   lds r16,tccr1b

   ori r16,(1<<cs12 | 1<<cs10 | 1<< wgm12)         ; 1024 prescale and ctc on A

   sts tccr1b,r16

   ldi r16,0x00
   sts ocr1ah,r16                      ; write high then low. read low then high

   ldi r16,42                          ; 42 is approx 362 hz == 0.00276 seconds
   
   ;ldi r16,190                         ; calculated in gravity.ods to get timing of 0.012 seconds

   sts ocr1al,r16

   lds r16,timsk1

   ori r16,(1<<ocie1a)                 ; int on compare a

   sts timsk1,r16


   clr r16
   sts tcnt1h,r16                      ; write high then low. read low then high
   sts tcnt1l,r16

   ret



;----------------------------

init_timer_1_interrupt:

   ; 16e6/1024/30 = 520 which means i cannot get 30fps from 8bit. 2560 has 4 16 bit timers
   ;
   ; so ctc at 520 counts 0x0208
   ;
   ; at 1024, 0x0048 is about 4.6 msec = 217 fps and looks good on scope.
   ;
   ; at 1024, 0x0088 is about 8.8 msec = 113 fps and has at least 5 msec idle time
   ;
   ; try 19 fps test since it seems tablet can send 256 bytes at that rate if baud is 57600
   ;
   ;     0x0336 at 1024 prescale: 16e6 / 1024 / 0x0336 = 19 fps = bad flicker
   ;
   ; try 50 fps = 16e6/1024/50 = 0x0138

   lds r16,tccr1b

   ori r16,(1<<cs12 | 1<<cs10 | 1<< wgm12)         ; 1024 prescale and ctc on A

   sts tccr1b,r16

   ldi r16,0x00
   sts ocr1ah,r16                      ; write high then low. read low then high

   ldi r16,42                          ; 35d looks like 430 fps on scope, and could go a lot faster
                                       ; 95d looks like 162 fps == 16e6/1024/95 = 164
                                       ; 25d is 602 fps per scope with 36 leds still some time left over
                                       ; 155d is 99.8 fps per scope and looks good
                                       ; 55d is 278 fps on scope, 33% duty with 36 leds, so 72+ should be easy?
                                       ; 22d scope says 680 fps 63% duty with 36 leds
                                       ; 17d scope 860 fps duty 80%  avr reports 17, 18 for tcnt after processing

   ; when tablet is set to 84 leds and timer tries to go faster, scope shows 366 hz at 79% duty. I suppose
   ; that means that is a good universal speed that will run at the same rate for any number of leds up to
   ; 84, which is the limit due to some byte counters (3 x 84 = 252; 85 works too...)
   ;
   ; so, 16e6 / 367 / 1024 = 42; scope says 362 hz, duty 33.5% with 36 leds
   ;
   ; freq = 16e6 / ( 1024 * timer comp value)
   ;
   ; period = 1024 * timer comp value / 16e6


   sts ocr1al,r16

   lds r16,timsk1

   ori r16,(1<<ocie1a)                 ; int on compare a

   sts timsk1,r16


   clr r16
   sts tcnt1h,r16                      ; write high then low. read low then high
   sts tcnt1l,r16

   ret



;--------------------------------------

adafruit:

   ; this awesome code is from adafruit's neo pixel code on github, I believe

;    // WS2811 and WS2812 have different hi/lo duty cycles; this is
;    // similar but NOT an exact copy of the prior 400-on-8 code.
;
;    // 20 inst. clocks per bit: HHHHHxxxxxxxxLLLLLLL
;    // ST instructions:         ^   ^        ^       (T=0,5,13)

;    volatile uint8_t next, bit;

   in hi,portd

   ori hi,0b00000100                   ; use this to raise line

   in lo,portd

   andi lo,0b11111011                  ; use this to lower line

   mov next,lo                           ; assume 1st bit is low


   lds r30,led_cnt
   ldi r31,3

   mul r31,r30                         ; mul result is in r1:r0

   mov r30,r0                          ; this section is ready for led cnt > 85 (255 / 3), but several other places
   mov r31,r1                          ; use one byte. 
   
   lds r26,rgb_led_bytes
   lds r27,rgb_led_bytes+1

   ld byet,X+

   ldi bit,8

   cli                                 ; led timing is critical and stream will be corrupted by interrupts

head20: 

   out  portd, hi 
   sbrc byet,7 
   mov next,hi 
   dec bit  
   out portd,next 
   mov next,lo 
   breq nextbyte20 
   rol byet 
   rjmp line2337  
line2337:
    nop 
    out portd,lo  
    nop  
    rjmp line2342  
line2342:
    rjmp head20  
nextbyte20:   
     ldi bit,8   
     ld byet, X+ 
     out portd,lo   
     nop   
     sbiw r30,1   
     brne head20   

   sei

   ret

;-----------------------------------

clear_sram:		;2560 sram is 0x0200 .. 0x21FF
			      ;
			      ; don't clear stack: stop at SP

   in r26,SPL
   in r27,SPH                          ; X = stack pointer

   ldi r30,low(SRAM_START)
   ldi r31,high(SRAM_START)
   
   ;ldi	r30,0x00
   ;ldi	r31,0x02                      ; this should use SRAM_START instead
	
	clr	r16
loop1287:
	st	z+,r16

   cp r30, r26
   cpc r31,r27

   brlo loop1287

   ret

;---------------------

init_wdr:  ;init_watchdog:

   cli

   wdr

   lds r16,wdtcsr

   ori r16, (1<<wdce | 1<<wde)

   sts wdtcsr, r16

   ldi r16, (1<<wde | 1<<wdp2 | 1<<wdp0 | 1<<wdp1)

                                       ;  wdp3     wdp2     wdp1     wdp0     timeout
                                       ;  0        1        0        1        0.5 seconds
                                       ;  0        0        0        0        0.016 seconds = default
                                       ;  0        1        1        1        2 sec
   sts wdtcsr, r16

   sei

   ret


;-------------------
;
;;*
;;* "div16u" - 16/16 Bit Unsigned Division
;;*
;;* This subroutine divides the two 16-bit numbers 
;;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor = denominator). 
;;* The result is placed in "dres16uH:dres16uL" and the remainder in
;;* "drem16uH:drem16uL".
;;*  
;;* Number of words	:19
;;* Number of cycles	:235/251 (Min/Max)
;;* Low registers used	:2 (drem16uL,drem16uH)
;;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;;*			    dcnt16u)
;;*
;
;;***** Subroutine Register Variables
;
;.def	drem16uL=r14
;.def	drem16uH=r15
;.def	dres16uL=r16
;.def	dres16uH=r17
;.def	dd16uL	=r16
;.def	dd16uH	=r17
;.def	dv16uL	=r18
;.def	dv16uH	=r19
;.def	dcnt16u	=r20
;
;;***** Code
;
;div16u:	clr	drem16uL	;clear remainder Low byte
;	sub	drem16uH,drem16uH;clear remainder High byte and carry
;	ldi	dcnt16u,17	;init loop counter
;d16u_1:	rol	dd16uL		;shift left dividend
;	rol	dd16uH
;	dec	dcnt16u		;decrement counter
;	brne	d16u_2		;if done
;	ret			;    return
;d16u_2:	rol	drem16uL	;shift dividend into remainder
;	rol	drem16uH
;	sub	drem16uL,dv16uL	;remainder = remainder - divisor
;	sbc	drem16uH,dv16uH	;
;	brcc	d16u_3		;if result negative
;	add	drem16uL,dv16uL	;    restore remainder
;	adc	drem16uH,dv16uH
;	clc			;    clear carry to be shifted into result
;	rjmp	d16u_1		;else
;d16u_3:	sec			;    set carry to be shifted into result
;	rjmp	d16u_1
;	
;	
;

;-------------------------

RESET:
	ldi	r16,high(RAMEND) 
	out	SPH,r16	         
	ldi	r16,low(RAMEND)	 
	out	SPL,r16

   rcall init_wdr

   rcall init_ports

   rcall clear_sram

   ldi r16,high(last_sram)
   sts rgb_led_bytes+1,r16

   ldi r16,low(last_sram)
   sts rgb_led_bytes,r16

   
   
   clr r17
   ldi r16, 0b10000000
   sts clkpr,r16                       ; pdf 640/1280/2560/2561 pg 48 this sets clock prescale to 1; this sets
   sts clkpr,r17                       ; a system prescale which is for power consumption. the ordinary prescales still work


   ldi r16,36                          ; 36 leds
   sts led_cnt,r16

   ldi r16,20
   sts velocity,r16

   ldi r16,4                           ; 1 = simple falling with fade tail
                                       ; 2 = bounce, simple crude constant speed both ways
                                       ; 3 = same as 2 except accelerate going down, decel going up - crude calc
                                       ; 4 = better calc using gravity accel equation
   sts anim_mode,r16

   cpi r16,4
   brne other_modes

   rcall	init_timer_1_interrupt_mode_4

   rjmp line1056

other_modes:

   rcall	init_timer_1_interrupt

line1056:


   sei
   
   ldi r16,1
   sts dir,r16

   ldi r16,35
   sts current_led,r16

   rcall reset_time_cnt
   rcall reset_accel_cnt

   rcall setup_gravity

main_loop:

   wdr

   lds r16,rgb_flag
   cpi r16,1
   brne line1281

   clr r16
   sts rgb_flag,r16


   lds r16,anim_mode
   cpi r16,1
   brne line698

   rcall load_rgb_simple_falling

   rjmp line699

line698:
    
   cpi r16,2
   brne line697

   rcall load_rgb_simple_bounce

   rjmp line699

line697:
   
   cpi r16,3
   brne line6937

   rcall load_rgb_bounce_with_accel

   rjmp line699

line6937:
   
   rcall load_rgb_bounce_with_accel_calc


line699:

   rcall adafruit
   
line1281:


  
   rjmp	main_loop

