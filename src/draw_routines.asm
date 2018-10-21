.segment "BANKF"

; ============================
; Do Update Nametable
; Copies the contents from the drawing buffer into the nametable.
; The contents of the nametable are formatted as follows:
;
;   byte    0 = length of data (0 = no more data)
;   byte    1 = high byte of target PPU address
;   byte    2 = low byte of target PPU address
;   byte    3 = drawing flags:
;               bit 0 = set if inc-by-32, clear if inc-by-1
;   bytes 4-X = the data to draw (number of bytes determined by the length)
; ============================
do_update_nmtbl:
