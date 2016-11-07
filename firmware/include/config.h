#ifndef CONFIG_H__
#define CONFIG_H__

#include <p18cxxx.h>
#include <typedefs.h>

// Pinout configuration
#define	LED0_TRIS	(TRISAbits.TRISA3)
#define	LED1_TRIS	(TRISAbits.TRISA4)
#define	LED2_TRIS	(TRISAbits.TRISA5)
#define	LED3_TRIS	(TRISEbits.TRISE0)
#define	LED4_TRIS	(TRISEbits.TRISE1)
#define	LED5_TRIS	(TRISEbits.TRISE2)
#define LED0		(PORTAbits.RA3)
#define LED1		(PORTAbits.RA4)
#define LED2		(PORTAbits.RA5)
#define LED3		(PORTEbits.RE0)
#define LED4		(PORTEbits.RE1)
#define LED5		(PORTEbits.RE2)

#define BTN0		(PORTDbits.RD0)
#define BTN1		(PORTDbits.RD1)
#define BTN2		(PORTDbits.RD2)
#define BTN3		(PORTDbits.RD3)
#define BTN4		(PORTDbits.RD4)
#define BTN5		(PORTDbits.RD5)

#define IN0 (PORTBbits.RB0)
#define IN1 (PORTBbits.RB1)
#define IN2 (PORTBbits.RB2)

#define FADER_EN	(PORTCbits.RC0)
#define FADER1		(PORTCbits.RC1)
#define FADER2		(PORTCbits.RC2)
#define FADER_EN_TRIS	(TRISCbits.TRISC0)
#define FADER1_TRIS		(TRISCbits.TRISC1)
#define FADER2_TRIS		(TRISCbits.TRISC2)


#define TSENSE_DRV	(PORTDbits.RD7)
#define TSENSE		(PORTAbits.RA1)
#define TSENSE_DRV_TRIS	(TRISDbits.TRISD7)
#define TSENSE_TRIS		(TRISAbits.TRISA1)

#endif
