; -------------------------------------------
;			Battleship
; Don MacPhail, Mohammed Khan
;	
;	Sources: 
;		http://programming.msjc.edu/asm/help/index.html?page=source%2Fwinstruct%2Finput_record.htm
;		https://www.csee.umbc.edu/courses/undergraduate/CMSC313/fall04/burt_katz/lectures/Lect01/ASCII.html
;		Irvine text book
;		stackoverflow
;		masm32.com
;	Code inspired by and some procedures adapted from github.com/andrewpryan
;	Don - Programming
;	Mohammed - Documentation & Bug Fixes
;	Assembly @ WIT with Durga Suresh-Menon
;	Summer 2019 (senior year!?)
;	License: None, who cares.  
;	Contact:
;		macphaild@wit.edu
;		khanm@wit.edu


INCLUDE Irvine32.inc
INCLUDE Macros.inc

.386
.stack 4096
ExitProcess proto,dwExitCode:dword

; TODO:
;	- Computer ship placement bugs need to be fixed
;	- Proper collission detection for user ship placement
;	- ASCII art or something cool like that

.data
; Messages displayed to the player that contains instructions on how to play the game.
intro1 BYTE "Welcome to BATTLESHIP!", 13, 10, 0
intro2 BYTE "How to play: ", 13, 10, 0
intro3 BYTE "-- You have five ships: Carrier, Battleship, Submarine, Destroyer, Sweeper.", 13, 10, 0
intro4 BYTE "-- Place a ship on the grid by clicking.", 13, 10, 0
intro5 BYTE "-- Left click: Place the ship vertically.  Right click: Place the ship horizontally.", 13, 10, 0
intro6 BYTE "-- Your goal is to sink all ships on the computer board.", 13, 10, 0
intro7 BYTE "Press any key to continue...", 13, 10, 0

; helpers
numRows BYTE ?	; 41
numCols BYTE ?	; 120
ShipsPlaced BYTE 0	; Increments every time a ship is placed
mouseNum BYTE ?	; 1: Left, 2: Right
currShipSize BYTE ?
currShipChar BYTE ?
currShipHealth BYTE ?
currShip BYTE ?
currOffset DWORD ?
hitBool BYTE 0

intersect BYTE 0

; ship char code and constants
_C_ BYTE 67
_B_ BYTE 66
_U_ BYTE 85
_D_ BYTE 68
_S_ BYTE 73
_EMPTY_ byte 95
COL_MIN BYTE 63
COL_MAX BYTE 81
ROW_MIN BYTE 6
ROW_MAX BYTE 15

; Grid system using characters. Each square is a char.
; one map for player, one map for computer
; each map is a single array
; Total squares:  22 x 11 = 222
; Usable Squares: 10 x 10 = 100
; clicks are registered by capturing x,y position
PlayerMap BYTE "#: A|B|C|D|E|F|G|H|I|J"
	BYTE "0: _|_|_|_|_|_|_|_|_|_"
	BYTE "1: _|_|_|_|_|_|_|_|_|_"
	BYTE "2: _|_|_|_|_|_|_|_|_|_"
	BYTE "3: _|_|_|_|_|_|_|_|_|_"
	BYTE "4: _|_|_|_|_|_|_|_|_|_"
	BYTE "5: _|_|_|_|_|_|_|_|_|_"
	BYTE "6: _|_|_|_|_|_|_|_|_|_"
	BYTE "7: _|_|_|_|_|_|_|_|_|_"
	BYTE "8: _|_|_|_|_|_|_|_|_|_"
	BYTE "9: _|_|_|_|_|_|_|_|_|_",0

; C -- Size 5
; B -- Size 4
; U -- Size 3
; D -- Size 3
; S -- Size 2

; The Ships.
playerHealth BYTE 17
playerCarrierHealth BYTE 5
playerBattleshipHealth BYTE 4
playerSubmarineHealth BYTE 3
playerDestroyerHealth BYTE 3
playerSweeperHealth BYTE 2


; Computer's map/grid.
ComputerMap BYTE "#: A|B|C|D|E|F|G|H|I|J"
	BYTE "0: _|_|_|_|_|_|_|_|_|_"
	BYTE "1: _|_|_|_|_|_|_|_|_|_"
	BYTE "2: _|_|_|_|_|_|_|_|_|_"
	BYTE "3: _|_|_|_|_|_|_|_|_|_"
	BYTE "4: _|_|_|_|_|_|_|_|_|_"
	BYTE "5: _|_|_|_|_|_|_|_|_|_"
	BYTE "6: _|_|_|_|_|_|_|_|_|_"
	BYTE "7: _|_|_|_|_|_|_|_|_|_"
	BYTE "8: _|_|_|_|_|_|_|_|_|_"
	BYTE "9: _|_|_|_|_|_|_|_|_|_",0
; computer stuff
isSunk BYTE 0
; Computer's ships and health value counters
compHealth BYTE 17
compCarrierHealth BYTE 5		
compBshipHealth BYTE 4			
compSubHealth BYTE 3			
compDestroyerHealth BYTE 3		
compSweeperHealth BYTE 2
; Ships arraysm double size 1 byte for row and 1 byte for col
compCarrierArray BYTE 10 DUP (0)
compBshipArray BYTE 8 DUP (0)
compSubArray BYTE 6 DUP (0)
compDestroyerArray BYTE 6 DUP (0)
compSweeperArray BYTE 4 DUP (0)

