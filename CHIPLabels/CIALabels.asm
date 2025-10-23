; Monitoring/control of the 8 data lines of Port A. The lines are used for multiple purposes:
; Read/Write: Bit 0..7 keyboard matrix columns
; Read: Joystick Port 2: Bit 0..3 Direction (Left/Right/Up/Down), Bit 4 Fire button. 0 = activated.
; Read: Lightpen: Bit 4 (as fire button), connected also with "/LP" (Pin 9) of the VIC
; Read: Paddles: Bit 2..3 Fire buttons, Bit 6..7 Switch control port 1 (%01=Paddles A) or 2 (%10=Paddles B)
CIA_1_DATA_PORT_A           =$DC00

; Monitoring/control of the 8 data lines of Port B. The lines are used for multiple purposes:
; Read/Write: Bit 0..7 keyboard matrix rows
; Read: Joystick Port 1: Bit 0..3 Direction (Left/Right/Up/Down), Bit 4 Fire button. 0 = activated.
; Read: Bit 6: Timer A: Toggle/Impulse output (see register 14 bit 2)
; Read: Bit 7: Timer B: Toggle/Impulse output (see register 15 bit 2)
CIA_1_DATA_PORT_B           =$DC01

; Joystick Macros
JOYSTICK_UP_MASK      =$1
JOYSTICK_DOWN_MASK    =$2

JOYSTICK_LEFT_MASK    =$4
JOYSTICK_RIGHT_MASK   =$8
JOYSTICK_FIRE_MASK    =$10


; BitX Input-Read Only (0), Output Read/Write (1)
CIA_1_DATA_DIRECTION_PORT_A =$Dc02

; BitX Input-Read Only (0), Output Read/Write (1)
CIA_1_DATA_DIRECTION_PORT_B =$Dc03

; Read Actual Value, Write - Set Value
CIA_1_TIMER_A_LOW           =$Dc04

; Read Actual Value, Write - Set Value
CIA_1_TIMER_A_HIGH          =$Dc05

; Read Actual Value, Write - Set Value
CIA_1_TIMER_B_LOW           =$Dc06

; Read Actual Value, Write - Set Value
CIA_1_TIMER_B_HIGH          =$Dc07

; 0-3 = BCD ($0-$9)
CIA_1_CLOCK_10THS           =$DC08

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$9)
CIA_1_CLOCK_SECONDS         =$DC09

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$9)
CIA_1_CLOCK_MINUTES         =$DC0A

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$5)
; 7 AM(0), PM(1)
CIA_1_CLOCK_HOURS           =$DC0B

CIA_1_SERIAL_SHIFT_REGISTER =$DC0C

; Read: (Bit0..4 = INT DATA, Origin of the IRQ)
; Bit 0: 1 = Underflow Timer A
; Bit 1: 1 = Underflow Timer B
; Bit 2: 1 = Time of day and alarm time is equal
; Bit 3: 1 = SDR full or empty, so full byte was transferred, depending of operating mode serial bus
; Bit 4: 1 = IRQ Signal occured at FLAG-pin (cassette port Data input, serial bus SRQ IN)
; Bit 5..6: always 0
; Bit 7: 1 = IRQ An IRQ occured, so at least one bit of INT MASK and INT DATA is set in both registers.
; Flags will be cleared after reading the register!
; Write: (Bit 0..4 = INT MASK, IRQ mask)
; Bit 0: 1 = IRQ release through timer A underflow
; Bit 1: 1 = IRQ release through timer B underflow
; Bit 2: 1 = IRQ release if clock=alarmtime
; Bit 3: 1 = IRQ release if a complete byte has been received/sent.
; Bit 4: 1 = IRQ release if a positive slope occurs at the FLAG-Pin.
; Bit 5..6: unused
; Bit 7: Source bit. 0 = set bits 0..4 are clearing the according mask bit. 1 = set bits 0..4 are setting the according mask bit. If all bits 0..4 are cleared, there will be no change to the mask.
CIA_1_IRQ_CONTROL           =$DC0D

; Stop timer (0); Start timer (1)
; Bit 1: 1 = Indicates a timer underflow at port B in bit 6.
; Bit 2: 0 = Through a timer overflow, bit 6 of port B will get high for one cycle , 1 = Through a timer underflow, bit 6 of port B will be inverted
; Bit 3: 0 = Timer-restart after underflow (latch will be reloaded), 1 = Timer stops after underflow.
; Bit 4: 1 = Load latch into the timer once.
; Bit 5: 0 = Timer counts system cycles, 1 = Timer counts positive slope at CNT-pin
; Bit 6: Direction of the serial shift register, 0 = SP-pin is input (read), 1 = SP-pin is output (write)
; Bit 7: Real Time Clock, 0 = 60 Hz, 1 = 50 Hz
CIA_1_CONTROL_TIMER_A       =$DC0E

