;===============================================================================================
;		VARIATEUR pour moteur BRUSHLESS à 3 fils  : variat3_21.ASM
;				pour PIC16F628 et Qx=20,000 Mhz
;				par Silicium 628
;dernière mise à jour: 29/09/2005
;===============================================================================================
;REMERCIEMENTS
;Suite à la publication de ce soft sur mon site, certains internautes spécialistes dans tel ou tel domaine
;m'ont contacté afin de m'aider à en améliorer l'écriture.
;Je tiens ainsi à remercier tout particulièrement I.M.B. qui m'a donné (en anglais);beaucoup d'astuces 
;afin de rendre mon code plus structuré et plus lisible.
;===============================================================================================

;DIRECTIVEES D'ASSEMBLAGE:
stops=1
stop_BEC=1
frein_permis=1
vif=1
detecte_perio_z=0
detecte_vts_lente=0
integration_PPM=1
;NOTE: ces directives activent ou inhibent certaines fontions


;LISTE DES PRINCIPALES PROCEDURES: (Double-clic sur 1 mot pour le sélectionner puis ctrl+F3 dans MPLAB, pratique...)
;TESTS
;MACROS
;mot16A	macro ;charge AH et AL avec le mot codé sur 16 bits transmis
;mot16B	macro ;charge BH et BL avec le mot codé sur 16 bits transmis
;Changements de banques
;R_EEPROM
;W_EEPROM
;CONSTANTES
;VARIABLES_EN_BANQUE0
;TRAITEMENT DES INTERRUPTIONS (Aiguillage vers routines)
;INITIALISATION DES PORTS

;PROGRAMMATION DU REGISTRE OPTION (BANK1)
;PROG DU REGISTRE INTCON (BANK0)
;PROG DU REGISTRE T1CON (BANK0)
;PROG DU REGISTRE T2CON (BANK0)
;PROG DU REGISTRE PR2 (BANK1)
;PROG DU REGISTRE PIE1 (BANK1)
;PROG DU REGISTRE CCP1CON (BANK0)

;Initialisation_des_variables
;BOUCLE_PRINCIPALE
;inttimer0	;-> PERIODEMETRE sur le signal PPM du récepteur de radiocommande (détecte arret radio)
;inttimer1	;-> génère les signaux de commande moteur
;inttimer2	;-> découpe le signal de sortie à (relativement, 10kHz) haute fréquence au démarrage
;intB0		;-> detecte les fronts du signal PPM du récepteur de radio-commande et MESURE le signal T_PPM
;intB4_7		;-> détection signaux BEMF

;pasMot1
;BLOQUE
;sortie
;demarre

;ROUTINES MATH
;convhbin	;conversion sexadécimale -> binaire ;entrée: AA, BB ;resultat: AH,AL = 60*AA+BB
;multi16	;mutiplication 8 bits x 8 bits de w par AA (données sur 1 octet) ;resultat (sur 2 octets) dans AH,AL
;multi24	;mutiplication 8 bits x 16 bits de w par AH,L (données sur 1 octet) ;resultat (sur 3 octets) dans A2,1,0
;divi2	;division d'une valeur codée sur 16 bits (AH,AL) par 2
;Div24_8	;division 24bits par 8 bits, résultat sur 24 bits
;add16A	;addition 16bits résultat dans A ;(AH,AL)+(BH,BL) -> (AH,AL)
;add16B	;addition 16bits résultat dans B ;(AH,AL)+(BH,BL) -> (BH,BL)
;cpl16x	;complément à deux de la variable codée sur 2 octets situés aux adresses w et w+1 permet les soustractions
;compar16p;comparaison de deux valeurs codées sur 16 bits (AH,AL à BH,BL) ;resultat dans STATUS carry et zéro 
;movxA	;mov la variable codée sur 2 octets situés aux adresses w et w+1  dans -> AH,AL
;movAx	;mov AH,AL dans -> la variable codée sur 2 octets situés aux adresses w et w+1  
;movxB	;mov la variable codée sur 2 octets situés aux adresses w et w+1  dans -> BH,BL
;movBx	;mov BH,BL dans -> la variable codée sur 2 octets situés aux adresses w et w+1 

;cvBDU	;CONVERSION BINAIRE(1) (1 octet incomplet 0..99 et pas 0..255) --> BCD ;nombre à convertir dans AA
;cvBCU	;CONVERSION BINAIRE(2) (1 octet complet 0..255) --> BCD ;resultat dans BB (centaines) et dans AA (unités)

;Delay_ms (voir code externe dans le fichier Delay.asm)

;pasMot1
;vari_vit
;demarre

;TABLEAUX
;
;
;------------------------------------------------------------------------------------------------
;remarque: suite aux modifications (=améliorations!) certains commentaires peuvent se révéler faux !!!
;j'en suis désolé. Je relis régulièrement les commentaires et essaye de les tenir à jour.
;toutefois il m'arrive de trouver des énormités ! que je corrige...
;------------------------------------------------------------------------------------------------



;===================================== PRINCIPE ==================================================
;REMARQUE PRELIMINAIRE:
;De par la constitution du moteur brusless utilisé: (9 pôles électro-magnétiques câblés en 3 groupes de 3 et 12 aimants):
;Quand le champ tourne de 360º durant le cycle électrique complet, le rotor ne tourne que de  360/6=60°.
;Il faut que le champ magnétique fasse 6 tours pour que le rotor en fasse un -> couple important

;un tour (360º) de champ magnétique se décompose électroniquement en 6 phases.
;un tour moteur est effectué après 6x6 = 36 phases électriques.
;chacune de ces phases électriques correspond à un pas dans le tableau Tab_ph
;le tableau Tab_ph comprend 6 lignes correspondant aux six types de phases, 
;dont la totalité se déroule pendant 1/6 de tour moteur soit 60º
;une ligne du tableau concerne donc un angle de 10º du moteur.

;le PIC commande 6 MOSFETS (2 par phase) montés en pont en H
;par  4 bits du PORTA (bit 0 à 3) et 2 bits du portB
;Il s'agit de construire un champs tournant avec un courant triphasé
;voir tableau Tab_ph

;Par l'interruption intPortB, les signaux issus d'un traitement analogique des tensions BEMF font avancer
;le cycle de commande des MOSFFETS d'un pas à chaque impulsion reçue sur un des 3 pins (RB5, RB6 ou RB7)

;la variation de vitesse se fait par variation du rapport cyclique de découpage des signaux de sortie

;===================================== SECURITE ==================================================