; Game mechanic/game state messages.
BeginText BYTE "Welcome to BattleShip! Press Enter to begin.", 0
PlayerLabel BYTE "-- YOUR BOARD --", 0
ComputerLabel BYTE "-- THE ENEMY --", 0
PlaceTitle BYTE "Ship Placement", 0
PlaceDirection BYTE "To place a ship, click a coordinate on the map", 0
PlaceVertical BYTE " Left Click = Vertical", 0
PlaceHorizontal BYTE " Right Click = Horizontal", 0
HealthLabel BYTE "Health: ", 0
RemainingLabel BYTE "Ships Remaining: ", 0
CompPlacedAll BYTE "The computer is ready!", 0
; turn messages
playerTurnResult BYTE "Player attack resulted in a ", 0
computerTurnResult BYTE "Computer attack resulted in a ", 0
pTurnNotice BYTE "Your turn!  Choose a grid coordinate", 0
cTurnNotice BYTE "The computer is attacking!", 0
pTurnResult BYTE "Your attack resulted in a ", 0
cTurnResult BYTE "Computer attack resulted in a ", 0
hitResult BYTE "HIT!", 0
missResult BYTE "MISS!", 0
; Types of ships and the spaces they take up.
BattleshipLabel BYTE "BattleShip (size 4)", 0
CarrierLabel BYTE "Carrier (size 5)", 0
SubmarineLabel BYTE "Submarine (size 3)", 0
DestroyerLabel BYTE "Detroyer (size 3)", 0
SweeperLabel BYTE "Sweeper (size 2)", 0
shipToPlace BYTE "[Ship to place]  ", 0
; starting
playerPlacementComplete BYTE "Your ships have been placed, now the computer places ships.", 0
computerPlacementComplete BYTE "The computer is ready!", 0
allShipsPlaced BYTE "All ships have been placed.", 0
; combat
playerShipSunkMsg BYTE "YOU LOST A SHIP!", 0
computerShipSunkMsg BYTE "YOU SUNK ONE OF THEIR SHIPS!", 0
Victory BYTE "You beat him!  Wow!  Awesome that's really amazing considering how buggy ship placement is right now.  Nice job!.", 0
Defeat BYTE "Mission Failed, We'll get 'em next time.", 0
; errors
PlacementError BYTE "Error: Ships cannot overlap. Please try again.", 0

; Macros and Structs
; writes string at x,y pos
mWriteAt MACRO X, Y, literal
	mGotoxy X, Y
	mWriteString literal
ENDM

; sets the text color
mSetTextColor MACRO color
	push eax
	mov eax, color
	call SetTextColor
	pop eax
ENDM

; insert delay for ui and gameplay stuff
mPause MACRO timeMs
	push eax
	mov eax, timeMs
	call Delay
	pop eax
ENDM

; writes text + '\n'
mWriteLn MACRO text
	mWriteString text
	call Crlf
ENDM

; writes a single char
mWriteChar MACRO charCode
	push eax
	mov eax, charChode
	call WriteChar
	pop eax
ENDM

; Compare ship health to 0
; NOTE: dont mess with ecx when check ship health
; returns ecx
mCheckShip MACRO hp
	.IF hp == 0
		dec ecx
	.ENDIF
ENDM

; modify state variable 
mCheckSunk MACRO shipHp
	.IF shipHp == 0
		mov isSunk, 1
	.ENDIF
ENDM

; https://msdn.microsoft.com/en-us/windows/desktop/ms683499
_INPUT_RECORD STRUCT
	EventType WORD ?
	WORD ?		; padding to align union
	UNION
		KeyEvent KEY_EVENT_RECORD <>		; contains KEY_EVENT_RECORD struct
		MouseEvent MOUSE_EVENT_RECORD <>	; contains MOUSE_EVENT_RECORD struct
	ENDS
_INPUT_RECORD ENDS


; Variables for mouse, winAPI stuff
ROW_COORD WORD ?
COL_COORD WORD ?
MAP_INDEX DWORD ?
InputRecord _INPUT_RECORD <>
ConsoleMode DWORD 0
hStdln DWORD 0
nRead DWORD 0

; ***************** Code *************************
.code
main proc	
	call Init
	call Intro
	call DrawMap
	call PrintBottomText
	call PlacePlayerShips
	call PlaceComputerShips
	GameLoop:
		call PlayerTurn
		call ComputerTurn
		; compare hhealth to 0
		mov eax, 0
		cmp al, compHealth
		je PlayerWin

		cmp al, playerHealth
		je ComputerWin
		jmp AnotherTurn

		PlayerWin:
		call PlayerWin
		jmp GameOver
	
		ComputerWin:
		call ComputerWin
		jmp GameOver
	
		AnotherTurn:
	jmp GameLoop
	
	GameOver:
INVOKE ExitProcess, 0
main endp

; Computer Wins screen
ComputerWin PROC
	call Clrscr
	mSetTextColor lightRed
	mWriteAt 15, 15, Defeat
	call ReadChar
	ret
ComputerWin ENDP

; Player Wins screen
PlayerWin PROC
	call Clrscr
	mSetTextColor lightGreen
	mWriteAt 15, 15, Victory
	call ReadChar
	ret
PlayerWin ENDP

; Sets some important values
Init PROC
	call Randomize
	call GetMaxXY
	mov numRows, al
	mov numCols, dl
	ret
Init ENDP

