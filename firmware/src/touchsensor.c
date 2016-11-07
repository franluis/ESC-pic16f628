#include <config.h>
#include <usb_user.h>
#include <utils.h>

void poll_touchsensor(void)
{
	byte b;
	TSENSE_DRV = 1;
	b = TSENSE;
	for(b=0; b<1; b++);
	TSENSE_DRV = 0;
	//for(b=0; b<1; b++);

	if(!b){
		usb_txr("C\n\r");
	}
}
