#ifndef USB_USER__
#define USB_USER__


#include <config.h>
#include <typedefs.h>

#include <microchip/usb.h>

#define usb_do_stuff() do {\
		USBCheckBusStatus(); \
    	if(UCFGbits.UTEYE!=1) USBDriverService();\
        CDCTxService();\
	} while(0)
		


#define usb_wait_tx() do { \
		usb_do_stuff();\
 	}while(!mUSBUSARTIsTxTrfReady())

#define usb_tx(str) do { \
		usb_wait_tx();	\
		putsUSBUSART((char *)(str));	\
		usb_do_stuff();	\
	} while(0)

#define usb_txr(str) do { \
		usb_wait_tx();	\
		putrsUSBUSART(str);	\
		usb_do_stuff();	\
	} while(0)


#endif
