#include <config.h>
#include <usb_user.h>
#include <utils.h>

#include <adc.h>

byte move_to_target = 1;
byte target_pos = 0x80;
byte old_pos = 0;

byte getFaderPosBlocking(void)
{
		int i;
		byte adc;
  		OpenADC(ADC_RIGHT_JUST & ADC_FOSC_64/*& ADC_1ANA_0REF*/, ADC_CH0 & ADC_INT_OFF & ADC_VREFPLUS_VDD & ADC_VREFMINUS_VSS, 0x0E);
		ConvertADC();
		while(BusyADC())	usb_do_stuff();
		
		// Read as 10bit value, covert to 8bit
		// Subtract from 0xFF to invert
		adc = 0xFF - (ReadADC() >> 2);
		return adc;
}


void poll_fader(void)
{
		byte curpos;
		byte tp;
		byte cp;
		curpos = getFaderPosBlocking();

		// Threshold - mask out lower bits to not detect
		//             small changes
		if((curpos & 0xF8) != (old_pos & 0xF8)){
			char buf[10];
			//FADER_EN = 0;
			buf[0] = 'f';
			byte2str(buf+1, curpos);
			buf[3] = '\n';
			buf[4] = '\r';
			buf[5] = '\0';
			usb_tx(buf);
			old_pos = curpos;
		}

	if(move_to_target){
		tp = target_pos & 0xFC;
		cp = curpos & 0xFC;

		if(tp > cp){
			FADER1 = 0;
			FADER2 = 1;
			FADER_EN = 1;			
		}else if(tp < cp){
			FADER1 = 1;
			FADER2 = 0;
			FADER_EN = 1;			
		}else{
			FADER_EN = 0;
			move_to_target = 0;
		}
	}
}
