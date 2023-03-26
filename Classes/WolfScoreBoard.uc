//=============================================================================
// WolfScoreBoard.
//=============================================================================
class WolfScoreBoard extends UnrealScoreBoard;

var int Lives[16],Healths[16],IDs[16];
var byte bAFKs[16],bVoteEnds[16],bInvaders[16],bSpecs[16],bTypings[16];

function DrawHeader( canvas Canvas )
{
	local int Holiday;

	Canvas.Font=Font'u96f_tech';

	Super.DrawHeader(Canvas);

	Canvas.Font=Font'u96f_huge';
	Canvas.SetPos(Canvas.ClipX*0.15,Canvas.ClipY*0.1);
	Holiday=wPRI(PlayerPawn(Owner).PlayerReplicationInfo).Holiday;

	if(Holiday<=0)
	{
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=255;
		Canvas.DrawColor.B=255;
		Canvas.DrawText("WELCOME TO", true);
		Canvas.DrawColor.R=0;
		Canvas.DrawColor.G=255;
		Canvas.DrawColor.B=0;
		Canvas.SetPos(Canvas.ClipX*0.15+25,Canvas.ClipY*0.1+35);
		Canvas.DrawText("WOLF COOP", true);
	}
	else if(Holiday==1)
	{
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=110;
		Canvas.DrawColor.B=0;
		Canvas.DrawText("HAPPY", true);
		Canvas.SetPos(Canvas.ClipX*0.15+25,Canvas.ClipY*0.1+35);
		Canvas.DrawText("HALLOWEEN !", true);
	}
	else if(Holiday==2)
	{
		Canvas.DrawColor.R=32;
		Canvas.DrawColor.G=200;
		Canvas.DrawColor.B=32;
		Canvas.DrawText("HAPPY", true);
		Canvas.SetPos(Canvas.ClipX*0.15+25,Canvas.ClipY*0.1+35);
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=32;
		Canvas.DrawColor.B=32;
		Canvas.DrawText("HOLIDAYS !", true);
	}
	else if(Holiday==3)
	{
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=220;
		Canvas.DrawColor.B=32;
		Canvas.DrawText("APRIL", true);
		Canvas.SetPos(Canvas.ClipX*0.15+25,Canvas.ClipY*0.1+35);
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=32;
		Canvas.DrawColor.B=200;
		Canvas.DrawText("FOOLS !", true);
	}
	else if(Holiday==4)
	{
		Canvas.DrawColor.R=0;
		Canvas.DrawColor.G=255;
		Canvas.DrawColor.B=0;
		Canvas.DrawText("UNREAL", true);
		Canvas.SetPos(Canvas.ClipX*0.15-25,Canvas.ClipY*0.1-35);
		Canvas.DrawColor.R=220;
		Canvas.DrawColor.G=220;
		Canvas.DrawColor.B=220;
		Canvas.DrawText("HAPPY", true);
		Canvas.SetPos(Canvas.ClipX*0.15+30,Canvas.ClipY*0.1+35);
		Canvas.DrawColor.R=220;
		Canvas.DrawColor.G=220;
		Canvas.DrawColor.B=220;
		Canvas.DrawText("DAY !", true);
	}
	else if(Holiday==5)
	{
		Canvas.DrawColor.R=255;
		Canvas.DrawColor.G=220;
		Canvas.DrawColor.B=48;
		Canvas.DrawText("HAPPY", true);
		Canvas.SetPos(Canvas.ClipX*0.15+25,Canvas.ClipY*0.1+35);
		Canvas.DrawColor.R=220;
		Canvas.DrawColor.G=220;
		Canvas.DrawColor.B=220;
		Canvas.DrawText("NEW YEAR !", true);
	}
	Canvas.DrawColor.R=255;
	Canvas.DrawColor.G=255;
	Canvas.DrawColor.B=255;

	Canvas.Style=4;
	Canvas.SetPos(0, Canvas.ClipY/4.5 -20);
	Canvas.DrawRect(Texture'ModulatedIcon',Canvas.ClipX,320);
	Canvas.Style=1;
}