; Introduction screen
; Displays the rules of the game, waits for user input
Intro PROC
	mSetTextColor lightMagenta
	mWriteAt 20, 6, intro1
	mWriteAt 3, 7, intro2
	mWriteAt 3, 8, intro3
	mWriteAt 3, 8, intro4
	mWriteAt 3, 9, intro5
	mWriteAt 3, 10, intro6
	call Crlf
	call Crlf
	mWriteAt 3, 11, intro7

	;call WaitMsg
	
	mSetTextColor white
	call ReadChar
	call Clrscr
	ret ; dont forget ret, or youll spend an hour debugging nothing
Intro ENDP

; Notifies player turn, waits for mouse click
PlayerTurn PROC
	call ClearDirections
	
	mWriteAt 20, 23, pTurnNotice

	mPause 1000
	; get mouse info
	call GetMouseLoc
	call ConvertRowCoord
	call ConvertColCoord

	call CheckAttkPlayer
	; redraw map
	call DrawMap
	call PrintBottomText
	mPause 1000
	ret
PlayerTurn ENDP

; Generates a player and computer grid/board.
; map is redrawn after each ship placed & each turn
DrawMap PROC
	mov esi, 0
	mov esi, OFFSET PlayerMap ; esi points to start of the player board array

	mGotoxy 20, 5		; initial cursor psition
	mSetTextColor cyan	; player board color

	; Prints the A-F header
	mov ecx, 22
	PrintTopRow:
		mov eax, [esi]
		call WriteChar
		inc esi
	loop PrintTopRow

	mov dl, 20		; ROW ---> save this value
	mov dh, 6		; COL ---> save this value
	call GoToXY
	;mGotoxy 10, 6

	mov ecx, 10
	CreatePlayerMap:
		push ecx			; save ecx for later (10 playable squares)
		mov ecx, 22			; use 22 for total squares

		ChooseChar:
		mov al, [esi]	; use the contents of esi to check what to draw
		cmp al, 'O'		; Compare to 'O'
		jne CheckPlayerHit
		mSetTextColor white
		mov eax, 'O'		; Write 'O'
		call WriteChar
		jmp PlayerCharPlaced

		CheckPlayerHit:
		cmp al, 'X'			; Compare to 'X'
		jne CheckCarrier
		mov eax, lightRed	; then it's a hit
		call SetTextColor
		mov eax, 'X'
		call WriteChar
		jmp PlayerCharPlaced

		; Compare to 'C' then it's a carrier
		CheckCarrier:
		cmp al, 'C'
		jne CheckBattleship
		mov eax, white + (blue * 16)
		call SetTextColor
		mov eax, 'C'
		call WriteChar
		jmp PlayerCharPlaced

		; Compare to 'B' for b-ship
		CheckBattleship:
		cmp al, 'B'
		jne CheckSubmarine
		mov eax, white + (blue * 16)
		call SetTextColor
		mov eax, 'B'
		call WriteChar
		jmp PlayerCharPlaced

		; compare al to 'U'
		CheckSubmarine:
		cmp al, 'U'
		jne CheckDestroyer
		mov eax, white + (blue * 16)
		call SetTextColor
		mov eax, 'U'
		call WriteChar
		jmp PlayerCharPlaced

		; cmp al to 'D'
		CheckDestroyer:
		cmp al, 'D'
		jne CheckSweeper
		mov eax, white + (blue * 16)
		call SetTextColor
		mov eax, 'D'
		call WriteChar
		jmp PlayerCharPlaced
		
		; compare al to "S'
		CheckSweeper:
		cmp al, 'S'
		jne PrintPlayerMapCharacter
		mov eax, white + (blue * 16)
		call SetTextColor
		mov eax, 'S'
		call WriteChar
		jmp PlayerCharPlaced

		; if none of above then write contents of esi
		PrintPlayerMapCharacter:
		mSetTextColor cyan
		mov eax, [esi]
		call WriteChar

		; jmp here if above condition succeeds
		PlayerCharPlaced:
		inc esi
		cmp ecx, 0	; loop from 10 --> 0
		je PlayerRowComplete
		dec ecx
		jne ChooseChar

	PlayerRowComplete:
	pop ecx		; Restore ecx = 22
	inc dh		; Next row (for gotoxy)
	call GoToXY
	;call Crlf

	cmp ecx, 0
	dec ecx
	jne CreatePlayerMap

	; ************* Computer map ****************
	mov edi, 0
	mov edi, OFFSET ComputerMap ; edi points to the viewable computer board

	mov dl, 60
	mov dh, 5
	call GoToXY
	mGotoxy 60, 5

	mov ecx, 11		; Outer loop counter = 11
	CreateComputerBoard:
		; save ecx
		push ecx	; inner loop counter = 22
		mov ecx, 22
		PrintComputerRow:
		mov al, [edi]
		; Missed Character 'O'
		cmp al, 'O'
		jne CheckComputerHit
		mSetTextColor white
		mov eax, 'O'
		call WriteChar
		jmp CompCharPlaced

		; check for 'X'
		CheckComputerHit:
		cmp al, 'X'
		jne PrintComputerMapCharacter
		mSetTextColor lightRed
		mov eax, 'X'
		call WriteChar
		jmp CompCharPlaced

		; otw just printchar from array (hidden from player view)
		PrintComputerMapCharacter:
		mSetTextColor yellow
		mov eax, [edi]
		call WriteChar

		CompCharPlaced:
		inc edi
		loop PrintComputerRow
		pop ecx		; restore ecx after inner loop
		inc dh		; Next row
		call GoToXY
		;call Crlf
	loop CreateComputerBoard
	mSetTextColor white
	ret
