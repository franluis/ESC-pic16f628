#include <config.h>

void isr_high(void);
void isr_low(void);

#pragma code vector_high = 0x08
void vector_high_redirect()
{
	_asm	goto isr_high _endasm
}

#pragma code vector_low = 0x18
void vector_low_redirect()
{
	_asm	goto isr_low _endasm
}

#pragma code

byte last1_edge = -1;
byte last2_edge = -2;
byte last3_edge = -3;

extern char *usb_tx_val;
#pragma interrupt isr_high
void isr_high(void)
{
	byte intcon1 = INTCON;
	byte intcon2 = INTCON2;
	byte intcon3 = INTCON3;

	if(INTCONbits.INT0IF){
		INTCONbits.INT0IF = 0;

		if(last1_edge == 2 && last2_edge == 3 && last3_edge == 1){
			usb_tx_val = "<";
			LED0 = 1;
		}else if(last1_edge == 3 && last2_edge == 2 && last3_edge == 1){
			usb_tx_val = ">";
			LED0 = 0;
		}

		last3_edge = last2_edge;
		last2_edge = last1_edge;
		last1_edge = 1;
	}else if(INTCON3bits.INT1IF){
		INTCON3bits.INT1IF = 0;

		if(last1_edge == 3 && last2_edge == 1 && last3_edge == 2){
			usb_tx_val = "<";
		}else if(last1_edge == 1 && last2_edge == 3 && last3_edge == 2){
			usb_tx_val = ">";
		}

		last3_edge = last2_edge;
		last2_edge = last1_edge;
		last1_edge = 2;
	}else if(INTCON3bits.INT2IF){
		INTCON3bits.INT2IF = 0;

		if(last1_edge == 1 && last2_edge == 2 && last3_edge == 3){
			usb_tx_val = "<";
		}else if(last1_edge == 2 && last2_edge == 1 && last3_edge == 3){
			usb_tx_val = ">";
		}

		last3_edge = last2_edge;
		last2_edge = last1_edge;
		last1_edge = 3;
	}else{
		LED0 = 1;
	}
}


#pragma interrupt isr_low
void isr_low(void)
{
	//LED0 = 1;
}
