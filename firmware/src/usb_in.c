#include <config.h>
#include <usb_user.h>
#include <utils.h>

#include <microchip/usb.h>


void set_led_x(byte b);
void set_led_i(byte b);
void set_led_o(byte b);

extern byte target_pos;
extern byte move_to_target;

byte cmd = 0;
byte param0 = 0;

void poll_usb(void)
{
	byte buffer[10];
	byte len = getsUSBUSART(buffer, 10);
	byte i;
	
	for(i=0; i<len; i++){
		byte c = buffer[i];
		if(c == ' ' || c == '\n' || c == '\r'){
			cmd = 0;
			param0 = 0;
		}
		switch(cmd){
		case 'l':
		case 'L':
			if(!param0){
				if(c == 'x' || c == 'X'){
					led_all_x();
				}else if(c == 'i' || c == 'I'){
					led_all_on();
				}else if(c == 'o' || c == 'O'){
					led_all_off();
				}else{
					param0 = c;
				}
			}else{
				if(c == 'x' || c == 'X'){
					set_led_x(param0);
				}else if(c == 'i' || c == 'I'){
					set_led_i(param0);
				}else if(c == 'o' || c == 'O'){
					set_led_o(param0);
				}
			}
			break;
	
		case 'f':
		case 'F':
			if(!param0){
				param0 = c;
			}else{
				byte b[2];
				byte newpos;
				byte err;

				// Convert paramter from ASCII string to byte
				b[0] = param0;
				b[1] = c;
				str2byte(newpos, b, err);

				// If no error then update the target_pos and
				// start move
				if(!err){
					target_pos = newpos;
					move_to_target = 1;
				}
			}
			break;

		default:
			cmd = c;
		}
	}
}