function DrawTrailer(canvas Canvas)
{
	local int Hours, Minutes, Seconds;
	local string HourString, MinuteString, SecondString;
	local float XL, YL;

	//Canvas.Font=Canvas.SmallFont;
	Canvas.Font=Font'u96f_tech';

	if (Canvas.ClipX > 500)
	{
		Seconds = int(Level.TimeSeconds);
		Minutes = Seconds / 60;
		Hours   = Minutes / 60;
		Seconds = Seconds - (Minutes * 60);
		Minutes = Minutes - (Hours * 60);

		if (Seconds < 10)
			SecondString = "0"$Seconds;
		else
			SecondString = string(Seconds);

		if (Minutes < 10)
			MinuteString = "0"$Minutes;
		else
			MinuteString = string(Minutes);

		if (Hours < 10)
			HourString = "0"$Hours;
		else
			HourString = string(Hours);

		Canvas.bCenter = true;
		Canvas.StrLen("Test", XL, YL);
		Canvas.SetPos(0, Canvas.ClipY - YL);
		Canvas.DrawText("Elapsed Time: "$HourString$":"$MinuteString$":"$SecondString, true);
		Canvas.bCenter = false;
	}

	if( Pawn(Owner).PlayerReplicationInfo!=None && Pawn(Owner).PlayerReplicationInfo.bIsSpectator || Pawn(Owner).Health<=0)
	{
		Canvas.bCenter = true;
		Canvas.StrLen("Test", XL, YL);
		Canvas.SetPos(0, Canvas.ClipY - YL*6);
		Canvas.DrawColor.R = 255;
		Canvas.DrawColor.G = 255;
		Canvas.DrawColor.B = 0;
		Canvas.DrawText(SpectatorStr, true);
		Canvas.bCenter = false;
	}
}

function ShowScores(canvas Canvas)
{
	local wPRI PRI;
	local int PlayerCount, LoopCount, I;

	//Canvas.Font = RegFont;
	Canvas.Font = Canvas.MedFont;

	// Header
	DrawHeader(Canvas);

	// Trailer
	DrawTrailer(Canvas);

	// Wipe everything.
	for ( I=0; I<16; I++ )
	{
		Scores[I] = 0;
		Lives[I] = 0;
		Healths[I] = 0;
		IDs[I] = 0;
		bTypings[I] = 0;
		bInvaders[I] = 0;
		bVoteEnds[I] = 0;
		bSpecs[I] = 0;
		bAFKs[I] = 0;
	}
	
	foreach AllActors(class'wPRI', PRI)
	{
		PlayerNames[PlayerCount] = PRI.PlayerName;
		TeamNames[PlayerCount]   = PRI.TeamName;
		Teams[PlayerCount]		 = PRI.Team;
		Pings[PlayerCount]       = PRI.Ping;
		Scores[PlayerCount]      = PRI.Score;
		Lives[PlayerCount]       = PRI.Lives;
		Healths[PlayerCount]	 = PRI.Health;
		IDs[PlayerCount]		 = PRI.ID;
		if(PRI.bIsTyping)  bTypings[PlayerCount] = 1;
		if(PRI.bInvader) bInvaders[PlayerCount] = 1;
		if(PRI.bVoteEnd) bVoteEnds[PlayerCount] = 1;
		if(PRI.bAFK) bAFKs[PlayerCount] = 1;
		if(PRI.bIsSpectator) bSpecs[PlayerCount] = 1;
		if ( ++PlayerCount>=ArrayCount(PlayerNames) )
		break;
	}
	
	SortScores(PlayerCount);
	LoopCount = 0;

	Canvas.DrawColor.R=0;
	Canvas.DrawColor.G=0;
	Canvas.DrawColor.B=0;

	Canvas.SetPos(Canvas.ClipX/5*1.25, Canvas.ClipY/4.5 -16);
	if(wPRI(Pawn(Owner).PlayerReplicationInfo).bInvader)
	{
		Canvas.DrawColor.G=0; Canvas.DrawColor.R=255;
		Canvas.DrawText("Your Target: "$wPRI(Pawn(Owner).PlayerReplicationInfo).InvadeTarget,false);
	}
	else
	{
		Canvas.DrawColor.G=0; Canvas.DrawColor.G=255;
		Canvas.DrawText("Total Score: "$wPRI(Pawn(Owner).PlayerReplicationInfo).TotalScore,false);
	}

	Canvas.DrawColor.R=255;
	Canvas.DrawColor.G=255;
	Canvas.DrawColor.B=255;

	Canvas.SetPos(Canvas.ClipX/5*1.15, Canvas.ClipY/4 -16);
	Canvas.DrawText("ID", false);
	Canvas.SetPos(Canvas.ClipX/5*1.25, Canvas.ClipY/4 -16);
	Canvas.DrawText("NAME", false);

	if(wPRI(Pawn(Owner).PlayerReplicationInfo).bEnableLives)
	{
		Canvas.SetPos(Canvas.ClipX/5 * 3, Canvas.ClipY/4 -16);
		if(wPRI(Pawn(Owner).PlayerReplicationInfo).MaxLives>1)
			Canvas.DrawText("LIVES", false);
		else
			Canvas.DrawText("STATUS", false);
	}

	Canvas.SetPos(Canvas.ClipX/5 * 3.5, Canvas.ClipY/4 -16);
	Canvas.DrawText("SCORE", false);
	
	Canvas.DrawColor.R = 255;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 255;

	Canvas.SetPos(Canvas.ClipX/5 * 3.5, Canvas.ClipY/4 -24);
	for ( I=0; I<PlayerCount; I++ )
	{
		//Canvas.Font = RegFont;
		Canvas.Font=Font(DynamicLoadObject("UWindowFonts.UTFont14B", class'Font'));
		// Player name
		DrawName(Canvas, I, 0, LoopCount);
		// Player ping
		DrawPing(Canvas, I, 0, LoopCount);
		Canvas.Font = Font'u96f_tech';
		// Player ID
		DrawIDs(Canvas, I, 0, LoopCount);
		// Player Endvotes
		if(bSpecs[I]!=1 && bInvaders[I]!=1) 
			DrawEndVotes(Canvas, I, 0, LoopCount);

		// Player Lives
		DrawLives(Canvas, I, 0, LoopCount);

		// Player Score
		if(bSpecs[I]!=1) 
			DrawScore(Canvas, I, 0, LoopCount);

		LoopCount++;
	}
	Canvas.Font = RegFont;

	Canvas.DrawColor.R = 255;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 255;
}

