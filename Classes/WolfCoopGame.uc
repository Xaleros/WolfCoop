//=============================================================================
// WolfCoopGame.
//=============================================================================
class WolfCoopGame extends CoopGame config(WolfCoop);

#exec obj load file="Sounds\AmbAncient.uax"
#exec obj load file="Sounds\AmbOutside.uax"
#exec obj load file="Sounds\DoorsAnc.uax"
#exec obj load file="Textures\U96Font.utx" Package="WolfCoop"
#exec obj load file="Textures\WolfCoopTextures.utx" Package="WolfCoop"
#exec obj load file="Textures\WolfCoopSounds.uax" Package="WolfCoop"

struct wPlayerClasses
{
	var()	globalconfig string OriginalClass;
	var()	globalconfig string ReplacementClass;
};

struct DisconnectedPlayers
{
	var string PlayerName;
	var int Lives, Score;
};

struct CheckPoint
{
	var int CheckPointType;
	var string MapName;
	var vector CPLocation;
	var rotator CPRotation;
	var float CPRadius,CPHeight;
	var bool bEventEnabled;
	var name EventTag;
};

var(wGameBalance) config bool bRestoreDrownDamage,bInventoryLossOnDeath,bDropInventoryOnDeath,bEnableVoteEnd,bNoChatVoteEnd,bEndTimerPunish,bPlayersEndGameSpectate,bShowEnds,bEnableCheckPoints,bDisableMapFixes,bRealCrouch,bShowRespawningItems,bAllowCheckpointRelocate,bCheckpointHeals,bPenalizeInventoryOnLifeLoss,bSaveScores,bUniqueItems,bUniquePowerUps,bPermanentFlares;//,bVoteStart,bAllowLatePlayers;
var(wGameBalance) config int EndTime,AFKTimer;
var(wGameBalance) globalconfig array<CheckPoint> CheckPoints;
var(wPlayerClasses) config wPlayerClasses ClassReplacement[64];

var(wHolidaySettings) globalconfig byte ForcedHoliday;
var(wHolidaySettings) globalconfig bool bRandomizeLightsColor;

var(wItemRespawning) config bool bRespawnItems;
var(wItemRespawning) config int AmmoRespawnTime;
var(wItemRespawning) config int WeaponRespawnTime;
var(wItemRespawning) config int ArmorRespawnTime;
var(wItemRespawning) config int PickupRespawnTime;
var(wItemRespawning) config int HealthRespawnTime;

var(wHookMutators) config bool bUseHookMutators;
var(wHookMutators) config String HookMutator[32];
var(wHookMutators) config String XmasMutators[16];
var(wHookMutators) config String HalloweenMutators[16];
var(wHookMutators) config String AprilFoolsMutators[16];
var(wSpawnItems) config String GiveItems[64];

var(wLives) config int StartingLives,MaxLives,ExtraLifeScore;
var(wLives) config bool bEnableLives,bExtraLives,bPersonalExtraLives,bRestartMapOnGameOver,bAllowReviving,
						bResetLivesOnMapChange,bMarioSounds,bSeriousSamExtraLife;
var() globalconfig bool bReturnToLastMap;

var bool bStarted,bChangingMap,bEndReached,bLMSWarn,bNeutralMap,bEndTimeStarted;
var array<DisconnectedPlayers> SavePlayers;
var string SaveURL,MapName,TempLastMap;
var string SavedURLs[64];
var int URLVoteCount[16];
var int URLWinner;

var() config string LastMap;
var() globalconfig string NeutralMaps[64];
var int SavedURLCount;
var wPlayer InvasionTarget;

var int TotalScore,CurrentExtraLifeScore,EndTimeCount;
var byte HolidayNum;

replication
{
		reliable if(ROLE==ROLE_Authority)
		TotalScore,EndTime,EndTimeCount,HolidayNum;
		reliable if(ROLE==ROLE_Authority && bNetOwner)
		ClassReplacement,bRespawnItems,AmmoRespawnTime,WeaponRespawnTime,ArmorRespawnTime,PickupRespawnTime,HealthRespawnTime,
		bEnableLives,bExtraLives,bPersonalExtraLives,MaxLives,StartingLives,bAllowReviving,
		bRestartMapOnGameOver,bInventoryLossOnDeath,bDropInventoryOnDeath,bResetLivesOnMapChange,bEnableVoteEnd,
		bNoChatVoteEnd,CurrentExtraLifeScore,bMarioSounds,bSeriousSamExtraLife,bShowEnds,ForcedHoliday,AFKTimer,
		CheckPoints,bRealCrouch,bAllowCheckpointRelocate;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	CurrentID++;
	if(bEnableCheckpoints)
	SetTimer(1,false,'SpawnCheckpoints');
	Spawn(Class'wChatRules');
}


function NavigationPoint FindPlayerStart( byte Team, optional string incomingName )
{
	local PlayerStart Dest,Best;
	local int Score,BestScore;
	local Pawn P;

	//choose candidates
	foreach AllActors( class 'PlayerStart', Dest )
	{
		Score = Rand(100); // Randomize base scoring.
		if( !Dest.bEnabled )
			Score-=10000;
		if (Level.NetMode==NM_Standalone)
		{ 	if(!Dest.bSinglePlayerStart && Dest.bCoopStart)
			Score-=1000;
			else if (Dest.bSinglePlayerStart && Dest.bCoopStart)
			Score-=250;
			else if (Dest.bSinglePlayerStart && !Dest.bCoopStart)
			Score+=1000;
		}
		else if( !Dest.bSinglePlayerStart && !Dest.bCoopStart )
			Score-=1000;

		foreach RadiusActors(class'Pawn',P,100,Dest.Location)
			if( P.bIsPlayer && P.Health>0 && P.bBlockActors )
				Score-=100;
		if( Best==None || Score>BestScore )
		{
			Best = Dest;
			BestScore = Score;
		}
	}
	if( Best==None )
		return Level.NavigationPointList; // Attempt to recover.
	return Best;
} 

