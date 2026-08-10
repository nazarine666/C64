!source "SIDRegisters"

SID_VOICE_1_FREQUENCY_LOW		= $d400
SID_VOICE_1_FREQUENCY_HIGH		= $d401
; 7..4	3..0
SID_VOICE_1_PULSE_WAVE_WAVE_CYCLE_LOW	= $d402
SID_VOICE_1_PULSE_WAVE_WAVE_CYCLE_HIGH	= $d403

;7	6	5	4	3	2	1	0
;noise	pulse	sawtooth	triangle	test	ring modulation with voice 3	synchronize with voice 3	gate
SID_VOICE_1_CONTROL			= $d404

;7..4	3..0
SID_VOICE_1_ATTACK_DECAY_DURATION	= $d405
SID_VOICE_1_SUSTAIN_RELEASE_DURATION	= $d406

SID_VOICE_2_FREQUENCY_LOW		= $d407
SID_VOICE_2_FREQUENCY_HIGH		= $d408

; 7..4	3..0
SID_VOICE_2_PULSE_WAVE_WAVE_CYCLE_LOW	= $d409
SID_VOICE_2_PULSE_WAVE_WAVE_CYCLE_HIGH	= $d40a

;7	6	5	4	3	2	1	0
;noise	pulse	sawtooth	triangle	test	ring modulation with voice 1	synchronize with voice 1	gate
; 7..4	3..0
SID_VOICE_2_CONTROL			= $d40b
SID_VOICE_2_ATTACK_DECAY_DURATION	= $d40c
SID_VOICE_2_SUSTAIN_RELEASE_DURATION	= $d40d




SID_VOICE_3_FREQUENCY_LOW		= $d40e
SID_VOICE_3_FREQUENCY_HIGH		= $d40f

; 7..4	3..0
SID_VOICE_3_PULSE_WAVE_WAVE_CYCLE_LOW	= $d410
SID_VOICE_3_PULSE_WAVE_WAVE_CYCLE_HIGH	= $d411

;7	6	5		4		3	2				1				0
;noise	pulse	sawtooth	triangle	test	ring modulation with voice 1	synchronize with voice 1	gate
SID_VOICE_3_CONTROL			= $d412
; 7..4	3..0
SID_VOICE_3_ATTACK_DECAY_DURATION	= $d413
SID_VOICE_3_SUSTAIN_RELEASE_DURATION	= $d414


SID_FILTER_CUTOFF_FREQUENCY_LOW		= $d415
SID_FILTER_CUTOFF_FREQUENCY_HIGH	= $d416

;7..4	3	2	1	0
;filter resonance	external input	voice 3	voice 2	voice 1
SID_FILTER_RESONANCE_AND_ROUTING	= $d417

; 7		6			5		4		3..0
; mute 		voice 3	high pass	band pass	low pass	main volume
SID_FILTER_MODE_AND_MAIN_VOLUME_CTRL	= $d418
SID_PADDLE_X_VALUE			= $d419
SID_PADDLE_Y_VALUE			= $d41a
SID_OSCILLATOR_VOICE_3			= $d41b
SID_ENVELOPE_VOICE_3			= $d41c
