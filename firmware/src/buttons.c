#include <config.h>
#include <usb_user.h>
#include <utils.h>

byte old_b0 = 0;
byte old_b1 = 0;
byte old_b2 = 0;
byte old_b3 = 0;
byte old_b4 = 0;
byte old_b5 = 0;

void poll_buttons(void)
{
	if(BTN0 != old_b0){
			old_b0 = BTN0;
			usb_txr("BTN0");
			if(BTN0){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}


		if(BTN1 != old_b1){
			old_b1 = BTN1;
			usb_txr("BTN1");
			if(BTN1){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}


		if(BTN2 != old_b2){
			old_b2 = BTN2;
			usb_txr("BTN2");
			if(BTN2){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}


		if(BTN3 != old_b3){
			old_b3 = BTN3;
			usb_txr("BTN3");
			if(BTN3){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}


		if(BTN4 != old_b4){
			old_b4 = BTN4;
			usb_txr("BTN4");
			if(BTN4){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}


		if(BTN5 != old_b5){
			old_b5 = BTN5;
			usb_txr("BTN5");
			if(BTN5){
				usb_txr("u\n\r");
			}else{
				usb_txr("d\n\r");
			}
		}
}