DrawMap ENDP


; Print UI Info/Stats --- Gets printed below the boards
; Health & num ships remaining
PrintBottomText PROC
	; top of board labels
	mWriteAt 22, 3, PlayerLabel
	mWriteAt 66, 3, ComputerLabel

	; player health
	mWriteAt 20, 19, HealthLabel	
	movzx eax, playerHealth
	call WriteInt

	; computer health
	mWriteAt 60, 19, HealthLabel
	movzx eax, compHealth
	call WriteInt

	; player ships remaining msg
	mWriteAt 20, 20, RemainingLabel
	call CalcShipsRemaining	; al=player count bl=comp count
	call WriteDec

	; computer ships remaining msg
	mWriteAt 60, 20, RemainingLabel
	mov al, bl
	call WriteDec
	
	mSetTextColor white
	ret
PrintBottomText ENDP

; Compares ship health variables to 0
; sinks player ships at 0
; returns	eax: player ships remaining
;			ebx: comp ships remaining
CalcShipsRemaining PROC USES ecx
	mov eax, 0
	mov ebx, 0
	mov ecx, 5		; num ships
	; c gets decremented for each missing
	mCheckShip playerCarrierHealth
	mCheckShip playerBattleshipHealth
	mCheckShip playerSubmarineHealth
	mCheckShip playerDestroyerHealth
	mCheckShip playerSweeperHealth
	mov eax, ecx

	mov ecx, 5
	mCheckShip compCarrierHealth
	mCheckShip compBshipHealth
	mCheckShip compSubHealth
	mCheckShip compDestroyerHealth
	mCheckShip compSweeperHealth
	mov ebx, ecx
	ret
CalcShipsRemaining ENDP


; ***********************************************************************************
;		Ship Placement
; ***********************************************************************************


; Places all the player ships on the map. Each ship is placed using separate procedures.
; Displays proper directions to the player.
; TODO: A lot of repetitive code here, may be able to simplify
;	A single method and pass the ship as a param?
PlacePlayerShips PROC
	mov eax, 0
	mov ebx, 0
	call PrintShipInstructions
	mWriteString CarrierLabel
	
	; carrier
	mov currShipSize, 5	; length of ship
	mov currShipChar, 'C'
	call PlaceShip
	call ClearDirections

	; b-ship
	call PrintShipInstructions
	mWriteString BattleshipLabel
	mov currShipSize, 4
	mov currShipChar, 'B'
	call PlaceShip
	call ClearDirections

	; sub
	call PrintShipInstructions
	mWriteString SubmarineLabel
	mov currShipSize, 3
	mov currShipChar, 'U'
	call PlaceShip
	call ClearDirections

	; destroyer
	call PrintShipInstructions
	mWriteString DestroyerLabel
	mov currShipSize, 3
	mov currShipChar, 'D'
	call PlaceShip
	call ClearDirections
	
	; sweeper
	call PrintShipInstructions
	mWriteString SweeperLabel
	mov currShipSize, 2
	mov currShipChar, 'S'
	call PlaceShip
	call ClearDirections

	;AllShipsPlaced
	mGotoxy 20, 23
	mWriteString playerPlacementComplete
	mPause 3000

	call ClearDirections
	ret
PlacePlayerShips ENDP

; Places a ship on the map based off user click
; Left click --> place vertical
; Right click --> horizontal
; TODO: fix collision detection
PlaceShip PROC
RetryThis:	; restart on error	
	call GetMouseLoc	;store 1 or 2 in mouesNum
	call ConvertRowCoord
	call ConvertColCoord

	mov edi, OFFSET PlayerMap
	add edi, MAP_INDEX

	cmp mouseNum, 1	; Left click
	je ItsVertical

	cmp mouseNum, 2	; right click
	je ItsHorizontal

	; vertical
	ItsVertical:	
	;call DetectVertical
	cmp edx, 0
	je RetryThis
	movzx ecx, currShipSize
	mov al, currShipChar
	Luigi:
		mov [edi], al
		add edi, 22
	loop Luigi

	jmp BonVoyage

	; horizontal
	ItsHorizontal:
	;call DetectHorizontal
	cmp edx, 0
	je RetryThis
	movzx ecx, currShipSize
	mov al, currShipChar
	Mario:
		mov [edi], al
		add edi, 2
	loop Mario

	; ships placed
	BonVoyage:
	mov eax, 0
	mov al, ShipsPlaced
	inc al
	mov ShipsPlaced, al

	call DrawMap
	call PrintBottomText
	ret
PlaceShip ENDP

; Main function to place each ship
; saves current values and calls PlaceCompShip
PlaceComputerShips PROC
	mov esi, OFFSET compCarrierArray
	movzx ecx, compCarrierHealth
	mov currShipHealth, cl	; save it
	mov currOffset, esi
	call PlaceCompShip

	mov esi, OFFSET compBshipArray
	movzx ecx, compBshipHealth
	mov currShipHealth, cl	; save it
	mov currOffset, esi
	call PlaceCompShip

	mov esi, OFFSET compSubArray
	movzx ecx, compSubHealth
	mov currShipHealth, cl	; save it
	mov currOffset, esi
	call PlaceCompShip

	mov esi, OFFSET compDestroyerArray
	movzx ecx, compDestroyerHealth
	mov currShipHealth, cl	; save it
	mov currOffset, esi
	call PlaceCompShip

	mov esi, OFFSET compSweeperArray
	movzx ecx, compSweeperHealth
	mov currShipHealth, cl	; save it
	mov currOffset, esi
	call PlaceCompShip

	; all done
	mWriteAt 20, 23, computerPlacementComplete
	mPause 3000
	call ClearDirections
	ret