function DrawName(canvas Canvas, int I, float XOffset, int LoopCount)
{
	local int Step;
	local float XL,YL;

	if (Canvas.ClipX >= 640) Step = 16;
	else Step = 8;
	
	if(bSpecs[I]==1) 
	{ 
		Canvas.DrawColor.R = 255; 
		Canvas.DrawColor.G = 255; 
		Canvas.DrawColor.B = 255; 
	}
	else if(bInvaders[I]>=1) 
	{ 
		Canvas.DrawColor.R = 255; 
		Canvas.DrawColor.G = 16; 
		Canvas.DrawColor.B = 16; 
	}
	else 
	{ 
		Canvas.DrawColor.R = 16; 	
		Canvas.DrawColor.G = 255; 
		Canvas.DrawColor.B = 16; 
	}

	Canvas.StrLen(PlayerNames[I],XL,YL);

	Canvas.SetPos(Canvas.ClipX/5*1.25, Canvas.ClipY/4 + (LoopCount * Step));
	if(bTypings[I]>0)
		Canvas.DrawText(PlayerNames[I]@"(Typing)", false);
	else if(bAFKs[I]>0)
		Canvas.DrawText(PlayerNames[I]@"(AFK)", false);
	else
		Canvas.DrawText(PlayerNames[I], false);

	Canvas.DrawColor.R = 0;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 0;
}

function DrawEndVotes(canvas Canvas, int I, float XOffset, int LoopCount)
{
	local int Step;
	
	if (Canvas.ClipX >= 640) 
		Step = 16;
	else 
		Step = 8;
	
	//if(PLevels[I]>0) { Canvas.DrawColor=PColors[I]; }
	//else { Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 0; }
	
	Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 0;	

	Canvas.SetPos(Canvas.ClipX/5*2.65, Canvas.ClipY/4 + (LoopCount * Step));
	if(bVoteEnds[I]==1)
	{
		if(Level.Pauser!="") 
			Canvas.DrawText("[START]", false);
		else 
			Canvas.DrawText("[END]", false);
	}

	Canvas.DrawColor.R = 0;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 0;
	
}

