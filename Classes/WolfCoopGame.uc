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

var(wGameBalance) config bool bRestoreDrownDamage,
bInventoryLossOnDeath,
bDropInventoryOnDeath,
bEnableVoteEnd,
bNoChatVoteEnd,
bEndTimerPunish,
bPlayersEndGameSpectate,
bShowEnds,
bEnableCheckPoints,
bDisableMapFixes,
bRealCrouch,
bShowRespawningItems,
bAllowCheckpointRelocate,
bCheckpointHeals,
bPenalizeInventoryOnLifeLoss,
bSaveScores,
bUniqueItems,
bUniquePowerUps,
bPermanentFlares;
//,bVoteStart,bAllowLatePlayers;

var(wGameBalance) config int EndTime,AFKTimer;
var(wGameBalance) globalconfig array<CheckPoint> CheckPoints;
var(wPlayerClasses) config wPlayerClasses ClassReplacement[64];
var(wPlayerClasses) config bool allowcustomwplayers;

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


var(wLives) config int StartingLives,
                       MaxLives,
                       ExtraLifeScore;
var(wLives) config bool bEnableLives,
                        bExtraLives,
                        bPersonalExtraLives,
                        bRestartMapOnGameOver,
                        bAllowReviving,
						bResetLivesOnMapChange,
                        bMarioSounds,
                        bSeriousSamExtraLife;
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
		{ 	
			if(!Dest.bSinglePlayerStart && Dest.bCoopStart)
				Score-=1000;
			else if (Dest.bSinglePlayerStart && Dest.bCoopStart)
				Score-=250;
			else if (Dest.bSinglePlayerStart && !Dest.bCoopStart)
				Score+=1000;
		}
		else if( !Dest.bSinglePlayerStart && !Dest.bCoopStart )
			Score-=1000;

		foreach RadiusActors(class'Pawn',P,100,Dest.Location)
		{
			if( P.bIsPlayer && P.Health>0 && P.bBlockActors )
				Score-=100;
		}
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


function ProcessServerTravel(string URL, bool bItems)
{
	TempLastMap=LastMap;
	LastMap=URL;
	SaveConfig();
	Super.ProcessServerTravel(URL,bItems);
}


function SaveOldMap()
{
	LastMap=TempLastMap;
}

