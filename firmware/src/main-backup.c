#include <config.h>
#include <usb_user.h>
#include <adc.h>
#include <utils.h>

#include <microchip/usb.h>

void init(void);

char *usb_tx_val = 0;

void long_delay()
{
	byte i;
	while(~((PORTD & 0x3F) | 0xC0));

	for(i=0; i<255; i++){
		byte j;
		for(j=0; j<255; j++){
			//byte k;
			//for(k=0; k<255; k++);
		}
	}
}

void set_led_i(byte b)
{
	if(b==0){
		LED0 = 1;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b==1){
		LED1 = 1;
		LED0 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b==2){
		LED2 = 1;
		LED0 = 0;
		LED1 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b==3){
		LED3 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b==4){
		LED4 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED5 = 0;
		return;
	}else if(b==5){
		LED5 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		return;
	}
}

byte oldfader[4];
byte getFaderPosBlocking()
{
		int i;
		byte adc;
  		OpenADC(ADC_RIGHT_JUST & ADC_FOSC_64/*& ADC_1ANA_0REF*/, ADC_CH0 & ADC_INT_OFF & ADC_VREFPLUS_VDD & ADC_VREFMINUS_VSS, 0x0E);
		ConvertADC();
		while(BusyADC())	usb_do_stuff();
		
		// Read as 10bit value, covert to 8bit
		// Subtract from 0xFF to invert
		adc = 0xFF - (ReadADC() >> 2);
		oldfader[3] = oldfader[2];
		oldfader[2] = oldfader[1];
		oldfader[1] = oldfader[0];
		oldfader[0] = adc;
		i = (int)oldfader[0] + (int)oldfader[1] + (int)oldfader[2] + (int)oldfader[3];
		return (byte)(i >> 2);
}

byte setFaderPos(byte pos)
{
	byte oldpos = -1;
	while(1){
		byte curpos;
		curpos = getFaderPosBlocking();

		if(curpos != oldpos){
			char buf[10];
			//FADER_EN = 0;
			buf[2] = '\n';
			buf[3] = '\r';
			buf[4] = '\0';
			byte2str(buf, curpos);
			usb_tx(buf);
			oldpos = curpos;
		}


		if(pos > curpos){
			FADER1 = 0;
			FADER2 = 1;
			FADER_EN = 1;			
		}else if(pos < curpos){
			FADER1 = 1;
			FADER2 = 0;
			FADER_EN = 1;			
		}else{
			FADER_EN = 0;
			return curpos;
		}
		usb_do_stuff();
	}
}



