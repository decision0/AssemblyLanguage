;  		test.asm			Port J Output   

		LIST P=18F97J60			; directive to define processor
		#include <P18F97J60.INC>	; processor specific variable definition
		config XINST = OFF
		config FOSC = HS
		config WDT = OFF
		
		; Using CBLOCK command to reserve the memory area, using 0x20 as an initial address
		; 'data8' will store the ninth character of the RFID card
		; 'data9' will store the tenth character of the RFID card
		; 'temp' and 'temp1' act as a temporary variables
		; 'counter' act as a counter for the loop later in the code 
		cblock 0x20
		data8
		data9
		temp
		temp1
		counter
		endc
				
		ORG		0x0000  ; Program start 
ResetV	goto	MAIN			; Skip over interrupt vectors

		ORG		0x0008
HPISR	
		retfie			; ret from interrupt enable	

		ORG		0x0018
LPISR
		retfie			; ret from interrupt enable

		ORG		0x0100	; Suggest starting address for codes
		
		; We begin the code with initialising the UART and initialising the TRISJ by calling the UART and TRISJ subroutine
		; Then call the ReadRFID subroutine to constantly read the RFID
		; Then display the last two character of the RFID by using the DisplayData subroutine
		
MAIN
		
		call InitUART  ; initUART subroutine
		call InitTRISJ ; initTRISJ subroutine
again
		call ReadRFID  ; ReadRFID subroutine
		call DisplayData  ; Display last 2 Characters of RFID subroutine
		
		bra again
		
		


		
		
		
;-----------------------------------------------------------------------------------------------------------------------------------------------;

		
		;initUART subrotine
InitUART		
		bcf   TRISC, TRISC6, 0 ;TRISCbits.TRISC6 = 0
		bsf   TRISC, TRISC7, 0 ;TRISCbits.TRISC7 = 1
		movlw 0x20	
		movwf TXSTA1, 0  ;TXSTA1 = 0x20
		clrf  BAUDCON1   ; baudcon1 = 0x00;
		movlw 0x28
		movwf SPBRG1, 0  ; SPBRG1 = 0x28;
		bsf   TXSTA1, TXEN, 0 ;TXSTA1bits.TXEN = 1;
		bsf   RCSTA1, CREN, 0 ; RCSTAbits.CREN = 1;
		bsf   RCSTA1, SPEN, 0 ; RCSTAbits.SPEN = 1;
		return
		
InitTRISJ	;init TRISJ
		clrf TRISJ ; config TRISJ output
		clrf PORTJ ; config the portj to OFF the LED
		return
		
		; This Subroutine is to display the last two characters of RFID card
DisplayData	swapf data8, 1, 0 ; To move the ninth character to the first 4 bits. 
		movf data9, w ; Move data9(last character) to working register
		xorwf data8,1,0 ; Use XOR logic to merge the eighth and ninth character together as data8
		movf data8, w  ; once data8 is finally merged, move it again to working register
		movwf PORTJ,0 ; display the data on portj as LED
		return
		
		
ReadRFID	; ReadRFID Subroutine	
		; This block of code will read the RFID 
wAgain		
		btfss PIR1, RCIF, 0 ; while(PIR1bits.RCIF == 0);
		bra wAgain
		; temp = RCREG
		; if(temp == 0x02)
		movf RCREG, w
		movwf temp, 0
		movlw 0x02
		subwf temp, f
		bnz  wAgain ; if(temp == 0x02)
		
		;Reading from RFID
initCounter1	;init the counter as 0x08	
		movlw 0x08
		movwf counter
FirstForLoop	; for(i=0; i<10; i++) - for(i=7; i<10; i++)
		btfss PIR1, RCIF, 0
		bra FirstForLoop
		movf RCREG, w
		decf counter, 1, 0
		bnz FirstForLoop
		
NinthFor	; for(i= 8; i < 10; i++) 
		btfss PIR1, RCIF, 0 ; while(PIR1bits.RCIF == 0);
		bra NinthFor
		movf RCREG, w
		movwf data8
		bra TenthFor
		
TenthFor	; for(i= 9; i < 10; i++) 
		btfss PIR1, RCIF, 0 ; while(PIR1bits.RCIF == 0);
		bra TenthFor
		movf RCREG, w
		movwf data9
		bra initCounter


initCounter	;init the counter as 0x05
		movlw 0x05
		movwf counter 
		bra AnotherForLoop
		
		; This block of code will constantly check for RFID card and update the inputs
AnotherForLoop  btfss PIR1, RC1IF, 0 ; while(PIR1bits.RCIF == 0);
		bra AnotherForLoop
		movff RCREG, temp  ; temp = RCREG
		decf counter, 1, 0 ; dec the counter  
		bnz AnotherForLoop
		
		
		; End of if(temp == 0x02)
		; in other words, end of readingRFID
		
		
		;Start of CheckValue
		bra CheckValueLogic
		; This CheckValueLogic will check the value and do the necessary logic before displaying the correct characters
		; CheckValueLogic is responsible for: 
		; 1) Assessing the data 
		; 2) Subtract the data by 30 or 37
		; For example:
		; if the data is '1' on RFID card, the data is read as '31' in ASCII
		; so to display as '1' on PORTJ, LED, we subtract is by 30.
		; Another example: 
		; if the data is 'A' on RFID card, the data is read as '41' in ASCII
		; so to display as 'A' on PORTJ, LED, we subtract is by 37.
CheckValueLogic 
						
CV8		
		movlw 0x3A
		movff data8, temp1
		cpfslt temp1, 0 ;skip if lesser
		bra minus378
		
		movf data8, w
		movwf temp1  ; i remove data9 to temp
		movlw 0x30
		subwf temp1, f ; i subtract the value in temp
		movf temp1, w 
 		movwf data8 ; move value of temp to data8
		bra CV9
		
		
CV9
		movlw 0x3A
		movff data9, temp
		cpfslt temp, 0 ;skip if lesser
		bra minus379
		
		movf data9, w
		movwf temp  ; i remove data9 to temp
		movlw 0x30
		subwf temp, f ; i subtract the value in temp
		movf temp, w 
 		movwf data9 ; move value of temp to data9
		return
					
		
minus378		
		
		movf data8, w
		movwf temp  ; i remove data9 to temp
		movlw 0x37
		subwf temp, f ; i subtract the value in temp
		movf temp, w 
 		movwf data8 ; move value of temp to data9
		bra CV9
		
minus379	
		movf data9, w
		movwf temp  ; i remove data9 to temp
		movlw 0x37
		subwf temp, f ; i subtract the value in temp
		movf temp, w 
 		movwf data9 ; move value of temp to data9
		return
		
		;End of the checkValue 
		;End of ReadRFID subroutine
		
		END			; No code beyond this line, absolutely.
