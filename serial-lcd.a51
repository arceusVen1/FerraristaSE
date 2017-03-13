;serial connection and lcd display
;tempo d'attente entre recep doit être sur timer 1 afin de pas interférer avec la tempo sur timer 0
;variable LCD--------------------------
RS		bit		P0.5
RW		bit		P0.6
E		bit		P0.7
LCD	equ		P2
busy	bit		P2.7

;variable-------------------------------
texte				data		30h
tampon			equ		34h

;reset----------------------------------
					org		0000h
					ljmp		debut
					
;interruption---------------------------
					org		0003h
printext0:
					push 		psw
					push		acc
					lcall		envoi_message
					pop		acc
					pop 		psw
					reti
				
					org		0023h
printes:
					ljmp		ssprgmes
;programme principale-------------------
					org		0030h
;sous-programme d'interruption----------
ssprgmes:
					clr		ri					;restart reception
					clr		es
					;clr		ex0
					mov		r0,#texte     
					mov		a,sbuf
					clr		acc.7
					mov		@r0,a				;place text to be displayed in the RAM at @30h
					inc		r0
					mov		@r0,#00h
					mov		r0,#texte
					lcall		envoi_message
					setb		es
					reti

;initialisation du LCD------------------
init_lcd:										;lcd fabriqué en chine en série => par garantie on maximise les tempos à l'init
					lcall		tempo          ;attentdre 40ms
					mov		LCD,#38h       ;code initialisation 2 lignes (voir doc)
					lcall		en_lcd_code		
					lcall		tempo
					mov		lcd,#0ch   		;allumer afficheur
					lcall		en_lcd_code
					lcall		tempo
					mov		lcd,#01h			;clear l'écran
					lcall		en_lcd_code
					lcall		tempo
					mov		lcd,#06h
					lcall		en_lcd_code
					lcall		tempo
					mov		lcd,#38h
					lcall		en_lcd_code
					lcall		tempo
					ret
			
;temporisation de 40ms------------------			
tempo:	
					clr 		tr0
					clr		tf0
					mov		th0,#63h			;40ms = 63C0
					mov		tl0,#0c0h      
					setb		tr0				;lancement timer0
attente_tempo:
 					jnb		tf0,attente_tempo
					clr		tr0  				;arreter timer0
					clr		tf0
					ret
				
;enable code/data-----------------------
en_lcd_code:									;but = envoyer les instructions sur P2 et attndre la fin du traitement des données par le lcd (par test_busy_lcd)
					clr		RS
					clr		RW
					clr		E
					setb		E
	         	clr		E
	         	lcall		test_busy_lcd
	         	ret
en_lcd_data:									;but = envoyer les données sur P2 et attendre la fin du traitement des données par le lcd (par test_busy_lcd)
					setb		RS
					clr		RW
					clr		E
					setb		E
					clr		E
					lcall		test_busy_lcd
					ret
test_busy_lcd:
					mov		LCD,#0ffh		;mode lecture du port
					clr		RS
					setb		RW
					setb		E
attente_busy:
					jb			busy,attente_busy
					clr		E
					ret
					
;ecriture sur lignes--------------------
ligne_1:
					push		psw				;sauvegarde du contexte
					push		acc
					mov		LCD,#80h			;se place en ligne 1
	 				lcall		en_lcd_code
					pop		acc
					pop		psw
					ret
ligne_2:
					push		psw
					push		acc
					mov		LCD,#0c0h		;se place en ligne 2
					lcall		en_lcd_code
					pop		acc
					pop		psw
					ret
					
;sous programme d'émission---------------
emi_car:											;emission caractère à la suite jusqu'à zéro
					mov		a,@r0
					cjne		a,#00h,emi_data	;si a= | !> end of message return to beginning
					mov		r0,#texte
					sjmp		fin_emi
;test_chariot:
					;cjne		a,#5ch,emi_data	;si a=/= \ on passe à la ligne
					;inc		r1     				;next line initiated
					;sjmp		fin_emi
emi_data:
					mov		lcd,a
					lcall		en_lcd_data
					lcall		tempo				;par expérience il vaut mieux faire une tempo meme si pas donner par constructeur
					inc 		r0
					sjmp		emi_car
fin_emi:	
					ret
envoi_message:									
					lcall		ligne_1
					lcall		emi_car
					ret
;debut du programme--------------------
debut:			
					mov		tmod,#21h		;timer1 i mode 2 and timer0 in mode 1
					lcall		init_lcd
					mov		r0,#texte      ;put the RAM address of texte in R0
					mov		a,#34h
					mov		@r0,a
					inc		r0
					mov		@r0,#00h
					lcall		envoi_message
					mov		tl1,#0e6h		;for speed, not production value
					mov		th1,#0e6h		;same as above
					;mov		tampon,#34h
					setb		ea	
capture:
					;mov		b,#20h
					;anl		tmod,b			;timer1 in mode2 whithout modifyin timer0mod 
					;mov		pcon,#80h		;doubles speed, not for production
					setb		tr1				;start timer1 for defining speed
					clr		ti
					clr		ri
					setb		es
					mov		scon,#50h		;start reception
;attente:											;wait for end of message signal (0 in ascii=30h)
					;cjne		@r0,#tampon,termine_recep
					;sjmp		attente	
;termine_recep:
					;clr		es
					;mov		scon,#00h		;stop reception/emission
					;clr 		tr1
					;mov		#tampon,@r0
;display:
					;mov		r1,#texte		;R1 must be a usable copy of R0 while R0 will be used for data registering and R& for display
					;lcall		envoi_message
					;setb		P3.2
					;clr		ie0
					;setb		ex0				;int0
					;setb		it0				;front descendant de P3.2
					sjmp		$ 
					end 


