//=============================================================================
// wSpectator.
//=============================================================================
class wSpectator extends wPlayer;

var bool bChaseCam;

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.bIsSpectator = true;
}

event FootZoneChange(ZoneInfo newFootZone)
{
}

event HeadZoneChange(ZoneInfo newHeadZone)
{
}


exec function Walk()
{
}

exec function ActivateItem()
{
	bBehindView = !bBehindView;
	bChaseCam = bBehindView;
}

exec function BehindView( Bool B )
{
	bBehindView = B;
	bChaseCam = bBehindView;
}

function ChangeTeam( int N )
{
	Level.Game.ChangeTeam(self, N);
}

exec function Taunt( name Sequence )
{
}

exec function CallForHelp()
{
}

exec function ThrowWeapon()
{
}

exec function Suicide()
{
}

exec function Fly()
{
	UnderWaterTime = -1;
	SetCollision(false, false, false);
	bCollideWorld = true;
	GotoState('CheatFlying');

	ClientRestart();
}

function ServerChangeSkin( coerce string SkinName, coerce string FaceName, byte TeamNum )
{
}

function ClientReStart()
{
	//log("client restart");
	Velocity = vect(0,0,0);
	Acceleration = vect(0,0,0);
	BaseEyeHeight = Default.BaseEyeHeight;
	EyeHeight = BaseEyeHeight;
	SetCollision(false,false,false);
	GotoState('CheatFlying');
}

function PlayerTimeOut()
{
	if (Health > 0)
		Died(None, 'dropped', Location);
}

exec function Grab()
{
}

// Send a message to all players.
exec function Say( string S )
{
	local GameRules G;

	if ( !Level.Game.bMuteSpectators )
	{
		if ( Level.Game.GameRules!=None )
		{
			for ( G=Level.Game.GameRules; G!=None; G=G.NextRules )
				if ( G.bNotifyMessages && !G.AllowChat(Self,S) )
					Return;
		}
		BroadcastMessage( PlayerReplicationInfo.PlayerName$":"@S, true );
	}
}
exec function TeamSay( string S )
{
	local Pawn P;
	local GameRules G;

	if ( !Level.Game.bMuteSpectators )
	{
		if ( Level.Game.GameRules!=None )
		{
			for ( G=Level.Game.GameRules; G!=None; G=G.NextRules )
				if ( G.bNotifyMessages && !G.AllowChat(Self,S) )
					Return;
		}

		// Message all spectators only.
		for( P=Level.PawnList; P!=None; P=P.NextPawn )
			if( P.bIsPlayer && P.PlayerReplicationInfo!=None && P.PlayerReplicationInfo.bIsSpectator )
				P.ClientMessage( PlayerReplicationInfo.PlayerName@"(Spectators):"@S,, true );
	}
}



//=============================================================================
// Inventory-related input notifications.

// The player wants to switch to weapon group numer I.
exec function SwitchWeapon (byte F )
{
}

exec function NextItem()
{
}

exec function PrevItem()
{
}

exec function AltFire(optional float F)
{
	ViewSelf();
	//bBehindView=true;
}

exec function Fire(optional float F)
{
	ViewPlayerNum(-1);
	//bBehindView=true;
}



//=================================================================================

function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
					 Vector momentum, name damageType)
{
}

defaultproperties
{
				bChaseCam=True
				bSinglePlayer=False
				bIsAmbientCreature=True
				Visibility=0
				BaseEyeHeight=0.000000
				Health=0
				AttitudeToPlayer=ATTITUDE_Friendly
				MenuName="Spectator"
				bHidden=True
				bTravel=False
				bAlwaysRelevant=False
				bCollideActors=False
				bCollideWorld=False
				bBlockActors=False
				bBlockPlayers=False
				bProjTarget=False
				AnimSequence=" "
				DrawType=DT_Sprite
				Texture=None
}
