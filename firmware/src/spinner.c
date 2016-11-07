#include <config.h>
#include <usb_user.h>
#include <utils.h>


byte old_in0 = 0;
byte old_in1 = 0;
byte old_in2 = 0;
	
byte last_edge = 0;
byte last_edge1 = 0;
byte last_edge2 = 0;

void poll_spinner(void)
{
		if(IN0 && !old_in0){
			if(last_edge == 5 && last_edge1 == 4 && last_edge2 == 3){
				usb_txr(">");
			}else if(last_edge == 1 && last_edge1 == 2 && last_edge2 == 3){
				usb_txr("<");
			}
			old_in0 = IN0;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 0;
		}else if(!IN2 && old_in2){
			if(last_edge == 0 && last_edge1 == 5 && last_edge2 == 4){
				usb_txr(">");
			}else if(last_edge == 2 && last_edge1 == 3 && last_edge2 == 4){
				usb_txr("<");
			}
			old_in2 = IN2;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 1;
		}else if(IN1 && !old_in1){
			if(last_edge == 1 && last_edge1 == 0 && last_edge2 == 5){
				usb_txr(">");
			}else if(last_edge == 3 && last_edge1 == 4 && last_edge2 == 5){
				usb_txr("<");
			}
			old_in1 = IN1;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 2;
		}else if(!IN0 && old_in0){
			if(last_edge == 2 && last_edge1 == 1 && last_edge2 == 0){
				usb_txr(">");
			}else if(last_edge == 4 && last_edge1 == 5 && last_edge2 == 0){
				usb_txr("<");
			}
			old_in0 = IN0;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 3;
		}else if(IN2 && !old_in2){
			if(last_edge == 3 && last_edge1 == 2 && last_edge2 == 1){
				usb_txr(">");
			}else if(last_edge == 5 && last_edge1 == 0 && last_edge2 == 1){
				usb_txr("<");
			}
			old_in2 = IN2;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 2;
		}else if(!IN1 && old_in1){
			if(last_edge == 4 && last_edge1 == 3 && last_edge2 == 2){
				usb_txr(">");
			}else if(last_edge == 0 && last_edge1 == 1 && last_edge1 == 2){
				usb_txr("<");
			}
			old_in1 = IN1;
			last_edge2 = last_edge1;
			last_edge1 = last_edge;
			last_edge = 3;
		}
	
	
}