; Stop timer (0); Start timer (1)
; Bit 1: 1 = Indicates a timer underflow at port B in bit 7.
; Bit 2: 0 = Through a timer overflow, bit 7 of port B will get high for one cycle , 1 = Through a timer underflow, bit 7 of port B will be inverted
; Bit 3: 0 = Timer-restart after underflow (latch will be reloaded), 1 = Timer stops after underflow.
; Bit 4: 1 = Load latch into the timer once.
; Bit 5..6:
;   %00 = Timer counts System cycle
;   %01 = Timer counts positive slope on CNT-pin
;   %10 = Timer counts underflow of timer A
;   %11 = Timer counts underflow of timer A if the CNT-pin is high
; Bit 7: 0 = Writing into the TOD register sets the clock time, 1 = Writing into the TOD register sets the alarm time.
CIA_1_CONTROL_TIMER_B       =$DC0F


; Bit 0..1: Select the position of the VIC-memory
;   %00, 0: Bank 3: $C000-$FFFF, 49152-65535
;   %01, 1: Bank 2: $8000-$BFFF, 32768-49151
;   %10, 2: Bank 1: $4000-$7FFF, 16384-32767
;   %11, 3: Bank 0: $0000-$3FFF, 0-16383 (standard)
; Bit 2: RS-232: TXD Output, userport: Data PA 2 (pin M)
; Bit 3..5: serial bus Output (0=High/Inactive, 1=Low/Active)
; Bit 3: ATN OUT
; Bit 4: CLOCK OUT
; Bit 5: DATA OUT
; Bit 6..7: serial bus Input (0=Low/Active, 1=High/Inactive)
; Bit 6: CLOCK IN
; Bit 7: DATA IN
CIA_2_DATA_PORT_A           =$DD00


; Bit 0..7: userport Data PB 0-7 (Pins C,D,E,F,H,J,K,L)
; The KERNAL offers several RS232-Routines, which use the pins as followed:
; Bit 0, 3..7: RS-232: reading
;   Bit 0: RXD
;   Bit 3: RI
;   Bit 4: DCD
;   Bit 5: User port pin J
;   Bit 6: CTS
;   Bit 7: DSR
; Bit 1..5: RS-232: writing
;   Bit 1: RTS
;   Bit 2: DTR
;   Bit 3: RI
;   Bit 4: DCD
;   Bit 5: User port pin J
CIA_2_DATA_PORT_B           =$DD01


; BitX Input-Read Only (0), Output Read/Write (1)
CIA_2_DATA_DIRECTION_PORT_A =$DD02

; BitX Input-Read Only (0), Output Read/Write (1)
CIA_2_DATA_DIRECTION_PORT_B =$DD03

; Read Actual Value, Write - Set Value
CIA_2_TIMER_A_LOW           =$DD04

; Read Actual Value, Write - Set Value
CIA_2_TIMER_A_HIGH          =$DD05

; Read Actual Value, Write - Set Value
CIA_2_TIMER_B_LOW           =$DD06

; Read Actual Value, Write - Set Value
CIA_2_TIMER_B_HIGH          =$DD07

; 0-3 = BCD ($0-$9)
CIA_2_CLOCK_10THS           =$DD08

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$9)
CIA_2_CLOCK_SECONDS         =$DD09

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$9)
CIA_2_CLOCK_MINUTES         =$DD0A

; 0-3 = BCD ($0-$9)
; 4-6 = BCD ($0-$5)
; 7 AM(0), PM(1)
CIA_2_CLOCK_HOURS           =$DD0B

CIA_2_SERIAL_SHIFT_REGISTER =$DD0C

; CIA2 is connected to the NMI-Line.
; Bit 4: 1 = NMI Signal occured at FLAG-pin (RS-232 data received)
; Bit 7: 1 = NMI An IRQ occured, so at least one bit of INT MASK and INT DATA is set in both registers
CIA_2_IRQ_CONTROL           =$DD0D

; Stop timer (0); Start timer (1)
; Bit 1: 1 = Indicates a timer underflow at port B in bit 6.
; Bit 2: 0 = Through a timer overflow, bit 6 of port B will get high for one cycle , 1 = Through a timer underflow, bit 6 of port B will be inverted
; Bit 3: 0 = Timer-restart after underflow (latch will be reloaded), 1 = Timer stops after underflow.
; Bit 4: 1 = Load latch into the timer once.
; Bit 5: 0 = Timer counts system cycles, 1 = Timer counts positive slope at CNT-pin
; Bit 6: Direction of the serial shift register, 0 = SP-pin is input (read), 1 = SP-pin is output (write)
; Bit 7: Real Time Clock, 0 = 60 Hz, 1 = 50 Hz
CIA_2_CONTROL_TIMER_A       =$DD0E

; Stop timer (0); Start timer (1)
; Bit 1: 1 = Indicates a timer underflow at port B in bit 7.
; Bit 2: 0 = Through a timer overflow, bit 7 of port B will get high for one cycle , 1 = Through a timer underflow, bit 7 of port B will be inverted
; Bit 3: 0 = Timer-restart after underflow (latch will be reloaded), 1 = Timer stops after underflow.
; Bit 4: 1 = Load latch into the timer once.
; Bit 5..6:
;   %00 = Timer counts System cycle
;   %01 = Timer counts positive slope on CNT-pin
;   %10 = Timer counts underflow of timer A
;   %11 = Timer counts underflow of timer A if the CNT-pin is high

; Bit 7: 0 = Writing into the TOD register sets the clock time, 1 = Writing into the TOD register sets the alarm time.
CIA_2_CONTROL_TIMER_B       =$DD0F