;arrêt si plus de signal de réception
;arrêt si manche gaz + trim =0
;ne démarre pas à la mise sous tension, même avec le manche des gaz à fond (à condition que la durée
;de coupure de l'alim soit suffisante pour que le PIC ait eu le temps de reseter, donc attention!)
;le seul demarrage possible se produit en montant le manche des gaz DEPUIS ZERO
;attention si l'émetteur de radiocommande est à l'arrêt, il faut s'attendre à des réceptions de parasites
;provoquant des démarrages ratés.

;fonction BEC implantée depuis la version 19 - met le moteur au ralentit si tension accu faible. sert à deux choses
;- ne pas décharger les accus LiPo sous le minimum autorisé (3V par élément, reglage par diode zener et resistances
;  sur le circuit)
;- toujours garder sufisamment de tension pour alimenter le récepteur de radiocommande
;ATTENTION: le BEC est ici ajusté pour 2 éléments LiPo en série, pas pour 3.
;le circuit constitué autour du transistor Q10 est perfectible
;la partie du soft qui gère le BEC, et qui stope complètement (ou pas) le moteur et également révisable
;(chercher BEC dans le listing)


;============================== REMARQUES GENERALES ==============================================
;RAZ signifie Remise à Zéro
;PPM : type de modulation utilisée en radiocommande analogique par largeur d'impulsion (Phase Pulse Modulation)
;un train de 'n' impulsions, 'n'=nombre de voies module la HF, 1 impulsion par voie
;les impulsions durent entre 1,1ms et 2,2ms suivant la position du manche de la télécommande
;période de 'relaxation' entre deux trains = 20ms environ
;la séparation des impultions destinées à chaque voies se fait dans le récepteur radio

;la notation ':=' dans les commentaires (affectation) me vient de la programmation en Pascal.
;une lecture attentive de ce code fait apparaitre de curieuses séquences goto étiquette suivis immédiatement
;par la destination. C'est voulu, par souci de lisibilité et de structuration du code
;ca évite surtout, lors d'ajout de bouts de code, D'OUBLIER d'ajouter le-dit goto
;D'autre part, j'aime bien que mes routines aient une porte de sortie unique 
;plutôt que de ballancer des 'return' un peu partout.

;représentation d'un nombre hexadécimal: commence par "0x" ex:  0x20
; B'00010000' represente une valeur binaire
;la notation periodeH,L  (par exemple) désigne ici le mot 16bits formé par les 2 octets periodeH et periodeL
;et représente donc une valeur numérique codée sur 16 bits

;Utiliser une version récente de MPLAB afin que le PIC16F628 soit pris en compte (ma version= 7.10.00 )
;voir sur le site de Microchip(R): http://www.microchip.com

;===============================================================================================================

	list      p=16f628A,r=dec      ; list directive to define processor ; constantes système décimal
	#include <p16f628a.inc>        ; processor specific variable definitions
	#include "Delay.inc"
	
	__CONFIG   _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _MCLRE_ON & _LVP_OFF


; '__CONFIG' précise les paramètres encodés dans le processeur au moment de
; la programmation du processeur. Les définitions sont dans le fichier include.
; Voici les valeurs et leurs définitions :
;	_CP_ON		Code protection ON : impossible de relire
;	_CP_OFF		Code protection OFF

;	_PWRTE_ON		Timer reset sur power on en service
;	_PWRTE_OFF	Timer reset hors-service

;	_WDT_ON		Watch-dog en service
;	_WDT_OFF		Watch-dog hors service

;	_LP_OSC		Oscillateur quartz basse vitesse   (32<F<200Khz)
;	_XT_OSC		Oscillateur quartz moyenne vitesse (200Khz<F<4Mhz)
;	_HS_OSC		Oscillateur quartz grande vitesse  (4Mhz<F<20Mhz)
;	_RC_OSC		Oscillateur à réseau RC

; Reset du PIC si tension <4V
; ------------------------------
; 	_BODEN_ON	Reset tension en service Valide PWRTE_ON automatiquement
; 	_BODEN_OFF	Reset tension hors service

; Programmation sur circuit
; ------------------------------
;	_LVP_ON		RB4 permet la programmation série du PIC
;	_LVP_OFF		RB4 en utilisation normale

;	"departRam equ 0x20"


;===============================================================================================================
;                             MACROS
;===============================================================================================================
SWAPwf  MACRO  reg
        xorwf  reg,f
        xorwf  reg,w
        xorwf  reg,f
        ENDM

mot16A	macro	mot16	;charge AH et AL avec le mot codé sur 16 bits transmis
	movlw	low mot16
	movwf	AL
	movlw	high mot16
	movwf	AH
	endm

mot16B	macro	mot16	;charge BH et BL avec le mot codé sur 16 bits transmis
	movlw	low mot16
	movwf	BL
	movlw	high mot16
	movwf	BH
	endm	

LoadInt24	macro	Destination,mot24b

	banksel	Destination
	movlw	low mot24b	;bits 0..7  (8 bits)
	movwf	Destination+0
	movlw	high mot24b	;bits 8..15 (8 bits)
	movwf	Destination+1
	movlw	upper mot24b	;bits 16..21 (6 bits)
	movwf	Destination+2

	endm

; lire eeprom (adresse et résultat en w) 
R_EEPROM 	macro 			
	clrwdt
	banksel 	EEADR 		;(bank1)
	movwf 	EEADR		; Adresse to read
	bsf 	EECON1,RD 	; ordre de lecture
	movf 	EEDATA,w 		; W = EEDATA
	bcf 	STATUS,RP0 	; Bank 0
	endm

;ecriture en EEPROM (adresse dans DDD (commun 4 banques), data dans w)
W_EEPROM	macro
	clrwdt	
	LOCAL	loop
	movwf 	EEDATA 		; Data to write
;	movlw	adress1		; adresse passée en paramètre à la macro (moins souple que par registre)
	movf	DDD,w		; adresse passée par registre DDD, commun aux 4 banques
	movwf 	EEADR
	bsf 	EECON1, WREN	; Enable Write
	bcf 	INTCON, GIE 	; Disable INTs
	movlw 	0x55
	movwf 	EECON2 		; Write 55
	movlw 	0xAA
	movwf 	EECON2 		; Write AA
	bsf 	EECON1, WR 	; lancer cycle d'écriture
	bsf 	INTCON, GIE	; réautoriser INTs

loop 	clrwdt
	btfsc 	EECON1 , WR 	; tester si écriture terminée
	goto 	loop 		; non, attendre 
	bcf 	EECON1 , WREN 	; verrouiller prochaine écriture 
	bcf 	STATUS , RP0 	; passer en banque0
	endm

;===============================================================================================================
;VARIABLES_EN_BANQUE0
;le PIC16F628 possède 224 octets de RAM répartis en 3 emplacements (80+16, +80, +48 octets)
;ici première banque de 96 octets, début à l'adresse 0x20
;vérifier sur le listing absolu que la dernière adresse soit < 7Fh

GPR0	udata	;
	
AA	res 1	;registre de travail
BB	res 1	;registre de travail	
CC	res 1	;registre de travail
DD	res 1	;registre de travail

;registres pour travailler avec des mots de 16 bits
AH	res 1	;registre de travail poids fort
AL	res 1	;registre de travail poids faible
BH	res 1	;registre de travail poids fort
BL	res 1	;registre de travail poids faible
CH	res 1	;registre de travail poids fort
CL	res 1	;registre de travail poids faible	

;registres pour travailler avec des mots de 24 bits
A2	res 1	;registre de travail poids fort
A1	res 1	;registre de travail poids intemédiaire
A0	res 1	;registre de travail poids faible
	
B2	res 1	;registre de travail poids fort
B1	res 1	;registre de travail poids intemédiaire
B0	res 1	;registre de travail poids faible
	
count0	res 1	;utilisé dans la l'int Timer0
count1	res 1	;utilisé dans la multiplication 8bits x 8bits

n_ph	res 1	;numéro de la période en cours (1 cycle = 6 périodes)

signal	res 1	;signal de sortie brut

T_PPM	res 1	;temps (durée) du signal PPM (voie des gaz en sortie du récepteur de radiocommande)
memo1	res 1	;memo dans la boucle principale
	
periodeH	res 1	;pour mesurer la période (vitesse de rotation) et découper le signal en fonction
periodeL	res 1

rapcycl	res 1	;pour le découpage HF des signaux de sortie pendant le démarrage

Dividende	res 3	;pour la routine Div24_8
Diviseur	res 1	;pour la routine Div24_8
Aux	res 2	;pour la routine Div24_8
Compteur1	res 1	;pour la routine Div24_8
#define Quotient Dividende


mesflag1	res 1	;8 flags perso divers
;b0: stop moteur par ordre émis par la radio-commande (trim + amnche gaz en bas...) ou pas de signal du tout
;b1; stop si accrochage HF de l'électronique
;b2: vitesse lente ou arret du moteur détecté
;b3: découpage HF des signaux pendant le démarrage
;b4: phase du découpage HF
;b5: quel front du signal PPM vient-on de détecter ? ( voir l'intB0 )
;b6: stop moteur permanent si tension faible ("BEC")
;b7: empêche le découpage: moteur forcé à vitesse max lorsque manche + trim de la radio au max


#define 	STOP_RADIO	mesflag1,0
#define 	STOP_ACCRO	mesflag1,1
#define 	VTS_LENTE		mesflag1,2
#define	DECOUP_HF		mesflag1,3
#define	PHASE_HF		mesflag1,4
#define	EDGE_PPM		mesflag1,5
#define	U_FAIBLE		mesflag1,6
#define	A_FOND		mesflag1,7

mesflag2	res 1	;8 flags perso divers
;b0: decoupage enable (1 seul par pas moteur)
;b1: FREIN MOTEUR Enable

#define 	DECOU_En		mesflag2,0
#define 	FREIN_En		mesflag2,1


;===============================================================================================================
; VARIABLES ZONE COMMUNE
; Zone de 16 bytes
;	CBLOCK 	0x70  	;Début de la zone (0x70 à 0x7F) 
	
	udata_shr
WW	res 1	;pour sauvegarder w pendant INT
STUS_TMP	res 1	;pour sauvegarder STATUS pendant INT
FSR_temp 	res 1 	;sauvegarde FSR (si indirect en interrupt)
PLATH_tmp res 1 

DDD	res 1	;registre d'adresses commun

;===============================================================================================================
STARTUP	code
;===============================================================================================================
	
	goto	start
	

;===============================================================================================================
; TRAITEMENT DES INTERRUPTIONS (Aiguillage vers routines)
;===============================================================================================================
;RAPPEL Un seul vecteur d'interruption, d'adresse 004 est diponible
;Quelle que soit la cause de l'interruption, le PC est chargé par 004
;Il faut ensuite tester les différents indicateurs pour savoir quel est la source de l'INT.
;voir le registre INTCON

;	ORG	ISR_V		; Vecteur d'Interruption
	
PROG	code	
	
ISR	movwf	WW
	swapf	STATUS,w
	movwf	STUS_TMP
	movf 	FSR , w
	movwf 	FSR_temp
	movf 	PCLATH , w 	;charger PCLATH 
	movwf 	PLATH_tmp 	;le sauver 
	clrf 	PCLATH 		;on est en page 0 
	banksel	INTCON		;passer en banque0

intTMR0	btfsc	INTCON,5		;TOIE teste si c'est bien le timer0 qui a déclenché l'INT
	btfss	INTCON,2		;TOIF test FLAG timer0
	goto 	intRB47		;non suite
	call	inttimer0		;oui, traiter interrupt timer0
	bcf	INTCON,2		;effacer flag interupt timer: réautorise l'INT Timer0
	goto	restorREG	

intRB47	btfsc	INTCON,3		;RBIE teste si c'est bien RB47 qui a déclenché l'INT
	btfss	INTCON,0		;RBIF test FLAG INT extérieure bits 4 à 7 du port B
	goto 	intRB0		;non suite
	call	intB4_7		;oui, traiter interrupt PORTB,4_7
	bcf	INTCON,0		;effacer flag interupt portB: réautorise interruption PORTB,4_7
	goto	restorREG
	
intRB0	btfsc	INTCON,4		;INTE teste si c'est bien RB0 qui a déclenché l'INT
	btfss	INTCON,1		;INTF test FLAG INT extérieure bit 0 du port B
	goto 	intTMR2		;non suite
	call	intB0		;oui, traiter interrupt PORTB,0
	bcf	INTCON,1		;effacer flag interupt portB: réautorise interruption PORTB,0
	goto	restorREG	
	
intTMR2	
	banksel	PIE1		;BANK1
	btfss	PIE1,TMR2IE	;TMR2IE teste si c'est bien le timer 2 qui a déclenché l'INT
	goto 	intTMR1
	banksel	PIR1		;BANK0
	btfss	PIR1,TMR2IF	;TMR2IF test FLAG timer2
	goto 	intTMR1		;non suite... 
	call 	inttimer2		;oui, traiter interrupt timer2
	bcf	PIR1,TMR2IF	;réautorise l'INT par Timer2
	goto	restorREG	

intTMR1	
	banksel	PIR1		;BANK0
	btfss	PIR1,TMR1IF	;test FLAG timer1
	goto 	intCCP1		;non test suivant
	call 	inttimer1		;oui, traiter interrupt timer1
	bcf	PIR1,TMR1IF	;réautorise l'INT par Timer1
	goto	restorREG

intCCP1	btfss	PIR1,CCP1IF	;test FLAG module de COMPARAISON TMR1H,L = CCPR1H,L ?
	goto 	restorREG		;non suite... 
	call 	intCompar		;oui, traiter interrupt COMPARAISON
	bcf	PIR1,CCP1IF	;réautorise l'INT COMPARAISON
	goto	restorREG
	
;intUSRTi	btfss	PIR1,RCIF		;test FLAG USART en reception
;	goto 	intUSRTo		;non test suivant
;	call	int232in		;oui, traiter interrupt USART IN
;	goto	restorREG
;
;intUSRTo	btfss	PIR1,TXIF		;test FLAG USART en émission
;	goto 	restorREG		;non suite
;	call	int232out		;oui, traiter interrupt USART OUT
;	goto	restorREG	

restorREG	movf 	PLATH_tmp, w 	;recharger ancien PCLATH 
	movwf	PCLATH
	movf 	FSR_temp,w
	movwf	FSR
	swapf	STUS_TMP,w	;swap STATUS_TMP, résultat dans w
	movwf	STATUS		;restaurer status
	swapf	WW,f		;Inversion L et H de l'ancien W sans modifier Z
	swapf	WW,w		;Ré-inversion de L et H dans W

	retfie			;remet GIE à 1 puis return
	
;===============================================================================================================
; TABLEAUX DE DONNEES
;===============================================================================================================

Tab_Ph	movlw	high Tableau
	movwf	PCLATH
	movlw	low Tableau
	addwf	n_ph,w
	btfsc	STATUS,C
	incf	PCLATH,f
	movwf	PCL

;tableau des valeurs des bits de commande des phases

Tableau	retlw	B'00000110' ;phase 0
	retlw	B'00100100' ;phase 1
	retlw	B'00100001' ;phase 2
	retlw	B'00001001' ;phase 3
	retlw	B'00011000' ;phase 4
	retlw	B'00010010' ;phase 5
	retlw	B'00000000'
	retlw	B'00000000'

;===============================================================================================================
; START START START START START START START START START START START
;===============================================================================================================

start	nop
	
	bcf	STATUS,IRP	;pour l'adressage indirect
;IRP: Register Bank Select bit (used for indirect addressing)
;=0 -> Bank 0, 1 (00h - FFh)
;=1 -> Bank 2, 3 (100h - 1FFh)

	banksel	AA	;BANK0

;===============================================================================================================
;ZONE de TESTS de procédures (simulation soft)
	

;===============================================================================================================
; INITIALISATION DES PORTS
;===============================================================================================================

	bcf	RCSTA,7		;(bit SPEN)	portB[1,2] en ports E/S ( pas en USART )

	banksel	CMCON		;BANK0
	movlw	0x07
	movwf	CMCON		;PORT A en E/S numériques (BANK0)

	call	BLOQUE		;positionne les bits du port A avant même de les configurer en sortie

	banksel 	TRISA
	movlw	B'00000000'	;0=sortie 1=entree ATTENTION RA4 =drain ouvert
	movwf	TRISA		;config du port A (TRISA en page 1)
	
	movlw	B'11101001'
	movwf	TRISB		;config du port B

	banksel	AA
;	bsf	PORTB,4		;POUR TEST: signal de RESET visible sur le PORTB,4

;===============================================================================================================
;PROGRAMMATION DU REGISTRE OPTION (BANK1)  -  voir datasheet p:20 du datasheet PIC16F62X.pdf

;bit 7:  RBPU =0 -> R tirage à Vdd du port B
;bit 6: INTEDG=1 -> INT sur front montant ou descendant de RB0
;		1 = Interrupt on rising edge of RB0/INT pin
;		0 = Interrupt on falling edge of RB0/INT pin

;bit 5:  T0CS = 0 -> TMR0 Clock Source Select bit 
;		1 = Transition on RA4/T0CKI pin (Fonctionnement en mode compteur)
;		0 = Internal instruction cycle clock (CLKOUT) (Fonctionnement en mode timer)

;bit 4:  RTE = 0 -> inc sur front montant

;bit 3:  PSA = 0 -> prédiv affecté au timer0
;bits 2,1,0 : PS2,1,0   	
;Bit Value TMR0 Rate WDT Rate
;000	1 : 2	1 : 1
;001	1 : 4	1 : 2
;010	1 : 8	1 : 4
;011	1 : 16	1 : 8
;100	1 : 32	1 : 16
;101	1 : 64	1 : 32	***** ICI  100b -> Timer0 = 1/64  *****
;110	1 : 128	1 : 64
;111	1 : 256	1 : 128

	banksel	OPTION_REG
;	 nº bits:  '76543210'
	movlw	B'01000101'
	movwf 	OPTION_REG

;===============================================================================================================
;PROG DU REGISTRE INTCON (BANK0)  -  voir datasheet p:21
;bit 7 GIE =0 -> INT GLOBALE interdite. (voir + bas)
;bit 6 PEIE=1 -> INT PERIPHERIQUES autorisées. (timer1 en fait partie)
;bit 5 T0IE=1 -> INT par debordement Timer0  autorisées.
;bit 4 INTE=1 -> INT de RB0/INT autorisée (INTERRUPTIONS EXTERNES)
;bit 3 RBIE=1 -> INT du port RB4 à RB7 autorisée.
;bit 2 T0IF=x (flag mis à 1 par débordement du Timer0)
;bit 1 INTF=x (flag  mis à 1 par une INT provoquée par la libne RB0/INT du port B)
;bit 0 RBIF=x (flag mis à 1 si changement d'état des entrées RB4 à RB7 du port B. attention RB1 à RB3 -> pas d'INT)

	banksel	INTCON
;	 nº bits:  '76543210'
	movlw	B'01111000'
	movwf	INTCON


;===============================================================================================================
;PROG DU REGISTRE T1CON (BANK0) (i zorépu lapelé ôtremen !)

;bit 7-6: Unimplemented: Read as '0'

;bit 5-4: T1CKPS1:T1CKPS0: Timer1 Input Clock Prescale Select bits
;11 = 1/8 Prescale value
;10 = 1/4 Prescale value	>> valeur choisie ici <<
;01 = 1/2 Prescale value
;00 = 1/1 Prescale value

;bit 3: T1OSCEN: Timer1 Oscillator Enable Control bit 
;1 = Oscillator is enabled 
;0 = Oscillator is shut off
;Note: The oscillator inverter and feedback resistor are turned off to eliminate power drain

;bit 2: T1SYNC: Timer1 External Clock Input Synchronization Control bit
;si -> TMR1CS = 1
;1 = Do not synchronize external clock input
;0 = Synchronize external clock input
;si -> TMR1CS = 0
;This bit is ignored. Timer1 uses the internal clock when TMR1CS = 0.

;bit 1: TMR1CS: Timer1 Clock Source Select bit 
;1 = External clock from pin RB6/T1OSO/T1CKI (on the rising edge)
;0 = Internal clock (FOSC/4)

;bit 0: TMR1ON: Timer1 On bit
;1 = Enables Timer1
;0 = Stops Timer1

; **** RECAPITULONS:*****
;bit 7 :	Inutilisé : lu comme « 0 »
;bit 6 :	Inutilisé : lu comme « 0 »
;bit 5 :	T1CKPS1 : Timer 1 oscillator ClocK Prescale Select bit 1
;bit 4 ;	T1CKPS0 : Timer 1 oscillator ClocK Prescale Select bit 0
;bit 3 :	T1OSCEN : Timer 1 OSCillator ENable control bit (oscillateur interne)
;bit 2 :	T1SYNC  : Timer 1 external clock input SYNChronisation control bit
;bit 1 :	TMR1CS  : TiMeR 1 Clock Source select bit
;bit 0 :	TMR1ON  : TiMeR 1 ON bit

	banksel	T1CON
;	 nº bits:  '76543210'	;prescale Timer1=1/4
	movlw	B'00100001'
	movwf	T1CON

;===============================================================================================================

;PROG DU REGISTRE T2CON (BANK0)

;bit 7: Unimplemented: Read as '0'
;bit 6-3: TOUTPS3:TOUTPS0: Timer2 Output Postscale Select bits
;0000 = 1:1 Postscale 
;0001 = 1:2 Postscale
;0010 = 1:3 Postscale
;0011 = 1:4 Postscale  
;0100 = 1:5 Postscale etc... (valeur binaire +1)
;1111 = 1:16 Postscale 

;bit 2: TMR2ON: Timer2 On bit =1 : Timer2 is on
;bit 1-0: T2CKPS1:T2CKPS0: Timer2 Clock Prescale Select bits
;00 = Prescaler = 1	
;01 = Prescaler = 4
;1x = Prescaler = 16    (valeur choisie ici)

	banksel	T2CON
;	 nº bits:  '76543210'
	movlw	B'00000110'
	movwf	T2CON

;===============================================================================================================
;PROG DU REGISTRE PR2 (BANK1)
;utilisé par timer2
	banksel	PR2
	movlw	16
	movwf	PR2

;===============================================================================================================
;PROG DU REGISTRE PIE1 (BANK1)
;bit 7 : PSPIE b7 : Toujours 0 sur PIC 16F876 
;bit 6 : ADIE  : masque int convertisseur A/D 
;bit 5 : RCIE  : masque int réception USART 
;bit 4 : TXIE  : masque int transmission USART 
;bit 3 : SSPIE : masque int port série synchrone 
;bit 2 : CCP1IE: masque int CCP1 (module de comparaison TMR1H,L = CCPR1H,L ->INT)
;bit 1 : TMR2IE: masque int TMR2 = PR2 
;bit 0 : TMR1IE: masque int débordement tmr1

	banksel	PIE1
;	 nº bits:  '76543210'
	movlw	B'00000111'	;enable: INT TIMER1 ; INT TIMER2 ; COMPARAISON ; disable le reste
	movwf	PIE1

;===============================================================================================================
;PROG DU REGISTRE CCP1CON (BANK0)
;je vous fais un petit copier coller du datasheet pour le plaisir...

;bit 7-6: Unimplemented: Read as '0' -> dommage, ça aurait pu compliquer un peu !
;bit 5-4: CCP1X:CCP1Y: PWM Least Significant bits
;Capture Mode: Unused
;Compare Mode: Unused
;PWM Mode: These bits are the two LSbs of the PWM duty cycle. The eight MSbs are found in CCPRxL.

;bit 3-0: CCP1M3:CCP1M0: CCPx Mode Select bits
;0000 = Capture/Compare/PWM off (resets CCP1 module)
;0100 = Capture mode, every falling edge
;0101 = Capture mode, every rising edge
;0110 = Capture mode, every 4th rising edge
;0111 = Capture mode, every 16th rising edge
;1000 = Compare mode, set output on match (CCP1IF bit is set)
;1001 = Compare mode, clear output on match (CCP1IF bit is set)
;1010 = Compare mode, generate software interrupt on match (CCP1IF bit is set, CCP1 pin is unaffected)
;1011 = Compare mode, trigger special event (CCP1IF bit is set; CCP1 resets TMR1
;11xx = PWM mode

	banksel	CCP1CON
;	 nº bits:  '76543210'	
	movlw	B'00001010'	;bits 0-3 = 1010 -> mode COMPARE
	movwf	CCP1CON
	
	banksel	AA		;BANK1
	movlw	.200		;durée du signal de RESET visible sur le PORTB,4
	call	Delay_ms		
;	bcf	PORTB,4		;POUR TEST: fin du signal de RESET visible sur le PORTB,4

	
;===============================================================================================================	
;Initialisation_des_variables
N1	bcf 	INTCON, GIE	;->INT GLOBALE interdite 
	movlw	.20		;voir inttimer2
	movwf	rapcycl
	
	banksel	n_ph
	clrf	n_ph
	clrf	count0		

  	movlw	200	
	movwf	TMR0
	
	clrf	TMR1L
	clrf	TMR1H
	
  	movlw	128	
	movwf	TMR2
	
	movlw	100
	clrf	CCPR1H	
	movlw	1
	movwf	CCPR1L
	
	bcf	VTS_LENTE
	bcf	A_FOND
	bsf	DECOU_En
	bcf	STOP_ACCRO
	bcf	U_FAIBLE
	
	movlw	.200		;durée du signal de RESET visible sur le PORTB,4
	call	Delay_ms
	bsf 	INTCON, GIE	;->INT GLOBALE autorisée 

;-----------------------------------------------------------------------
	call	STOP

;===============================================================================================================
;TESTS HARDWARE
;ici1	bcf	PORTB,1
;	call	tp10ms
;	bsf	PORTB,1
;	call	tp10ms
;	goto	ici1

;===============================================================================================================
;				BOUCLE_PRINCIPALE
;===============================================================================================================
;Les numéros des noeuds N1,2... correspondent à ceux de l'organigramme

N2	call	PPMzero?	;c=1 si oui
	btfss	STATUS,C
	goto	N2	;non
	goto	N3	;oui
	
N3	call	PPMzero?	;c=1 si oui
	btfss	STATUS,C
	goto	N4	;non
	goto	N3	;oui		

N4	goto	demarre

N5	call	REG_VIT

N6	call	PPMzero?	;c=1 si oui
	btfss	STATUS,C
	goto	N7	;non
	goto	N8	;oui
	
N7	nop
	if detecte_vts_lente == 1	;voir directives en tout début du listing
	btfss	VTS_LENTE		;vitesse lente ou moteur arrêté ?
	ENDIF
	goto	N9	;non
	goto	N1	;oui
	
N8	bsf	STOP_RADIO	;pour stopper le MOTEUR
	goto	N3	
	
N9	nop
	if detecte_perio_z == 1
	call	perio_z?	;(c=1 si oui)
	btfss	STOP_ACCRO
	ENDIF
	goto	N5	;non
	goto	N1	;oui	
	
	
;===============================================================================================================
;				DEBUT DES PROCEDURES
;===============================================================================================================

;Teste si  T_PPM est inférieure à 90 ? (c=1 si oui)
PPMzero?	movf	T_PPM,w
	sublw	91	;90-w ; c=0 si neg ; c=1 si pos c.a.d si T_PPM<91
	btfss	STATUS,C	;(c=1 si oui)
	bcf	FREIN_En
	btfsc	STATUS,C	;
	bsf	FREIN_En	
	return		;si oui, c=1 et FREIN_En=1

;===============================================================================================================
;teste si periodeH,L < valeur mini (si accrochage HF) (c=1 si oui)
;RAPPEL: 1 pas de TMR1H,L = 20MHz/4/4 -> 0,8us
;cette routine ne me donne pas satisfaction ! le moteur ne peut pas prendre ses tours !

perio_z?	movlw	periodeH	;adresse de periodeH,L
	call	movxA
	
	mot16B	20	;20*0.8 = 16us ; si la période est < 16us, on positionne 'c'
	call	compar16p	;B-A  c=0 si négatif c.a.d  si  A>B
;	btfsc	STATUS,C	;(c=1 si oui)
;	return	
;	bsf	STOP_ACCRO
	return

;===============================================================================================================
STOP	bsf	STOP_RADIO	;STOP
	bcf	INTCON,3		;bit3 RBIE=0 -> disable INT du port RB4 à RB7 ; Le moteur ne peut redémarrer
				;que par la routine 'demarre', et pas 'à la main'
	call	BLOQUE
	return

;===============================================================================================================
;note: ce test est appelé dans l'int timer0
V_mini?	btfsc	PORTB,3	;PB3=1 si U<6V
	bsf	U_FAIBLE
	btfss	PORTB,3
	bcf	U_FAIBLE
	return

;===============================================================================================================
;REGLAGE DE LA VITESSE (en fait, règlage du rapport cyclique de conduction des MOSFETS,
;ce qui entraine la variation de vitesse)
;calcul d'une fonction AH,L = F(T_PPM)
;fait sauter l'offset
REG_VIT	movf	T_PPM,w
	movwf	memo1
	movlw	95	; w:=95 	T_PPM_G mini 	CETTE VALEUR EST A AJUSTER
	subwf	memo1,f	; f-w(c=0 si negatif)	T_PPM_G:= T_PPM_G - 90 (pré-ofset)
	btfss	STATUS,C	; débordement ?	
	clrf	memo1	;oui	;memo1 n'est  jamais <0
	
;memo1 est donc une fontion directe de T_PPM
;ici memo1 = [0..80]

;offset strictement positif
	movlw	15	;valeur minimale admise
	addwf	memo1,f
;ici memo1 = [15..95]

;-----------------------------------	
;BEC = DETECTION TENSION D'ALIM FAIBLE
	if stop_BEC == 1
	btfss	U_FAIBLE	;U faible ?
	goto	suite2	;non
	movlw	4	;oui, brider vitesse moteur à une valeur fixe, faible, si l'accu est déchargé (BEC)
	movwf	memo1
	bcf	A_FOND	;pour s'assurer que le découpage aura bien lieu
	goto	suite3
	endif

;-----------------------------------
;ARRET DU DECOUPAGE si manche des gaz à fond : pleine puissance.
;cette partie est sautée si le BEC est entré en limitation de vitesse
suite2	movlw	90
	subwf	memo1,w	; f-w(c=0 si negatif donc si memo1<90)	w= memo1 - 90
	btfsc	STATUS,C	;memo1>=90 ?
	bsf	A_FOND	;oui
	
	movlw	85	;cette valeur différente de la précédente imtroduit un hystérésis dans le seuil
	subwf	memo1,w	; f-w(c=0 si negatif donc si memo1<90)	w= memo1 - 85
	btfss	STATUS,C	;memo1>=90 ?
	bcf	A_FOND	;non

;-----------------------------------

suite3	movlw	periodeH	;adresse de periodeH,L
	call	movxA	;AH,L:=periodeH,L
	
;on va borner la valeur obtenue à la valeur max atteinte par TMR1H,L compte tenu de la vitesse de rotation actuelle
;c.a.d de la période actuelle max
;qui est mémorisée dans periodeH,L par l'INT PORTB4-7
;le but est de ne pas découper le signal de sortie à partir d'un instant situé au delà de sa durée maximale !
;REMARQUE: cette durée maximale de la période EN COURS n'est pas connue d'avance ! 
;on prend donc en compte la durée de la période précédente et on suppose que la période en cours
;aura une durée très proche, même si le moteur accélère ou ralentit...
;La méthode a ses limites (en cas de changement brutal du couple mécanique par exemple)
;toutefois, avec comme charge une hélice d'avion, les changements de régime restent progressifs

;Le calcul est le suivant:
;CCPR1H,L = ( memo1 * periodeH,L  )/95
;sachant que 95 représente la valeur max de memo1, lorsque memo1 = memo1_max = 95 on aura:
;CCPR1H,L = 95 * periodeH,L / 95 = periodeH,L
;on obtient donc pour memo1 une valeur [0..periodeH,L]
	
	movlw	-1 * 20	;w=20	;garde
	addwf	AL,f
	btfss	STATUS,C
	decf	AH,f	;ici AH,L:=periodeH,L -20
	
	movf	memo1,w	
	call	multi24	;mutiplication 8 bits x 16 bits de w par AH,L resultat (24bits) dans A2,1,0
;B:=A	
	movf	A0,w
	movwf	Dividende	
	movf	A1,w
	movwf	Dividende+1
	movf	A2,w
	movwf	Dividende+2
;ici Dividende= memo1 * periodeH,L
	movlw	95	;valeur de max de memo1
	call	Div24_8	;Dividende / w -> Quotient (division 24bits par 8 bits résultat sur 24 bits)
	
;------------------------------------------------
;écriture de la valeur dans le registre CCPR1L du module de COMPARAISON du PIC
;fonctionne avec le Timer1
;lorsque 	TMR1H,L (qui mesure le temps depuis l'INT PORB4-7) = CCPR1H,L, une interruption se produit 
;qui découpe le signal de sortie
;RAPPEL: l'INT PORB4-7 se produit quant à elle lors d'un front d'un des trois signaux BEMF
;et détermine 2 actions:
;- RAZ du Timer1 (TMR1H,L:=0)
;- Début de conduction d'une phase

	movf	Quotient,w	
	movwf	CCPR1L
	movf	Quotient+1,w
	movwf	CCPR1H

	return
	
;===============================================================================================================
; SOUS-ROUTINES d'INTERRUPTIONS
;===============================================================================================================
;int timer0
;utilisé en PERIODEMETRE sur le signal PPM du récepteur de radiocommande
;la RAZ du timer0 se fait par l'intportB; en principe le timer0 ne déborde jamais, sauf émetteur sur OFF.

;20MHz/4/64= 78.125kHz (12.8us)
;12.8us*256=3.2768ms (temps max mesurable)
;en fait on doit mesurer une durée [1,1 ... 2,2 ms]

inttimer0	decfsz	count0,f
	goto	fintimer0
	bsf	STOP_RADIO	;STOP MOTEUR pour arrêt si plus de signal de réception
	
fintimer0	call	V_mini?
	return	

;===============================================================================================================
;int timer1
;TMR1H,L est utilisé pour chronometrer la période de l'enveloppe (1 pas moteur) et géré par l'intB4_7
;on passe ici si le moteur est à l'arrêt ou tourne à vitesse très faible <100rpm

;voir prediv =1/4 (voir T1CON))
;20MHz -> 50ns
;20MHz/4/4 -> 0,8us
;THM1H,L peuvent compter 65536 soit: 53 ms
;Le moteur à fond sous 8V -> 10 000 rpm soit 1/(10000 /60 *6) -> 1ms de durée de cycle entre 2 INT PORTB4-7
;Le moteur à 3000 rpm soit 10/3000 = 3,3ms de durée de cycle entre 2 INT PORTB4-7
;Le moteur à  100 rpm soit 10/100 = 100ms de durée de cycle entre 2 INT PORTB4-7 soit presque 104ms (max)
;Donc la limite de la vitesse minimale mesurable est d'environ 200rpm

;10000rpm	->TRM1H,L max:=  1236
;3000	->TRM1H,L max:=  3710
;200	->TRM1H,L max:= 61826


inttimer1 bsf	VTS_LENTE	;vitesse lente ou arret
	
fin_int1	return
	
;===============================================================================================================
;int module COMPARAISON 
;on passe ici lorsque TMR1H,L = CCPR1H,L

intCompar	btfsc	A_FOND
	goto	FinIntCmp
	btfss	DECOU_En
	goto	FinIntCmp	
	call	BLOQUE	;decoupage des signaux de sortie
	
FinIntCmp	return

;===============================================================================================================
;int timer2
;pour découper le signal de sortie à (relativement, 10kHz) haute fréquence lors de la phase de démarrage
;ce timer fonctionne ici suivant 2 alternances consécutives de durées inégales, mais dont la somme est constante


inttimer2	btfss	DECOUP_HF
	goto	fin_int2
	
	btfss	PHASE_HF
	goto	ph0
	goto	ph1
	
ph0	bsf	PHASE_HF
	movf 	rapcycl,w		;ici w=rapcycl
	sublw	.255		;ici w=255-rapcycl
	banksel	PR2
	movwf	PR2
	banksel	AA
	
	call	BLOQUE	;bloque les MOSFETS du port A (pas le moteur!)
	goto	fin_int2
	
ph1	bcf	PHASE_HF
	movf 	rapcycl,w		;ici w=rapcycl
	banksel	PR2
	movwf	PR2
	banksel	AA
	
	call	sortie	;sortie physique des signaux vers les MOSFETS
	goto	fin_int2		

fin_int2	return

;===============================================================================================================
;int Extérieure par bit 0 du port B
;detecte les fronts du signal PPM du récepteur de radio-commande
;mesure et mémorise la durée des impulsions PPM de la voie gaz dans la variable T_PPM 

intB0	btfss	EDGE_PPM	;quel front vient-on de détecter ?
	goto	frontD	;le front descendant
	
frontM	clrf	TMR0	;le front montant. 	RAZ Timer0
	clrf	count0
	banksel	OPTION_REG
	bcf	OPTION_REG,6 ;Interrupt on falling edge of RB0/INT pin (détectera le front descendant)
	banksel	AA	;BANK0
	bcf	EDGE_PPM	;pour éviter une lecture en bank1 au début de cette procédure, on testera ce flag
	return

frontD	movf	TMR0,w	;le timer0 à compté (l'horloge du PIC) depuis le front montant précédent

	if vif == 1	;voir directives en tout début du listing
	movwf	T_PPM	;mémorisation du temps mesuré dans T_PPM, pour utilisation dans le reste du programme
	else
;-----------------------------------------
;on va mémoriser dans T_PPM le temps mesuré, pour utilisation dans le reste du programme
;ici, plutôt qu'une affectation directe et brutale (comme T_PPM:=TMR0), on va procéder
;par comparaison des deux valeurs, et on va faire tendre T_PPM vers TMR0 progressivement
;ceci dans le but d'éliminer les valeurs abérantes qui peuvent se présenter
;ce qui rendait la vitesse de rotation un peu fluctuante autour de certaines valeurs. 

	subwf	T_PPM,w	; f-w(c=0 si negatif)	w:= T_PPM - TMR0 (c=0 si TMR0 > T_PPM)
	btfsc	STATUS,Z
	goto	intB0_1	;si égalité, on ne fait rien
	btfsc	STATUS,C
	decf	T_PPM,f	
	btfss	STATUS,C
	incf	T_PPM,f
	endif
;-----------------------------------------		

intB0_1	nop
	banksel	OPTION_REG
	bsf	OPTION_REG,6 ;(détectera le front montant)
	banksel	AA	;BANK0
	bsf	EDGE_PPM
	clrf	TMR0
	clrf	count0
	return
	
;===============================================================================================================
;int Extérieure par bits 4à7 du port B
;détecte les fronts des 3 signaux de BEMF
;REMARQUE: contrairement à l'intRB0, les INT RB4-7 sont déclenchées par les fronts montants ET descendants
;sans que l'on puisse choisir lequel
;RAPPEL: TMR1H,L est compteur 16 bits du timer1 (voir plus haut l'inttimer1)

intB4_7	movf	TMR1H,w


	if integration_PPM == 1	;voir directives en tout début du listing
	addwf	periodeH,f	;intègre et mémorise la valeur mesurée de la période de rotation
	rrf	periodeH,f	;/2
	;il s'agit donc de la valeur maximale de TMRH,L d'autant plus grande que la vitesse est faible
	movf	TMR1L,w	
	addwf	periodeL,f
	rrf	periodeL,f
	
	else
	movf	TMR1H,w
	movwf	periodeH	;mémorise la valeur mesurée de la période de rotation
	;il s'agit donc de la valeur maximale de TMRH,L d'autant plus grande que la vitesse est faible
	movf	TMR1L,w	
	movwf	periodeL
	endif
		
	clrf	TMR1H	
	clrf	TMR1L	;départ de la mesure suivante

saut2	call	pasMot1 	;prépare l'enveloppe du signal
	call	sortie  
	
	return



;===============================================================================================================
; PROCEDURES de commande moteur
;===============================================================================================================

;cette routine est appelée par l'int ext: intB4_7
;génere l'enveloppe du signal qui sera sorti par l'intimer2 

pasMot1	movlw	HIGH 	Tab_Ph
	movwf	PCLATH

	movf	n_ph,w
	call	Tab_Ph		;retourne la valeur de l'octet dans w
	movwf	signal		;signal pour commande des MOSFETs. sera utilisé par intTimer2

	IF stops == 1		;voir directives en tout début du listing	
	btfsc	STOP_RADIO
	clrf	signal
;	btfsc	STOP_ACCRO
;	clrf	signal		
	ENDIF

	incf	n_ph,f
	movlw	6		;butée max
	subwf	n_ph,w		;w-f(c=0 si negatif)
	btfsc	STATUS,C
	clrf	n_ph
	
	return	

;===============================================================================================================
;bloque électriquement tous les MOSFETS reliés au PORT A (uniquement) sauf pendqnt le freinage moteur	
BLOQUE	btfsc	FREIN_En
	return
	movlw	B'00001010'
	movwf	PORTA
	return	


;===============================================================================================================
;SORTIE PHYSIQUE DES SIGNAUX VERS LES MOSFETS
sortie	nop
	if	frein_permis == 1	;voir directives en tout début du listing
	btfsc	FREIN_En	
	goto	frein
	ENDIF

	movlw	B'00001111'	;bits concernant le  PORT A
	andwf	signal,w		;ne touche pas signal
	xorlw	B'00001010'	;les MOSFETS côté(+) sont pilotés par des transistors inversant la phase
	
	movwf	PORTA
	
	btfss	signal,4	
	bcf	PORTB,1
	btfsc	signal,4
	bsf	PORTB,1
	
	btfss	signal,5
	bsf	PORTB,2		;inverse le bit
	btfsc	signal,5			
	bcf	PORTB,2		;inverse le bit	

	return

frein	bsf	PORTB,2		;bloque Q6 (MOSFET côté(+))
	bsf	PORTB,1		;puis ensuite sature Q5 (MOSFET côté(-))
	movlw	B'00001111'	;sature les transistors côté(-), bloque ceux côté(+) (MOSFETS Q1,2,3,4)
	movwf	PORTA
	return
	
;===============================================================================================================
;demarrage forcé du moteur. On ne passe ici que sur action du manche des GAZ en partant de zéro
; ATTENTION: routine appelée par un goto (N4 dans bcl pincipale) et pas par un call.
; ne se termine donc pas par un return, mais par un goto N5
; permet de gagner un niveau dans de pile, mais surtout permet de retourner ailleurs en cas d'arret d'urgence
	
demarre	bcf	STOP_RADIO
	bcf	VTS_LENTE
	bcf	STOP_ACCRO	
	
	bcf	INTCON,3		;bit3 RBIE=1 -> desable INT du port RB4 à RB7
	bsf	DECOUP_HF		;découpage HF pendant le démarrage forçé

	banksel	PIR1
	bsf	PIR1,TMR2IE	;enable INT Timer2 pour découper les signaux en HF pendant le démarrage
	
	banksel	AA		;BANK0
	bsf	INTCON,GIE	;enable INT's
	
	movlw	20	;20
	movwf	AA
;======================================		
dema1	movlw	4	;8
	movwf	BB
	
	call	PPMzero?		;c=1 si oui
	btfss	STATUS,C
	goto	dema2		;non
	
	bsf	STOP_RADIO	;oui, arret d'urgence et retour
	call	BLOQUE		;moteur en roue libre		
	bcf	DECOUP_HF		;plus de découpage 10kHz
	banksel	PIR1	
	bcf	PIR1,TMR2IE	;disable INT Timer2		
	banksel	AA		;BANK0	
	bsf	DECOU_En		;découpage PWM	
	bsf	INTCON,RBIE	;enable INT du port RB4 à RB7; passe le cycle en mode automatique	
	goto	N8		;VERS boucle principale		
;--------------------------	
dema2	call	pasMot1
	call	sortie
;pendant la phase de démarrage, les signaux sont physiquement sortis par l'int timer2 (qui découpe en HF)

	movlw	2
	addwf	AA,w
	call	Delay_ms		;delai proportionnel à AA +2 donc qui décroit avec AA -> f augmente
	decfsz	BB,f
	goto	dema2		;boucle intérieure courte, BB fois
;--------------------------		
	decfsz	AA,f
	goto	dema1		;boucle extérieure, AA fois
;======================================		
	bsf	DECOU_En		;découpage PWM	
	bsf	INTCON,RBIE	;enable INT du port RB4 à RB7; passe le cycle en mode automatique

	call	BLOQUE		;moteur en roue libre		
	bcf	DECOUP_HF		;plus de découpage 10kHz		
	banksel	PIR1	
	bcf	PIR1,TMR2IE	;disable INT Timer2		
	banksel	AA		;BANK0	

	movlw	128
	movwf	CCPR1L
	movlw	120
	movwf	CCPR1H
		
	movlw	10
	call	Delay_ms

	bcf	STOP_RADIO
	bcf	VTS_LENTE	

	goto	N5	;vers appelant dans la boucle principale


;===============================================================================================================
; ROUTINES MATH
;===============================================================================================================

;conversion sexadécimale -> binaire
;entrée: AA, BB
;resultat: AH,AL = 60*AA+BB

convhbin	movlw	60
	call	multi16	;AA contient la donnée à multiplier
	movf	BB,w
	addwf	AL,f	
	btfsc	STATUS,C
	incf	AH,f
	return

;===============================================================================================================
;mutiplication 8 bits x 8 bits de w par AA (données sur 1 octet)
;d'après note AN526 Microchip
;resultat (sur 2 octets) dans AH,AL (poids fort et poids faible)
;principe: exactement celui de la multiplication faite 'à la main'
;décallages (donc multiplications par le poids de chaque bit) et additions si le bit est un '1'

multi16	clrf	AH	;RAZ de AH qui est ainsi prêt à servir pour réceptionner le résultat (poids fort)
	movwf	AL	;memo temporaire du contenu de w, on a en effet besoin de w à la ligne suivante
	movlw	8	;pour charger une constante dans le compteur de boucle (8 passes)
	movwf	count1	;compteur de passages dans la boucle
	movf	AL,w	;on remet la valeur sauvegardée temporairement dans AL dans w
	clrf	AL	;RAZ de AL qui est ainsi prêt à servir pour réceptionner le résultat (poids faible)
	bcf	STATUS,C	;RAZ carry
loopm16	rrf	AA,f	;lecture d'un bit de AA
	btfsc	STATUS,C
	addwf	AH,f	;si c' est un '1' on ajoute w à AH
	rrf	AH,f	;on décalle AH (poids forts) vers la droite, le bit de droite tombe dans c
	rrf	AL,f	;le bit de droite est récupéré dans AL
	decfsz	count1,f	;compte les passages dans la boucle count1 = 0?
	goto	loopm16	;non, on boucle
	return		;oui, on sort
;===============================================================================================================
;multi24	;mutiplication 8 bits x 16 bits de w par AH,L
;resultat 24bits (sur 3 octets) dans A2,1,0
;principe: exactement celui de la multiplication faite 'à la main'
;décallages (donc multiplications par le poids de chaque bit) et additions si le bit est un '1'
;remarque: CAPACITE MAX: 
;AH,L:=255,255 =65535 = 2^16 -1
;w:=255 =2^8 -1
;w * AH,L := 16711425 = (254,255,1) et pas (255,255,255) 

multi24	clrf	A2	;RAZ de A2 qui est ainsi prêt à servir pour réceptionner le résultat (poids fort)
	clrf	A1	;RAZ de A1 qui est ainsi prêt à servir pour réceptionner le résultat
	movwf	A0	;memo temporaire du contenu de w, on a en effet besoin de w à la ligne suivante
	movlw	16	;pour charger une constante dans le compteur de boucle (16 passes)
	movwf	count1	;compteur de passages dans la boucle
	movf	A0,w	;on remet la valeur sauvegardée temporairement dans AL dans w
	clrf	A0	;RAZ de AL qui est ainsi prêt à servir pour réceptionner le résultat (poids faible)
loopm24	bcf	STATUS,C	;RAZ carry
	rrf	AH,f	;décallage à droite, le bit de droite tombe dans c
	rrf	AL,f	;décallage à droite avec récup du bit ci-dessus, le bit de droite tombe dans c
	btfsc	STATUS,C	;lecture d'un bit de AH,L ; test de ce bit
	addwf	A2,f	;si c' est un '1' on ajoute w à A2
	rrf	A2,f	;on décalle A2 (poids forts) vers la droite, le bit de droite tombe dans c
	rrf	A1,f	;le bit de droite de A2 est récupéré dans A1
	rrf	A0,f	;le bit de droite de A1 est récupéré dans A0
	decfsz	count1,f	;compte les passages dans la boucle count1 = 0?
	goto	loopm24	;non, on boucle
	return		;oui, on sort
;===============================================================================================================
;division d'une valeur codée sur 16 bits (AH,AL) par 2
divi2	bcf	STATUS,C	;RAZ carry
	rrf	AH,f	;le bit de poids faible tombe dans -> c ; le bit de poids fort de AH devient nul
	rrf	AL,f	;le bit de poids faible de AH devient le bit de poids fort de AL
	return


;===============================================================================================================
;division 24 bits par 8 bits
;(auteur I.M.B que je remercie)

Div24_8	movwf	Diviseur
	movlw	24
	movwf	Compteur1
	clrf	Aux+0

	rlf	Dividende+0,f
	rlf	Dividende+1,f
	rlf	Dividende+2,f

Div24_81	rlf	Aux+0,f
	rlf	Aux+1,f
	movf	Diviseur,w
	subwf	Aux,w
		
	btfsc	Aux+1,0
	bsf	STATUS,C
	btfsc	STATUS,C
	movwf	Aux

	rlf	Dividende+0,f
	rlf	Dividende+1,f
	rlf	Dividende+2,f

	decfsz	Compteur1,f
	goto	Div24_81

	return

;===============================================================================================================
;addition 16bits
;(AH,AL)+(BH,BL) -> (AH,AL) 

add16A	movf	BL,w
	addwf	AL,f	;(f+w) -> dest ; c=1 si retenue (à traiter)
	btfsc	STATUS,C
	incf	BH,f	;ajout retenue
	movf	BH,w
	addwf	AH,f	;(f+w) -> dest ; c=1 si retenue
	return

;===============================================================================================================
;addition 16bits
;(AH,AL)+(AH,AL) -> (BH,BL)
;remarque seule la destination (B) est différente par rapport à la procédure add16A
add16B	movf	AL,w
	addwf	BL,f	;(f+w) -> dest ; c=1 si retenue (à traiter)
	btfsc	STATUS,C
	incf	AH,f	;ajout retenue
	movf	AH,w
	addwf	BH,f	;(f+w) -> dest ; c=1 si retenue
	return

;===============================================================================================================
;complément à deux de la variable codée sur 2 octets situés aux adresses w et w+1
cpl16x	movwf	FSR
	comf	INDF,f	;w=complément (H)
	incf	FSR,f
	comf	INDF,f	;w=complément (L)
	incf	INDF,f	;w=complément à 2 de L
	btfss	STATUS,Z
	return	
	decf	FSR,f	;pointe H
	incf	INDF,f	;retenue
	return
;===============================================================================================================
;mov la variable codée sur 2 octets situés aux adresses w et w+1  dans -> AH,AL
;ATTENTION: AL doit etre stocké en RAM à (adresse de AH) +1
movxA	movwf	FSR
	movf	INDF,w
	movwf	AH
	incf	FSR,f
	movf	INDF,w
	movwf	AL
	return	
;===============================================================================================================
;mov AH,AL dans -> la variable codée sur 2 octets situés aux adresses w et w+1
;ATTENTION: AL doit etre stocké en RAM à (adresse de AH) +1  
movAx	movwf	FSR
	movf	AH,w
	movwf	INDF
	incf	FSR,f
	movf	AL,w
	movwf	INDF
	return
;===============================================================================================================
;mov la variable codée sur 2 octets situés aux adresses w et w+1  dans -> BH,BL
;ATTENTION: BL doit etre stocké en RAM à (adresse de BH) +1
movxB	movwf	FSR
	movf	INDF,w
	movwf	BH
	incf	FSR,f
	movf	INDF,w
	movwf	BL
	return	
;===============================================================================================================
;mov BH,BL dans -> la variable codée sur 2 octets situés aux adresses w et w+1
;ATTENTION: BL doit etre stocké en RAM à (adresse de BH) +1  
movBx	movwf	FSR
	movf	BH,w
	movwf	INDF
	incf	FSR,f
	movf	BL,w
	movwf	INDF
	return

;===============================================================================================================
;comparaison de deux valeurs codées sur 16 bits (AH,L à BH,L)
;resultat dans STATUS carry et zéro
;les valeurs doivent représenter des nombres tous deux positifs (pas ok si valeurs codées en complément à 2
;sauf pour le test d'égalité STATUS,Z ('z') ) ;16p-> p comme positifs
;les valeurs des flags c et z qui sont retournées sont les même que celles de l'instruction subwf
;z indiquant l'égalité et c=o si négatif c.a.d si A>B

compar16p	movf	AH,w
	subwf	BH,w	;f-w  c.a.d B-A	c=0 si neg donc si AH>BH
	btfss	STATUS,Z	;z=1 si AH=BH il faut alors comparer AL à BL
	return
	movf	AL,w
	subwf	BL,w	;z=1 si AL=BL et comme on sait déjà que AH=BH, si z=1 -> A=B
	return

;===============================================================================================================
;comparaison de deux valeurs codées sur 24 bits (A2,1,0 à B2,1,0)
;resultat dans STATUS carry et zéro
;les valeurs doivent représenter des nombres tous deux positifs (pas ok si valeurs codées en complément à 2
;sauf pour le test d'égalité STATUS,Z ('z') ) ;16p-> p comme positifs
;les valeurs des flags c et z qui sont retournées sont les même que celles de l'instruction subwf
;z indiquant l'égalité et c=o si négatif c.a.d si A>B


compar24p	movf	A2,w
	subwf	B2,w	;f-w	c=0 si neg donc si AH>BH
	btfss	STATUS,Z	;z=1 si A2=B2 il faut alors comparer A1 à B1
	return
	movf	A1,w
	subwf	B1,w	
	btfss	STATUS,Z	;z=1 si A1=B1 et comme on sait déjà que A2=B2, il faut alors comparer A0 à B0
	return
	movf	A0,w
	subwf	B0,w	;z=1 si A0=B0 et comme on sait déjà que A2,1=B2,1, si z=1 -> A=B
	return



;===============================================================================================================
;DATA EN EEPROM
;===============================================================================================================

	;ORG 0x2100 ; zone EEPROM 

;===============================================================================================================
	end