function FixCoopMaps()
{
	local String S;
	local Weapon Weap;
	local Trigger T;
	local bool bReplaceMe;
	local ZoneInfo ZI;
	local Mover M;
	local PlayerStart P;
	local Actor A;
	local Mercenary Merc;
	local SpecialEvent SE;
	local Counter C;
	local Dispatcher D;
	local JumpBoots JB;
	local Spawnpoint SP;
	local Teleporter TP;
	local UpakTeleporter UTP;
	local Pawn PA;
	local Cannon CA;
	local BlockPlayer BP;
	local Fan2 F2;
	local DynamicZoneInfo DZI;
	local wTPFix wTP;
	local PlayerPawn Pp;
	local Warlord WL;
	local MusicEvent ME;
	local PathNode PN;

	S = GetURLMap();
	if( InStr(S,".")==-1 )
	S = S$".unr";

	//========================================================
	//Unreal + RTNP
	//========================================================
	
	if( S~="Passage.unr" )
	{
		T = Trigger(DynamicLoadObject("passage.trigger0",Class'Trigger'));
		if( T!=None )
			T.bInitiallyActive = False;
	}

	if( S~="Noork.unr" )
	{
		M = Mover(DynamicLoadObject("noork.mover5",Class'Mover'));
		if( M!=None )
			M.Tag = 'none';

		M = Mover(DynamicLoadObject("noork.mover9",Class'Mover'));
		if( M!=None )
			M.Tag = 'none';
	}

	if( S~="Ruins.unr" )
	{
		D = Dispatcher(DynamicLoadObject("Ruins.Dispatcher0",Class'Dispatcher'));
		if( D!=None)
		D.Tag='None';

		T = Trigger(DynamicLoadObject("Ruins.Trigger1",Class'Trigger'));
		if( T!=None)
			T.bInitiallyActive=False;
	}

	if (S~="Trench.unr" || S~="TerraLift.unr")
	{
		foreach allactors(class'Mover', M)
		{
			M.MoverEncroachType=ME_IgnoreWhenEncroach;
			M.EncroachDamage=0;
		}
	}

	if (S~="ISVKran4.unr")
	{
		foreach allactors(class'Mover', M)
		{
			M.MoverEncroachType=ME_IgnoreWhenEncroach;
		}
	}

	if( S~="ISVDeck1.unr" )
	{
		M = Mover(DynamicLoadObject("isvdeck1.mover61",Class'Mover'));
		if( M!=None )
			M.bBlockPlayers = false;
	}

	if (S~="SkyTown.unr")
	{
		M = Mover(DynamicLoadObject("SkyTown.Mover48",Class'Mover'));
		if( M!=None )
		{
			M.GoToState('TriggerToggle');
			M.bUseTriggered=True;
			M.ClosedSound=Sound'wdend1';
			M.MoveAmbientSound=Sound'wdloop22';
			M.OpenedSound=Sound'wdend1';
			M.MoverEncroachType=ME_IgnoreWhenEncroach;
		}
		M = Mover(DynamicLoadObject("SkyTown.Mover52",Class'Mover'));
		if( M!=None )
		{
			M.GoToState('TriggerToggle');
			M.bUseTriggered=True;
			M.ClosedSound=Sound'wdend1';
			M.MoveAmbientSound=Sound'wdloop22';
			M.OpenedSound=Sound'wdend1';
			M.MoverEncroachType=ME_IgnoreWhenEncroach;
		}
	}

	if( S~="SkyBase.unr" )
	{
		ForEach AllActors(class'Mover',M)
		M.MoverEncroachType=ME_IgnoreWhenEncroach;
	}

	if( S~="NaliBoat.unr" )
	{
		M = Mover(DynamicLoadObject("naliboat.mover64",Class'Mover'));
		if( M!=None )
			M.Tag = 'none';
	}

	if( S~="NaliC.unr" )
	{
		M = Mover(DynamicLoadObject("nalic.mover35",Class'Mover'));
		if( M!=None )
			M.Tag = 'none';

		M = Mover(DynamicLoadObject("nalic.mover36",Class'Mover'));
		if( M!=None )
			M.Tag = 'none';
	}

	if( S~="ExtremeCore.unr" )
	{
		P = PlayerStart(DynamicLoadObject("extremecore.PlayerStart1",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;
	}

	if (S~="ExtremeGen.unr")
	{
		foreach allactors(class'ZoneInfo', ZI)
		{
			ZI.ZoneTerminalVelocity=ZI.Default.ZoneTerminalVelocity;
		}
	}

	if( S~="ExtremeDark.unr" )
	{
		ForEach AllActors(class'Mercenary',Merc)
		{Merc.AttitudeToPlayer=ATTITUDE_Friendly;}

		P = PlayerStart(DynamicLoadObject("extremedark.PlayerStart6",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("extremedark.PlayerStart7",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		D = Dispatcher(DynamicLoadObject("extremedark.Dispatcher0",Class'Dispatcher'));
		if( D!=None)
			D.OutEvents[1]='None';
	}


	if( S~="ExtremeEnd.unr" )
	{
		T = Trigger(DynamicLoadObject("extremeend.trigger0",Class'Trigger'));
		if( T!=None )
			T.bTriggerOnceOnly = False;
			T.SetCollisionSize(100,100);
	}

	if( S~="QueenEnd.unr" )
	{
		ForEach AllActors(class'Mover',M)
		M.MoverEncroachType=ME_IgnoreWhenEncroach;
	}

	if( S~="Eldora.unr" )
	{
		ForEach AllActors(class'PlayerStart',P)
		{
			P.bEnabled = False;
			P.bSinglePlayerStart = False;
			P.bCoopStart = False;
		}
		
		if(Level.NetMode!=NM_Standalone)
		Spawn(class'wPlayerStart',,,vect(-1784.812134,-221.392105,963.897583));
		else
		{
			ForEach AllActors(class'PlayerPawn',Pp)
			{Pp.SetLocation(vect(-1784.812134,-221.392105,963.897583));}
		}
		Spawn(class'ScubaGear',,,vect(5557.761719,-6250.633301,911.099976));

		M = Mover(DynamicLoadObject("Eldora.Mover18", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = True;
			M.Tag = 'risewater';
			M.DelayTime = 30;

		M = Mover(DynamicLoadObject("Eldora.Mover19", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = True;
			M.Tag = 'risewater';
			M.DelayTime = 30;

		M = Mover(DynamicLoadObject("Eldora.Mover16", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = True;
			M.Tag = 'risewater';
			M.DelayTime = 30;

		M = Mover(DynamicLoadObject("Eldora.Mover15", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = True;
			M.Tag = 'risewater';
			M.DelayTime = 30;

		M = Mover(DynamicLoadObject("Eldora.Mover13", class'Mover'));
		if( M!=None )
			M.Tag = 'none';
	}

	if( S~="Glathriel1.unr" )
	{
		P = PlayerStart(DynamicLoadObject("glathriel1.PlayerStart0",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("glathriel1.PlayerStart2",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("glathriel1.PlayerStart3",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("glathriel1.PlayerStart4",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("glathriel1.PlayerStart5",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;
	}


	if( S~="Glathriel2.unr" )
	{
		M = Mover(DynamicLoadObject("Glathriel2.Mover21", class'Mover'));
		if( M!=None )
			M.InitialState = 'TriggerOpenTimed';
			M.GoToState('TriggerOpenTimed');

		M = Mover(DynamicLoadObject("Glathriel2.Mover19", class'Mover'));
		if( M!=None )
			M.InitialState = 'TriggerOpenTimed';
			M.GoToState('TriggerOpenTimed');

		M = Mover(DynamicLoadObject("Glathriel2.Mover27", class'Mover'));
		if( M!=None )
			M.Tag = 'fleenali_run';
			M.DelayTime = 1.4;

		M = Mover(DynamicLoadObject("Glathriel2.Mover28", class'Mover'));
		if( M!=None )
			M.Tag = 'fleenali_run';
			M.DelayTime = 1.4;
	}

	if( S~="Crashsite.unr" )
	{
		M = Mover(DynamicLoadObject("Crashsite.Mover4", class'Mover'));
		if( M!=None )
			M.bDifficulty0 = True;
			M.bDifficulty1 = True;
			M.bDifficulty2 = True;
			M.bDifficulty3 = True;

		M = Mover(DynamicLoadObject("Crashsite.Mover9", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;

		M = Mover(DynamicLoadObject("Crashsite.Mover8", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
	}


	if( S~="Crashsite1.unr" )
	{
		M = Mover(DynamicLoadObject("Crashsite1.Mover46", class'Mover'));
		if( M!=None )
			M.bDifficulty0 = True;
			M.bDifficulty1 = True;
			M.bDifficulty2 = True;
			M.bDifficulty3 = True;

		M = Mover(DynamicLoadObject("Crashsite1.Mover66", class'Mover'));
		if( M!=None )
			M.bDifficulty0 = True;
			M.bDifficulty1 = True;
			M.bDifficulty2 = True;
			M.bDifficulty3 = True;

		M = Mover(DynamicLoadObject("Crashsite1.Mover47", class'Mover'));
		if( M!=None )
			M.bDifficulty0 = True;
			M.bDifficulty1 = True;
			M.bDifficulty2 = True;
			M.bDifficulty3 = True;
	}

	if( S~="CrashSite2.unr" )
	{
		T = Trigger(DynamicLoadObject("Crashsite2.Trigger36", class'Trigger'));
		if( T!=None )
			T.TriggerType = TT_PawnProximity;

		M = Mover(DynamicLoadObject("Crashsite2.Mover87", class'Mover'));
		if( M!=None )
			M.Tag = 'none';

		M = Mover(DynamicLoadObject("Crashsite2.Mover4", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = False;

		M = Mover(DynamicLoadObject("Crashsite2.Mover5", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = False;

		M = Mover(DynamicLoadObject("Crashsite2.Mover86", class'Mover'));
		if( M!=None )
			M.Tag = 'none';

		M = Mover(DynamicLoadObject("Crashsite2.Mover83", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = False;
	}

	if( S~="Foundry.unr" )
	{
		T = Trigger(DynamicLoadObject("Foundry.Trigger49", class'Trigger'));
		if( T!=None )
			T.Destroy();

		M = Mover(DynamicLoadObject("Foundry.Mover127", class'Mover'));
		if( M!=None )
			M.Tag = 'pimpdie';
			M.bTriggerOnceOnly = true;

		M = Mover(DynamicLoadObject("Foundry.Mover126", class'Mover'));
		if( M!=None )
			M.Tag = 'pimpdie';
			M.bTriggerOnceOnly = true;
	}


	if( S~="Toxic.unr" )
	{
		P = PlayerStart(DynamicLoadObject("Toxic.PlayerStart37",Class'PlayerStart'));
		if( P!=None )
		{	P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;}

		P = PlayerStart(DynamicLoadObject("Toxic.PlayerStart38",Class'PlayerStart'));
		if( P!=None )
		{	P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;}

		P = PlayerStart(DynamicLoadObject("Toxic.PlayerStart39",Class'PlayerStart'));
		if( P!=None )
		{	P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;}

		P = PlayerStart(DynamicLoadObject("Toxic.PlayerStart40",Class'PlayerStart'));
		if( P!=None )
		{	P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;}

		P = PlayerStart(DynamicLoadObject("Toxic.PlayerStart41",Class'PlayerStart'));
		if( P!=None )
		{	P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;}

		M = Mover(DynamicLoadObject("Toxic.Mover113", class'Mover'));
		if( M!=None )
		{	M.GoToState('BumpOpenTimed');
			M.bTriggerOnceOnly=False;
			M.bDynamicLightMover=True;}
		M = Mover(DynamicLoadObject("Toxic.Mover28", class'Mover'));
		if( M!=None )
			M.bDynamicLightMover=True;
		M = Mover(DynamicLoadObject("Toxic.Mover29", class'Mover'));
		if( M!=None )
			M.bDynamicLightMover=True;

		foreach allactors(class'wTPFix',wTP)
		{
			if( wTP!=None )
			wTP.SetCollisionSize(60,135);
		}
	}

	if( S~="NaliC2.unr" )
	{
		M = Mover(DynamicLoadObject("NaliC2.Mover10", class'Mover'));
		if( M!=None )
			M.Tag = 'OpenDaDoor';

		M = Mover(DynamicLoadObject("NaliC2.Mover9", class'Mover'));
		if( M!=None )
			M.Tag = 'OpenDaDoor';

		T = Spawn(class'Trigger',,,vect(3502.737305,-224.830917,-12824.607422));
		if( T!=None )
			T.SetCollisionSize(128,128);
			T.Event = 'OpenDaDoor';
			T.TriggerType = TT_PawnProximity;

		A = WarLord(DynamicLoadObject("NaliC2.WarLord0", class'WarLord'));
		if( A!=None )
			A.Tag = 'Switch2';

		M = Mover(DynamicLoadObject("NaliC2.Mover33", class'Mover'));
		if( M!=None )
			M.SetLocation(vect(-1920.000000,-688.000000,-12750.000000));

		M = Mover(DynamicLoadObject("NaliC2.Mover30", class'Mover'));
		if( M!=None )
			M.SetLocation(vect(-1616.000000,-224.000000,-12750.000000));

		M = Mover(DynamicLoadObject("NaliC2.Mover42", class'Mover'));
		if( M!=None )
			M.SetLocation(vect(-688.000000,-224.000000,-12750.000000));
	}

	//========================================================
	//Custom Maps
	//========================================================


	//RTNPUE--------------------------------------

	if( S~="Nexus.unr" )
	{
		SE = SpecialEvent(DynamicLoadObject("Nexus.SpecialEvent2",Class'SpecialEvent'));
		if( SE.Tag == 'killplayerpreend' && SE!=None )
			SE.Tag = 'none';
	}

	if( S~="Soledad.unr" )
	{
		SE = SpecialEvent(DynamicLoadObject("Soledad.SpecialEvent15",Class'SpecialEvent'));
		if( SE.Tag == 'killplayertrapped2' && SE!=None )
			SE.Tag = 'none';
	}

	//Attacked------------------------------------

	if( S~="Attacked3[1].unr" )
	{
		M = Mover(DynamicLoadObject("Attacked3[1].Mover20",Class'Mover'));
		if( M!=None )
			M.DelayTime = 3.0;

		M = Mover(DynamicLoadObject("Attacked3[1].Mover0",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;

		M = Mover(DynamicLoadObject("Attacked3[1].Mover8",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;

		M = Mover(DynamicLoadObject("Attacked3[1].Mover9",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;

		M = Mover(DynamicLoadObject("Attacked3[1].Mover10",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;

		M = Mover(DynamicLoadObject("Attacked3[1].Mover25",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;
	}


	if( S~="Attacked3[1].unr" )
	{
		M = Mover(DynamicLoadObject("Attacked3[1].Mover26",Class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.EncroachDamage = 0.0;
	}


	if( S~="Attacked4[wtf].unr" )
	{
		T = Trigger(DynamicLoadObject("Attacked4[wtf].Trigger65",Class'Trigger'));
		if( T!=None )
			T.bTriggerOnceOnly = False;
	}


	if( S~="Attacked_extro1.unr" )
	{
		T = Trigger(DynamicLoadObject("Attacked_extro1.Trigger14",Class'Trigger'));
		if( T!=None )
			T.bTriggerOnceOnly = False;
	}

	//Strange--------------------------------------

	if( S~="Strange1.unr" )
	{
		P = PlayerStart(DynamicLoadObject("Strange1.PlayerStart1",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		T = Trigger(DynamicLoadObject("Strange1.Trigger2",Class'Trigger'));
		if( T!=None )
			T.bInitiallyActive = False;

		C = Counter(DynamicLoadObject("Strange1.Counter5",Class'Counter'));
		if( C!=None )
			C.NumToCount=1;
	}


	if( S~="Strange2.unr" )
	{
		T = Spawn(class'Trigger',,,vect(11713,-4689,-471));
		if( T!=None )
			T.Event = 'scht';
	}

	if( S~="Strange6.unr" )
	{

		P = PlayerStart(DynamicLoadObject("Strange6.PlayerStart6",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		T = Trigger(DynamicLoadObject("Strange6.Trigger24",Class'Trigger'));
		if( T!=None )
			T.bInitiallyActive = False;

		T = Trigger(DynamicLoadObject("Strange6.Trigger33",Class'Trigger'));
		if( T!=None )
			T.InitialState = 'None';

		D = Dispatcher(DynamicLoadObject("Strange6.Dispatcher5",Class'Dispatcher'));
		if( D!=None )
			D.OutEvents[0] = 'None';

		T = Trigger(DynamicLoadObject("Strange6.Trigger12",Class'Trigger'));
		if( T!=None )
			T.Event = 'shivbsfix';

		T = Trigger(DynamicLoadObject("Strange6.Trigger3",Class'Trigger'));
		if( T!=None )
			T.Tag = 'shivbsfix';

		T = Trigger(DynamicLoadObject("Strange6.Trigger13",Class'Trigger'));
		if( T!=None )
			T.Event = 'shivbsfix2';
			T.Tag = 'shivbsfix';

		D = Dispatcher(DynamicLoadObject("Strange6.Dispatcher7",Class'Dispatcher'));
		if( D!=None )
			D.Tag = 'shivbsfix';

		D = Dispatcher(DynamicLoadObject("Strange6.Dispatcher8",Class'Dispatcher'));
		if( D!=None )
			D.Tag = 'shivbsfix2';

		SP = Spawnpoint(DynamicLoadObject("Strange6.Spawnpoint6",Class'Spawnpoint'));
		if( SP!=None )
			SP.Tag = 'shivbsfix2';
	}

	//Illhaven------------------------------------------

	if( S~="Illhaven_6.unr" )
	{
		P = PlayerStart(DynamicLoadObject("Illhaven_6.PlayerStart1",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;
	}

		if( S~="Illhaven_113.unr" )
	{
		TP = Teleporter(DynamicLoadObject("Illhaven_113.Teleporter0",Class'Teleporter'));
		if( TP!=None )
			TP.bEnabled=False;
			TP.Tag='boat';
	}

	//Unreal PSX----------------------------------------

	if( S~="UPB-E1L1C.unr" )
	{
		T = Trigger(DynamicLoadObject("UPB-E1L1C.Trigger0",Class'Trigger'));
		if( T!=None )
			T.bInitiallyActive = False;
	}

	//Tentacle Hunter-----------------------------------

	if( S~="BeamOut.unr" )
	{
		M = Mover(DynamicLoadObject("BeamOut.Mover1", class'Mover'));
		if( M!=None )
			M.Tag = 'nope';
	}

	if( S~="TheSwamp.unr" )
	{
		T = Trigger(DynamicLoadObject("TheSwamp.Trigger13", class'Trigger'));
		if( T!=None )
			T.bInitiallyActive = False;
	}

	if( S~="Sunken.unr" )
	{
		TP = Teleporter(DynamicLoadObject("Sunken.Teleporter2", class'Teleporter'));
		if( TP!=None )
			TP.SetCollisionSize(400,400);
	}

	//Shrakita-----------------------------------------

	if( S~="Shrak4.unr" )
	{
		wTP = Spawn(class'wTPFix',,,vect(6921.416016,9083.062500,-94.899994));
		if( wTP!=None )
		{	wTP.bEnabled = True;
			wTP.SetCollisionSize(500,10);
			wTP.URL="Vortex2#EndMap?Peer";}
	}

	//The Elder----------------------------------------

	if( S~="TheElder.unr" )
	{
		ZI = ZoneInfo(DynamicLoadObject("TheElder.ZoneInfo0", class'ZoneInfo'));
		if( ZI!=None )
			ZI.bNeutralZone=True;
	}

	if( S~="TheElder01.unr" )
	{
		M = Mover(DynamicLoadObject("TheElder01.Mover9", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;

		M = Mover(DynamicLoadObject("TheElder01.Mover12", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
	}

	if( S~="TheElder02.unr" )
	{
		wTP = Spawn(class'wTPFix',,,vect(1821.507080,-13214.152344,1128.000000));
		if( wTP!=None )
			wTP.Tag = 'cover';
			wTP.bEnabled = False;
		//	wTP.URL = theelder$"#Terentry?peer";
	}

	//Hexephet--------------------------------------

	if( S~="FissionSmelter.unr" )
	{
		T = Trigger(DynamicLoadObject("FissionSmelter.Trigger30",Class'Trigger'));
		if( T!=None )
			T.SetCollisionSize(192,192);

		T = Trigger(DynamicLoadObject("FissionSmelter.Trigger28",Class'Trigger'));
		if( T!=None )
			T.SetCollisionSize(192,192);

		T = Trigger(DynamicLoadObject("FissionSmelter.Trigger77",Class'Trigger'));
		if( T!=None )
			T.SetCollisionSize(192,192);

		T = Trigger(DynamicLoadObject("FissionSmelter.Trigger78",Class'Trigger'));
		if( T!=None )
			T.SetCollisionSize(192,192);

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute6", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute3", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute4", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute1", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute2", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;

		PA = Pawn(DynamicLoadObject("FissionSmelter.LesserBrute5", class'Pawn'));
		if( PA!=None )
			PA.GroundSpeed=150;
			PA.AccelRate=100;
	}

	if( S~="HCLF5.unr" )
	{
		M = Mover(DynamicLoadObject("HCLF5.AttachMover1", class'Mover'));
		if( M!=None )
			M.DelayTime = 1;
	}

	if( S~="HCL5.unr" )
	{
		M = Mover(DynamicLoadObject("HCLF5.AttachMover1", class'Mover'));
		if( M!=None )
			M.DelayTime = 1;
	}

	//Sinistral-------------------------------------

	if( S~="Sinistral_Level6.unr" )
	{
		M = Mover(DynamicLoadObject("Sinistral_Level6.Mover88", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;

		M = Mover(DynamicLoadObject("Sinistral_Level6.Mover89", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
			M.bTriggerOnceOnly = True;

		M = Mover(DynamicLoadObject("Sinistral_Level6.Mover27", class'Mover'));
		if( M!=None )
			M.MoverEncroachType = ME_IgnoreWhenEncroach;
	}

	//New Alcatraz----------------------------------

	if( S~="NewAlc1.unr" )
	{
		F2 = Fan2(DynamicLoadObject("NewAlc1.Fan3", class'Fan2'));
		if( F2!=None )
			F2.SetCollision(false,false,false);
			F2.bProjTarget=False;

		DZI = Spawn(class'DynamicWaterZoneInfo',,,vect(11844,-1026,-4489));
		if( DZI!=None )
			DZI.ZoneAreaType = DZONE_Cylinder;
	}

	if( S~="NewAlc2.unr" )
	{
		TP = Teleporter(DynamicLoadObject("NewAlc2.Teleporter1", class'Teleporter'));
		if( TP!=None )
			TP.SetCollisionSize(300,300);
	}

	//The Crash-------------------------------------


	if( S~="TheCrash2.unr" )
	{
		P = PlayerStart(DynamicLoadObject("TheCrash2.PlayerStart2",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		P = PlayerStart(DynamicLoadObject("TheCrash2.PlayerStart3",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=False;
			P.bEnabled=False;
			P.bSinglePlayerStart=False;

		M = Mover(DynamicLoadObject("TheCrash2.Mover0", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = False;

		M = Mover(DynamicLoadObject("TheCrash2.Mover5", class'Mover'));
		if( M!=None )
			M.bTriggerOnceOnly = True;
	}


	//========================================================
	//RLDM/Deathmatch Maps
	//========================================================

	if( S~="DM-Letting.unr" )
	{
		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart0",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;

		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart5",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;

		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart6",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;

		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart7",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;

		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart8",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;

		P = PlayerStart(DynamicLoadObject("DM-Letting.PlayerStart9",Class'PlayerStart'));
		if( P!=None )
			P.bCoopStart=True;
			P.bEnabled=True;
			P.bSinglePlayerStart=True;
	}

	//========================================================
	//All Maps
	//========================================================

	foreach allactors (class'Mover',M)
	{
		if(M.MoverEncroachType==ME_ReturnWhenEncroach && M.bTriggerOnceOnly)
		M.MoverEncroachType=ME_IgnoreWhenEncroach;	
	}
}

function ProcessServerTravel(string URL, bool bItems)
{
	TempLastMap=LastMap;
	LastMap=URL;
	SaveConfig();
	Super.ProcessServerTravel(URL,bItems);
}


function SaveOldMap()
{LastMap=TempLastMap;}

event InitGame( string Options, out string Error )
{
	local Teleporter TP;
	local wTPFix NewTP;
	local NaliFruit NF;

	if(bReturnToLastMap && Level.NetMode!=NM_Standalone && LastMap!=GetURLMap())
	{Level.ServerTravel(LastMap,false);}

	if(ForcedHoliday>0)
	HolidayNum=ForcedHoliday;
	else if	((Level.Month==10 && Level.Day>=17) || (Level.Month==11 && Level.Day<=4))
	HolidayNum=1; //Halloween
	else if (Level.Month==12 && Level.Day>=21)
	HolidayNum=2; //Xmas
	else if (Level.Month==1 && Level.Day<=8)
	HolidayNum=5; //New Year
	else if ((Level.Month==4 && Level.Day<3) || (Level.Month==3 && Level.Day>=31))
	HolidayNum=3; //April Fools
	else if (Level.Month==5 && (Level.Day>=21 && Level.Day<=23))
	HolidayNum=4; //Unreal BDay

	if(AFKTimer<60) AFKTimer=60;

	AccessManagerClass="WolfCoop.wAAM";
	if(StartingLives<=0) StartingLives=1;
	CurrentExtraLifeScore=ExtraLifeScore;
	Level.bSupportsRealCrouching=False;
	if(bUseHookMutators)
	LoadHookMutators();
	if(!bDisableMapFixes)
	FixCoopMaps();

	Class'StingerAmmo'.Default.MultiSkins[4]=Texture'JTaryPickJ42Fix';
	Class'StingerProjectile'.Default.MultiSkins[4]=Texture'JTaryPickJ42Fix';

	foreach allactors(class 'Teleporter', TP)
	{if ( InStr( TP.URL, "?" ) > -1 )
		{
			if(bShowEnds)
			{TP.bHidden = False;
			if(TP.Texture==None)
			TP.Texture = texture'S_Teleport';
			TP.bAlwaysRelevant = True;
			if(bool(UpakTeleporter(TP)))
			TP.DrawType=DT_Sprite;}
		}
	}
	foreach allactors(class 'NaliFruit', NF)
	NF.bGrowWhenSeen=True;

	Super.InitGame(Options,Error);
}


function SpawnCheckPoints()
{
	local int i;
	local wCheckPoint CP;
	local String S;

	S = GetURLMap();

	For(I=0; I<array_size(CheckPoints); I++)
	{
		if(S ~= CheckPoints[I].MapName)
		{
			if(CheckPoints[I].CheckPointType==2 && bEnableLives && bExtraLives && MaxLives>1)
			CP=Spawn(class'wExtraLifeCheckPoint',,,CheckPoints[I].CPLocation,CheckPoints[I].CPRotation);
			else if((CheckPoints[I].CheckPointType==1 || CheckPoints[I].CheckPointType==2) && bEnableLives)
			CP=Spawn(class'wReviveCheckPoint',,,CheckPoints[I].CPLocation,CheckPoints[I].CPRotation);
			else
			CP=Spawn(class'wCheckPoint',,,CheckPoints[I].CPLocation,CheckPoints[I].CPRotation);
			if(CP!=None)
			{CP.SetUpCheckPoint(CheckPoints[I].CPRadius,CheckPoints[I].CPHeight,CheckPoints[I].bEventEnabled,CheckPoints[I].EventTag);}
			CP=None;
		}
	}
}


function LoadHookMutators()
{
	local int i;
	local class<mutator> Mut;
	local Mutator M;
	
	For(i=0;i<ArrayCount(HookMutator);i++)
	{
		If( Hookmutator[i] == "" ) continue;
		Mut = Class<Mutator>(Dynamicloadobject(HookMutator[i],class'Class'));	
		
		If( Mut==none )
		{
			Log("HookMutator: Failed to load "$HookMutator[i]$".");
			Continue;
		}
		M=Spawn(Mut);
		If( M==None )
		{
			Log("HookMutator: Failed to create "$HookMutator[i]$".");
			Continue;
		}
		
		If( BaseMutator == None ) 
		{
			BaseMutator = M;	
		}
		Else
		{
			BaseMutator.AddMutator( M );
		}
	}
	if(HolidayNum==1)
	{
		For(i=0;i<ArrayCount(HalloweenMutators);i++)
		{
			If( HalloweenMutators[i] ~= "" || HalloweenMutators[i] ~= "None" ) continue;
			Mut = Class<Mutator>(Dynamicloadobject(HalloweenMutators[i],class'Class'));	
			
			If( Mut==none )
			{
				Log("HookMutator (Halloween): Failed to load "$HalloweenMutators[i]$".");
				Continue;
			}
			M=Spawn(Mut);
			If( M==None )
			{
				Log("HookMutator (Halloween): Failed to create "$HalloweenMutators[i]$".");
				Continue;
			}
			
			If( BaseMutator == None ) 
			{
				BaseMutator = M;	
			}
			Else
			{
				BaseMutator.AddMutator( M );
			}
		}
	}
	else if(HolidayNum==2||HolidayNum==5)
	{
		For(i=0;i<ArrayCount(XMasMutators);i++)
		{
			If( XMasMutators[i] ~= "" || XMasMutators[i] ~= "None" ) continue;
			Mut = Class<Mutator>(Dynamicloadobject(XMasMutators[i],class'Class'));	
			
			If( Mut==none )
			{
				Log("HookMutator (XMas): Failed to load "$XMasMutators[i]$".");
				Continue;
			}
			M=Spawn(Mut);
			If( M==None )
			{
				Log("HookMutator (XMas): Failed to create "$XMasMutators[i]$".");
				Continue;
			}
			
			If( BaseMutator == None ) 
			{
				BaseMutator = M;	
			}
			Else
			{
				BaseMutator.AddMutator( M );
			}
		}
	}
	else if(HolidayNum==3)
	{
		Spawn(Class'wHolidayLightsMut');
		For(i=0;i<ArrayCount(AprilFoolsMutators);i++)
		{
			If( AprilFoolsMutators[i] ~= "" || AprilFoolsMutators[i] ~= "None" ) continue;
			Mut = Class<Mutator>(Dynamicloadobject(AprilFoolsMutators[i],class'Class'));	
			
			If( Mut==none )
			{
				Log("HookMutator (AprilFools): Failed to load "$AprilFoolsMutators[i]$".");
				Continue;
			}
			M=Spawn(Mut);
			If( M==None )
			{
				Log("HookMutator (AprilFools): Failed to create "$AprilFoolsMutators[i]$".");
				Continue;
			}
			
			If( BaseMutator == None ) 
			{
				BaseMutator = M;	
			}
			Else
			{
				BaseMutator.AddMutator( M );
			}
		}
	}
	if(HolidayNum==4 || bRandomizeLightsColor)
	{
		Spawn(Class'wHolidayLightsMut');
	}

	If( BaseMutator == None )
		BaseMutator = Spawn(class'Mutator');
}


event playerpawn Login(string Portal, string Options, out string Error, class<playerpawn> SpawnClass)
{
	local PlayerPawn NewPlayer;
	local int i;
	local Class<playerpawn> Desired,Rep;
	local string Classname,PN;
	local bool bNewPlayer;
	//local bool bInvasion;

	Desired = SpawnClass;
	ClassName = String(SpawnClass);
	ClassName = Right( Classname, Len(Classname) - InStr(Classname,".") -1 );

	PN = Left(ParseOption(Options,"Name"),40);

	/*Foreach AllActors(class'RLRespawner',RE)
	{
		if(bStarted && (RE.SaveName~=PN || RE.SaveName~=("Invader "$PN)))
		{Rep = Class<Playerpawn>(DynamicLoadObject( RE.SaveClass, Class'Class' ));
		return Super.Login(Portal, Options, Error, Rep);}
	}

	if(PN~=InvadingPlayer)
	bInvasion=True;*/
	Log(PN);
	if(ClassIsChildOf(SpawnClass,class'Spectator')/* && !bInvasion*/) {NewPlayer=Super.Login(Portal, Options, Error, Class'wSpectator'); return NewPlayer;}

	//if(bInvasion) {InvadingPlayer=""; Rep=Class'RLCoopE.RLSkaarjInvader'; NewPlayer=Super.Login(Portal, Options, Error, Rep);}

	else if (/*!bInvasion && */!ClassIsChildOf(SpawnClass,class'wPlayer'))
	{
		For( I = 0; I < 64; i++ )
		{
			If( ClassReplacement[i].OriginalClass != "" && ClassReplacement[i].ReplacementClass != "" )
			{
				If( ClassReplacement[i].OriginalClass ~= ClassName )
				{
					Rep = Class<Playerpawn>(DynamicLoadObject( ClassReplacement[i].ReplacementClass, Class'Class' ));
					If( Rep == None || !ClassIsChildOf(Rep,class'wPlayer'))
					{
						Log("Failed to replace "$ClassName$" with "$ClassReplacement[i].ReplacementClass,'Log');
						if(!ClassIsChildOf(Rep,class'wPlayer'))
						Log("Reason: Invalid wPlayer Class '"$Rep$"'",'Log');
						else if(Rep == None)
						Log("Reason: Replacement Class is None",'Log');
						NewPlayer=Super.Login(Portal, Options, Error, Class'wFemaleOne');
					}
					else NewPlayer=Super.Login(Portal, Options, Error, Rep);
				}
			}
		}
	}

	if(!bool(NewPlayer))
	NewPlayer = Super.Login(Portal, Options, Error, class'wFemaleOne');
	if ( NewPlayer != None )
	{
		wAAM(GetAccessManager()).wAdminLogin(NewPlayer,NewPlayer.Password);
		if ( !NewPlayer.IsA('wSpectator') )
		{
			NewPlayer.bHidden = false;
			NewPlayer.SetCollision(true,true,true);
		}

		if(bool(wPlayer(NewPlayer)))
		{
			bNewPlayer=True;
			for(i=0; i<array_size(SavePlayers); i++)
			{	if(NewPlayer.GetHumanName()~=SavePlayers[I].PlayerName)
				{Log("Player Recognized:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score);
				wPlayer(NewPlayer).Lives=SavePlayers[I].Lives;
				wPRI(NewPlayer.PlayerReplicationInfo).Score=SavePlayers[I].Score;
				bNewPlayer=False;}
			}
			if(bNewPlayer && (wPlayer(NewPlayer).Lives<=0 || bResetLivesOnMapChange))
			{wPlayer(NewPlayer).Lives=StartingLives;}

			if(MaxLives<=1) wPlayer(NewPlayer).Lives=1;
		}

		log("Logging in to "$Level.Title);
		if ( Level.Title ~= "The Source Antechamber" )
		{
			bSpecialFallDamage = true;
			log("reduce fall damage");
		}
	}

	return NewPlayer;
}

function Logout( pawn Exiting )
{
	local int i;
	local bool bNewSlot;
	if(bool(wPlayer(Exiting)) && !bool(Spectator(Exiting)) && !bool(wSpectator(Exiting)))
	{
		bNewSlot=True;
		for(i=0; i<array_size(SavePlayers); i++)
		{
			if(SavePlayers[I].PlayerName~=Exiting.GetHumanName())
			{SavePlayers[I].Lives=wPlayer(Exiting).Lives;
			SavePlayers[I].Score=wPlayer(Exiting).Score;
			bNewSlot=False;
			Log("Updating Exiting Player:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score);}
		}
		if(bNewSlot)
		{
			I=array_size(SavePlayers);
			SavePlayers[I].PlayerName=Exiting.GetHumanName();
			SavePlayers[I].Lives=wPlayer(Exiting).Lives;
			SavePlayers[I].Score=wPlayer(Exiting).Score;
			Log("Saving Exiting Player:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score);
		}
	}
	Super.Logout(Exiting);
	CheckAlivePlayers();
}

function bool ShouldRespawn(Actor Other)
{
	local wRespawningItem ItemGhost;

	if( bRespawnItems )
	{
		if(AmmoRespawnTime<1)
		AmmoRespawnTime=1;
		if(WeaponRespawnTime<1)
		WeaponRespawnTime=1;
		if(ArmorRespawnTime<1)
		ArmorRespawnTime=1;
		if(PickupRespawnTime<1)
		PickupRespawnTime=1;
		if(HealthRespawnTime<1)
		HealthRespawnTime=1;
		if((Other.IsA('Inventory') && !Inventory(Other).bHeldItem &&	Inventory(Other).RespawnTime != 0))
		{
			if ( Other.IsA('SCUBAGear') || Other.IsA('JumpBoots') )
			Inventory(Other).ReSpawnTime = 1.0;
			else if ( Other.IsA('Flare') || Other.IsA('Seeds') )
			Inventory(Other).ReSpawnTime = FlareAndSeedRespawnTime;
			else if(bool(Ammo(Other)))
			Inventory(Other).ReSpawnTime = AmmoRespawnTime;
			else if(bool(Health(Other)))
			{
				if(NaliFruit(Other)==None || NaliFruit(Other).bGrowWhenSeen)
				Inventory(Other).ReSpawnTime = HealthRespawnTime;
				else return false;
			}
			else if(bool(Weapon(Other)))
			Inventory(Other).ReSpawnTime = WeaponRespawnTime;
			else if(Inventory(Other).bIsAnArmor)
			Inventory(Other).ReSpawnTime = ArmorRespawnTime;
			else if(bool(PickUp(Other)))
			Inventory(Other).ReSpawnTime = PickupRespawnTime;
			if(bShowRespawningItems)
			{ItemGhost=Spawn(class'wRespawningItem',Other,,Other.Location,Other.Rotation);
			ItemGhost.LifeSpan=Inventory(Other).ReSpawnTime;}
			return true;
		}
		return false;
	}
	else 
	{
		if ( Other.IsA('Weapon') && !Weapon(Other).bHeldItem && (Weapon(Other).ReSpawnTime > 0) )
		{
			Inventory(Other).ReSpawnTime = 1.0;
			return true;
		}
		if ( Other.IsA('Suits') && !Other.IsA('KevlarSuit') && !Suits(Other).bHeldItem )
		{
			Inventory(Other).ReSpawnTime = 1.0;
			return true;
		}
		if ( Other.IsA('SCUBAGear') || Other.IsA('JumpBoots') )
		{
			Inventory(Other).ReSpawnTime = 1.0;
			return true;
		}
		return false;
	}
}

simulated function int ReduceDamage(int Damage, name DamageType, pawn injured, pawn instigatedBy)
{
	local int DamageNum;
	if(bool(wPlayer(instigatedBy)) && instigatedBy!=injured && (!bool(wPlayer(injured)) || !bNoFriendlyFire) && Damage>0)
	{	
		DamageNum=Damage;
		if(Difficulty<=0)
		DamageNum*=1.1;
		else if(Difficulty==1)
		DamageNum*=0.9;
		else if(Difficulty>=2)
		DamageNum*=0.8;
		if(DamageNum>0)
		{
			wPlayer(InstigatedBy).PlayHitMarker(DamageType);
			wPlayer(InstigatedBy).LastDamageTarget=Injured;
			if(wPlayer(InstigatedBy).LastDamageTick<=0.66)
			wPlayer(InstigatedBy).LastDamageAmount=DamageNum;
			else
			wPlayer(InstigatedBy).LastDamageAmount+=DamageNum;
			wPlayer(InstigatedBy).LastDamageTick=1;
		}
	}

	return Super.ReduceDamage(Damage,DamageType,injured,instigatedBy);
}


simulated function ScoreKill(pawn Killer, pawn Other)
{
	local int ScoreAmount;
	local wPlayer P;

	if(bool(wPlayer(Killer)) && Other!=Killer)
	{
		wPlayer(Killer).PlayHitMarker('Killed',True);
	}


		if(bool(Bots(Other)))
		{
			ScoreAmount+=50;
			if(bool(SpaceMarine(Other)))
			ScoreAmount+=100;
		}
		else if(Other.IsA('Skaarj'))
		{	
			if(Other.IsA('SkaarjLord'))		
				ScoreAmount+=100;
			else if(Other.IsA('SkaarjBerserker'))		
				ScoreAmount+=85;
			else if(Other.IsA('SkaarjAssassin'))		
				ScoreAmount+=50;
			else if(Other.IsA('SkaarjScout'))		
				ScoreAmount+=25;
			else if(Other.IsA('SkaarjGunner'))		
				ScoreAmount+=50;
			else if(Other.IsA('SkaarjSniper'))		
				ScoreAmount+=50;
			else if(Other.IsA('SkaarjOfficer'))		
				ScoreAmount+=125;
			else if(Other.IsA('SkaarjTrooper'))		
				ScoreAmount+=50;
			else
				ScoreAmount+=25;
		}
		else if(Other.IsA('Brute'))
		{
			if(Other.IsA('LesserBrute'))		
				ScoreAmount+=25;
			else
				ScoreAmount+=40;
			if(Other.IsA('Behemoth'))		
				ScoreAmount+=40;
		}
		else if(Other.IsA('Krall'))
		{			
			if(Other.IsA('KrallElite'))		
				ScoreAmount+=15;
				ScoreAmount+=25;
		}
		else if(Other.IsA('Mercenary'))
		{			
			if(Other.IsA('MercenaryElite'))		
				ScoreAmount+=25;
				ScoreAmount+=50;
		}
		else if(Other.IsA('Gasbag'))
		{			
			if(Other.IsA('GiantGasbag'))		
				ScoreAmount+=65;
				ScoreAmount+=15;
		}
		else if(Other.IsA('Manta'))
		{
			if(Other.IsA('GiantManta'))		
				ScoreAmount+=50;
				ScoreAmount+=10;
		}

		else if(Other.IsA('Titan'))
		{
			ScoreAmount+=500;
			if(Other.IsA('StoneTitan'))
			ScoreAmount+=250;
		}
		else if(Other.IsA('WarLord'))
			ScoreAmount+=1000;
		else if(Other.IsA('Queen'))
			ScoreAmount+=1250;

		else if(Other.IsA('Fly'))
			ScoreAmount+=10;
		else if(Other.IsA('DevilFish'))
			ScoreAmount+=10;
		else if(Other.IsA('Hawk'))
			ScoreAmount+=15;
		else if(Other.IsA('Pupae'))
			ScoreAmount+=15;
		else if(Other.IsA('Slith'))
			ScoreAmount+=25;
		else if(Other.IsA('Predator'))
			ScoreAmount+=10;
		else if(Other.IsA('Spinner'))
			ScoreAmount+=15;
		else if(Other.IsA('Squid'))
			ScoreAmount+=15;
		else if(Other.IsA('Tentacle'))
			ScoreAmount+=15;

		else if(Other.IsA('Nali') || Other.IsA('Cow'))
			ScoreAmount-=100;
		else if(Other.IsA('BabyCow'))
			ScoreAmount-=150;
		else if(Other.AttitudeToPlayer==ATTITUDE_Friendly || Other.AttitudeToPlayer==ATTITUDE_Follow)
			ScoreAmount-=50;

		else if(bool(PlayerPawn(Other)))
		{
			if(wPRI(Other.PlayerReplicationInfo).bInvader!=wPRI(Killer.PlayerReplicationInfo).bInvader)
			ScoreAmount+=200;
			else
			ScoreAmount-=200;
		}
		else
			ScoreAmount+=Other.Default.Health*0.2;

		if(ScriptedPawn(Other)!=None && !ScriptedPawn(Other).Default.bIsBoss && ScriptedPawn(Other).bIsBoss)
		ScoreAmount*=10;
	
	Other.DieCount++;
	if (killer == Other || killer == None)
	{
		if ( Other.PlayerReplicationInfo!=None )
			Other.PlayerReplicationInfo.Score -= 100;
	}
	else if ( killer != None )
	{
		killer.killCount++;
		if ( killer.PlayerReplicationInfo != None )
			killer.PlayerReplicationInfo.Score += ScoreAmount;
	}

	if(ScoreAmount>0)
	TotalScore+=ScoreAmount;
	if(TotalScore>0 && bEnableLives && bExtraLives && ExtraLifeScore>0 && MaxLives>1)
	{
		if(wPlayer(Killer)!=None && bPersonalExtraLives && Killer.PlayerReplicationInfo.Score>=ExtraLifeScore)
		{
			Killer.ClientMessage("Extra Life!",'LowCriticalEvent');
			BroadcastMessage(Killer.GetHumanName()@"gained an Extra Life!");
			if(bSeriousSamExtraLife)
			wPlayer(Killer).ClientPlaySound(Sound'SeriousSamExtraLife');
			else if(bMarioSounds || HolidayNum==3)
			wPlayer(Killer).ClientPlaySound(Sound'MarioExtraLife');
			else
			wPlayer(Killer).ClientPlaySound(Sound'ExtraLife');
			if(wPlayer(Killer).Lives<MaxLives)
			wPlayer(Killer).Lives+=1;
			Killer.PlayerReplicationInfo.Score=0;
		}
		else if(TotalScore>=CurrentExtraLifeScore && !bPersonalExtraLives)
		{
			while(CurrentExtraLifeScore<=TotalScore)
			{
				BroadcastMessage("Extra Life!",false,'LowCriticalEvent');
				foreach allactors(class'wPlayer',P)
				{if(bSeriousSamExtraLife)
				P.ClientPlaySound(Sound'SeriousSamExtraLife');
				else if(bMarioSounds || HolidayNum==3)
				P.ClientPlaySound(Sound'MarioExtraLife');
				else
				P.ClientPlaySound(Sound'ExtraLife');
				if(P.Lives<MaxLives)
				P.Lives+=1;}
				CurrentExtraLifeScore+=ExtraLifeScore;
			}
		}
	}

	if(bEnableLives && PlayerPawn(Other)!=None)
	CheckAlivePlayers();
}

function Killed(pawn killer, pawn Other, name damageType)
{
	Super(UnrealGameInfo).Killed(killer, Other, damageType);
}

Function CheckAlivePlayers()
{
	local wPlayer P;
	local int i,PlayerCount;

	if(!bEnableLives) return;

	foreach allactors(class'wPlayer',P)
	{
		if((P.Health>0 || P.Lives>0) && !P.bAFK && !P.IsInState('EndGameSpectate'))
		i++;
		PlayerCount++;
	}

	if(i==1 && PlayerCount>1 && !bLMSWarn)
	{	BroadcastMessage("Last Man Standing!",false,'RedCriticalEvent');
		foreach allactors(class'wPlayer',P)
		{
			P.ClientPlaySound(Sound'LastManStanding');
		}
		bLMSWarn=True;
	}
	else bLMSWarn=False;

	if(i<=0 && PlayerCount>0)
	{
		if(bEndReached && bPlayersEndGameSpectate)
		{
			foreach allactors(class'wPlayer',P)
			{SendPlayer(P,SaveURL); return;}
		}
		else if(bRestartMapOnGameOver)
		GoToState('RestartingMap');
		else
		{GameOverText();
		SetTimer(2.5,false,'PlayGameOver');
		SetTimer(3,false,'RestartPlayers');}
	}
}

function RestartPlayers()
{
	local Pawn P;

	BroadcastMessage("The Enemy recovers their strength...",false,'RedCriticalEvent');

	foreach allactors(class'Pawn',P)
	{
		if(wPlayer(P)!=None && P.Health<=0 && !bool(wSpectator(P)))
		{
			wPlayer(P).ServerReStartPlayer();
			wPlayer(P).Lives=StartingLives;
			if(MaxLives<=1)
			wPlayer(P).Lives=1;
			wPlayer(P).ViewTarget=None;
		}
		else if(PlayerPawn(P)==None && P.Health<=P.Default.Health)
		P.Health=P.Default.Health;
	}
	GameOverTextOff();
}

function GameOverText()
{
	local wPRI PRI;

	foreach allactors(class'wPRI',PRI)
	PRI.bGameOver=True;
}

function GameOverTextOff()
{
	local wPRI PRI;

	foreach allactors(class'wPRI',PRI)
	PRI.bGameOver=False;
}

state RestartingMap
{
	ignores CheckAlivePlayers;

	function Timer()
	{
		local PlayerPawn P;

		foreach allactors(class'PlayerPawn',P)
		{
			if(P.Health>0)
			{
				SetTimer(0,false);
				GameOverTextOff();
				GoToState('None');
			}
		}
	}

	begin:
	SetTimer(0.01,true);

	sleep(2.5);
	PlayGameOver();
	GameOverText();
	sleep(2.5);

	while(level.HasDownloaders()) Sleep(0);
	consolecommand("servertravel "$self.getUrlMap());
}

function PlayGameOver()
{
	local PlayerPawn P;

	foreach allactors(class'PlayerPawn',P)
	{
		if(bMarioSounds || HolidayNum==3)
		P.ClientPlaySound(Sound'MarioGameOver');
		else
		P.ClientPlaySound(Sound'laugh1WL');
	}
}

Function AddDefaultInventory( Pawn P )
{
	local int i,ItemNum;
	local inventory inv;
	local translator NewTranslator;
	local bool bCWP,bCW,bItemFound;
	local string ItemName;

	if(wPRI(P.PlayerReplicationInfo)!=None)
	wPRI(P.PlayerReplicationInfo).Holiday=HolidayNum;

	if( P.IsA('wSpectator') )
	return;

	if(P.Health<=0) P.Health=P.Default.Health;

	// Spawn translator.
	if( P.FindInventoryType(class'Translator') == None )
	{
		newTranslator = Spawn(class'Translator',,,P.Location);
		if( newTranslator != None )
		{
			newTranslator.bHeldItem = true;
			newTranslator.GiveTo( P );
			P.SelectedItem = newTranslator;
			newTranslator.PickupFunction(P);
		}
	}

	//Extra Items
	For(I=0; I<64; I++)
	{	if(GiveItems[I]!="" && GiveItems[I]!=" " && GiveItems[I]!="None")
		{
			if(InStr(GiveItems[I],"?")>=0)
			ItemName=Left(GiveItems[I],InStr(GiveItems[I],"?"));
			else ItemName=GiveItems[I];
			bItemFound=False;
			for(Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory)
			{
				if(Inv.Class==class<Inventory>(DynamicLoadObject(ItemName,class'Class')))
				{
					bItemFound=True;
					if(InStr(GiveItems[I],"?")>=0)
					{
						if(Pickup(Inv)!=None && InStr(GiveItems[I],"?Copies=")>=0)
						{
							ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Copies=")+8));
							if(Pickup(Inv).NumCopies<ItemNum-1) Pickup(Inv).NumCopies=ItemNum-1;
						}
						if(InStr(GiveItems[I],"?Charges=")>=0)
						{
							ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Charges=")+9));
							if(Inv.Charge<ItemNum) Inv.Charge = ItemNum;
						}
						if(InStr(GiveItems[I],"?Charge=")>=0)
						{
							ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Charge=")+8));
							if(Inv.Charge<ItemNum) Inv.Charge = ItemNum;
						}
					}
					else if(Inv.Charge<Inv.Default.Charge) Inv.Charge=Inv.Default.Charge;
				}
			}
			if(!bItemFound)
			Inv=Spawn(class<Inventory>(DynamicLoadObject(ItemName,class'Class')),,,P.Location);
		}
		if( Inv != None )
		{
			Inv.bHeldItem = true;
			Inv.PickupSound=None;
			Inv.PickupMessage="";
			if(bool(Weapon(Inv)))
			Weapon(Inv).SelectSound=None;
			Inv.SetOwner(P);
			Inv.Touch(P);
			Inv.PickupSound=Inv.Default.PickupSound;
			Inv.PickupMessage=Inv.Default.PickupMessage;
			if(bool(Weapon(Inv)))
			Weapon(Inv).SelectSound=Weapon(Inv).Default.SelectSound;
			if(InStr(GiveItems[I],"?")>=0)
			{
				if(Pickup(Inv)!=None && InStr(GiveItems[I],"?Copies=")>=0)
				{
					ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Copies=")+8));
					Pickup(Inv).NumCopies = ItemNum-1;
				}
				if(InStr(GiveItems[I],"?Charges=")>=0)
				{
					ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Charges=")+9));
					Inv.Charge = ItemNum;
				}
				if(InStr(GiveItems[I],"?Charge=")>=0)
				{
					ItemNum=Int(Mid(GiveItems[I],InStr(GiveItems[I],"?Charge=")+8));
					Inv.Charge = ItemNum;
				}
			}
		}
	}
}

function DiscardInventory(Pawn Other)
{
	local inventory inv,next;
	local int i;

	if(!bool(wPlayer(Other))) 
	{
		if(!bDropInventoryOnDeath || !bool(Bots(Other)))
		{Super.DiscardInventory(Other); return;}
	}
	
	Other.bFire=0; Other.bAltFire=0;
	Other.PendingWeapon=None;
	Other.Weapon=None;

	For(Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory)
	{
		if(Inv.bActive || Inv.IsInState('Active'))
		{
			//Inv.bActive=False;
			//Inv.GoToState('Deactivated');
			Inv.Activate();
		}
	}

	if(!bInventoryLossOnDeath && !bDropInventoryOnDeath) return;
	else if(!bDropInventoryOnDeath)
	{
		if(wPlayer(Other)!=None && (!bEnableLives || bPenalizeInventoryOnLifeLoss || (wPRI(PlayerPawn(Other).PlayerReplicationInfo).Lives<=1 && !bAllowReviving && !bExtraLives)))
		{
			for(i=0; i<array_size(wPlayer(Other).CollectedItems); i++)
			wPlayer(Other).CollectedItems[I]=None;
			array_size(wPlayer(Other).CollectedItems,0);
			Super.DiscardInventory(Other);
			return;
		}
	}

	if(Bots(Other)!=None || (!bEnableLives || bPenalizeInventoryOnLifeLoss || (wPRI(PlayerPawn(Other).PlayerReplicationInfo).Lives<=1 && !bAllowReviving)))
	{
		if(wPlayer(Other)!=None)
		{
			for(i=0; i<array_size(wPlayer(Other).CollectedItems); i++)
			wPlayer(Other).CollectedItems[I]=None;
			array_size(wPlayer(Other).CollectedItems,0);
		}
		For(Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory)
		{
			if(Translator(Inv)!=None || (Weapon(Inv)!=None && !Weapon(Inv).bCanThrow) || DefaultAmmo(Inv)!=None)
			Inv.Destroy();
			if(ShieldBelt(Inv)!=None) ShieldBelt(Inv).MyEffect.Destroy();
			while(Pickup(Inv)!=None && Pickup(Inv).NumCopies>0)
			{	Next.RespawnTime=0.0;
				Next.BecomePickup();
				Next.RemoteRole = ROLE_DumbProxy;
				Next.SetPhysics(PHYS_Falling);
				Next.bCollideWorld = true;
				Next.Velocity = Other.Velocity + VRand()*500;
				Next.GotoState('PickUp', 'Dropped');
				Pickup(Inv).NumCopies--;
			}
			Other.DeleteInventory(Inv);
			Inv.SetLocation(Other.Location);
			Inv.RespawnTime=0.0;
			Inv.BecomePickup();
			Inv.RemoteRole = ROLE_DumbProxy;
			Inv.SetPhysics(PHYS_Falling);
			Inv.bCollideWorld = true;
			Inv.Velocity = Other.Velocity + VRand()*500;
			Inv.GotoState('PickUp', 'Dropped');
			Inv.SetRotation(rot(0,65536,0)*FRand());
		}
	}
}

function VoteEndCheck()
{
	local wPlayer P;
	local float votes,players,percentage;
	local int permsg, permsg2;

	if(bChangingMap || !bEnableVoteEnd) return;
	foreach allactors(class'wPlayer', p)
	{
		if(!bEnableLives || (p.Lives>0 || p.Health>0))
		{
			if(wPRI(p.PlayerReplicationInfo).bVoteEnd)
			votes+=1;
			players+=1;
		}
	}
	if(players<=0 || votes<=0) return; //I doubt this will ever happen but just to be sure
	percentage=votes/players;
	permsg=percentage*100;
	if(percentage>=1 && bEndReached)
	{bChangingMap=True;}
	else
	{BroadCastMessage(permsg$"% of players voted to End, 100% of Players required to End");
	BroadCastMessage("You can vote to End by saying 'VoteEnd'");}
}



function SendPlayer( PlayerPawn aPlayer, string URL )
{
	local GameRules G;
	local wPRI PRI;
	local bool bAlreadySaved;
	local int i;
	local inventory Inv;
	
	if(!bEnableVoteEnd) {Super.SendPlayer(aPlayer,URL); return;}

	if(bool(wPlayer(aPlayer)) && wPRI(aPlayer.PlayerReplicationInfo).bInvader) return;

	//BroadCastMessage("Debug: Sending "$aPlayer.PlayerReplicationInfo.PlayerName$" to "$URL);
	SaveURL=URL;
	wPRI(aPlayer.PlayerReplicationInfo).VotedURL=URL;

	if(wPlayer(aPlayer)!=None)
	{
		if(Level.NetMode!=NM_Standalone && !wPRI(aPlayer.PlayerReplicationInfo).bVoteEnd)
		{
			BroadcastMessage(aPlayer.GetHumanName()@"has reached the end!",true,'CriticalEvent');
			if(!bNoChatVoteEnd)
			BroadcastMessage("Type 'VoteEnd' in chat to vote to end the map!");
		}
		wPRI(aPlayer.PlayerReplicationInfo).bVoteEnd=True;
		if(bPlayersEndGameSpectate)
		aPlayer.GoToState('EndGameSpectate');
		if(aPlayer==InvasionTarget)
		{
			ForEach AllActors(class'wPRI', PRI)
			{	if(PRI.bInvader)
				{
					Pawn(PRI.Owner).ClientMessage("Target Escaped!",'RedCriticalEvent');
				}
			}
			SetTimer(5,false,'InvaderGameOver');
		}
		if(!bEndTimeStarted)
		CheckEndTimer();
	}

	ForEach AllActors(class'wPRI', PRI)
	{
		if(!PRI.bVoteEnd && !PRI.bIsSpectator && (PRI.Health>0 || PRI.Lives>0) && !PRI.bAFK  && !PRI.bInvader)
		return;

		if(PRI.Health<=0 && bInventoryLossOnDeath && PRI.Lives<=0 && !PRI.bIsSpectator)
		{
			For(Inv=Pawn(PRI.Owner).Inventory; Inv!=None; Inv=Inv.Inventory)
			Inv.Destroy();
		}
	}

	if(EndTimeCount>0)
	{EndTimeCount=0; SetTimer(0,false,'EndTimer');}


	ForEach AllActors(class'wPRI', PRI)
	{
		if(PRI.bVoteEnd && PRI.VotedURL!="")
		SavedURLs[SavedURLCount]=PRI.VotedURL;
		SavedURLCount++;
	}

	For(i=0; i<16; i++)
	{
		ForEach AllActors(class'wPRI', PRI)
		{
			if(PRI.bVoteEnd && PRI.VotedURL!="" && PRI.VotedURL~=SavedURLs[i])
			URLVoteCount[i]+=1;
		}
		if(URLVoteCount[URLWinner]<URLVoteCount[i])
		URLWinner=i;
	}
	
	URL=SavedURLs[URLWinner];

	if ( GameRules!=None )
	{
		for ( G=GameRules; G!=None; G=G.NextRules )
			if ( G.bHandleMapEvents && !G.CanCoopTravel(aPlayer,URL) )
				{return;}
	}
	
	if ( left(URL,11) ~= "extremeDGen")//change to fixed map instead
	{
		if(DynamicLoadObject("EXTREMEDarkGen.MyLevel",class'Level') != None)
		{
			Level.ServerTravel( "EXTREMEDarkGen", True);
			return;
		}
	}
	if(InStr(Locs(URL),Locs("ReturnToLastMap"))>=0)
	{Level.ServerTravel( URL, false ); return;}
	if(InStr(Locs(URL),Locs("ResetPlayers"))>=0)
	ResetPlayers();

	Level.ServerTravel( URL, true );
}

function ResetPlayers()
{
	local wPlayer P;

	ForEach AllActors(Class'wPlayer',P)
	{
		ResetPlayer(P);
	}	
}

function ResetPlayer(PlayerPawn P)
{
	local Inventory Inv;

	if(!bool(P)) return;
	P.Health=P.Default.Health;
	For(Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory)
	{if(!Inv.IsA('Translator')) Inv.Destroy();}
	AddDefaultInventory(P);
}

function EndTimer()
{
	local wPRI PRI;
	local PlayerPawn P;

	if(EndTimeCount>=0)
	EndTimeCount-=1;
	ForEach AllActors(class'wPRI',PRI)
	{
		if(PRI.bAFK && bEndTimerPunish)
		{PRI.bAFK=False; BroadCastMessage(PRI.PlayerName$" was kicked for being AFK during the End Timer"); PRI.Owner.Destroy();}
		PRI.EndTimer=EndTimeCount;
	}
	if(EndTimeCount==0)
	{
		if(bNeutralMap || !bEndTimerPunish)
		{
			ForEach AllActors(class'wPRI',PRI)
			PRI.bVoteEnd=True;
			BroadCastMessage("Times Up!",True,'RedCriticalEvent');
			SetTimer(0.1,false,'DelaySend');
		}
		else
		{
			BroadCastMessage("Times Up!",True,'RedCriticalEvent');
			ForEach AllActors(class'wPRI',PRI)
			{if(!PRI.bVoteEnd) {Pawn(PRI.Owner).GibbedBy(Pawn(PRI.Owner)); BroadCastMessage(PRI.PlayerName$" was left behind...",false,'RedCriticalEvent'); PRI.bVoteEnd=True;}}
			PlayerPawn(PRI.Owner).ClientPlaySound(Sound'laugh1WL');
			SetTimer(0.1,false,'DelaySend');
		}
	}
	if(EndTimeCount<=10&&EndTimeCount>0)
	{
		ForEach AllActors(class'wPRI',PRI)
		PlayerPawn(PRI.Owner).ClientPlaySound(Sound'ScaryN6');
	}
	SetTimer(1,false,'EndTimer');
}

function CheckEndTimer()
{
	local wPRI PRI;
	local float votes, players, percentage;
	
	if(EndTimeCount>0)
	return;

	ForEach AllActors(class'wPRI', PRI)
	{
		if(!PRI.bIsSpectator && !PRI.bAFK && PRI.Health>0 && !PRI.bInvader)
		{
			players+=1;
			if(PRI.bVoteEnd)
			votes+=1;
		}
	}

	percentage=votes/players;

	if(Percentage>=0.5 && EndTimeCount==0)
	{
		bEndTimeStarted=True;
		if(EndTime<30)
		EndTimeCount=30;
		else
		EndTimeCount=EndTime;
		if(bEndTimerPunish && players>1)
		BroadCastMessage("HURRY UP!!",false,'RedCriticalEvent');
		SetTimer(1,false,'EndTimer');
		TriggerEvent('EndTimerStart');
	}
}

function DelaySend()
{
	local PlayerPawn P;

	foreach allactors(Class'PlayerPawn',P)
	{
		if(!P.IsA('Spectator') && wPRI(P.PlayerReplicationInfo).bVoteEnd)
		{
			if(wPRI(P.PlayerReplicationInfo).VotedURL!="")
			SaveURL=wPRI(P.PlayerReplicationInfo).VotedURL;
			SendPlayer(P,SaveURL);
			return;
		}
	} 
}

function bool IsRelevant(Actor Other)
{
	local wTriggeredDeath wTD;
	local wWeaponPowerUp wPU;
	local int i;

	if(HolidayNum==3)
	{
		Other.Skin=Texture'DefaultTexture';
		for (i=0; i<8; i++)
		Other.MultiSkins[i]=Texture'DefaultTexture';
		Other.Texture=Texture'DefaultTexture';
	}
	if(Other.IsA('Flare') && bPermanentFlares)
	Flare(Other).Charge=1234567;
	if(Other.IsA('TriggeredDeath') && !Other.IsA('wTriggeredDeath'))
	{
		wTD = Spawn(Class'wTriggeredDeath',Other.Owner,Other.tag,Other.Location, Other.Rotation);
		if ( wTD != None )
		{
			wTD.SetCollisionSize(Other.CollisionRadius,Other.CollisionHeight);
			wTD.Tag=TriggeredDeath(Other).Tag;
			wTD.Event=TriggeredDeath(Other).Event;
			wTD.MaleDeathSound=TriggeredDeath(Other).MaleDeathSound;
			wTD.FemaleDeathSound=TriggeredDeath(Other).FemaleDeathSound;
			wTD.StartFlashScale=TriggeredDeath(Other).StartFlashScale;
			wTD.StartFlashFog=TriggeredDeath(Other).StartFlashFog;
			wTD.EndFlashScale=TriggeredDeath(Other).EndFlashScale;
			wTD.EndFlashFog=TriggeredDeath(Other).EndFlashFog;
			wTD.ChangeTime=TriggeredDeath(Other).ChangeTime;
			wTD.DeathName=TriggeredDeath(Other).DeathName;
			wTD.bDestroyItems=TriggeredDeath(Other).bDestroyItems;
			return False;
		}
	}
	if(Other.Class==Class'WeaponPowerUp' && (bUniquePowerUps || bUniqueItems))
	{
		wPU = Spawn(Class'wWeaponPowerUp',Other.Owner,Other.tag,Other.Location, Other.Rotation);
		if ( wPU != None )
		{
			wPU.SetCollisionSize(Other.CollisionRadius,Other.CollisionHeight);
			wPU.Tag=TriggeredDeath(Other).Tag;
			wPU.Event=TriggeredDeath(Other).Event;
			Inventory(Other).MyMarker.markedItem = wPU;
			wPU.myMarker = Inventory(Other).myMarker;
			Inventory(Other).myMarker = None;
			wPU.DrawScale=Other.DrawScale;
			wPU.SetCollisionSize(Other.CollisionRadius,Other.CollisionHeight);
			if(Other.Skin!=Other.Default.Skin)
			wPU.Skin=Other.Skin;
			for(i=0;i<8;i++)
			{if(Other.MultiSkins[i]!=Other.Default.MultiSkins[i])
			wPU.MultiSkins[i]=Other.MultiSkins[i];}
			if(Other.Texture!=Other.Default.Texture)
			wPU.Texture=Other.Texture;
			return False;
		}
	}
	return Super.IsRelevant(Other);
}

function bool PickupQuery( Pawn Other, Inventory item )
{
	local int i;
	local Inventory Inv;

	if((bUniquePowerUps || bUniqueItems) && WeaponPowerUp(Item)!=None && wPlayer(Other)!=None)
	{
		for(i=0; i<array_size(wPlayer(Other).CollectedItems); i++)
		{if(wPlayer(Other).CollectedItems[i]==Item) return false;}
		for (inv=other.Inventory; inv!=None; inv=inv.Inventory)
		{
			if (inv.isa('dispersionpistol') && dispersionpistol(inv).powerlevel<4)
			{
				WeaponPowerUp(Item).ActivateSound = WeaponPowerUp(Item).PowerUpSounds[dispersionpistol(inv).PowerLevel];
				DispersionPistol(Inv).HandlePickupQuery(Item);
				wPlayer(Other).CollectedItems[array_size(wPlayer(Other).CollectedItems)]=Item;
				return True;
			}
		}
		return Super.PickupQuery(Other,Item);
	}
	if(bUniqueItems && wPlayer(Other)!=None)
	{
		for(i=0; i<array_size(wPlayer(Other).CollectedItems); i++)
		{if(wPlayer(Other).CollectedItems[i]==Item) return false;}
		wPlayer(Other).CollectedItems[array_size(wPlayer(Other).CollectedItems)]=Item; return Super.PickupQuery(Other,Item);
	}
	else return Super.PickupQuery(Other,Item);
}

defaultproperties
{
				bRestoreDrownDamage=True
				bEnableVoteEnd=True
				bShowEnds=True
				bEnableCheckPoints=True
				bRealCrouch=True
				bShowRespawningItems=True
				bAllowCheckpointRelocate=True
				bCheckpointHeals=True
				EndTime=30
				AFKTimer=120
				CheckPoints(0)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-8883.000000,Y=-9064.000000,Z=-1282.000000),CPRotation=(Pitch=65523,Yaw=32332))
				CheckPoints(1)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-13374.000000,Y=3543.000000,Z=-218.000000),CPRotation=(Pitch=1015,Yaw=65525))
				CheckPoints(2)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-16030.000000,Y=4198.000000,Z=-4857.000000),CPRotation=(Pitch=877,Yaw=16976))
				CheckPoints(3)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=-6711.000000,Y=22188.000000,Z=3484.000000),CPRotation=(Pitch=63434,Yaw=35251))
				CheckPoints(4)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=1083.000000,Y=17199.000000,Z=1351.000000),CPRotation=(Pitch=616,Yaw=44098))
				CheckPoints(5)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=-7559.000000,Y=18550.000000,Z=3830.000000),CPRotation=(Pitch=1169,Yaw=36342))
				CheckPoints(6)=(MapName="Shrak1",CPLocation=(X=6232.000000,Y=474.000000,Z=-388.000000),CPRotation=(Pitch=65447,Yaw=49651))
				CheckPoints(7)=(MapName="Shrak2",CPLocation=(X=4435.000000,Y=659.000000,Z=188.000000),CPRotation=(Pitch=65447,Yaw=49651))
				CheckPoints(8)=(MapName="Shrak3",CPLocation=(X=2.000000,Y=-73.000000,Z=107.000000),CPRotation=(Pitch=661,Yaw=49111,Roll=65530))
				CheckPoints(9)=(MapName="Dawn_UnDead",CPLocation=(X=4183.000000,Y=-417.000000,Z=-1262.000000),CPRotation=(Pitch=64783,Yaw=2277,Roll=7))
				CheckPoints(10)=(MapName="HCLF2",CPLocation=(X=9159.000000,Y=-9119.000000,Z=-3278.000000),CPRotation=(Pitch=598,Yaw=53098,Roll=65534))
				CheckPoints(11)=(MapName="HCLF2",CPLocation=(X=4398.000000,Y=-7206.000000,Z=-6087.000000),CPRotation=(Yaw=28974,Roll=65534),bEventEnabled=True,EventTag="Skill")
				CheckPoints(12)=(MapName="HCLF3",CPLocation=(X=6291.000000,Y=-5796.000000,Z=-3815.000000),CPRotation=(Pitch=276,Yaw=40058))
				CheckPoints(13)=(MapName="HCLF3",CPLocation=(X=-7143.000000,Y=-4381.000000,Z=-5282.000000),CPRotation=(Pitch=598,Yaw=16697,Roll=5),bEventEnabled=True,EventTag="basement")
				CheckPoints(14)=(MapName="HCLF4",CPLocation=(X=-2662.000000,Y=2548.000000,Z=-69.000000),CPRotation=(Pitch=353,Yaw=49312,Roll=65532))
				CheckPoints(15)=(MapName="HCLF5",CPLocation=(X=-9527.000000,Y=7044.000000,Z=5223.000000),CPRotation=(Pitch=65506,Yaw=49279),CPRadius=600.000000,CPHeight=600.000000)
				CheckPoints(16)=(MapName="HCLF5",CPLocation=(X=-6655.000000,Y=5885.000000,Z=564.000000),CPRotation=(Pitch=844,Yaw=61765),CPRadius=600.000000,CPHeight=60.000000)
				CheckPoints(17)=(CheckPointType=1,MapName="HCLF5",CPLocation=(X=7106.000000,Y=2117.000000,Z=-1796.000000),CPRotation=(Pitch=65429,Yaw=49003,Roll=65534))
				CheckPoints(18)=(MapName="HCLF5",CPLocation=(X=5501.000000,Y=-1019.000000,Z=-2531.000000),CPRotation=(Pitch=491,Yaw=32786,Roll=5))
				CheckPoints(19)=(CheckPointType=1,MapName="HCLF5",CPLocation=(X=-4602.000000,Y=-1574.000000,Z=-3843.000000),CPRotation=(Pitch=65351,Yaw=32693,Roll=65531),bEventEnabled=True,EventTag="finalfight")
				CheckPoints(20)=(MapName="HCLF7",CPLocation=(X=-8899.000000,Y=-4969.000000,Z=-10904.000000),CPRotation=(Pitch=65352,Yaw=30593,Roll=65532))
				CheckPoints(21)=(MapName="HCLF7",CPLocation=(X=-16119.000000,Y=1158.000000,Z=-8328.000000),CPRotation=(Pitch=65520,Yaw=48854,Roll=65532))
				CheckPoints(22)=(MapName="HCLF8",CPLocation=(X=-12896.000000,Y=89.000000,Z=-16394.000000),CPRotation=(Pitch=598,Yaw=49087,Roll=8))
				CheckPoints(23)=(CheckPointType=2,MapName="HCLF8",CPLocation=(X=1331.000000,Y=2240.000000,Z=-18561.000000),CPRotation=(Pitch=157,Yaw=65520,Roll=8))
				CheckPoints(24)=(CheckPointType=1,MapName="HCLF8",CPLocation=(X=-1554.000000,Y=-3959.000000,Z=-18513.000000),CPRotation=(Pitch=64986,Yaw=16696,Roll=8),bEventEnabled=True,EventTag="Queen")
				CheckPoints(25)=(MapName="theswamp",CPLocation=(X=-7924.000000,Y=5592.000000,Z=-1203.000000),CPRotation=(Pitch=65229,Yaw=57428,Roll=5))
				CheckPoints(26)=(MapName="theswamp",CPLocation=(X=-177.000000,Y=829.000000,Z=-951.000000),CPRotation=(Pitch=476,Yaw=16327,Roll=5))
				CheckPoints(27)=(MapName="Cregor",CPLocation=(X=10516.000000,Y=1083.000000,Z=-3516.000000),CPRotation=(Pitch=65320,Yaw=64552,Roll=6))
				CheckPoints(28)=(CheckPointType=1,MapName="Cregor",CPLocation=(X=18481.000000,Y=2237.000000,Z=-3366.000000),CPRotation=(Pitch=64553,Yaw=57611,Roll=6))
				CheckPoints(29)=(CheckPointType=1,MapName="Cregor",CPLocation=(X=18874.000000,Y=3292.000000,Z=-3444.000000),CPRotation=(Pitch=64692,Yaw=76,Roll=6))
				CheckPoints(30)=(MapName="cregorpass",CPLocation=(X=2525.000000,Y=-723.000000,Z=2380.000000),CPRotation=(Pitch=185,Yaw=49123,Roll=6))
				CheckPoints(31)=(MapName="EhactoraThree",CPLocation=(X=6919.000000,Y=4117.000000,Z=-34.000000),CPRotation=(Pitch=1859,Yaw=14928))
				CheckPoints(32)=(MapName="EhactoraFive",CPLocation=(X=18536.000000,Y=16519.000000,Z=-310.000000),CPRotation=(Pitch=844,Yaw=28841,Roll=65530))
				CheckPoints(33)=(MapName="EhactoraFive",CPLocation=(X=23203.000000,Y=-21200.000000,Z=620.000000),CPRotation=(Pitch=230,Yaw=48675,Roll=5))
				CheckPoints(34)=(CheckPointType=2,MapName="EhactoraFive",CPLocation=(X=-30212.000000,Y=-29347.000000,Z=296.000000),CPRotation=(Pitch=65443,Yaw=48973,Roll=202))
				CheckPoints(35)=(CheckPointType=1,MapName="EhactoraFive",CPLocation=(X=-8360.000000,Y=-11006.000000,Z=-1940.000000),CPRotation=(Pitch=65060,Yaw=32701,Roll=3))
				CheckPoints(36)=(CheckPointType=1,MapName="Sinistral_Level2",CPLocation=(X=7668.000000,Y=7053.000000,Z=-4196.000000),CPRotation=(Pitch=63539,Yaw=51872,Roll=7))
				CheckPoints(37)=(CheckPointType=1,MapName="Sinistral_Level3",CPLocation=(X=-1926.000000,Y=-6822.000000,Z=1703.000000),CPRotation=(Pitch=65443,Yaw=32777,Roll=7))
				CheckPoints(38)=(CheckPointType=1,MapName="Sinistral_Level4",CPLocation=(X=17151.000000,Y=-7112.000000,Z=443.000000),CPRotation=(Pitch=64830,Yaw=37064,Roll=65532))
				CheckPoints(39)=(CheckPointType=1,MapName="Sinistral_Level4",CPLocation=(X=6592.000000,Y=-18057.000000,Z=548.000000),CPRotation=(Pitch=65122,Yaw=23962,Roll=65532))
				CheckPoints(40)=(CheckPointType=2,MapName="Sinistral_Level4",CPLocation=(X=5946.000000,Y=-18431.000000,Z=2472.000000),CPRotation=(Pitch=706,Yaw=32949,Roll=65532))
				CheckPoints(41)=(CheckPointType=1,MapName="Sinistral_Level5",CPLocation=(X=-772.000000,Y=12300.000000,Z=232.000000),CPRotation=(Pitch=65459,Yaw=16382,Roll=18))
				CheckPoints(42)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=2951.000000,Y=6812.000000,Z=193.000000),CPRotation=(Pitch=65382,Yaw=32747,Roll=5))
				CheckPoints(43)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=-7584.000000,Y=7216.000000,Z=388.000000),CPRotation=(Pitch=184,Yaw=16219,Roll=5))
				CheckPoints(44)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=-10601.000000,Y=6653.000000,Z=1528.000000),CPRotation=(Pitch=65260,Yaw=26940,Roll=5))
				CheckPoints(45)=(MapName="Strange1",CPLocation=(X=4164.000000,Y=-2177.000000,Z=-468.000000),CPRotation=(Pitch=266,Yaw=49207,Roll=5),bEventEnabled=True,EventTag="Startd")
				CheckPoints(46)=(MapName="Strange1",CPLocation=(X=-4263.000000,Y=-3242.000000,Z=-940.000000),CPRotation=(Pitch=65260,Yaw=50142,Roll=65533))
				CheckPoints(47)=(MapName="Strange2",CPLocation=(X=6920.000000,Y=688.000000,Z=-340.000000),CPRotation=(Pitch=65397,Yaw=16581,Roll=65531))
				CheckPoints(48)=(MapName="Strange3",CPLocation=(X=1258.000000,Y=-4495.000000,Z=-1748.000000),CPRotation=(Pitch=65505,Yaw=33025,Roll=65532))
				CheckPoints(49)=(MapName="Strange3",CPLocation=(X=-4050.000000,Y=4526.000000,Z=-724.000000),CPRotation=(Pitch=65505,Yaw=62869,Roll=5))
				CheckPoints(50)=(MapName="Strange5",CPLocation=(X=4444.000000,Y=-4336.000000,Z=27.000000),CPRotation=(Pitch=65305,Yaw=62423,Roll=65529))
				CheckPoints(51)=(MapName="Strange6",CPLocation=(X=3863.000000,Y=-562.000000,Z=-340.000000),CPRotation=(Pitch=65013,Yaw=32664,Roll=4))
				CheckPoints(52)=(MapName="Strange7",CPLocation=(X=2220.000000,Y=-4277.000000,Z=427.000000),CPRotation=(Pitch=122,Yaw=13576,Roll=65530))
				CheckPoints(53)=(MapName="Dig",CPLocation=(X=4186.000000,Y=-1965.000000,Z=-84.000000),CPRotation=(Pitch=65428,Yaw=32595,Roll=6))
				CheckPoints(54)=(MapName="Dug",CPLocation=(X=4605.000000,Y=-2676.000000,Z=140.000000),CPRotation=(Pitch=65474,Yaw=16548,Roll=6))
				CheckPoints(55)=(MapName="Chizra",CPLocation=(X=-5915.000000,Y=-1309.000000,Z=588.000000),CPRotation=(Pitch=65413,Yaw=16385,Roll=6))
				CheckPoints(56)=(MapName="Ceremony",CPLocation=(X=520.000000,Y=3844.000000,Z=315.000000),CPRotation=(Pitch=65351,Yaw=49360,Roll=5))
				CheckPoints(57)=(MapName="Dark",CPLocation=(X=-2472.000000,Y=22.000000,Z=172.000000),CPRotation=(Pitch=65167,Yaw=116,Roll=65530))
				CheckPoints(58)=(MapName="TerraLift",CPLocation=(X=-892.000000,Y=720.000000,Z=3787.000000),CPRotation=(Pitch=65337,Yaw=49321,Roll=6))
				CheckPoints(59)=(MapName="Terraniux",CPLocation=(X=-1008.000000,Y=-15448.000000,Z=1452.000000),CPRotation=(Pitch=65045,Yaw=48901,Roll=4))
				CheckPoints(60)=(CheckPointType=1,MapName="Ruins",CPLocation=(X=2688.000000,Y=-2592.000000,Z=-4.000000),CPRotation=(Pitch=65213,Yaw=49360,Roll=65530))
				CheckPoints(61)=(MapName="ISVDeck1",CPLocation=(Y=-3.000000,Z=372.000000),CPRotation=(Pitch=65213,Yaw=16376,Roll=5))
				CheckPoints(62)=(MapName="TheSunspire",CPLocation=(X=2828.000000,Y=3229.000000,Z=-11113.000000),CPRotation=(Pitch=383,Yaw=32822,Roll=65532))
				CheckPoints(63)=(CheckPointType=1,MapName="TheSunspire",CPLocation=(X=-3018.000000,Y=3003.000000,Z=-6985.000000),CPRotation=(Pitch=76,Yaw=16312,Roll=65533))
				CheckPoints(64)=(MapName="SkyBase",CPLocation=(X=1818.000000,Y=4084.000000,Z=3115.000000),CPRotation=(Pitch=65489,Yaw=65495))
				CheckPoints(65)=(MapName="Bluff",CPLocation=(X=47.000000,Y=1489.000000,Z=-2516.000000),CPRotation=(Pitch=154,Yaw=36458,Roll=7))
				CheckPoints(66)=(MapName="Dasapass",CPLocation=(X=-422.000000,Y=20.000000,Z=-640.000000),CPRotation=(Pitch=184,Yaw=14,Roll=65529))
				CheckPoints(67)=(MapName="Dasacellars",CPRotation=(Pitch=65474,Yaw=65499,Roll=6))
				CheckPoints(68)=(MapName="Nalic",CPLocation=(X=572.000000,Y=-158.000000,Z=3260.000000),CPRotation=(Pitch=65352,Yaw=49289))
				CheckPoints(69)=(MapName="Duskfalls",CPLocation=(X=7625.000000,Z=-340.000000),CPRotation=(Pitch=64952,Yaw=33396,Roll=3))
				CheckPoints(70)=(MapName="Eldora",CPLocation=(X=2944.000000,Y=33.000000,Z=1324.000000),CPRotation=(Pitch=65521,Yaw=246))
				CheckPoints(71)=(CheckPointType=2,MapName="Glathriel2",CPLocation=(X=-408.000000,Y=-2478.000000,Z=-49.000000),CPRotation=(Pitch=64599,Yaw=25986,Roll=65531))
				CheckPoints(72)=(MapName="Crashsite1",CPLocation=(X=-3173.000000,Y=7635.000000,Z=1538.000000),CPRotation=(Pitch=65259,Yaw=49132,Roll=65534))
				CheckPoints(73)=(CheckPointType=2,MapName="Crashsite2",CPLocation=(X=-3399.000000,Y=9448.000000,Z=2498.000000),CPRotation=(Pitch=215,Yaw=19353))
				CheckPoints(74)=(MapName="Soledad",CPLocation=(X=103.000000,Y=-2031.000000,Z=-1876.000000),CPRotation=(Pitch=65351,Yaw=65499,Roll=7))
				CheckPoints(75)=(CheckPointType=1,MapName="Soledad",CPLocation=(X=5187.000000,Y=-530.000000,Z=-1564.000000),CPRotation=(Pitch=62,Yaw=49112,Roll=3))
				CheckPoints(76)=(MapName="Velora",CPLocation=(X=-812.000000,Y=-10513.000000,Z=-740.000000),CPRotation=(Pitch=307,Yaw=32402,Roll=2))
				CheckPoints(77)=(MapName="Foundry",CPLocation=(X=-1048.000000,Y=2460.000000,Z=-1221.000000),CPRotation=(Pitch=65336,Yaw=32684,Roll=65530),CPRadius=768.000000,CPHeight=256.000000)
				CheckPoints(78)=(MapName="Toxic",CPLocation=(X=1022.000000,Y=-213.000000,Z=-228.000000),CPRotation=(Pitch=15,Yaw=49292))
				CheckPoints(79)=(CheckPointType=1,MapName="Toxic",CPLocation=(X=-2761.000000,Y=-2323.000000,Z=-3428.000000),CPRotation=(Pitch=65353,Yaw=48793,Roll=65531))
				CheckPoints(80)=(MapName="Abyss",CPLocation=(X=-4084.000000,Y=331.000000,Z=-2516.000000),CPRotation=(Pitch=230,Yaw=65401,Roll=65532))
				CheckPoints(81)=(CheckPointType=1,MapName="Nalic2",CPLocation=(X=-924.000000,Y=-238.000000,Z=-12820.000000),CPRotation=(Pitch=65505,Yaw=65371))
				CheckPoints(82)=(MapName="03Temple",CPLocation=(X=3135.244629,Y=-1154.156372,Z=3603.800049),CPRotation=(Pitch=598,Yaw=10801,Roll=65541))
				CheckPoints(83)=(MapName="04mountains",CPLocation=(X=-2303.927734,Y=10496.312500,Z=43.799999),CPRotation=(Pitch=231,Yaw=-16399,Roll=65541))
				CheckPoints(84)=(MapName="05Spire",CPLocation=(X=-1284.343750,Y=-1250.463379,Z=203.899994),CPRotation=(Pitch=76,Yaw=16473))
				CheckPoints(85)=(MapName="05Spire",CPLocation=(X=-1951.208496,Y=-665.160767,Z=203.899994),CPRotation=(Pitch=752,Yaw=32368,Roll=3))
				CheckPoints(86)=(CheckPointType=1,MapName="06Streets",CPLocation=(X=-1987.273804,Y=14106.760742,Z=-84.199997),CPRotation=(Pitch=47,Yaw=-35598,Roll=-6))
				CheckPoints(87)=(CheckPointType=1,MapName="08StellTown",CPLocation=(X=-83.579079,Y=-1919.297485,Z=43.900002),CPRotation=(Pitch=123,Yaw=184,Roll=6))
				CheckPoints(88)=(CheckPointType=2,MapName="08StellTown",CPLocation=(X=267.695709,Y=-4241.928223,Z=43.900002),CPRotation=(Pitch=414,Yaw=-16434,Roll=5))
				CheckPoints(89)=(CheckPointType=2,MapName="09Underground",CPLocation=(X=-3233.467529,Y=2047.901123,Z=-212.199997),CPRotation=(Pitch=399,Yaw=127,Roll=-5))
				CheckPoints(90)=(MapName="09Underground",CPLocation=(X=2615.570068,Y=3874.637207,Z=-212.100006),CPRotation=(Pitch=753,Yaw=-8796,Roll=-5))
				CheckPoints(91)=(CheckPointType=1,MapName="10Queen",CPLocation=(X=-4900.975098,Y=-18070.617188,Z=-572.200012),CPRotation=(Pitch=139,Yaw=-16568,Roll=7))
				CheckPoints(92)=(MapName="12ColdPassage",CPLocation=(X=597.512634,Y=21782.000000,Z=-1908.099976),CPRotation=(Yaw=-32837,Roll=65531))
				CheckPoints(93)=(CheckPointType=2,MapName="12ColdPassage",CPLocation=(X=1632.452148,Y=20932.894531,Z=-2452.199951),CPRotation=(Pitch=65444,Yaw=-25525,Roll=65540))
				CheckPoints(94)=(CheckPointType=2,MapName="13Cemetery",CPLocation=(X=-909.462952,Y=-1477.234009,Z=-372.100006),CPRotation=(Pitch=262,Yaw=-65455,Roll=65531))
				CheckPoints(95)=(MapName="16Castle",CPLocation=(X=2571.329834,Y=-413.196533,Z=555.900024),CPRotation=(Pitch=65351,Yaw=-39499))
				CheckPoints(96)=(MapName="16Castle",CPLocation=(X=1095.428711,Y=-3149.472900,Z=1387.900024),CPRotation=(Pitch=31,Yaw=65307,Roll=65541))
				CheckPoints(97)=(CheckPointType=2,MapName="16Castle",CPLocation=(X=3164.655518,Y=-1687.027588,Z=1387.800049),CPRotation=(Pitch=65413,Yaw=82094,Roll=65542))
				CheckPoints(98)=(MapName="17Tower",CPLocation=(X=2.749130,Y=-1169.704590,Z=1579.800049),CPRotation=(Pitch=127,Yaw=16622,Roll=65531))
				CheckPoints(99)=(MapName="19IceMorning",CPLocation=(X=-536.310852,Y=1215.991699,Z=-180.199997),CPRotation=(Pitch=65136,Yaw=-98629,Roll=65531))
				CheckPoints(100)=(MapName="19IceMorning",CPLocation=(X=-8794.848633,Y=3469.071289,Z=-69.245293),CPRotation=(Pitch=507,Yaw=-98444,Roll=7))
				CheckPoints(101)=(CheckPointType=2,MapName="19IceMorning",CPLocation=(X=-14916.650391,Y=2169.041748,Z=-84.099998),CPRotation=(Pitch=65413,Yaw=-120913,Roll=4))
				CheckPoints(102)=(MapName="20Cave",CPLocation=(X=-6151.305664,Y=-713.886414,Z=-514.198120),CPRotation=(Pitch=65351,Yaw=-48817))
				CheckPoints(103)=(MapName="21Mine",CPLocation=(X=-2396.394531,Y=-3547.686768,Z=-244.199997),CPRotation=(Pitch=185,Yaw=49709,Roll=65531))
				CheckPoints(104)=(MapName="21Mine",CPLocation=(X=-4812.637695,Y=882.686401,Z=619.799988),CPRotation=(Pitch=262,Yaw=19530,Roll=6))
				CheckPoints(105)=(MapName="21Mine",CPLocation=(X=-1539.301147,Y=3813.140869,Z=-228.048615),CPRotation=(Pitch=2027,Yaw=16564,Roll=65540))
				CheckPoints(106)=(CheckPointType=1,MapName="21Mine",CPLocation=(X=-6339.994141,Y=11845.984375,Z=603.799988),CPRotation=(Pitch=65259,Yaw=-130,Roll=7))
				CheckPoints(107)=(MapName="22SpeedWay",CPLocation=(X=9024.704102,Y=8792.241211,Z=-980.200012),CPRotation=(Pitch=891,Yaw=32576,Roll=7))
				CheckPoints(108)=(MapName="22SpeedWay",CPLocation=(X=3752.965332,Y=13902.318359,Z=-977.244751),CPRotation=(Pitch=65290,Yaw=30886,Roll=66346))
				CheckPoints(109)=(CheckPointType=2,MapName="22SpeedWay",CPLocation=(X=-19909.154297,Y=20749.208984,Z=39.033958),CPRotation=(Pitch=65397,Yaw=114744,Roll=7))
				CheckPoints(110)=(MapName="22SpeedWay",CPLocation=(X=-21033.310547,Y=14150.694336,Z=250.212387),CPRotation=(Pitch=47,Yaw=114528,Roll=7),CPRadius=512.000000,CPHeight=4096.000000)
				CheckPoints(111)=(MapName="23WarFactory",CPLocation=(X=7829.740723,Y=-4732.586914,Z=55.262253),CPRotation=(Pitch=64231,Yaw=-12,Roll=65535))
				CheckPoints(112)=(CheckPointType=1,MapName="23WarFactory",CPLocation=(X=18587.294922,Y=-14822.748047,Z=-308.200012),CPRotation=(Pitch=261,Yaw=-16323,Roll=65531))
				CheckPoints(113)=(MapName="24HeadQuarter",CPLocation=(X=-866.171387,Y=-3053.793701,Z=435.507782),CPRotation=(Pitch=65382,Yaw=-16615))
				CheckPoints(114)=(CheckPointType=1,MapName="24HeadQuarter",CPLocation=(X=-1127.197876,Y=-2710.870361,Z=1195.699951),CPRotation=(Pitch=65459,Yaw=-9749,Roll=4))
				CheckPoints(115)=(CheckPointType=1,MapName="24HeadQuarter",CPLocation=(X=2667.711670,Y=1352.502441,Z=971.799988),CPRotation=(Pitch=492,Yaw=41410,Roll=65542))
				CheckPoints(116)=(MapName="25LostPalace",CPLocation=(X=-1116.155518,Y=-6936.464355,Z=-1508.199951),CPRotation=(Pitch=200,Yaw=32472,Roll=5))
				CheckPoints(117)=(CheckPointType=1,MapName="25LostPalace",CPLocation=(X=-7808.711426,Y=-10331.493164,Z=-594.437073),CPRotation=(Pitch=63955,Yaw=65538,Roll=65540))
				CheckPoints(118)=(CheckPointType=2,MapName="25LostPalace",CPLocation=(X=-1856.239624,Y=-8309.007813,Z=-2475.600586),CPRotation=(Pitch=62464,Yaw=180219,Roll=65540))
				CheckPoints(119)=(CheckPointType=1,MapName="25LostPalace",CPLocation=(X=1326.492310,Y=-3243.878662,Z=-615.840820),CPRotation=(Pitch=384,Yaw=131396,Roll=65540))
				CheckPoints(120)=(CheckPointType=2,MapName="26Town",CPLocation=(X=5123.295410,Y=-4987.903320,Z=710.703308),CPRotation=(Pitch=65397,Yaw=-16387,Roll=65536))
				CheckPoints(121)=(MapName="26Town",CPLocation=(X=10880.164063,Y=-2239.248779,Z=-437.964600),CPRotation=(Pitch=322,Yaw=-16,Roll=65536))
				CheckPoints(122)=(CheckPointType=1,MapName="27Cellars",CPLocation=(X=3020.089111,Y=-3.422905,Z=26.337471),CPRotation=(Pitch=277,Yaw=-122))
				CheckPoints(123)=(CheckPointType=2,MapName="27Cellars",CPLocation=(X=5114.044434,Y=9.803796,Z=330.833405),CPRotation=(Pitch=184,Yaw=-31))
				CheckPoints(124)=(MapName="27Cellars",CPLocation=(X=1827.107788,Y=-960.373779,Z=54.414825),CPRotation=(Pitch=65182,Yaw=-16280))
				CheckPoints(125)=(CheckPointType=1,MapName="29CentralTown",CPLocation=(X=-832.631409,Y=-206.211365,Z=-94.536827),CPRotation=(Pitch=65490,Yaw=-61741,Roll=65536))
				CheckPoints(126)=(CheckPointType=1,MapName="30Catacombs",CPLocation=(X=-1959.196655,Y=-6701.621094,Z=-1704.967651),CPRotation=(Pitch=65290,Yaw=-147975,Roll=65536))
				CheckPoints(127)=(CheckPointType=2,MapName="31LostCity",CPLocation=(X=-2013.835449,Y=-5528.533691,Z=526.653320),CPRotation=(Pitch=138,Yaw=16571))
				CheckPoints(128)=(MapName="32Piramide",CPLocation=(X=-1046.505737,Y=935.628479,Z=1600.478394),CPRotation=(Pitch=231,Yaw=-65807,Roll=65528))
				CheckPoints(129)=(CheckPointType=2,MapName="32Piramide",CPLocation=(X=-0.468003,Y=-7473.144531,Z=4776.706055),CPRotation=(Pitch=122,Yaw=-82088,Roll=65528))
				CheckPoints(130)=(CheckPointType=1,MapName="32Piramide",CPLocation=(X=5208.727051,Y=-10297.287109,Z=5695.070801),CPRotation=(Pitch=384,Yaw=-114724,Roll=65528))
				CheckPoints(131)=(MapName="32Piramide",CPLocation=(X=-535.593994,Y=-9520.701172,Z=5223.652832),CPRotation=(Pitch=168,Yaw=-82179,Roll=65528))
				CheckPoints(132)=(MapName="32Piramide",CPLocation=(X=-1427.626709,Y=-7741.291016,Z=5243.166992),CPRotation=(Pitch=65059,Yaw=-129191,Roll=65528))
				CheckPoints(133)=(MapName="32Piramide",CPLocation=(X=3933.989990,Y=-9029.244141,Z=4802.679199),CPRotation=(Pitch=65383,Yaw=-163594,Roll=65528))
				CheckPoints(134)=(CheckPointType=1,MapName="32Piramide",CPLocation=(X=3.710362,Y=422.724579,Z=2874.625732),CPRotation=(Pitch=460,Yaw=-81812,Roll=65528))
				CheckPoints(135)=(MapName="33Sarevok",CPLocation=(X=8451.472656,Y=-962.313843,Z=227.116379),CPRotation=(Pitch=107,Yaw=-320))
				CheckPoints(136)=(CheckPointType=2,MapName="33Sarevok",CPLocation=(X=11420.282227,Y=-574.334961,Z=681.689575),CPRotation=(Pitch=65244,Yaw=-32786))
				CheckPoints(137)=(CheckPointType=1,MapName="34DarkWood",CPLocation=(X=-21.080406,Y=-1746.979492,Z=69.003960),CPRotation=(Pitch=65429,Yaw=-16369,Roll=65530))
				CheckPoints(138)=(CheckPointType=1,MapName="34DarkWood",CPLocation=(X=-5418.933105,Y=-10576.745117,Z=-287.077850),CPRotation=(Pitch=308,Yaw=-27,Roll=65530))
				CheckPoints(139)=(MapName="34DarkWood",CPLocation=(X=10426.292969,Y=-11325.646484,Z=-330.773132),CPRotation=(Pitch=65213,Yaw=-65900))
				CheckPoints(140)=(MapName="35Monastery",CPLocation=(X=-1213.739746,Y=-1834.895996,Z=77.792145),CPRotation=(Pitch=153,Yaw=-24432,Roll=65536))
				CheckPoints(141)=(MapName="35Monastery",CPLocation=(X=-1903.486084,Y=-4470.354980,Z=106.864082),CPRotation=(Pitch=65397,Yaw=32778,Roll=65536))
				CheckPoints(142)=(CheckPointType=2,MapName="36Amarok",CPLocation=(X=-3971.322998,Y=-5297.095703,Z=2121.626465),CPRotation=(Pitch=552,Yaw=-16336))
				CheckPoints(143)=(CheckPointType=1,MapName="37Castle",CPLocation=(X=762.986023,Y=-2783.126221,Z=339.793091),CPRotation=(Pitch=65475,Yaw=49216,Roll=65529))
				CheckPoints(144)=(MapName="37Castle",CPLocation=(X=1635.976318,Y=-1959.624146,Z=-864.043213),CPRotation=(Pitch=65137,Yaw=104184,Roll=65529))
				CheckPoints(145)=(CheckPointType=2,MapName="37Castle",CPLocation=(X=763.707092,Y=-2201.127930,Z=1331.684082),CPRotation=(Pitch=199,Yaw=-16042,Roll=65529))
				CheckPoints(146)=(MapName="37Castle",CPLocation=(X=-95.162308,Y=-2418.997559,Z=157.988495),CPRotation=(Pitch=64169,Yaw=-653,Roll=65529))
				CheckPoints(147)=(MapName="38Specters",CPLocation=(X=-1784.007446,Y=-15131.832031,Z=-1296.887573),CPRotation=(Pitch=65228,Yaw=-32885,Roll=65528))
				CheckPoints(148)=(MapName="38Specters",CPLocation=(X=-715.742493,Y=-11355.379883,Z=-1391.955322),CPRotation=(Pitch=63754,Yaw=-49165,Roll=65528))
				CheckPoints(149)=(MapName="38Specters",CPLocation=(X=-2455.535889,Y=-8050.464355,Z=-1441.145508),CPRotation=(Pitch=65213,Yaw=-48811,Roll=65528))
				CheckPoints(150)=(MapName="38Specters",CPLocation=(X=-564.633484,Y=-3602.367188,Z=-674.304199),CPRotation=(Pitch=354,Yaw=-48950,Roll=65528))
				CheckPoints(151)=(CheckPointType=2,MapName="38Specters",CPLocation=(X=638.882385,Y=-125.085594,Z=223.420578),CPRotation=(Pitch=292,Yaw=-114576,Roll=65528))
				CheckPoints(152)=(MapName="39Ruins",CPLocation=(X=507.113464,Y=-3404.839355,Z=4154.468750),CPRotation=(Pitch=65429,Yaw=49421))
				CheckPoints(153)=(CheckPointType=1,MapName="40Underworld",CPLocation=(X=-16967.412109,Y=3030.541992,Z=-1074.406494),CPRotation=(Pitch=64277,Yaw=82483,Roll=65536))
				CheckPoints(154)=(CheckPointType=1,MapName="40Underworld",CPLocation=(X=-18807.140625,Y=8102.538086,Z=-1003.832458),CPRotation=(Pitch=65459,Yaw=81976,Roll=65536))
				CheckPoints(155)=(CheckPointType=2,MapName="40Underworld",CPLocation=(X=-18810.283203,Y=16508.966797,Z=-1500.473633),CPRotation=(Pitch=65152,Yaw=82115,Roll=65536))
				CheckPoints(156)=(MapName="40Underworld",CPLocation=(X=-18773.251953,Y=21529.156250,Z=-1159.853760),CPRotation=(Pitch=307,Yaw=98317,Roll=65536))
				CheckPoints(157)=(CheckPointType=2,MapName="43City",CPLocation=(X=2463.008545,Y=3.197786,Z=2694.214844),CPRotation=(Pitch=31,Yaw=49078))
				CheckPoints(158)=(MapName="43City",CPLocation=(X=-1890.731812,Y=-259.245392,Z=2229.185547),CPRotation=(Pitch=337,Yaw=81884))
				CheckPoints(159)=(MapName="43City",CPLocation=(X=-7203.780762,Y=819.696045,Z=2769.543945),CPRotation=(Pitch=65306,Yaw=81239))
				CheckPoints(160)=(MapName="44OldSection",CPLocation=(X=540.105652,Y=558.682495,Z=-522.991089),CPRotation=(Pitch=65214,Yaw=-16440))
				CheckPoints(161)=(CheckPointType=1,MapName="44OldSection",CPLocation=(X=-2567.625977,Y=2850.867920,Z=-2044.346069),CPRotation=(Pitch=64798,Yaw=3494))
				CheckPoints(162)=(CheckPointType=1,MapName="44OldSection",CPLocation=(X=-722.297424,Y=5257.599609,Z=-2453.817871),CPRotation=(Pitch=153,Yaw=32875))
				CheckPoints(163)=(CheckPointType=2,MapName="44OldSection",CPLocation=(X=-3927.894043,Y=9478.188477,Z=-4875.821289),CPRotation=(Pitch=123,Yaw=16488))
				CheckPoints(164)=(MapName="45HighTown",CPLocation=(X=-1878.087280,Y=335.161163,Z=-608.316162),CPRotation=(Pitch=123,Yaw=-49481,Roll=65536))
				CheckPoints(165)=(CheckPointType=1,MapName="45HighTown",CPLocation=(X=-2086.287354,Y=-323.811798,Z=5767.408203),CPRotation=(Pitch=65443,Yaw=-81612,Roll=65536))
				CheckPoints(166)=(MapName="45HighTown",CPLocation=(X=-2124.345947,Y=-2071.957275,Z=3781.227051),CPRotation=(Pitch=65428,Yaw=-15970,Roll=65536))
				CheckPoints(167)=(CheckPointType=1,MapName="45HighTown",CPLocation=(X=-7168.093750,Y=-3768.953613,Z=3757.498779),CPRotation=(Pitch=415,Yaw=65645,Roll=65536))
				CheckPoints(168)=(CheckPointType=2,MapName="45HighTown",CPLocation=(X=-2579.899170,Y=-7140.746094,Z=4024.702637),CPRotation=(Pitch=261,Yaw=49458,Roll=65536))
				CheckPoints(169)=(CheckPointType=1,MapName="46SpacePort",CPLocation=(X=1902.699097,Y=14590.425781,Z=11.699999),CPRotation=(Pitch=65244,Yaw=23,Roll=4))
				CheckPoints(170)=(CheckPointType=2,MapName="46SpacePort",CPLocation=(X=6040.140137,Y=14597.294922,Z=1648.983643),CPRotation=(Pitch=65368,Yaw=32645,Roll=4))
				CheckPoints(171)=(CheckPointType=1,MapName="46SpacePort",CPLocation=(X=5927.611816,Y=14590.519531,Z=-164.100006),CPRotation=(Pitch=65198,Yaw=98380,Roll=65531))
				CheckPoints(172)=(CheckPointType=2,MapName="S1Skyship",CPLocation=(X=1916.143677,Y=-2211.456787,Z=-596.200012),CPRotation=(Pitch=168,Yaw=-81688))
				CheckPoints(173)=(CheckPointType=2,MapName="S2Cursed",CPLocation=(X=-6798.819824,Y=1084.523804,Z=359.001190),CPRotation=(Pitch=108,Yaw=32815,Roll=65542))
				CheckPoints(174)=(CheckPointType=2,MapName="S3Toys",CPLocation=(X=-3136.929443,Y=-4417.128906,Z=2347.800049),CPRotation=(Yaw=49278))
				CheckPoints(175)=(MapName="S3Toys",CPLocation=(X=-3140.560547,Y=-198.852020,Z=115.316628),CPRotation=(Pitch=65290,Yaw=48832))
				CheckPoints(176)=(MapName="S4VReality",CPLocation=(X=-0.458409,Y=-5407.324707,Z=-1556.199951),CPRotation=(Pitch=65383,Yaw=-16338,Roll=65531))
				CheckPoints(177)=(CheckPointType=1,MapName="S4VReality",CPLocation=(X=703.208130,Y=-11589.592773,Z=-1126.469971),CPRotation=(Pitch=65398,Yaw=95,Roll=65531))
				CheckPoints(178)=(CheckPointType=2,MapName="S4VReality",CPLocation=(X=7866.821289,Y=-13687.983398,Z=-823.500122),CPRotation=(Pitch=65459,Yaw=250,Roll=65531))
				CheckPoints(179)=(MapName="S5HellRaiser",CPLocation=(X=1622.408813,Y=-5857.442383,Z=-458.840942),CPRotation=(Pitch=65263,Yaw=46798,Roll=65122))
				CheckPoints(180)=(CheckPointType=2,MapName="S5HellRaiser",CPLocation=(X=1263.882935,Y=-12708.950195,Z=-182.724854),CPRotation=(Pitch=65444,Yaw=27642))
				CheckPoints(181)=(MapName="S5HellRaiser",CPLocation=(X=311.376831,Y=-11700.899414,Z=-675.606750),CPRotation=(Pitch=123,Yaw=-12935))
				CheckPoints(182)=(MapName="S5HellRaiser",CPLocation=(X=21019.720703,Y=-25949.449219,Z=1456.108032),CPRotation=(Pitch=65445,Yaw=16292))
				CheckPoints(183)=(CheckPointType=2,MapName="S5HellRaiser",CPLocation=(X=21261.843750,Y=-26682.218750,Z=1453.477051),CPRotation=(Pitch=17,Yaw=-571))
				CheckPoints(184)=(MapName="S5HellRaiser",CPLocation=(X=13027.133789,Y=-12675.136719,Z=579.602112),CPRotation=(Pitch=65292,Yaw=-65262))
				CheckPoints(185)=(CheckPointType=2,MapName="S6PaciManor",CPLocation=(X=-1866.727173,Y=2341.106201,Z=-211.416183),CPRotation=(Pitch=65290,Yaw=-65378,Roll=7))
				CheckPoints(186)=(CheckPointType=2,MapName="S6PaciManor",CPLocation=(X=2159.979248,Y=1897.745972,Z=-280.971893),CPRotation=(Pitch=65367,Yaw=-33033,Roll=7))
				CheckPoints(187)=(CheckPointType=1,MapName="S7Gloomy",CPLocation=(X=116.152946,Y=512.942261,Z=-108.199997),CPRotation=(Pitch=64492,Yaw=-400,Roll=65540))
				CheckPoints(188)=(MapName="S7Gloomy",CPLocation=(X=1750.221680,Y=382.185822,Z=-156.199997),CPRotation=(Pitch=276,Yaw=-98018,Roll=65529))
				CheckPoints(189)=(CheckPointType=2,MapName="S7Gloomy",CPLocation=(X=2293.635010,Y=724.863647,Z=131.800003),CPRotation=(Pitch=64139,Yaw=-130624,Roll=65542))
				ClassReplacement(0)=(OriginalClass="FemaleOne",ReplacementClass="WolfCoop.wFemaleOne")
				ClassReplacement(1)=(OriginalClass="FemaleTwo",ReplacementClass="WolfCoop.wFemaleTwo")
				ClassReplacement(2)=(OriginalClass="MaleThree",ReplacementClass="WolfCoop.wMaleThree")
				ClassReplacement(3)=(OriginalClass="MaleTwo",ReplacementClass="WolfCoop.wMaleTwo")
				ClassReplacement(4)=(OriginalClass="MaleOne",ReplacementClass="WolfCoop.wMaleOne")
				ClassReplacement(5)=(OriginalClass="SkaarjPlayer",ReplacementClass="WolfCoop.wSkaarjPlayer")
				ClassReplacement(6)=(OriginalClass="NaliPlayer",ReplacementClass="WolfCoop.wNaliPlayer")
				bRespawnItems=True
				AmmoRespawnTime=5
				WeaponRespawnTime=5
				ArmorRespawnTime=10
				PickupRespawnTime=15
				HealthRespawnTime=5
				bUseHookMutators=True
				HookMutator(0)="None"
				HookMutator(1)="None"
				HookMutator(2)="None"
				HookMutator(3)="None"
				HookMutator(4)="None"
				HookMutator(5)="None"
				HookMutator(6)="None"
				HookMutator(7)="None"
				HookMutator(8)="None"
				HookMutator(9)="None"
				HookMutator(10)="None"
				HookMutator(11)="None"
				HookMutator(12)="None"
				HookMutator(13)="None"
				HookMutator(14)="None"
				HookMutator(15)="None"
				HookMutator(16)="None"
				HookMutator(17)="None"
				HookMutator(18)="None"
				HookMutator(19)="None"
				HookMutator(20)="None"
				HookMutator(21)="None"
				HookMutator(22)="None"
				HookMutator(23)="None"
				HookMutator(24)="None"
				HookMutator(25)="None"
				HookMutator(26)="None"
				HookMutator(27)="None"
				HookMutator(28)="None"
				HookMutator(29)="None"
				HookMutator(30)="None"
				HookMutator(31)="None"
				XmasMutators(0)="None"
				XmasMutators(1)="None"
				XmasMutators(2)="None"
				XmasMutators(3)="None"
				XmasMutators(4)="None"
				XmasMutators(5)="None"
				XmasMutators(6)="None"
				XmasMutators(7)="None"
				XmasMutators(8)="None"
				XmasMutators(9)="None"
				XmasMutators(10)="None"
				XmasMutators(11)="None"
				XmasMutators(12)="None"
				XmasMutators(13)="None"
				XmasMutators(14)="None"
				XmasMutators(15)="None"
				HalloweenMutators(0)="None"
				HalloweenMutators(1)="None"
				HalloweenMutators(2)="None"
				HalloweenMutators(3)="None"
				HalloweenMutators(4)="None"
				HalloweenMutators(5)="None"
				HalloweenMutators(6)="None"
				HalloweenMutators(7)="None"
				HalloweenMutators(8)="None"
				HalloweenMutators(9)="None"
				HalloweenMutators(10)="None"
				HalloweenMutators(11)="None"
				HalloweenMutators(12)="None"
				HalloweenMutators(13)="None"
				HalloweenMutators(14)="None"
				HalloweenMutators(15)="None"
				AprilFoolsMutators(0)="None"
				AprilFoolsMutators(1)="None"
				AprilFoolsMutators(2)="None"
				AprilFoolsMutators(3)="None"
				AprilFoolsMutators(4)="None"
				AprilFoolsMutators(5)="None"
				AprilFoolsMutators(6)="None"
				AprilFoolsMutators(7)="None"
				AprilFoolsMutators(8)="None"
				AprilFoolsMutators(9)="None"
				AprilFoolsMutators(10)="None"
				AprilFoolsMutators(11)="None"
				AprilFoolsMutators(12)="None"
				AprilFoolsMutators(13)="None"
				AprilFoolsMutators(14)="None"
				AprilFoolsMutators(15)="None"
				GiveItems(0)="UnrealShare.DispersionPistol"
				GiveItems(1)="UnrealShare.FlashLight?Charges=10000"
				GiveItems(2)="UnrealShare.Flare?Copies=5"
				StartingLives=3
				MaxLives=5
				ExtraLifeScore=1250
				bEnableLives=True
				bExtraLives=True
				bAllowReviving=True
				bReturnToLastMap=True
				LastMap="Vortex2"
				NeutralMaps(0)="MapFileName"
				NeutralMaps(1)=" "
				NeutralMaps(2)=" "
				NeutralMaps(3)=" "
				FlareAndSeedRespawnTime=15.000000
				DefaultPlayerClass=Class'WolfCoop.wFemaleOne'
				DefaultWeapon=None
				ScoreBoardType=Class'WolfCoop.WolfScoreBoard'
				HUDType=Class'WolfCoop.WolfHUD'
				LocalBatcherParams="UM27EDDZM-B318EDCF20290429"
				AccessManagerClass="WolfCoop.wAAM"
				bHumansOnly=False
				bUseRealtimeShadow=True
}