function DrawLives( canvas Canvas, int I, float XOffset, int LoopCount )
{
	local int Step;

	Canvas.DrawColor.R = 0;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 0;

	if(bSpecs[I]==1) { Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255; }
	else if(Lives[I]<=0 && Healths[I]<=0)
	{ Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0; }


	if (Canvas.ClipX >= 640) Step = 16;
	else Step = 8;
	Canvas.SetPos(Canvas.ClipX/5 * 3, Canvas.ClipY/4 + (LoopCount * Step));

	if(bSpecs[I]==1)
	Canvas.DrawText("SPECTATING", false);
	else if((wPRI(Pawn(Owner).PlayerReplicationInfo).bInvader && bInvaders[I]<=0) || (!wPRI(Pawn(Owner).PlayerReplicationInfo).bInvader && bInvaders[I]>=1))
	{
		if((wPRI(Pawn(Owner).PlayerReplicationInfo).bInvader && bInvaders[I]<=0) || (!wPRI(Pawn(Owner).PlayerReplicationInfo).bInvader && bInvaders[I]>=1))
		{Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;}
		if(Healths[I]<=0)
		{ Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0; Canvas.DrawText("DEAD", false); }
		else if(bInvaders[I]>=1)
		Canvas.DrawText("INVADER", false);
		else
		Canvas.DrawText("SURVIVOR", false);
	}
	else if(wPRI(Pawn(Owner).PlayerReplicationInfo).bEnableLives)
	{	if(wPRI(Pawn(Owner).PlayerReplicationInfo).MaxLives<=1)
		{
			if(Healths[I]>0)
			Canvas.DrawText("ALIVE", false);
			else
			Canvas.DrawText("DEAD", false);
		}
		else if(Lives[I]>0 || Healths[I]>0)
		Canvas.DrawText(Lives[I], false);
		else if(Healths[I]<=0)
		Canvas.DrawText("OUT", false);
	}
}

function DrawScore( canvas Canvas, int I, float XOffset, int LoopCount )
{
	local int Step;

	Canvas.DrawColor.R = 0;
	Canvas.DrawColor.G = 0;
	if(Scores[I]<0)
	Canvas.DrawColor.R = 255;
	else
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 0;

	if (Canvas.ClipX >= 640)
		Step = 16;
	else
		Step = 8;

	Canvas.SetPos(Canvas.ClipX/5 * 3.5, Canvas.ClipY/4 + (LoopCount * Step));
	Canvas.DrawText(int(Scores[I]), false);
}


function DrawIDs( canvas Canvas, int I, float XOffset, int LoopCount )
{
	local float XL, YL;
	local int Step;

	if (Canvas.ClipX >= 640)
		Step = 16;
	else
		Step = 8;

	Canvas.StrLen(IDs[I], XL, YL);
	Canvas.SetPos(Canvas.ClipX/5*1.15, Canvas.ClipY/4 + (LoopCount * Step));

	if(bSpecs[I]==1)
	{Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;}
	else if(bInvaders[I]>=1)
	{Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;}
	else { Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 0; }
	Canvas.DrawText(IDs[I], false);

	Canvas.Font = RegFont;
}


function DrawPing( canvas Canvas, int I, float XOffset, int LoopCount )
{
	local float XL, YL;
	local int Step;

	if (Canvas.ClipX >= 640)
		Step = 16;
	else
		Step = 8;

	//if (Level.Netmode == NM_Standalone)
	//	return;

	Canvas.StrLen(Pings[I], XL, YL);
	Canvas.SetPos(Canvas.ClipX/5*1.15 - XL - 8, Canvas.ClipY/4 + (LoopCount * Step));
	Canvas.Font = Font'TinyWhiteFont';
	Canvas.DrawColor.R = 255;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 255;
	Canvas.DrawText(Pings[I], false);
	Canvas.Font = RegFont;
	Canvas.DrawColor.R = 0;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 0;
}


function Swap( int L, int R )
{
	local string TempPlayerName, TempTeamName;
	local float TempScore;
	local byte TempTeam, TempEnd, TempInvaders;
	local int TempPing, TempSpec, TempIDs,TempLives;
	local byte TempbAFKs,TempTypings;

	
	TempPlayerName = PlayerNames[L];
	TempTeamName = TeamNames[L];
	TempScore = Scores[L];
	TempTeam = Teams[L];
	TempPing = Pings[L];
	TempbAFKs = bAFKs[L];
	TempSpec = bSpecs[L];
	TempEnd = bVoteEnds[L];
	TempIDs = IDs[L];
	TempInvaders = bInvaders[L];
	TempLives = Lives[L];
	TempTypings = bTypings[L];
	
	PlayerNames[L] = PlayerNames[R];
	TeamNames[L] = TeamNames[R];
	Scores[L] = Scores[R];
	Teams[L] = Teams[R];
	Pings[L] = Pings[R];
	bAFKs[L] = bAFKs[R];
	bSpecs[L] = bSpecs[R];
	bVoteEnds[L] = bVoteEnds[R];
	IDs[L] = IDs[R];
	bInvaders[L] = bInvaders[R];
	Lives[L] = Lives[R];
	bTypings[L] = bTypings[R];

	PlayerNames[R] = TempPlayerName;
	TeamNames[R] = TempTeamName;
	Scores[R] = TempScore;
	Teams[R] = TempTeam;
	Pings[R] = TempPing;
	bAFKs[R] = TempbAFKs;
	bSpecs[R] = TempSpec;
	bVoteEnds[R] = TempEnd;
	IDs[R] = TempIDs;
	bInvaders[R] = TempInvaders;
	Lives[R] = TempLives;
	bTypings[R] = TempTypings;
}