event InitGame( string Options, out string Error )
{
	local Teleporter TP;
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

	if(AFKTimer<60) 
		AFKTimer=60;

	AccessManagerClass="WolfCoop.wAAM";
	if(StartingLives<=0) 
		StartingLives=1;

	CurrentExtraLifeScore=ExtraLifeScore;
	Level.bSupportsRealCrouching=False;

	if(bUseHookMutators)
		LoadHookMutators();

	if(!bDisableMapFixes)
    {
    	Spawn(class'wCoopFixes');
    }

    // spawn the helper list builder
    Spawn(class'wObjectCompleter');
    

	//FixCoopMaps();

	Class'StingerAmmo'.Default.MultiSkins[4]=Texture'JTaryPickJ42Fix';
	Class'StingerProjectile'.Default.MultiSkins[4]=Texture'JTaryPickJ42Fix';

	foreach allactors(class 'Teleporter', TP)
	{
		if ( InStr( TP.URL, "?" ) > -1 )
		{
			if(bShowEnds)
			{
				TP.bHidden = False;
				if(TP.Texture==None)
					TP.Texture = texture'S_Teleport';

				TP.bAlwaysRelevant = True;

				if(bool(UpakTeleporter(TP)))
					TP.DrawType=DT_Sprite;
			}
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
			{
				CP.SetUpCheckPoint(CheckPoints[I].CPRadius,CheckPoints[I].CPHeight,CheckPoints[I].bEventEnabled,CheckPoints[I].EventTag);
			}
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
		If( Hookmutator[i] == "None" ) continue;
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
	//Log(PN,'wolfgame');
	if(ClassIsChildOf(SpawnClass,class'Spectator')/* && !bInvasion*/) 
    {
      NewPlayer=Super.Login(Portal, Options, Error, Class'wSpectator');
      return NewPlayer;
    }
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
						Log("Failed to replace "$ClassName$" with "$ClassReplacement[i].ReplacementClass,stringtoname("WolfCoopGame - Login"));
						if(!ClassIsChildOf(Rep,class'wPlayer'))
       					log( "Replacment exception: Player "$ PN $  " Desired " $ ClassName $ " but got femaleone  due to not being wplayer" $ Rep,stringtoname("WolfCoopGame - Login"));
						else if(Rep == None)
                        log( "Replacment exception: Player "$ PN $  " Desired " $ ClassName $ " but got femaleone  due to invalid replacment class" $ Rep,stringtoname("WolfCoopGame - Login"));
						NewPlayer=Super.Login(Portal, Options, Error, Class'wFemaleOne');
					}
					else 
                    {
                    NewPlayer=Super.Login(Portal, Options, Error, Rep);
                    log( "Replacment: Player "$ PN $  " Desired " $ ClassName $ " but got " $ Rep,stringtoname("WolfCoopGame - Login"));
                    }
				}
			}
		}
	}

	if(!bool(NewPlayer))
    {
      // thought of checking it a second time but 90 percent of time  the use case would be from non wplayers.
      // if you want to be mose secure, check id class.outer  != wolfcoop then you know the class wasnt bundled in gametype

      if(ClassIsChildOf(SpawnClass,class'wPlayer') )
      { // not a spectator, not a unreal char replaced, but a custom playerclass based on wplayer.
       
        if(allowcustomwplayers)
          {
          NewPlayer=Super.Login(Portal, Options, Error, SpawnClass);
          log( "Player "$ PN $  " Desired wplayer custom class : " $ ClassName ,stringtoname("WolfCoopGame - Login"));
          }else{
          NewPlayer=Super.Login(Portal, Options, Error, class'wFemaleOne');
          log( "Player "$ PN $  " Desired wplayer custom class : " $ ClassName $ " but custom classes are disabled." ,stringtoname("WolfCoopGame - Login"));
          }


       // NewPlayer=Super.Login(Portal, Options, Error, SpawnClass);
      // //log( "Player "$ PN $  " Desired wplayer custom class : " $ ClassName ,stringtoname("WolfCoopGame - Login"));

      }else{
    	NewPlayer = Super.Login(Portal, Options, Error, class'wFemaleOne');
        log( "Exception: Player "$ PN $  " Desired " $ ClassName $ " but got Wfemaleone",stringtoname("WolfCoopGame - Login"));
      }
    }

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
				{Log("Player Recognized:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score ,stringtoname("WolfCoopGame - Login") );
				wPlayer(NewPlayer).Lives=SavePlayers[I].Lives;
				wPRI(NewPlayer.PlayerReplicationInfo).Score=SavePlayers[I].Score;
				bNewPlayer=False;}
			}
			if(bNewPlayer && (wPlayer(NewPlayer).Lives<=0 || bResetLivesOnMapChange))
			{wPlayer(NewPlayer).Lives=StartingLives;}

			if(MaxLives<=1) wPlayer(NewPlayer).Lives=1;
		}

		//log("Logging in to "$Level.Title);
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
			Log("Updating Exiting Player:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score,stringtoname("WolfCoopGame - Logout"));}
		}
		if(bNewSlot)
		{
			I=array_size(SavePlayers);
			SavePlayers[I].PlayerName=Exiting.GetHumanName();
			SavePlayers[I].Lives=wPlayer(Exiting).Lives;
			SavePlayers[I].Score=wPlayer(Exiting).Score;
			Log("Saving Exiting Player:"@SavePlayers[I].PlayerName@"Lives:"@SavePlayers[I].Lives@"Score:"@SavePlayers[I].Score,stringtoname("WolfCoopGame - Logout"));
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

		else if(bool(PlayerPawn(Other)) && bool(PlayerPawn(killer)))
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

function ModifyPlayerWithGameRules(Pawn Player)
{
	local GameRules G;

	for (G = GameRules; G != none; G = G.NextRules)
		if (G.bNotifySpawnPoint)
			G.ModifyPlayer(Player);
}

Function AddDefaultInventory( Pawn P )
{
	local int i,ItemNum;
	local inventory inv;
	local translator NewTranslator;
	local bool bItemFound;
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

ModifyPlayerWithGameRules(P);

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
	local int permsg;

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
			{
				if(!PRI.bVoteEnd)
				{
					Pawn(PRI.Owner).GibbedBy(Pawn(PRI.Owner)); 
					BroadCastMessage(PRI.PlayerName$" was left behind...",false,'RedCriticalEvent'); 
					PRI.bVoteEnd=True;
				}
			}
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





//---------------------------- SERVER CONSOLE ---------------------


// skip tha map to the next map
exec function skipmap(){advance();} // alias this

exec function advance()
{
	local NavigationPoint N;
	local string Dest;
	
	For(n=level.navigationpointlist;n!=none;n=n.nextnavigationpoint)
		if( n.isa('teleporter') && ( InStr( Teleporter(N).URL, "#" ) > -1 || InStr( Teleporter(N).URL, "?" ) > -1 ) )
			Dest = Teleporter( N ).URL;

	BroadcastMessage("Level has been skipped to the next map by server",true,'CriticalEvent');			
	Log("Level has been skipped to: "$dest,'LOG_WATERMARK');
	
	Level.ServerTravel(dest,True);
}

// psay to a player from the console
exec function PSay(int PawnID, string Msg)
{
	local PlayerPawn P;

    // we cant check gamerules here becuase we are not a player, we are a gamtype.!
	if(PawnID>=0)
	{
		Foreach allactors(class'PlayerPawn', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{
				log("(PSay) Serverconsole(ID = 1800)-->"@P.PlayerReplicationInfo.PlayerName$":"@Msg,);
				P.ClientMessage("(PSay) Serverconsole(ID = 1800)--> You:"@Msg,,true);
			}
		}
	}
}

//----------------------------------------------------------------------------

defaultproperties
{
	EndTime=30
	AFKTimer=120
	AmmoRespawnTime=5
	WeaponRespawnTime=5
	ArmorRespawnTime=10
	PickupRespawnTime=15
	HealthRespawnTime=5
	StartingLives=3
	MaxLives=5
	ExtraLifeScore=1250
	URLVoteCount(0)=0
	URLVoteCount(1)=0
	URLVoteCount(2)=0
	URLVoteCount(3)=0
	URLVoteCount(4)=0
	URLVoteCount(5)=0
	URLVoteCount(6)=0
	URLVoteCount(7)=0
	URLVoteCount(8)=0
	URLVoteCount(9)=0
	URLVoteCount(10)=0
	URLVoteCount(11)=0
	URLVoteCount(12)=0
	URLVoteCount(13)=0
	URLVoteCount(14)=0
	URLVoteCount(15)=0
	URLWinner=0
	SavedURLCount=0
	TotalScore=0
	CurrentExtraLifeScore=0
	EndTimeCount=0
	InvasionTarget=None
	CheckPoints(0)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-8883.0,Y=-9064.0,Z=-1282.0),CPRotation=(Pitch=65523,Yaw=32332,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(1)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-13374.0,Y=3543.0,Z=-218.0),CPRotation=(Pitch=1015,Yaw=65525,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(2)=(CheckPointType=2,MapName="skaarjtowerf",CPLocation=(X=-16030.0,Y=4198.0,Z=-4857.0),CPRotation=(Pitch=877,Yaw=16976,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(3)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=-6711.0,Y=22188.0,Z=3484.0),CPRotation=(Pitch=63434,Yaw=35251,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(4)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=1083.0,Y=17199.0,Z=1351.0),CPRotation=(Pitch=616,Yaw=44098,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(5)=(CheckPointType=2,MapName="skaarjcastle_v2f",CPLocation=(X=-7559.0,Y=18550.0,Z=3830.0),CPRotation=(Pitch=1169,Yaw=36342,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(6)=(CheckPointType=0,MapName="Shrak1",CPLocation=(X=6232.0,Y=474.0,Z=-388.0),CPRotation=(Pitch=65447,Yaw=49651,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(7)=(CheckPointType=0,MapName="Shrak2",CPLocation=(X=4435.0,Y=659.0,Z=188.0),CPRotation=(Pitch=65447,Yaw=49651,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(8)=(CheckPointType=0,MapName="Shrak3",CPLocation=(X=2.0,Y=-73.0,Z=107.0),CPRotation=(Pitch=661,Yaw=49111,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(9)=(CheckPointType=0,MapName="Dawn_UnDead",CPLocation=(X=4183.0,Y=-417.0,Z=-1262.0),CPRotation=(Pitch=64783,Yaw=2277,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(10)=(CheckPointType=0,MapName="HCLF2",CPLocation=(X=9159.0,Y=-9119.0,Z=-3278.0),CPRotation=(Pitch=598,Yaw=53098,Roll=65534),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(11)=(CheckPointType=0,MapName="HCLF2",CPLocation=(X=4398.0,Y=-7206.0,Z=-6087.0),CPRotation=(Pitch=0,Yaw=28974,Roll=65534),CPRadius=0.0,CPHeight=0.0,bEventEnabled=True,EventTag="Skill")
	CheckPoints(12)=(CheckPointType=0,MapName="HCLF3",CPLocation=(X=6291.0,Y=-5796.0,Z=-3815.0),CPRotation=(Pitch=276,Yaw=40058,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(13)=(CheckPointType=0,MapName="HCLF3",CPLocation=(X=-7143.0,Y=-4381.0,Z=-5282.0),CPRotation=(Pitch=598,Yaw=16697,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=True,EventTag="basement")
	CheckPoints(14)=(CheckPointType=0,MapName="HCLF4",CPLocation=(X=-2662.0,Y=2548.0,Z=-69.0),CPRotation=(Pitch=353,Yaw=49312,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(15)=(CheckPointType=0,MapName="HCLF5",CPLocation=(X=-9527.0,Y=7044.0,Z=5223.0),CPRotation=(Pitch=65506,Yaw=49279,Roll=0),CPRadius=600.0,CPHeight=600.0,bEventEnabled=False,EventTag="None")
	CheckPoints(16)=(CheckPointType=0,MapName="HCLF5",CPLocation=(X=-6655.0,Y=5885.0,Z=564.0),CPRotation=(Pitch=844,Yaw=61765,Roll=0),CPRadius=600.0,CPHeight=60.0,bEventEnabled=False,EventTag="None")
	CheckPoints(17)=(CheckPointType=1,MapName="HCLF5",CPLocation=(X=7106.0,Y=2117.0,Z=-1796.0),CPRotation=(Pitch=65429,Yaw=49003,Roll=65534),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(18)=(CheckPointType=0,MapName="HCLF5",CPLocation=(X=5501.0,Y=-1019.0,Z=-2531.0),CPRotation=(Pitch=491,Yaw=32786,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(19)=(CheckPointType=1,MapName="HCLF5",CPLocation=(X=-4602.0,Y=-1574.0,Z=-3843.0),CPRotation=(Pitch=65351,Yaw=32693,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=True,EventTag="finalfight")
	CheckPoints(20)=(CheckPointType=0,MapName="HCLF7",CPLocation=(X=-8899.0,Y=-4969.0,Z=-10904.0),CPRotation=(Pitch=65352,Yaw=30593,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(21)=(CheckPointType=0,MapName="HCLF7",CPLocation=(X=-16119.0,Y=1158.0,Z=-8328.0),CPRotation=(Pitch=65520,Yaw=48854,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(22)=(CheckPointType=0,MapName="HCLF8",CPLocation=(X=-12896.0,Y=89.0,Z=-16394.0),CPRotation=(Pitch=598,Yaw=49087,Roll=8),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(23)=(CheckPointType=2,MapName="HCLF8",CPLocation=(X=1331.0,Y=2240.0,Z=-18561.0),CPRotation=(Pitch=157,Yaw=65520,Roll=8),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(24)=(CheckPointType=1,MapName="HCLF8",CPLocation=(X=-1554.0,Y=-3959.0,Z=-18513.0),CPRotation=(Pitch=64986,Yaw=16696,Roll=8),CPRadius=0.0,CPHeight=0.0,bEventEnabled=True,EventTag="Queen")
	CheckPoints(25)=(CheckPointType=0,MapName="theswamp",CPLocation=(X=-7924.0,Y=5592.0,Z=-1203.0),CPRotation=(Pitch=65229,Yaw=57428,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(26)=(CheckPointType=0,MapName="theswamp",CPLocation=(X=-177.0,Y=829.0,Z=-951.0),CPRotation=(Pitch=476,Yaw=16327,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(27)=(CheckPointType=0,MapName="Cregor",CPLocation=(X=10516.0,Y=1083.0,Z=-3516.0),CPRotation=(Pitch=65320,Yaw=64552,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(28)=(CheckPointType=1,MapName="Cregor",CPLocation=(X=18481.0,Y=2237.0,Z=-3366.0),CPRotation=(Pitch=64553,Yaw=57611,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(29)=(CheckPointType=1,MapName="Cregor",CPLocation=(X=18874.0,Y=3292.0,Z=-3444.0),CPRotation=(Pitch=64692,Yaw=76,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(30)=(CheckPointType=0,MapName="cregorpass",CPLocation=(X=2525.0,Y=-723.0,Z=2380.0),CPRotation=(Pitch=185,Yaw=49123,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(31)=(CheckPointType=0,MapName="EhactoraThree",CPLocation=(X=6919.0,Y=4117.0,Z=-34.0),CPRotation=(Pitch=1859,Yaw=14928,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(32)=(CheckPointType=0,MapName="EhactoraFive",CPLocation=(X=18536.0,Y=16519.0,Z=-310.0),CPRotation=(Pitch=844,Yaw=28841,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(33)=(CheckPointType=0,MapName="EhactoraFive",CPLocation=(X=23203.0,Y=-21200.0,Z=620.0),CPRotation=(Pitch=230,Yaw=48675,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(34)=(CheckPointType=2,MapName="EhactoraFive",CPLocation=(X=-30212.0,Y=-29347.0,Z=296.0),CPRotation=(Pitch=65443,Yaw=48973,Roll=202),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(35)=(CheckPointType=1,MapName="EhactoraFive",CPLocation=(X=-8360.0,Y=-11006.0,Z=-1940.0),CPRotation=(Pitch=65060,Yaw=32701,Roll=3),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(36)=(CheckPointType=1,MapName="Sinistral_Level2",CPLocation=(X=7668.0,Y=7053.0,Z=-4196.0),CPRotation=(Pitch=63539,Yaw=51872,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(37)=(CheckPointType=1,MapName="Sinistral_Level3",CPLocation=(X=-1926.0,Y=-6822.0,Z=1703.0),CPRotation=(Pitch=65443,Yaw=32777,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(38)=(CheckPointType=1,MapName="Sinistral_Level4",CPLocation=(X=17151.0,Y=-7112.0,Z=443.0),CPRotation=(Pitch=64830,Yaw=37064,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(39)=(CheckPointType=1,MapName="Sinistral_Level4",CPLocation=(X=6592.0,Y=-18057.0,Z=548.0),CPRotation=(Pitch=65122,Yaw=23962,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(40)=(CheckPointType=2,MapName="Sinistral_Level4",CPLocation=(X=5946.0,Y=-18431.0,Z=2472.0),CPRotation=(Pitch=706,Yaw=32949,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(41)=(CheckPointType=1,MapName="Sinistral_Level5",CPLocation=(X=-772.0,Y=12300.0,Z=232.0),CPRotation=(Pitch=65459,Yaw=16382,Roll=18),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(42)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=2951.0,Y=6812.0,Z=193.0),CPRotation=(Pitch=65382,Yaw=32747,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(43)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=-7584.0,Y=7216.0,Z=388.0),CPRotation=(Pitch=184,Yaw=16219,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(44)=(CheckPointType=1,MapName="Sinistral_Level6",CPLocation=(X=-10601.0,Y=6653.0,Z=1528.0),CPRotation=(Pitch=65260,Yaw=26940,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(45)=(CheckPointType=0,MapName="Strange1",CPLocation=(X=4164.0,Y=-2177.0,Z=-468.0),CPRotation=(Pitch=266,Yaw=49207,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=True,EventTag="Startd")
	CheckPoints(46)=(CheckPointType=0,MapName="Strange1",CPLocation=(X=-4263.0,Y=-3242.0,Z=-940.0),CPRotation=(Pitch=65260,Yaw=50142,Roll=65533),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(47)=(CheckPointType=0,MapName="Strange2",CPLocation=(X=6920.0,Y=688.0,Z=-340.0),CPRotation=(Pitch=65397,Yaw=16581,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(48)=(CheckPointType=0,MapName="Strange3",CPLocation=(X=1258.0,Y=-4495.0,Z=-1748.0),CPRotation=(Pitch=65505,Yaw=33025,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(49)=(CheckPointType=0,MapName="Strange3",CPLocation=(X=-4050.0,Y=4526.0,Z=-724.0),CPRotation=(Pitch=65505,Yaw=62869,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(50)=(CheckPointType=0,MapName="Strange5",CPLocation=(X=4444.0,Y=-4336.0,Z=27.0),CPRotation=(Pitch=65305,Yaw=62423,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(51)=(CheckPointType=0,MapName="Strange6",CPLocation=(X=3863.0,Y=-562.0,Z=-340.0),CPRotation=(Pitch=65013,Yaw=32664,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(52)=(CheckPointType=0,MapName="Strange7",CPLocation=(X=2220.0,Y=-4277.0,Z=427.0),CPRotation=(Pitch=122,Yaw=13576,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(53)=(CheckPointType=0,MapName="Dig",CPLocation=(X=4186.0,Y=-1965.0,Z=-84.0),CPRotation=(Pitch=65428,Yaw=32595,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(54)=(CheckPointType=0,MapName="Dug",CPLocation=(X=4605.0,Y=-2676.0,Z=140.0),CPRotation=(Pitch=65474,Yaw=16548,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(55)=(CheckPointType=0,MapName="Chizra",CPLocation=(X=-5915.0,Y=-1309.0,Z=588.0),CPRotation=(Pitch=65413,Yaw=16385,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(56)=(CheckPointType=0,MapName="Ceremony",CPLocation=(X=520.0,Y=3844.0,Z=315.0),CPRotation=(Pitch=65351,Yaw=49360,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(57)=(CheckPointType=0,MapName="Dark",CPLocation=(X=-2472.0,Y=22.0,Z=172.0),CPRotation=(Pitch=65167,Yaw=116,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(58)=(CheckPointType=0,MapName="TerraLift",CPLocation=(X=-892.0,Y=720.0,Z=3787.0),CPRotation=(Pitch=65337,Yaw=49321,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(59)=(CheckPointType=0,MapName="Terraniux",CPLocation=(X=-1008.0,Y=-15448.0,Z=1452.0),CPRotation=(Pitch=65045,Yaw=48901,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(60)=(CheckPointType=1,MapName="Ruins",CPLocation=(X=2688.0,Y=-2592.0,Z=-4.0),CPRotation=(Pitch=65213,Yaw=49360,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(61)=(CheckPointType=0,MapName="ISVDeck1",CPLocation=(X=0.0,Y=-3.0,Z=372.0),CPRotation=(Pitch=65213,Yaw=16376,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(62)=(CheckPointType=0,MapName="TheSunspire",CPLocation=(X=2828.0,Y=3229.0,Z=-11113.0),CPRotation=(Pitch=383,Yaw=32822,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(63)=(CheckPointType=1,MapName="TheSunspire",CPLocation=(X=-3018.0,Y=3003.0,Z=-6985.0),CPRotation=(Pitch=76,Yaw=16312,Roll=65533),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(64)=(CheckPointType=0,MapName="SkyBase",CPLocation=(X=1818.0,Y=4084.0,Z=3115.0),CPRotation=(Pitch=65489,Yaw=65495,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(65)=(CheckPointType=0,MapName="Bluff",CPLocation=(X=47.0,Y=1489.0,Z=-2516.0),CPRotation=(Pitch=154,Yaw=36458,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(66)=(CheckPointType=0,MapName="Dasapass",CPLocation=(X=-422.0,Y=20.0,Z=-640.0),CPRotation=(Pitch=184,Yaw=14,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(67)=(CheckPointType=0,MapName="Dasacellars",CPLocation=(X=0.0,Y=0.0,Z=0.0),CPRotation=(Pitch=65474,Yaw=65499,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(68)=(CheckPointType=0,MapName="Nalic",CPLocation=(X=572.0,Y=-158.0,Z=3260.0),CPRotation=(Pitch=65352,Yaw=49289,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(69)=(CheckPointType=0,MapName="Duskfalls",CPLocation=(X=7625.0,Y=0.0,Z=-340.0),CPRotation=(Pitch=64952,Yaw=33396,Roll=3),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(70)=(CheckPointType=0,MapName="Eldora",CPLocation=(X=2944.0,Y=33.0,Z=1324.0),CPRotation=(Pitch=65521,Yaw=246,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(71)=(CheckPointType=2,MapName="Glathriel2",CPLocation=(X=-408.0,Y=-2478.0,Z=-49.0),CPRotation=(Pitch=64599,Yaw=25986,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(72)=(CheckPointType=0,MapName="Crashsite1",CPLocation=(X=-3173.0,Y=7635.0,Z=1538.0),CPRotation=(Pitch=65259,Yaw=49132,Roll=65534),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(73)=(CheckPointType=2,MapName="Crashsite2",CPLocation=(X=-3399.0,Y=9448.0,Z=2498.0),CPRotation=(Pitch=215,Yaw=19353,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(74)=(CheckPointType=0,MapName="Soledad",CPLocation=(X=103.0,Y=-2031.0,Z=-1876.0),CPRotation=(Pitch=65351,Yaw=65499,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(75)=(CheckPointType=1,MapName="Soledad",CPLocation=(X=5187.0,Y=-530.0,Z=-1564.0),CPRotation=(Pitch=62,Yaw=49112,Roll=3),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(76)=(CheckPointType=0,MapName="Velora",CPLocation=(X=-812.0,Y=-10513.0,Z=-740.0),CPRotation=(Pitch=307,Yaw=32402,Roll=2),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(77)=(CheckPointType=0,MapName="Foundry",CPLocation=(X=-1048.0,Y=2460.0,Z=-1221.0),CPRotation=(Pitch=65336,Yaw=32684,Roll=65530),CPRadius=768.0,CPHeight=256.0,bEventEnabled=False,EventTag="None")
	CheckPoints(78)=(CheckPointType=0,MapName="Toxic",CPLocation=(X=1022.0,Y=-213.0,Z=-228.0),CPRotation=(Pitch=15,Yaw=49292,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(79)=(CheckPointType=1,MapName="Toxic",CPLocation=(X=-2761.0,Y=-2323.0,Z=-3428.0),CPRotation=(Pitch=65353,Yaw=48793,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(80)=(CheckPointType=0,MapName="Abyss",CPLocation=(X=-4084.0,Y=331.0,Z=-2516.0),CPRotation=(Pitch=230,Yaw=65401,Roll=65532),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(81)=(CheckPointType=1,MapName="Nalic2",CPLocation=(X=-924.0,Y=-238.0,Z=-12820.0),CPRotation=(Pitch=65505,Yaw=65371,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(82)=(CheckPointType=0,MapName="03Temple",CPLocation=(X=3135.24,Y=-1154.16,Z=3603.8),CPRotation=(Pitch=598,Yaw=10801,Roll=65541),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(83)=(CheckPointType=0,MapName="04mountains",CPLocation=(X=-2303.93,Y=10496.3,Z=43.8),CPRotation=(Pitch=231,Yaw=-16399,Roll=65541),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(84)=(CheckPointType=0,MapName="05Spire",CPLocation=(X=-1284.34,Y=-1250.46,Z=203.9),CPRotation=(Pitch=76,Yaw=16473,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(85)=(CheckPointType=0,MapName="05Spire",CPLocation=(X=-1951.21,Y=-665.161,Z=203.9),CPRotation=(Pitch=752,Yaw=32368,Roll=3),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(86)=(CheckPointType=1,MapName="06Streets",CPLocation=(X=-1987.27,Y=14106.8,Z=-84.2),CPRotation=(Pitch=47,Yaw=-35598,Roll=-6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(87)=(CheckPointType=1,MapName="08StellTown",CPLocation=(X=-83.5791,Y=-1919.3,Z=43.9),CPRotation=(Pitch=123,Yaw=184,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(88)=(CheckPointType=2,MapName="08StellTown",CPLocation=(X=267.696,Y=-4241.93,Z=43.9),CPRotation=(Pitch=414,Yaw=-16434,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(89)=(CheckPointType=2,MapName="09Underground",CPLocation=(X=-3233.47,Y=2047.9,Z=-212.2),CPRotation=(Pitch=399,Yaw=127,Roll=-5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(90)=(CheckPointType=0,MapName="09Underground",CPLocation=(X=2615.57,Y=3874.64,Z=-212.1),CPRotation=(Pitch=753,Yaw=-8796,Roll=-5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(91)=(CheckPointType=1,MapName="10Queen",CPLocation=(X=-4900.98,Y=-18070.6,Z=-572.2),CPRotation=(Pitch=139,Yaw=-16568,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(92)=(CheckPointType=0,MapName="12ColdPassage",CPLocation=(X=597.513,Y=21782.0,Z=-1908.1),CPRotation=(Pitch=0,Yaw=-32837,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(93)=(CheckPointType=2,MapName="12ColdPassage",CPLocation=(X=1632.45,Y=20932.9,Z=-2452.2),CPRotation=(Pitch=65444,Yaw=-25525,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(94)=(CheckPointType=2,MapName="13Cemetery",CPLocation=(X=-909.463,Y=-1477.23,Z=-372.1),CPRotation=(Pitch=262,Yaw=-65455,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(95)=(CheckPointType=0,MapName="16Castle",CPLocation=(X=2571.33,Y=-413.197,Z=555.9),CPRotation=(Pitch=65351,Yaw=-39499,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(96)=(CheckPointType=0,MapName="16Castle",CPLocation=(X=1095.43,Y=-3149.47,Z=1387.9),CPRotation=(Pitch=31,Yaw=65307,Roll=65541),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(97)=(CheckPointType=2,MapName="16Castle",CPLocation=(X=3164.66,Y=-1687.03,Z=1387.8),CPRotation=(Pitch=65413,Yaw=82094,Roll=65542),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(98)=(CheckPointType=0,MapName="17Tower",CPLocation=(X=2.74913,Y=-1169.7,Z=1579.8),CPRotation=(Pitch=127,Yaw=16622,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(99)=(CheckPointType=0,MapName="19IceMorning",CPLocation=(X=-536.311,Y=1215.99,Z=-180.2),CPRotation=(Pitch=65136,Yaw=-98629,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(100)=(CheckPointType=0,MapName="19IceMorning",CPLocation=(X=-8794.85,Y=3469.07,Z=-69.2453),CPRotation=(Pitch=507,Yaw=-98444,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(101)=(CheckPointType=2,MapName="19IceMorning",CPLocation=(X=-14916.7,Y=2169.04,Z=-84.1),CPRotation=(Pitch=65413,Yaw=-120913,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(102)=(CheckPointType=0,MapName="20Cave",CPLocation=(X=-6151.31,Y=-713.886,Z=-514.198),CPRotation=(Pitch=65351,Yaw=-48817,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(103)=(CheckPointType=0,MapName="21Mine",CPLocation=(X=-2396.39,Y=-3547.69,Z=-244.2),CPRotation=(Pitch=185,Yaw=49709,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(104)=(CheckPointType=0,MapName="21Mine",CPLocation=(X=-4812.64,Y=882.686,Z=619.8),CPRotation=(Pitch=262,Yaw=19530,Roll=6),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(105)=(CheckPointType=0,MapName="21Mine",CPLocation=(X=-1539.3,Y=3813.14,Z=-228.049),CPRotation=(Pitch=2027,Yaw=16564,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(106)=(CheckPointType=1,MapName="21Mine",CPLocation=(X=-6339.99,Y=11846.0,Z=603.8),CPRotation=(Pitch=65259,Yaw=-130,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(107)=(CheckPointType=0,MapName="22SpeedWay",CPLocation=(X=9024.7,Y=8792.24,Z=-980.2),CPRotation=(Pitch=891,Yaw=32576,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(108)=(CheckPointType=0,MapName="22SpeedWay",CPLocation=(X=3752.97,Y=13902.3,Z=-977.245),CPRotation=(Pitch=65290,Yaw=30886,Roll=66346),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(109)=(CheckPointType=2,MapName="22SpeedWay",CPLocation=(X=-19909.2,Y=20749.2,Z=39.034),CPRotation=(Pitch=65397,Yaw=114744,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(110)=(CheckPointType=0,MapName="22SpeedWay",CPLocation=(X=-21033.3,Y=14150.7,Z=250.212),CPRotation=(Pitch=47,Yaw=114528,Roll=7),CPRadius=512.0,CPHeight=4096.0,bEventEnabled=False,EventTag="None")
	CheckPoints(111)=(CheckPointType=0,MapName="23WarFactory",CPLocation=(X=7829.74,Y=-4732.59,Z=55.2623),CPRotation=(Pitch=64231,Yaw=-12,Roll=65535),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(112)=(CheckPointType=1,MapName="23WarFactory",CPLocation=(X=18587.3,Y=-14822.7,Z=-308.2),CPRotation=(Pitch=261,Yaw=-16323,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(113)=(CheckPointType=0,MapName="24HeadQuarter",CPLocation=(X=-866.171,Y=-3053.79,Z=435.508),CPRotation=(Pitch=65382,Yaw=-16615,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(114)=(CheckPointType=1,MapName="24HeadQuarter",CPLocation=(X=-1127.2,Y=-2710.87,Z=1195.7),CPRotation=(Pitch=65459,Yaw=-9749,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(115)=(CheckPointType=1,MapName="24HeadQuarter",CPLocation=(X=2667.71,Y=1352.5,Z=971.8),CPRotation=(Pitch=492,Yaw=41410,Roll=65542),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(116)=(CheckPointType=0,MapName="25LostPalace",CPLocation=(X=-1116.16,Y=-6936.46,Z=-1508.2),CPRotation=(Pitch=200,Yaw=32472,Roll=5),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(117)=(CheckPointType=1,MapName="25LostPalace",CPLocation=(X=-7808.71,Y=-10331.5,Z=-594.437),CPRotation=(Pitch=63955,Yaw=65538,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(118)=(CheckPointType=2,MapName="25LostPalace",CPLocation=(X=-1856.24,Y=-8309.01,Z=-2475.6),CPRotation=(Pitch=62464,Yaw=180219,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(119)=(CheckPointType=1,MapName="25LostPalace",CPLocation=(X=1326.49,Y=-3243.88,Z=-615.841),CPRotation=(Pitch=384,Yaw=131396,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(120)=(CheckPointType=2,MapName="26Town",CPLocation=(X=5123.3,Y=-4987.9,Z=710.703),CPRotation=(Pitch=65397,Yaw=-16387,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(121)=(CheckPointType=0,MapName="26Town",CPLocation=(X=10880.2,Y=-2239.25,Z=-437.965),CPRotation=(Pitch=322,Yaw=-16,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(122)=(CheckPointType=1,MapName="27Cellars",CPLocation=(X=3020.09,Y=-3.4229,Z=26.3375),CPRotation=(Pitch=277,Yaw=-122,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(123)=(CheckPointType=2,MapName="27Cellars",CPLocation=(X=5114.04,Y=9.8038,Z=330.833),CPRotation=(Pitch=184,Yaw=-31,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(124)=(CheckPointType=0,MapName="27Cellars",CPLocation=(X=1827.11,Y=-960.374,Z=54.4148),CPRotation=(Pitch=65182,Yaw=-16280,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(125)=(CheckPointType=1,MapName="29CentralTown",CPLocation=(X=-832.631,Y=-206.211,Z=-94.5368),CPRotation=(Pitch=65490,Yaw=-61741,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(126)=(CheckPointType=1,MapName="30Catacombs",CPLocation=(X=-1959.2,Y=-6701.62,Z=-1704.97),CPRotation=(Pitch=65290,Yaw=-147975,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(127)=(CheckPointType=2,MapName="31LostCity",CPLocation=(X=-2013.84,Y=-5528.53,Z=526.653),CPRotation=(Pitch=138,Yaw=16571,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(128)=(CheckPointType=0,MapName="32Piramide",CPLocation=(X=-1046.51,Y=935.628,Z=1600.48),CPRotation=(Pitch=231,Yaw=-65807,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(129)=(CheckPointType=2,MapName="32Piramide",CPLocation=(X=-0.468003,Y=-7473.14,Z=4776.71),CPRotation=(Pitch=122,Yaw=-82088,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(130)=(CheckPointType=1,MapName="32Piramide",CPLocation=(X=5208.73,Y=-10297.3,Z=5695.07),CPRotation=(Pitch=384,Yaw=-114724,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(131)=(CheckPointType=0,MapName="32Piramide",CPLocation=(X=-535.594,Y=-9520.7,Z=5223.65),CPRotation=(Pitch=168,Yaw=-82179,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(132)=(CheckPointType=0,MapName="32Piramide",CPLocation=(X=-1427.63,Y=-7741.29,Z=5243.17),CPRotation=(Pitch=65059,Yaw=-129191,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(133)=(CheckPointType=0,MapName="32Piramide",CPLocation=(X=3933.99,Y=-9029.24,Z=4802.68),CPRotation=(Pitch=65383,Yaw=-163594,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(134)=(CheckPointType=1,MapName="32Piramide",CPLocation=(X=3.71036,Y=422.725,Z=2874.63),CPRotation=(Pitch=460,Yaw=-81812,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(135)=(CheckPointType=0,MapName="33Sarevok",CPLocation=(X=8451.47,Y=-962.314,Z=227.116),CPRotation=(Pitch=107,Yaw=-320,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(136)=(CheckPointType=2,MapName="33Sarevok",CPLocation=(X=11420.3,Y=-574.335,Z=681.69),CPRotation=(Pitch=65244,Yaw=-32786,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(137)=(CheckPointType=1,MapName="34DarkWood",CPLocation=(X=-21.0804,Y=-1746.98,Z=69.004),CPRotation=(Pitch=65429,Yaw=-16369,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(138)=(CheckPointType=1,MapName="34DarkWood",CPLocation=(X=-5418.93,Y=-10576.7,Z=-287.078),CPRotation=(Pitch=308,Yaw=-27,Roll=65530),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(139)=(CheckPointType=0,MapName="34DarkWood",CPLocation=(X=10426.3,Y=-11325.6,Z=-330.773),CPRotation=(Pitch=65213,Yaw=-65900,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(140)=(CheckPointType=0,MapName="35Monastery",CPLocation=(X=-1213.74,Y=-1834.9,Z=77.7921),CPRotation=(Pitch=153,Yaw=-24432,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(141)=(CheckPointType=0,MapName="35Monastery",CPLocation=(X=-1903.49,Y=-4470.35,Z=106.864),CPRotation=(Pitch=65397,Yaw=32778,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(142)=(CheckPointType=2,MapName="36Amarok",CPLocation=(X=-3971.32,Y=-5297.1,Z=2121.63),CPRotation=(Pitch=552,Yaw=-16336,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(143)=(CheckPointType=1,MapName="37Castle",CPLocation=(X=762.986,Y=-2783.13,Z=339.793),CPRotation=(Pitch=65475,Yaw=49216,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(144)=(CheckPointType=0,MapName="37Castle",CPLocation=(X=1635.98,Y=-1959.62,Z=-864.043),CPRotation=(Pitch=65137,Yaw=104184,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(145)=(CheckPointType=2,MapName="37Castle",CPLocation=(X=763.707,Y=-2201.13,Z=1331.68),CPRotation=(Pitch=199,Yaw=-16042,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(146)=(CheckPointType=0,MapName="37Castle",CPLocation=(X=-95.1623,Y=-2419.0,Z=157.988),CPRotation=(Pitch=64169,Yaw=-653,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(147)=(CheckPointType=0,MapName="38Specters",CPLocation=(X=-1784.01,Y=-15131.8,Z=-1296.89),CPRotation=(Pitch=65228,Yaw=-32885,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(148)=(CheckPointType=0,MapName="38Specters",CPLocation=(X=-715.742,Y=-11355.4,Z=-1391.96),CPRotation=(Pitch=63754,Yaw=-49165,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(149)=(CheckPointType=0,MapName="38Specters",CPLocation=(X=-2455.54,Y=-8050.46,Z=-1441.15),CPRotation=(Pitch=65213,Yaw=-48811,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(150)=(CheckPointType=0,MapName="38Specters",CPLocation=(X=-564.633,Y=-3602.37,Z=-674.304),CPRotation=(Pitch=354,Yaw=-48950,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(151)=(CheckPointType=2,MapName="38Specters",CPLocation=(X=638.882,Y=-125.086,Z=223.421),CPRotation=(Pitch=292,Yaw=-114576,Roll=65528),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(152)=(CheckPointType=0,MapName="39Ruins",CPLocation=(X=507.113,Y=-3404.84,Z=4154.47),CPRotation=(Pitch=65429,Yaw=49421,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(153)=(CheckPointType=1,MapName="40Underworld",CPLocation=(X=-16967.4,Y=3030.54,Z=-1074.41),CPRotation=(Pitch=64277,Yaw=82483,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(154)=(CheckPointType=1,MapName="40Underworld",CPLocation=(X=-18807.1,Y=8102.54,Z=-1003.83),CPRotation=(Pitch=65459,Yaw=81976,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(155)=(CheckPointType=2,MapName="40Underworld",CPLocation=(X=-18810.3,Y=16509.0,Z=-1500.47),CPRotation=(Pitch=65152,Yaw=82115,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(156)=(CheckPointType=0,MapName="40Underworld",CPLocation=(X=-18773.3,Y=21529.2,Z=-1159.85),CPRotation=(Pitch=307,Yaw=98317,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(157)=(CheckPointType=2,MapName="43City",CPLocation=(X=2463.01,Y=3.19779,Z=2694.21),CPRotation=(Pitch=31,Yaw=49078,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(158)=(CheckPointType=0,MapName="43City",CPLocation=(X=-1890.73,Y=-259.245,Z=2229.19),CPRotation=(Pitch=337,Yaw=81884,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(159)=(CheckPointType=0,MapName="43City",CPLocation=(X=-7203.78,Y=819.696,Z=2769.54),CPRotation=(Pitch=65306,Yaw=81239,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(160)=(CheckPointType=0,MapName="44OldSection",CPLocation=(X=540.106,Y=558.682,Z=-522.991),CPRotation=(Pitch=65214,Yaw=-16440,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(161)=(CheckPointType=1,MapName="44OldSection",CPLocation=(X=-2567.63,Y=2850.87,Z=-2044.35),CPRotation=(Pitch=64798,Yaw=3494,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(162)=(CheckPointType=1,MapName="44OldSection",CPLocation=(X=-722.297,Y=5257.6,Z=-2453.82),CPRotation=(Pitch=153,Yaw=32875,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(163)=(CheckPointType=2,MapName="44OldSection",CPLocation=(X=-3927.89,Y=9478.19,Z=-4875.82),CPRotation=(Pitch=123,Yaw=16488,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(164)=(CheckPointType=0,MapName="45HighTown",CPLocation=(X=-1878.09,Y=335.161,Z=-608.316),CPRotation=(Pitch=123,Yaw=-49481,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(165)=(CheckPointType=1,MapName="45HighTown",CPLocation=(X=-2086.29,Y=-323.812,Z=5767.41),CPRotation=(Pitch=65443,Yaw=-81612,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(166)=(CheckPointType=0,MapName="45HighTown",CPLocation=(X=-2124.35,Y=-2071.96,Z=3781.23),CPRotation=(Pitch=65428,Yaw=-15970,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(167)=(CheckPointType=1,MapName="45HighTown",CPLocation=(X=-7168.09,Y=-3768.95,Z=3757.5),CPRotation=(Pitch=415,Yaw=65645,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(168)=(CheckPointType=2,MapName="45HighTown",CPLocation=(X=-2579.9,Y=-7140.75,Z=4024.7),CPRotation=(Pitch=261,Yaw=49458,Roll=65536),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(169)=(CheckPointType=1,MapName="46SpacePort",CPLocation=(X=1902.7,Y=14590.4,Z=11.7),CPRotation=(Pitch=65244,Yaw=23,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(170)=(CheckPointType=2,MapName="46SpacePort",CPLocation=(X=6040.14,Y=14597.3,Z=1648.98),CPRotation=(Pitch=65368,Yaw=32645,Roll=4),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(171)=(CheckPointType=1,MapName="46SpacePort",CPLocation=(X=5927.61,Y=14590.5,Z=-164.1),CPRotation=(Pitch=65198,Yaw=98380,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(172)=(CheckPointType=2,MapName="S1Skyship",CPLocation=(X=1916.14,Y=-2211.46,Z=-596.2),CPRotation=(Pitch=168,Yaw=-81688,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(173)=(CheckPointType=2,MapName="S2Cursed",CPLocation=(X=-6798.82,Y=1084.52,Z=359.001),CPRotation=(Pitch=108,Yaw=32815,Roll=65542),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(174)=(CheckPointType=2,MapName="S3Toys",CPLocation=(X=-3136.93,Y=-4417.13,Z=2347.8),CPRotation=(Pitch=0,Yaw=49278,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(175)=(CheckPointType=0,MapName="S3Toys",CPLocation=(X=-3140.56,Y=-198.852,Z=115.317),CPRotation=(Pitch=65290,Yaw=48832,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(176)=(CheckPointType=0,MapName="S4VReality",CPLocation=(X=-0.458409,Y=-5407.32,Z=-1556.2),CPRotation=(Pitch=65383,Yaw=-16338,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(177)=(CheckPointType=1,MapName="S4VReality",CPLocation=(X=703.208,Y=-11589.6,Z=-1126.47),CPRotation=(Pitch=65398,Yaw=95,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(178)=(CheckPointType=2,MapName="S4VReality",CPLocation=(X=7866.82,Y=-13688.0,Z=-823.5),CPRotation=(Pitch=65459,Yaw=250,Roll=65531),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(179)=(CheckPointType=0,MapName="S5HellRaiser",CPLocation=(X=1622.41,Y=-5857.44,Z=-458.841),CPRotation=(Pitch=65263,Yaw=46798,Roll=65122),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(180)=(CheckPointType=2,MapName="S5HellRaiser",CPLocation=(X=1263.88,Y=-12709.0,Z=-182.725),CPRotation=(Pitch=65444,Yaw=27642,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(181)=(CheckPointType=0,MapName="S5HellRaiser",CPLocation=(X=311.377,Y=-11700.9,Z=-675.607),CPRotation=(Pitch=123,Yaw=-12935,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(182)=(CheckPointType=0,MapName="S5HellRaiser",CPLocation=(X=21019.7,Y=-25949.4,Z=1456.11),CPRotation=(Pitch=65445,Yaw=16292,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(183)=(CheckPointType=2,MapName="S5HellRaiser",CPLocation=(X=21261.8,Y=-26682.2,Z=1453.48),CPRotation=(Pitch=17,Yaw=-571,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(184)=(CheckPointType=0,MapName="S5HellRaiser",CPLocation=(X=13027.1,Y=-12675.1,Z=579.602),CPRotation=(Pitch=65292,Yaw=-65262,Roll=0),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(185)=(CheckPointType=2,MapName="S6PaciManor",CPLocation=(X=-1866.73,Y=2341.11,Z=-211.416),CPRotation=(Pitch=65290,Yaw=-65378,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(186)=(CheckPointType=2,MapName="S6PaciManor",CPLocation=(X=2159.98,Y=1897.75,Z=-280.972),CPRotation=(Pitch=65367,Yaw=-33033,Roll=7),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(187)=(CheckPointType=1,MapName="S7Gloomy",CPLocation=(X=116.153,Y=512.942,Z=-108.2),CPRotation=(Pitch=64492,Yaw=-400,Roll=65540),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(188)=(CheckPointType=0,MapName="S7Gloomy",CPLocation=(X=1750.22,Y=382.186,Z=-156.2),CPRotation=(Pitch=276,Yaw=-98018,Roll=65529),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	CheckPoints(189)=(CheckPointType=2,MapName="S7Gloomy",CPLocation=(X=2293.64,Y=724.864,Z=131.8),CPRotation=(Pitch=64139,Yaw=-130624,Roll=65542),CPRadius=0.0,CPHeight=0.0,bEventEnabled=False,EventTag="None")
	ClassReplacement(0)=(OriginalClass="FemaleOne",ReplacementClass="WolfCoop.wFemaleOne")
	ClassReplacement(1)=(OriginalClass="FemaleTwo",ReplacementClass="WolfCoop.wFemaleTwo")
	ClassReplacement(2)=(OriginalClass="MaleThree",ReplacementClass="WolfCoop.wMaleThree")
	ClassReplacement(3)=(OriginalClass="MaleTwo",ReplacementClass="WolfCoop.wMaleTwo")
	ClassReplacement(4)=(OriginalClass="MaleOne",ReplacementClass="WolfCoop.wMaleOne")
	ClassReplacement(5)=(OriginalClass="SkaarjPlayer",ReplacementClass="WolfCoop.wSkaarjPlayer")
	ClassReplacement(6)=(OriginalClass="NaliPlayer",ReplacementClass="WolfCoop.wNaliPlayer")
	ClassReplacement(7)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(8)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(9)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(10)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(11)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(12)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(13)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(14)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(15)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(16)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(17)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(18)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(19)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(20)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(21)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(22)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(23)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(24)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(25)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(26)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(27)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(28)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(29)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(30)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(31)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(32)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(33)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(34)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(35)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(36)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(37)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(38)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(39)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(40)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(41)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(42)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(43)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(44)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(45)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(46)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(47)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(48)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(49)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(50)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(51)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(52)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(53)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(54)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(55)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(56)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(57)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(58)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(59)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(60)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(61)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(62)=(OriginalClass="",ReplacementClass="")
	ClassReplacement(63)=(OriginalClass="",ReplacementClass="")
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
	GiveItems(3)=""
	GiveItems(4)=""
	GiveItems(5)=""
	GiveItems(6)=""
	GiveItems(7)=""
	GiveItems(8)=""
	GiveItems(9)=""
	GiveItems(10)=""
	GiveItems(11)=""
	GiveItems(12)=""
	GiveItems(13)=""
	GiveItems(14)=""
	GiveItems(15)=""
	GiveItems(16)=""
	GiveItems(17)=""
	GiveItems(18)=""
	GiveItems(19)=""
	GiveItems(20)=""
	GiveItems(21)=""
	GiveItems(22)=""
	GiveItems(23)=""
	GiveItems(24)=""
	GiveItems(25)=""
	GiveItems(26)=""
	GiveItems(27)=""
	GiveItems(28)=""
	GiveItems(29)=""
	GiveItems(30)=""
	GiveItems(31)=""
	GiveItems(32)=""
	GiveItems(33)=""
	GiveItems(34)=""
	GiveItems(35)=""
	GiveItems(36)=""
	GiveItems(37)=""
	GiveItems(38)=""
	GiveItems(39)=""
	GiveItems(40)=""
	GiveItems(41)=""
	GiveItems(42)=""
	GiveItems(43)=""
	GiveItems(44)=""
	GiveItems(45)=""
	GiveItems(46)=""
	GiveItems(47)=""
	GiveItems(48)=""
	GiveItems(49)=""
	GiveItems(50)=""
	GiveItems(51)=""
	GiveItems(52)=""
	GiveItems(53)=""
	GiveItems(54)=""
	GiveItems(55)=""
	GiveItems(56)=""
	GiveItems(57)=""
	GiveItems(58)=""
	GiveItems(59)=""
	GiveItems(60)=""
	GiveItems(61)=""
	GiveItems(62)=""
	GiveItems(63)=""
	SaveURL=""
	MapName=""
	TempLastMap=""
	SavedURLs(0)=""
	SavedURLs(1)=""
	SavedURLs(2)=""
	SavedURLs(3)=""
	SavedURLs(4)=""
	SavedURLs(5)=""
	SavedURLs(6)=""
	SavedURLs(7)=""
	SavedURLs(8)=""
	SavedURLs(9)=""
	SavedURLs(10)=""
	SavedURLs(11)=""
	SavedURLs(12)=""
	SavedURLs(13)=""
	SavedURLs(14)=""
	SavedURLs(15)=""
	SavedURLs(16)=""
	SavedURLs(17)=""
	SavedURLs(18)=""
	SavedURLs(19)=""
	SavedURLs(20)=""
	SavedURLs(21)=""
	SavedURLs(22)=""
	SavedURLs(23)=""
	SavedURLs(24)=""
	SavedURLs(25)=""
	SavedURLs(26)=""
	SavedURLs(27)=""
	SavedURLs(28)=""
	SavedURLs(29)=""
	SavedURLs(30)=""
	SavedURLs(31)=""
	SavedURLs(32)=""
	SavedURLs(33)=""
	SavedURLs(34)=""
	SavedURLs(35)=""
	SavedURLs(36)=""
	SavedURLs(37)=""
	SavedURLs(38)=""
	SavedURLs(39)=""
	SavedURLs(40)=""
	SavedURLs(41)=""
	SavedURLs(42)=""
	SavedURLs(43)=""
	SavedURLs(44)=""
	SavedURLs(45)=""
	SavedURLs(46)=""
	SavedURLs(47)=""
	SavedURLs(48)=""
	SavedURLs(49)=""
	SavedURLs(50)=""
	SavedURLs(51)=""
	SavedURLs(52)=""
	SavedURLs(53)=""
	SavedURLs(54)=""
	SavedURLs(55)=""
	SavedURLs(56)=""
	SavedURLs(57)=""
	SavedURLs(58)=""
	SavedURLs(59)=""
	SavedURLs(60)=""
	SavedURLs(61)=""
	SavedURLs(62)=""
	SavedURLs(63)=""
	LastMap="Vortex2"
	NeutralMaps(0)="MapFileName"
	NeutralMaps(1)=" "
	NeutralMaps(2)=" "
	NeutralMaps(3)=" "
	NeutralMaps(4)=""
	NeutralMaps(5)=""
	NeutralMaps(6)=""
	NeutralMaps(7)=""
	NeutralMaps(8)=""
	NeutralMaps(9)=""
	NeutralMaps(10)=""
	NeutralMaps(11)=""
	NeutralMaps(12)=""
	NeutralMaps(13)=""
	NeutralMaps(14)=""
	NeutralMaps(15)=""
	NeutralMaps(16)=""
	NeutralMaps(17)=""
	NeutralMaps(18)=""
	NeutralMaps(19)=""
	NeutralMaps(20)=""
	NeutralMaps(21)=""
	NeutralMaps(22)=""
	NeutralMaps(23)=""
	NeutralMaps(24)=""
	NeutralMaps(25)=""
	NeutralMaps(26)=""
	NeutralMaps(27)=""
	NeutralMaps(28)=""
	NeutralMaps(29)=""
	NeutralMaps(30)=""
	NeutralMaps(31)=""
	NeutralMaps(32)=""
	NeutralMaps(33)=""
	NeutralMaps(34)=""
	NeutralMaps(35)=""
	NeutralMaps(36)=""
	NeutralMaps(37)=""
	NeutralMaps(38)=""
	NeutralMaps(39)=""
	NeutralMaps(40)=""
	NeutralMaps(41)=""
	NeutralMaps(42)=""
	NeutralMaps(43)=""
	NeutralMaps(44)=""
	NeutralMaps(45)=""
	NeutralMaps(46)=""
	NeutralMaps(47)=""
	NeutralMaps(48)=""
	NeutralMaps(49)=""
	NeutralMaps(50)=""
	NeutralMaps(51)=""
	NeutralMaps(52)=""
	NeutralMaps(53)=""
	NeutralMaps(54)=""
	NeutralMaps(55)=""
	NeutralMaps(56)=""
	NeutralMaps(57)=""
	NeutralMaps(58)=""
	NeutralMaps(59)=""
	NeutralMaps(60)=""
	NeutralMaps(61)=""
	NeutralMaps(62)=""
	NeutralMaps(63)=""
	ForcedHoliday=0
	HolidayNum=0
	bRestoreDrownDamage=True
	bInventoryLossOnDeath=False
	bDropInventoryOnDeath=False
	bEnableVoteEnd=True
	bNoChatVoteEnd=False
	bEndTimerPunish=False
	bPlayersEndGameSpectate=False
	bShowEnds=True
	bEnableCheckPoints=True
	bDisableMapFixes=False
	bRealCrouch=True
	bShowRespawningItems=True
	bAllowCheckpointRelocate=True
	bCheckpointHeals=True
	bPenalizeInventoryOnLifeLoss=False
	bSaveScores=False
	bUniqueItems=False
	bUniquePowerUps=False
	bPermanentFlares=False
	allowcustomwplayers=False
	bRandomizeLightsColor=False
	bRespawnItems=True
	bUseHookMutators=True
	bEnableLives=True
	bExtraLives=True
	bPersonalExtraLives=False
	bRestartMapOnGameOver=False
	bAllowReviving=True
	bResetLivesOnMapChange=False
	bMarioSounds=False
	bSeriousSamExtraLife=False
	bReturnToLastMap=True
	bStarted=False
	bChangingMap=False
	bEndReached=False
	bLMSWarn=False
	bNeutralMap=False
	bEndTimeStarted=False
	FlareAndSeedRespawnTime=15.0
	DefaultPlayerClass=Class'WolfCoop.wFemaleOne'
	DefaultWeapon=None
	ScoreBoardType=Class'WolfCoop.WolfScoreBoard'
	HUDType=Class'WolfCoop.WolfHUD'
	LocalBatcherParams="UM27EDDZM-B318EDCF20290429"
	AccessManagerClass="WolfCoop.wAAM"
	bHumansOnly=False
}