void main(void)
{
	byte buffer[6];

	byte b;
	byte cmd = 0;
	byte d0  = 0;

	byte old_b0 = 0;
	byte old_b1 = 0;
	byte old_b2 = 0;
	byte old_b3 = 0;
	byte old_b4 = 0;
	byte old_b5 = 0;

	byte old_adc = -1;

	init();	
	setFaderPos(0x80);
    while(1){
		byte adc = getFaderPosBlocking();
		if(adc != old_adc){
			char buf[10];
			buf[2] = '\n';
			buf[3] = '\r';
			buf[4] = '\0';
			byte2str(buf, adc);
			usb_tx(buf);

			old_adc = adc;
		}

		if(BTN0 == 0){
			setFaderPos(0x40);
		}else if(BTN1 == 0){
			setFaderPos(0x80);
		}else if(BTN2 == 0){
			setFaderPos(0xC0);
		}
		usb_do_stuff();
	}

    
	while(0){
		if(BTN0 != old_b0){
			old_b0 = BTN0;
			usb_txr("BTN0");
			if(BTN0){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}


		if(BTN1 != old_b1){
			old_b1 = BTN1;
			usb_txr("BTN1");
			if(BTN1){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}


		if(BTN2 != old_b2){
			old_b2 = BTN2;
			usb_txr("BTN2");
			if(BTN2){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}


		if(BTN3 != old_b3){
			old_b3 = BTN3;
			usb_txr("BTN3");
			if(BTN3){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}


		if(BTN4 != old_b4){
			old_b4 = BTN4;
			usb_txr("BTN4");
			if(BTN4){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}


		if(BTN5 != old_b5){
			old_b5 = BTN5;
			usb_txr("BTN5");
			if(BTN5){
				usb_txr("u");
			}else{
				usb_txr("d");
			}
		}

		if(b = getsUSBUSART(buffer, 5)){
			byte c;
			for(c=0; c<b; c++){
                
				byte bufs[2];
				bufs[0] = buffer[c];
				bufs[1] = '\0';
				buffer[b] = 0;
				usb_tx(buffer);
				
				if(cmd == 'l'){
					if(buffer[c] == '0'){
						LED0 = 1;
						LED1 = 0;
						LED2 = 0;
						LED3 = 0;
						LED4 = 0;
						LED5 = 0;
					}else if (buffer[c] == '1'){
						LED0 = 0;
						LED1 = 1;
						LED2 = 0;
						LED3 = 0;
						LED4 = 0;
						LED5 = 0;
					}else if (buffer[c] == '2'){
						LED0 = 0;
						LED1 = 0;
						LED2 = 1;
						LED3 = 0;
						LED4 = 0;
						LED5 = 0;
					}else if (buffer[c] == '3'){
						LED0 = 0;
						LED1 = 0;
						LED2 = 0;
						LED3 = 1;
						LED4 = 0;
						LED5 = 0;
					}else if (buffer[c] == '4'){
						LED0 = 0;
						LED1 = 0;
						LED2 = 0;
						LED3 = 0;
						LED4 = 1;
						LED5 = 0;
					}else if (buffer[c] == '5'){
						LED0 = 0;
						LED1 = 0;
						LED2 = 0;
						LED3 = 0;
						LED4 = 0;
						LED5 = 1;
					}else if(buffer[c] == 'o'){
						LED0 = 0;
						LED1 = 0;
						LED2 = 0;
						LED3 = 0;
						LED4 = 0;
						LED5 = 0;
					}
				}else if(cmd == 's'){
	
				}else{
					cmd = buffer[c];
				}			
			}
		}		
	

		usb_do_stuff();
	}
}

void main1(void)
{
	byte active = 0;

	byte old_in0 = IN0;
	byte old_in1 = IN1;
	byte old_in2 = IN2;
	
	byte last_edge = 0;
	byte last_edge1 = 0;
	byte last_edge2 = 0;

	init();


#if 0
	while(1){
		if(BTN0 == 0){
			LED1 = 1;
			FADER1 = 1;
			FADER2 = 0;
			FADER_EN = 1;			
		}else if(BTN1 == 0){
			FADER1 = 0;
			FADER2 = 1;
			FADER_EN = 1;
			LED1 = 1;
		}else{
			FADER_EN = 0;
			LED1 = 0;
		}
		

	}

	while(1){
		/*
		LED0  = ~BTN0;
		LED1  = ~BTN1;
		LED2  = ~BTN2;
		LED3  = ~BTN3;
		LED4  = ~BTN4;
		LED5  = ~BTN5;
*/
	LED5 = 0;
	LED0 = 1;
	long_delay(); //long_delay();
	LED0 = 0;
	LED1 = 1;
	long_delay(); //long_delay();
	LED1 = 0;
	LED2 = 1;
	long_delay(); //long_delay();
	LED2 = 0;
	LED3 = 1;
	long_delay(); //long_delay();	
	LED3 = 0;
	LED4 = 1;
	long_delay(); //long_delay();
	LED4 = 0;
	LED5 = 1;
	long_delay(); //long_delay();



		//set_led_i(active);
		//set_led_i(4);
		//long_delay(); long_delay();
		//if(active++ >= 6) active = 0;
	}

#endif


	putrsUSBUSART("££        HDDJ v0.1         ££\n\r");

	
	while(1){
		if(IN0 && !old_in0){
			if(last_edge == 5 && last_edge1 == 4 && last_edge2 == 3){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 1 && last_edge1 == 2 && last_edge2 == 3){
				LED2 = 1;
				usb_txr("<");
			}
			old_in0 = IN0;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 0;
		}else if(!IN2 && old_in2){
			if(last_edge == 0 && last_edge1 == 5 && last_edge2 == 4){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 2 && last_edge1 == 3 && last_edge2 == 4){
				LED2 = 1;
				usb_txr("<");
			}
			old_in2 = IN2;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 1;
		}else if(IN1 && !old_in1){
			if(last_edge == 1 && last_edge1 == 0 && last_edge2 == 5){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 3 && last_edge1 == 4 && last_edge2 == 5){
				LED2 = 1;
				usb_txr("<");
			}
			old_in1 = IN1;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 2;
		}else if(!IN0 && old_in0){
			if(last_edge == 2 && last_edge1 == 1 && last_edge2 == 0){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 4 && last_edge1 == 5 && last_edge2 == 0){
				LED2 = 1;
				usb_txr("<");
			}
			old_in0 = IN0;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 3;
		}else if(IN2 && !old_in2){
			if(last_edge == 3 && last_edge1 == 2 && last_edge2 == 1){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 5 && last_edge1 == 0 && last_edge2 == 1){
				LED2 = 1;
				usb_txr("<");
			}
			old_in2 = IN2;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 2;
		}else if(!IN1 && old_in1){
			if(last_edge == 4 && last_edge1 == 3 && last_edge2 == 2){
				LED1 = 1;
				usb_txr(">");
			}else if(last_edge == 0 && last_edge1 == 1 && last_edge1 == 2){
				LED2 = 1;
				usb_txr("<");
			}
			old_in1 = IN1;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 3;
		}else{
			LED1 = 0;
			LED2 = 0;
			LED3 = IN0;
			LED4 = IN1;
			LED5 = IN2;
		}
		usb_do_stuff();
	}


/*
  // INTERRUPT BASED ROUTINES
	while(1){
		byte old_gie;
		usb_do_stuff();

		old_gie = INTCONbits.GIE;
		INTCONbits.GIE = 0;
		if(usb_tx_val){
			putrsUSBUSART(usb_tx_val);
			usb_tx_val = 0;
		}
		INTCONbits.GIE = old_gie;
		//LED0 = 0;

		//if(usb_tx_val)
		//putrsUSBUSART(usb_tx_val);

	}	
*/
}


void init(void)
{
	// USB
	mInitializeUSBDriver();         // See usbdrv.h

    // Turn all ports analog input off, except RA0/AN0
	ADCON1 = 0x0E;
    // Enable ADC and select channel 0
    ADCON0 = 0x01;
    // Disable all comparators
    CMCON = 0x07;

	// Interrupts
	INTCON  = 0x50;
	INTCON2 = 0xF0;
	INTCON3 = 0xD8;

	LED0_TRIS = 0;
	LED0 = 0;
	LED1_TRIS = 0;
	LED1 = 0;
	LED2_TRIS = 0;
	LED2 = 0;
	LED3_TRIS = 0;
	LED3 = 0;
	LED4_TRIS = 0;
	LED4 = 0;
	LED5_TRIS = 0;
	LED5 = 0;

	FADER_EN_TRIS = 0;
	FADER_EN = 0;
	FADER1_TRIS = 0;
	FADER1 = 0;
	FADER2_TRIS = 0;
	FADER2 = 0;


	// Enable interrupts
	//INTCONbits.GIE = 1;
}