PlaceComputerShips ENDP

; generic place ship proc
; Recieves: currShipSize and currOffset
; Returns: Arrays filled with valid coordinates
PlaceCompShip PROC
RetryThis:		; restart on error
	mov lowerBound, 1
	mov upperBound, 2
	call BoundedRandomNum
	cmp al, 1
	je  RandV

	; horizontal
	mov esi, currOffset
	inc esi
	call GetCoordsH	; start position
	movzx ecx, currShipHealth
	dec ecx
	call FillArrayH	; rest of array
	jmp CheckColl

	RandV:
	mov esi, currOffset
	call GetCoordsV	; start
	movzx ecx, currShipHealth
	dec ecx
	call FillArrayV	; rest of it

	CheckColl:
	mov esi, currOffset
	movzx ecx, currShipHealth
	call CheckRandomCollision
	cmp intersect, 1
	jne RetryThis

	ret
PlaceCompShip ENDP


; ***********************************************************************************
;		Hit/Miss Detection
; ***********************************************************************************

; compares mouse coords to ship locations
CheckAttkPlayer PROC
	mov hitBool, 0
	;mov esi, OFFSET compCarrierArray
	mov currOffset, OFFSET compCarrierArray
	movzx ecx, compCarrierHealth
	mov currShipHealth, cl		; save for proc call
	mov currShipSize, 5
	call ConfirmRowCols
	movzx ecx, currShipHealth		; updated health
	mov compCarrierHealth, cl
	cmp hitBool, 1
	je YouGotEm
	; else check nxt ship

	; battleship
	;mov esi, OFFSET compBshipArray	
	mov currOffset, OFFSET compBshipArray
	movzx ecx, compBshipHealth
	mov currShipHealth, cl
	mov currShipSize, 4
	call ConfirmRowCols
	movzx ecx, currShipHealth
	mov compBshipHealth, cl
	cmp hitBool, 1
	je YouGotEm

	; destroyer
	;mov esi, OFFSET compDestroyerArray	
	mov currOffset, OFFSET compDestroyerArray
	movzx ecx, compDestroyerHealth
	mov currShipHealth, cl
	;mov ecx, 3
	mov currShipSize, 3
	call ConfirmRowCols
	movzx ecx, currShipHealth
	mov compDestroyerHealth, cl
	cmp hitBool, 1
	je YouGotEm

	; submarine
	;mov esi, OFFSET compSubArray	
	mov currOffset, OFFSET compSubArray
	movzx ecx, compSubHealth
	mov currShipHealth, cl
	;mov ecx, 3
	mov currShipSize, 3
	call ConfirmRowCols
	movzx ecx, currShipHealth
	mov compSubHealth, cl
	cmp hitBool, 1
	je YouGotEm

	; sweeperino
	;mov esi, OFFSET compSweeperArray
	mov currOffset, OFFSET compSweeperArray
	movzx ecx, compSweeperHealth
	mov currShipHealth, cl
	;mov ecx, 2
	mov currShipSize, 2
	call ConfirmRowCols
	movzx ecx, currShipHealth
	mov compSweeperHealth, cl
	cmp hitBool, 1
	je YouGotEm
	jne YouMissed

	YouMissed:
	call LogMiss

YouGotEm:
	ret
CheckAttkPlayer ENDP

; recevies 
;		esi: ship array
;		ecx: ship size
ConfirmRowCols PROC USES eax ebx edx
; mouse coords updated in PlayerTurn proc
	mov esi, currOffset
	movzx ecx, currShipSize
	mov ax, ROW_COORD
	mov bx, COL_COORD
	CheckRow:
	cmp [esi], al	; exception thrown here
	je CheckCol
	jmp NextPlace

	CheckCol:
	inc esi
	cmp [esi], bl	; col coord (exception here now)
	je BigHit
	dec esi
	jmp NextPlace

	BigHit:
	mov hitBool, 1	; return this value on hit
	mov dl, currShipHealth
	dec dl
	mov currShipHealth, dl
	cmp currShipHealth, 0	; is it dead?
	je ShipSunk
	jmp JustAHit

	ShipSunk:
	call ComputerShipSunk
	jmp JustAHit

	NextPlace:
	dec ecx
	cmp ecx, 0	; if eq 0, return
	je AllDone
	add esi, 2	; else adjust ptr
	jmp CheckRow

	JustAHit:
	call LogHit

AllDone:
	ret
ConfirmRowCols ENDP

; places red 'X' on grid square of hit
LogHit PROC USES eax ebx
	; change health values
	mov eax, 0
	mov al, compHealth	; total health value (starts at 17)
	dec al
	mov compHealth, al
	; adjust map pointer
	mov edi, OFFSET ComputerMap
	add edi, MAP_INDEX
	sub edi, 40
	; update map square
	mov bl, 'X'
	mov [edi], bl

	; write output
	mWriteAt 20, 25, clearLine
	mWriteAt 20, 25, pTurnResult	;label
	mSetTextColor lightRed
	mWriteString hitResult			; hit
	mSetTextColor white
	ret
LogHit ENDP


