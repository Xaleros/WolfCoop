//=============================================================================
// wCoopFixes.
//=============================================================================
class wCoopFixes extends Mutator;

function PostBeginPlay()
{
	log("Appling Mapfixes..",stringtoname("WolfCoop(coopfixes)"));
	FixCoopMaps();
}

function FixCoopMaps()
{
	local String S;
	//local Weapon Weap;
	local Trigger T;
	//local bool bReplaceMe;
	local ZoneInfo ZI;
	local Mover M;
	local PlayerStart P;
	local Actor A;
	local Mercenary Merc;
	local SpecialEvent SE;
	local Counter C;
	local Dispatcher D;
	//local JumpBoots JB;
	local Spawnpoint SP;
	local Teleporter TP;
	//local UpakTeleporter UTP;
	local Pawn PA;
	//local Cannon CA;
	//local BlockPlayer BP;
	local Fan2 F2;
	local DynamicZoneInfo DZI;
	local wTPFix wTP;
	local PlayerPawn Pp;
	//local Warlord WL;
	//local MusicEvent ME;
	//local PathNode PN;

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

defaultproperties
{
}
