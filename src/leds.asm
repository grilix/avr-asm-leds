; vim:syntax=avr8bit

.nolist
.include "inc/tn85def.inc"
.list

.def    FLAG_REG = r22
.def    QS_REG   = r23

.equ    FLAG_MS  = 0
.equ    FLAG_HS  = 1

.org 0x0000
rjmp main                    ; Reset - Address 0
reti                         ; INT0 (address 01)
reti                         ; Pin Change Interrupt Request 0
reti                         ; Timer/Counter1 Compare Match A
reti                         ; Timer/Counter1 Overflow
reti                         ; Timer/Counter0 Overflow
reti                         ; EEPROM Ready
reti                         ; Analog Comparator
reti                         ; ADC Conversion Complete
reti                         ; Timer/Counter1 Compare Match B
rjmp TC0CA_handler           ; Timer/Counter0 Compare Match A
reti                         ; Timer/Counter0 Compare Match B
reti                         ; Watchdog Timeout
reti                         ; USI START
reti                         ; USI Overflow

LED_PERIODS:
  ;        PB4
  ;        |PB3    <- led
  ;        ||PB2
  ;        |||PB1  <- led
  ;        ||||PB0 <- led
  ;        |||||
  .Db 0b00000001, \
      0b00000010, \
      0b00010000, \
      0b00000010, \
      0b00000000, \
      0b00000000

; -- TCC based Clock.

TC0CA_handler:
  in    r15, SREG

  sbr   FLAG_REG, (1<<FLAG_MS) ; ~2ms

  dec   QS_REG
  brne  TC0CA_handler_end
  sbr   FLAG_REG, (1<<FLAG_HS) ; ~500ms
  ldi   QS_REG, 250            ; 250*2ms

TC0CA_handler_end:
  out   SREG, r15
  reti

; -- /clock

set_pins:
  ldi   r16, (1<<PB0) | (1<<PB1) | (1<<PB4)
  out   DDRB, r16            ; Set OUTput ports.

  ret

setup_timers:
  ldi   r16, (1<<CS01)       ; clock counter with I/O clock/8
  out   TCCR0B, r16

  ldi   r16, (1<<OCIE0A)     ; Output Compare_0 interrupt enable
  out   TIMSK, r16

  sei                        ; Set enable interrupt

  ret

main:
  ; Load stack register.
  ldi   r16, high(RAMEND)    ; Upper byte
  out   SPH, r16
  ldi   r16, low(RAMEND)     ; Lower byte
  out   SPL, r16

  rcall set_pins

  rcall setup_timers

period_start:
  ldi   ZL, low(2*LED_PERIODS)
  ldi   ZH, high(2*LED_PERIODS)

set_led:
  lpm   r20, z+
  tst   r20
  breq  reset_period

  out   PORTB, r20

wait_timer:
  sbrs  FLAG_REG, FLAG_HS
  rjmp  wait_timer
  cbr   FLAG_REG, (1<<FLAG_HS)
  rjmp  set_led

reset_period:
  rjmp  period_start