; Prints white O in spot of the miss.
; Notifies user their click was a miss.
LogMiss PROC USES edi ebx
	mov edi, OFFSET ComputerMap
	add edi, MAP_INDEX
	sub edi, 40
	mov bl, 'O'
	mov [edi], bl

	mWriteAt 20, 25, clearLine
	mWriteAt 20, 25, pTurnResult	; label
	mSetTextColor cyan
	mWriteString missResult			; miss
	mSetTextColor white

	ret
LogMiss ENDP

; Clears screen and notifies player a ship was sunk
PlayerShipSunk PROC
	call Clrscr
	mSetTextColor red
	mWriteAt 30, 20, playerShipSunkMsg
	mSetTextColor white
	mPause 3000
	call Clrscr
	call DrawMap
	call PrintBottomText
	ret
PlayerShipSunk ENDP

; Clears screen and notifies player a ship was sunk
ComputerShipSunk PROC USES eax
	call Clrscr
	mSetTextColor lightMagenta
	mWriteAt 25, 10, computerShipSunkMsg
	mSetTextColor white
	mPause 3000
	call Clrscr
	call DrawMap
	call PrintBottomText
	ret
ComputerShipSunk ENDP

; Notifies user it is the computers turn.
; generates a random point to attack
; Checks if turn was hit or miss and updates the map accordingly.


ComputerTurn PROC
	mSetTextColor lightRed
	mWriteAt 20, 23, clearLine
	mWriteAt 20, 24, clearLine
	mWriteAt 20, 25, clearLine
	mWriteAt 20, 23, cTurnNotice
	mSetTextColor white
	mPause 3000

	start:
	; initialize values
	mov lowerbound, 6
	mov upperbound, 15
	call BoundedRandomNum	; random num in eax
	; simulate computer mouse click
	mov ROW_COORD, ax	
	mov lowerbound, 23
	mov upperbound, 41
	call GetRandomOdd
	mov COL_COORD, ax

	; convert to board coords
	call ConvertRowCoord
	call ConvertColCoord

	mov edi, OFFSET PlayerMap
	add edi, MAP_INDEX

	mov al, '_'
	cmp al, [edi]
	je cMiss

	mov al, 'O'
	cmp al, [edi]
	je Start	; retry, not a valid shot

	mov al, 'X'
	cmp al, [edi]
	je Start	; retru

	cHit:
	call CheckComputerTurnHit
	mWriteAt 20, 25, clearLine
	mWriteAt 20, 25, cTurnResult
	mSetTextColor lightRed
	mWriteSpace 1
	mWriteString hitResult
	mSetTextColor white

	mov al, 'X'
	mov [edi], al

	jmp redraw

	cMiss:
	skip:
	mWriteAt 20, 25, clearLine
	mWriteAt 20, 25, cTurnResult
	mSetTextColor cyan
	mWriteSpace 1
	mWriteString missResult
	mSetTextColor white
	mov al, 'O'
	mov [edi], al

	redraw:
	call DrawMap
	call PrintBottomText

	; if ship sunk call proc
	cmp isSunk, 1
	; else return
	jne return
	call PlayerShipSunk
	mov isSunk, 0

	return:
	mPause 1000
	ret
ComputerTurn ENDP


; Call this when hit is confirmed to check what ship was hit.
; compare location to map ascii
; Recieves: Pointer to coordinate on the map (EDI).
CheckComputerTurnHit PROC USES edx ebx eax
	mov dh, 0

	; if battleship, check bship hp
	mov bl, 'B'
	cmp [edi], bl
	je HitB

	; if carrier, check carrier hp
	mov bl, 'C'
	cmp [edi], bl
	je HitC

	mov bl, 'D'
	cmp [edi], bl
	je HitD

	mov bl, 'U'
	cmp [edi], bl
	je HitU

	; else hit a sweeper
	mov al, PlayerSweeperHealth
	dec al
	mCheckSunk PlayerSweeperHealth
	jmp Return

	HitB:
	mov al, PlayerBattleshipHealth
	dec al
	mov PlayerBattleshipHealth, al
	mCheckSunk PlayerBattleshipHealth
	jmp Return

	HitC:
	mov al, PlayerCarrierHealth
	dec al
	mov PlayerCarrierHealth, al
	mCheckSunk PlayerCarrierHealth
	jmp Return

	HitD:
	mov al, PlayerDestroyerHealth
	dec al
	mov PlayerDestroyerHealth, al
	mCheckSunk PlayerDestroyerHealth
	jmp Return

	HitU:
	mov al, PlayerSubmarineHealth
	dec al
	mov PlayerSubmarineHealth, al
	mCheckSunk PlayerSubmarineHealth
	jmp Return

	Return:
	mov al, PlayerHealth
	dec al
	mov PlayerHealth, al
	ret
CheckComputerTurnHit ENDP


; ***********************************************************************************
;		Helper Functions
; ***********************************************************************************

.data
savedLocation DWORD ?
upperBound DWORD ?
lowerBound DWORD ?
clearLine BYTE "                                                                                                  ", 0
savedShiphealth BYTE ?
currentCol BYTE ?
currentRow BYTE ?

.code

