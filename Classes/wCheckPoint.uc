//=============================================================================
// wCheckPoint.
//=============================================================================
class wCheckPoint expands Actor;

var() bool bEnabled;
var() bool bRevive,bExtraLife;
var wCheckPointLight CPLight;
var() int ScoreAmount;

replication
{
	reliable if(ROLE==Role_Authority)
	bEnabled;
}

function PostBeginPlay()
{CPLight=Spawn(Class'wCheckpointLight',Self); CPLight.LightHue=LightHue; CPLight.LightSaturation=LightSaturation;}

function SetUpCheckPoint(float Radius,float Height,bool bRequireEvent,name EventTag)
{
	if(bRequireEvent) {bEnabled=False; Tag=EventTag;}
	else bEnabled=True;
	if(Radius<=0)Radius=Default.CollisionRadius;
	if(Height<=0)Height=Default.CollisionHeight;
	SetCollisionSize(Radius,Height);
}

function Trigger( actor Other, pawn EventInstigator )
{
	bEnabled=True;
}

simulated function Tick(Float DT)
{
	if(!bEnabled)
	{	bHidden=True;
		CPLight.LightType=LT_None;
		LightRadius=0;
	}
	else
	{	bHidden=False;
		CPLight.LightType=CPLight.Default.LightType;
		LightRadius=Default.LightRadius;
	}
	Super.Tick(DT);
}

simulated function Touch(Actor Other)
{
	local wPlayer P;

	if(PlayerPawn(Other)!=None && bEnabled)
	{
		TriggerEvent(Event,Other,Other.Instigator);
		SetCollision(false,false,false);
		PlayerPawn(Other).PlayerReplicationInfo.Score+=ScoreAmount;
		
		if(bExtraLife)
			BroadcastMessage("Checkpoint Reached: Extra Life!",True,'CriticalEvent');
		else if(bRevive)
			BroadcastMessage("Checkpoint Reached: Dead Players Revived!",True,'CriticalEvent');
		else
			BroadcastMessage("Checkpoint Reached!",True,'CriticalEvent');

		Spawn(Class'ParticleBurst');
		NewPlayerStart();
		if(WolfCoopGame(Level.Game).bCheckpointHeals)
		{
			if(Pawn(Other).Health<Pawn(Other).Default.Health)
				Pawn(Other).Health=Pawn(Other).Default.Health;
		}
		if(WolfCoopGame(Level.Game).bAllowCheckpointRelocate)
		{
			foreach allactors(class'wPlayer',P)
			{
				if(P.Health>0 && P!=Other)
				{
					P.CheckPointTime=30;
					P.SetTimer(1,False,'CheckPointTimer');
				}
			}
		}
		Destroy();
	}
}

simulated function NewPlayerStart()
{
	local wPlayer P;
	local PlayerStart Start,NewStart;

	if(WolfCoopGame(Level.Game).bEnableLives && (bExtraLife || bRevive))
	{	
		foreach allactors(class'wPlayer',P)
		{
			if(bExtraLife)
			{
				if(WolfCoopGame(Level.Game).bSeriousSamExtraLife)
					P.ClientPlaySound(Sound'SeriousSamExtraLife');
				else if(WolfCoopGame(Level.Game).bMarioSounds || WolfCoopGame(Level.Game).HolidayNum==3)
					P.ClientPlaySound(Sound'MarioExtraLife');
				else
					P.ClientPlaySound(Sound'ExtraLife');
			}
			else
				P.ClientPlaySound(Sound'RevivedNotif');

			if (P.Health<=0 && P.Lives<=0 && (bExtraLife || bRevive))
			{
				P.ServerReStartPlayer();
				P.SetLocation(Location);
				P.SetRotation(Rotation);
				P.ViewTarget=None;
			}
			else if (bExtraLife) 
			{
				if(P.Lives<WolfCoopGame(Level.Game).MaxLives)
					P.Lives++;
			}
		}
	}

	ForEach allactors(class 'PlayerStart', Start)
	{
		if(Start.IsA('wPlayerStart'))
			Start.Destroy();
		else
			Start.bEnabled=False;
	}

	NewStart = Spawn(class'wPlayerStart',,,location,rotation);
}

defaultproperties
{
	ScoreAmount=150
	CPLight=None
	bEnabled=True
	bRevive=False
	bExtraLife=False
	LifeSpan=99999.0
	DrawScale=0.5
	ScaleGlow=2.0
	Texture=WetTexture'SpaceFX.wormhole'
	Skin=Texture'GenFX.LensFlar.3'
	RotationRate=(Roll=4096)
	RemoteRole=ROLE_SimulatedProxy
	Style=STY_Translucent
	AmbientGlow=254
	LightType=LT_Steady
	LightEffect=LE_WateryShimmer
	LightHue=140
	LightSaturation=255
	LightRadius=64
	bUnlit=True
	bAlwaysRelevant=True
	bCollideActors=True
	bCollideWorld=True
	bCorona=True
}
