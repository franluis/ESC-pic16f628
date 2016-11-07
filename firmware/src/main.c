#include <config.h>
#include <usb_user.h>
#include <adc.h>
#include <utils.h>

#include <microchip/usb.h>

void init(void);

void main(void)
{
	init();

	while(1){
		poll_usb();
		poll_buttons();
		poll_fader();
		poll_spinner();
		usb_do_stuff();
	}
	
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

	TSENSE_DRV_TRIS = 0;
	TSENSE_DRV = 0;
}