defaultproperties
{
	Lives(0)=0
	Lives(1)=0
	Lives(2)=0
	Lives(3)=0
	Lives(4)=0
	Lives(5)=0
	Lives(6)=0
	Lives(7)=0
	Lives(8)=0
	Lives(9)=0
	Lives(10)=0
	Lives(11)=0
	Lives(12)=0
	Lives(13)=0
	Lives(14)=0
	Lives(15)=0
	Healths(0)=0
	Healths(1)=0
	Healths(2)=0
	Healths(3)=0
	Healths(4)=0
	Healths(5)=0
	Healths(6)=0
	Healths(7)=0
	Healths(8)=0
	Healths(9)=0
	Healths(10)=0
	Healths(11)=0
	Healths(12)=0
	Healths(13)=0
	Healths(14)=0
	Healths(15)=0
	IDs(0)=0
	IDs(1)=0
	IDs(2)=0
	IDs(3)=0
	IDs(4)=0
	IDs(5)=0
	IDs(6)=0
	IDs(7)=0
	IDs(8)=0
	IDs(9)=0
	IDs(10)=0
	IDs(11)=0
	IDs(12)=0
	IDs(13)=0
	IDs(14)=0
	IDs(15)=0
	bAFKs(0)=0
	bAFKs(1)=0
	bAFKs(2)=0
	bAFKs(3)=0
	bAFKs(4)=0
	bAFKs(5)=0
	bAFKs(6)=0
	bAFKs(7)=0
	bAFKs(8)=0
	bAFKs(9)=0
	bAFKs(10)=0
	bAFKs(11)=0
	bAFKs(12)=0
	bAFKs(13)=0
	bAFKs(14)=0
	bAFKs(15)=0
	bVoteEnds(0)=0
	bVoteEnds(1)=0
	bVoteEnds(2)=0
	bVoteEnds(3)=0
	bVoteEnds(4)=0
	bVoteEnds(5)=0
	bVoteEnds(6)=0
	bVoteEnds(7)=0
	bVoteEnds(8)=0
	bVoteEnds(9)=0
	bVoteEnds(10)=0
	bVoteEnds(11)=0
	bVoteEnds(12)=0
	bVoteEnds(13)=0
	bVoteEnds(14)=0
	bVoteEnds(15)=0
	bInvaders(0)=0
	bInvaders(1)=0
	bInvaders(2)=0
	bInvaders(3)=0
	bInvaders(4)=0
	bInvaders(5)=0
	bInvaders(6)=0
	bInvaders(7)=0
	bInvaders(8)=0
	bInvaders(9)=0
	bInvaders(10)=0
	bInvaders(11)=0
	bInvaders(12)=0
	bInvaders(13)=0
	bInvaders(14)=0
	bInvaders(15)=0
	bSpecs(0)=0
	bSpecs(1)=0
	bSpecs(2)=0
	bSpecs(3)=0
	bSpecs(4)=0
	bSpecs(5)=0
	bSpecs(6)=0
	bSpecs(7)=0
	bSpecs(8)=0
	bSpecs(9)=0
	bSpecs(10)=0
	bSpecs(11)=0
	bSpecs(12)=0
	bSpecs(13)=0
	bSpecs(14)=0
	bSpecs(15)=0
	bTypings(0)=0
	bTypings(1)=0
	bTypings(2)=0
	bTypings(3)=0
	bTypings(4)=0
	bTypings(5)=0
	bTypings(6)=0
	bTypings(7)=0
	bTypings(8)=0
	bTypings(9)=0
	bTypings(10)=0
	bTypings(11)=0
	bTypings(12)=0
	bTypings(13)=0
	bTypings(14)=0
	bTypings(15)=0
}
