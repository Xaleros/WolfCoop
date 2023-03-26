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
	if(Team<0||Team>3) 
		Team=1;

    if(WolfCoopGame(Level.Game)!=None)
	{ 
		// can happen if a installed wplayerpawn is seleleted in playeroptions.
		EndTimer=WolfCoopGame(Level.Game).EndTimeCount;
		Holiday=WolfCoopGame(Level.Game).HolidayNum;
		TotalScore=WolfCoopGame(Level.Game).TotalScore;
		bEnableLives=WolfCoopGame(Level.Game).bEnableLives;
		MaxLives=WolfCoopGame(Level.Game).MaxLives;
    }

	if(wPlayer(Owner)==None)
		return;

	if(WolfCoopGame(Level.Game).bSaveScores && WolfCoopGame(Level.Game)!=None)
	{
		if(!bLoadScore && Score==0)
		{
			Score=wPlayer(Owner).Score; 
			if(Score!=0) 
			bLoadScore=True;
		}
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
	AdminLevel=0
	Lives=0
	EndTimer=0
	Health=0
	Id=0
	TotalScore=0
	MaxLives=0
	Holiday=0
	InvadeTarget=""
	VotedURL=""
	bVoteEnd=False
	bForcedAFK=False
	bInvader=False
	bAFK=False
	bGameOver=False
	bEnableLives=False
	bNeutralMap=False
	bLoadScore=False
	bIsTyping=False
}