; Clears the lower area in the UI for displaying directions
; Helps keep the direction section of the UI clean and readable
; otherwise chars get written on top of chars until it's a mess
ClearDirections PROC
	; overwrite chars at these positions with blank line
	;mWriteAt 20, 22, clearLine
	;mWriteAt 20, 22, clearLine
	mWriteAt 10, 23, clearLine
	mWriteAt 10, 24, clearLine
	mWriteAt 10, 25, clearLine
	mWriteAt 10, 26, clearLine
	mWriteAt 10, 27, clearLine
	mWriteAt 10, 28, clearLine
	mWriteAt 10, 29, clearLine
	mWriteAt 10, 30, clearLine
	;mov edx, 0
	;call GoToXY
	ret
ClearDirections ENDP

; Produces a random int with lower and upper bound.
; Receives: upperBound, lowerBound.
; Returns: eax
; RandomRange: receives max in eax, returns random in eax
BoundedRandomNum PROC USES ebx
	mov ebx, lowerBound
	mov eax, upperBound
	sub eax, ebx
	inc eax
	call RandomRange
	add eax, ebx
	ret
BoundedRandomNum ENDP

; uses random range to get an odd number
; bounded by upper and lower
; receives upper/lower bound
; returns eax
; RandomRange: receives max in eax, returns random in eax
GetRandomOdd PROC USES ebx
	mov ebx, lowerbound
	mov eax, upperbound
	sub eax, ebx
	inc eax
	call RandomRange
	add eax, ebx
	mov edx, eax
	mov bl, 2
	div bl
	cmp ah, 0
	jne Found
	cmp edx, upperbound
	je decrement
	inc edx
	jmp Found

	decrement:
	dec edx

	Found:
	mov eax, edx
	ret
GetRandomOdd endp

; Bounds = mapLen - shipSize
; receives ship array @ esi
; dl: length of ship
GetCoordsH PROC USES ebx
	; set up the bounds
	mov bh, COL_MAX
	sub bh, currShipSize	; subtract length of ship from max col
	movzx ebx, bh		; save that number in ebx
	mov upperbound, ebx	; save it as upperbound
	movzx ebx, COL_MIN	; use col-min to find random num
	mov lowerbound, ebx
	call GetRandomOdd	; random odd number now in eax
	mov currentCol, al	; save as current col
	mov [esi], al		; move into the ship array
	dec esi				; adjust pointer

	movzx ebx, ROW_MAX
	mov upperbound, ebx
	movzx ebx, ROW_MIN
	mov lowerbound, ebx
	call BoundedRandomNum
	mov currentRow, al
	mov [esi], al
	inc esi

	ret
GetCoordsH ENDP

; Bounds = mapHeight - shipLen
; Picks a random column coordinate.
; Recieves: ship to be filled @ esi
GetCoordsV PROC USES ebx
	mov bh, ROW_MAX
	sub bh, dl
	movzx ebx, bh
	mov upperbound, ebx
	movzx ebx, ROW_MIN
	mov lowerbound, ebx
	call BoundedRandomNum
	mov currentRow, al
	mov [esi], al
	inc esi
	movzx ebx, COL_MAX
	mov upperbound, ebx
	movzx ebx, COL_MIN
	mov lowerbound, ebx
	call GetRandomOdd
	mov currentCol, al
	mov [esi], al

	ret
GetCoordsV ENDP

; Fills vertical @ esi
; start point chosen by getcoordsV proc.
FillArrayV PROC USES edx
	; current map position
	mov dh, currentRow
	mov dl, currentCol
	; loop through len of ship
	Lisa:
		inc esi
		inc dh
		mov [esi], dh
		inc esi
		mov [esi], dl
	loop Lisa

ret
FillArrayV ENDP

; Fills horizontal array @ esi
; start point chosen by getcoordsH proc.
FillArrayH PROC USES edx
	; current board position
	mov dh, currentRow
	mov dl, currentCol
	; loop through length of ship
	Doug:
		inc esi
		add dl, 2
		mov [esi], dh
		inc esi
		mov [esi], dl
	loop Doug
ret
FillArrayH ENDP

; checks against all ships
; if there is a collision it returns 1 in intersection variable
CheckRandomCollision PROC
	mov intersect, 0
	mov ebx, esi
	mov edx, ecx
	; check once for each ship
	mov savedLocation, OFFSET compCarrierArray
	movzx eax, compCarrierHealth
	mov savedShipHealth, al
	call CheckShipCollision
	add intersect, al

	mov esi, ebx
	mov ecx, edx
	mov savedLocation, OFFSET compBshipArray
	movzx eax, compBshipHealth
	mov savedShipHealth, al
	call CheckShipCollision
	add intersect, al

	mov esi, ebx
	mov ecx, edx
	mov savedLocation, OFFSET compSubArray
	movzx eax, compSubHealth
	mov savedShipHealth, al
	call CheckShipCollision
	add intersect, al


	mov esi, ebx
	mov ecx, edx
	mov savedLocation, OFFSET compDestroyerArray
	movzx eax, compDestroyerHealth
	mov savedShipHealth, al
	call CheckShipCollision
	add intersect, al

	return:
	ret
CheckRandomCollision ENDP

; Double Loop to check if any point in the two ship arrays match
; Recieves: Pointers to both ships (ESI, EDI) Health of each ship (ECX, currentshiphealth)
; TODO: fix esi index location, or comparisons.  need more time
CheckShipCollision PROC uses EBX EDX
	mov al, 0
	LoopOuter:
		mov bh, [esi]
		inc esi
		mov bl, [esi]
		inc esi
		push ecx
		mov edi, savedLocation
		movzx ecx, savedShipHealth
		LoopInner:
			mov dh, [edi]
			inc edi
			mov dl, [edi]
			inc edi
			cmp dh, bh
			jne next
			cmp dl, bl
			jne next
			inc al

			next:
			loop LoopInner
		pop ecx
		cmp al, 1
		je return
		loop LoopOuter

	return:
	ret
