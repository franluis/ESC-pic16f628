#include <config.h>
#include <usb_user.h>
#include <utils.h>

void led_all_on()
{
		LED0 = 1;
		LED1 = 1;
		LED2 = 1;
		LED3 = 1;
		LED4 = 1;
		LED5 = 1;	
}

void led_all_off()
{
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;	
}

void led_all_x()
{
		LED0 = ~LED0;
		LED1 = ~LED1;
		LED2 = ~LED2;
		LED3 = ~LED3;
		LED4 = ~LED4;
		LED5 = ~LED5;
}

void set_led_x(byte b)
{
	if(b=='0'){
		LED0 = 1;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b=='1'){
		LED1 = 1;
		LED0 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b=='2'){
		LED2 = 1;
		LED0 = 0;
		LED1 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b=='3'){
		LED3 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED4 = 0;
		LED5 = 0;
		return;
	}else if(b=='4'){
		LED4 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED5 = 0;
		return;
	}else if(b=='5'){
		LED5 = 1;
		LED0 = 0;
		LED1 = 0;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		return;
	}
}

void set_led_i(byte b)
{
	if(b=='0'){
		LED0 = 1;
		return;
	}else if(b=='1'){
		LED1 = 1;
		return;
	}else if(b=='2'){
		LED2 = 1;
		return;
	}else if(b=='3'){
		LED3 = 1;
		return;
	}else if(b=='4'){
		LED4 = 1;
		return;
	}else if(b=='5'){
		LED5 = 1;
		return;
	}
}

void set_led_o(byte b)
{
	if(b=='0'){
		LED0 = 0;
		return;
	}else if(b=='1'){
		LED1 = 0;
		return;
	}else if(b=='2'){
		LED2 = 0;
		return;
	}else if(b=='3'){
		LED3 = 0;
		return;
	}else if(b=='4'){
		LED4 = 0;
		return;
	}else if(b=='5'){
		LED5 = 0;
		return;
	}
}
