//=============================================================================
// wPRI.
//=============================================================================
class wPRI extends PlayerReplicationInfo;

var int AdminLevel,Lives,EndTimer,Health,ID,TotalScore,MaxLives;
var int Holiday;
var bool bVoteEnd,bForcedAFK,bInvader,bAFK,bGameOver,bEnableLives,bNeutralMap,bLoadScore,bIsTyping;
var string InvadeTarget,VotedURL;

replication
{
	reliable if(Role==ROLE_Authority)
	Health, bVoteEnd, ID, bAFK, AdminLevel, EndTimer, bGameOver, bInvader, InvadeTarget, TotalScore, bEnableLives, MaxLives, Lives, VotedURL, bNeutralMap, bIsTyping, bForcedAFK, Holiday;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(0.000001,True);
	SetTimer(1,False,'InvasionMessage');
}

function InvasionMessage()
{
	if(bInvader)
	Pawn(Owner).ClientMessage("You are Invading, your target is:"@InvadeTarget,'RedCriticalEvent');
}


function CheckScoreBoardInfo()
{
	local wPRI PRI;

	if(PlayerID<=0)
	PlayerID=Level.Game.CurrentID;

	foreach allactors(class'wPRI',PRI)
	{
		if(PRI!=Self && PRI.ID==PlayerID)
		PlayerID++;
	}
	
	ID=PlayerID;
	if(Team<0||Team>3) Team=1;

	EndTimer=WolfCoopGame(Level.Game).EndTimeCount;
	Holiday=WolfCoopGame(Level.Game).HolidayNum;
	TotalScore=WolfCoopGame(Level.Game).TotalScore;
	bEnableLives=WolfCoopGame(Level.Game).bEnableLives;
	MaxLives=WolfCoopGame(Level.Game).MaxLives;

	if(wPlayer(Owner)==None)
		return;

	if(WolfCoopGame(Level.Game).bSaveScores)
	{
		if(!bLoadScore && Score==0)
		{Score=wPlayer(Owner).Score; if(Score!=0) bLoadScore=True;}
		else
		wPlayer(Owner).Score=Score;
	}

	bIsTyping=wPlayer(Owner).RepTyping;
	bInvader=wPlayer(Owner).bInvaderClass;
	Health=Pawn(Owner).Health;
	Lives=wPlayer(Owner).Lives;
	bAFK=wPlayer(Owner).bAFK;
	bForcedAFK=wPlayer(Owner).bForcedAFK;
}

function Timer()
{
	CheckScoreBoardInfo();
	Super.Timer();
}

defaultproperties
{
}