CheckShipCollision ENDP

; prints instructions at bottom of screen
PrintShipInstructions PROC
	mSetTextColor gray
	mWriteAt 20, 25, shipToPlace
	mSetTextColor white
	ret
PrintShipInstructions ENDP

GetMouseAlt PROC
	; nevermind
	ret
GetMouseAlt ENDP


;  X = Row Coordinate, Y = Column Coordinate
; Returns row in bx, col in ax
; Uses InputRecord struct to compare
; Updates ROW_COORD and COL_COORD
GetMouseLoc PROC USES edx ebx eax
	; get handles and console info from Irvine libraries
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	mov hStdln, eax
	INVOKE GetConsoleMode, hStdln, ADDR ConsoleMode
	mov eax, 0090h	; = enable_mouse_input
	INVOKE SetConsoleMode, hStdln, eax

	Begin:
	INVOKE ReadConsoleInput, hStdln, ADDR InputRecord, 1, ADDR nRead
	movzx eax, InputRecord.EventType
	jne skip
	cmp InputRecord.MouseEvent.dwButtonState, 2
	je HandleRightClick
	cmp InputRecord.MouseEvent.dwButtonState, 1
	jne skip
	je HandleLeftClick

	; http://programming.msjc.edu/asm/help/index.html?page=source%2Fwin32lib%2Fwriteconsoleoutputcharacter.htm
	; Note: mouseEvent struct contains dwMousePosition which is a COORD struct
	;		Use this to get x and y positions of mouse
	HandleLeftClick:
	mov ax, InputRecord.MouseEvent.dwMousePosition.X
	mov dx, 0
	mov bx, 2
	div bx
	cmp dx, 0
	je skip
	mov ax, InputRecord.MouseEvent.dwMousePosition.X
	mov bx, InputRecord.MouseEvent.dwMousePosition.Y
	mov mouseNum, 1
	mov ROW_COORD, bx
	mov COL_COORD, ax
	jmp Complete

	HandleRightClick:
	mov ax, InputRecord.MouseEvent.dwMousePosition.X
	mov dx, 0
	mov bx, 2
	div bx
	cmp dx, 0
	je skip
	mov ax, InputRecord.MouseEvent.dwMousePosition.X
	mov bx, InputRecord.MouseEvent.dwMousePosition.Y
	mov mouseNum, 2
	mov ROW_COORD, bx
	mov COL_COORD, ax
	jmp Complete

	skip:	; do not register click, try again
	cmp ecx, 0
	jne Begin

	Complete:
	ret
GetMouseLoc ENDP

; Makes X-coordinate from mouse click to be compatible with battleship map.
;	Returns: Updated map index
ConvertRowCoord PROC USES eax ebx
	mov eax, 0
	mov eax, 25	; A1 in Map
	mov bx, 6	; Starting X-Row coordinate in console

	SeekRow:
		cmp bx, ROW_COORD
		je RowFound
		add eax, 22
		inc bx
	jmp SeekRow

	RowFound:
	mov MAP_INDEX, eax
	ret
ConvertRowCoord ENDP


; Makes Y-coordinate from mouse click to be compatible with the battleship map.
;	Returns: Updated MAP_INDEX
ConvertColCoord PROC USES eax ebx
	mov eax, MAP_INDEX	; Starting from where we are in the row of the map
	mov bx, 23			; Starting coordinate for A-column

	SeekColumn:
		cmp bx, COL_COORD
		je ColumnFound
		add ebx, 2
		add eax, 2
	jmp SeekColumn

	ColumnFound:
	mov MAP_INDEX, eax
	ret
ConvertColCoord ENDP


; Checks if player ship placement is valid
; Compares grid square to '_'
; Retry ship placement if there is an error
;	ecx = size of ship
DetectVertical PROC USES eax ecx edi
	mov edi, OFFSET PlayerMap
	add edi, MAP_INDEX
	movzx ecx, bl
	mov ah, _EMPTY_
	CheckV:
		cmp [edi], ah
		jne ErrorV
		add edi, 22		; +22 to next _ in curr row
	loop CheckV

	jmp ValidV

	; writes an error message if detect occupied grid
	ErrorV:
	mWriteAt 20, 28, clearLine
	mSetTextColor lightRed
	mWriteAt 20, 28, PlacementError
	mSetTextColor white
	mov edx, 1	; set 1 = error

ValidV:
	ret
DetectVertical ENDP

; Checks if player ship placement is valid
; Compares grid square to '_'
; Retry ship placement if there is an error
;	ecx = size of ship
DetectHorizontal PROC USES eax ecx edi
	mov edi, OFFSET PlayerMap
	add edi, MAP_INDEX
	movzx ecx, bl
	mov ah, _EMPTY_
	CheckH:
		cmp [edi], ah
		jne ErrorH
		add edi, 2	; +2 to next _ in curr row
	loop CheckH

	jmp ValidH

	; prints the error message
	ErrorH:
	mWriteAt 20, 28, ClearLine
	mSetTextColor lightRed
	mWriteAt 20, 28, PlacementError
	mSetTextColor white
	mov edx, 1
	jmp ValidH

ValidH:
	ret
DetectHorizontal ENDP


end main