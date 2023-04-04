//=============================================================================
// wPlayer.
//=============================================================================
class wPlayer extends Human abstract config(WolfCoop);

var float LastSaveTime,LandedSpeedDif,HitMarkerTime,LastDamageTick,ReviveProgress;
var wPlayer ReviveTarget;
var vector LastSaveLocation;
var wPRI PRI;
var int AFKCheck,LoginAttempts,RespawnImmunity,LastDamageAmount,CheckPointTime;
var travel int DrownHP,Lives,Score;
var bool bGodMode, bBuddha, HitMarkerHS, HitMarkerKill, bGhost, bAFK, bForcedAFK, RepTyping, bForcedCrouch;
var() bool bGreenBlood,bInvaderClass;
var() float CurrentSize;
var wRespawner Respawner;
var Pawn LastDamageTarget;
var array<Inventory> CollectedItems;

var rotator CamSpeedDif;

var bool bFPBody;

var(FPBody) int AttachVert;
var(FPBody) vector FPBodyAdjustment;

Replication
{
	Reliable If (Role==Role_AUTHORITY)
	HitMarkerTime,HitMarkerHS,HitMarkerKill,bFPBody,AttachVert,bAFK,bForcedAFK,Lives,CurrentSize,
	LastDamageTick,LastDamageAmount,LastDamageTarget,LastSaveTime,LastSaveLocation,DrownHP,
	Score,bGreenBlood,bInvaderClass,Respawner,RepTyping,LoginAttempts,CheckPointTime,CollectedItems,ReviveProgress,ReviveTarget;
	Reliable If(Role<Role_AUTHORITY)
	HurtMe,Explode,Help,SummonP,GoToP,Slap,Resize,AddStart,RemoveStarts,
	Login,AdminLogin,GrantAdmin,Revive,FPBody,SkipMap,RestartMap,Buddha,CustomTaunt,
	PSay,Kill,AFK,KickID,GrantGod,WipeItems,AFKReset,bForcedCrouch,CheckPoint,AdminAddCheckpoint;
	unReliable if(Role==ROLE_Authority&&bNetOwner)
	ClientShowHit;
}


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	AttachVert=0;
	SpeechTime=0.000001;
	SetTimer(1,True,'AFKChecker');
	PRI=wPRI(PlayerReplicationInfo);
}

function DrainRespawnImmunity()
{
	if(RespawnImmunity>0)
	{RespawnImmunity-=1;
	SetTimer(1,False,'DrainRespawnImmunity');}
}

function CheckPointTimer()
{
	if(CheckPointTime>0)
	{CheckPointTime-=1;
	SetTimer(1,False,'CheckPointTimer');}
}

simulated event SpeechTimer()
{	
	if(IsA('wSpectator')) {Weapon=None; Health=0; RepTyping=bIsTyping; SpeechTime=0.000001; return;}

	if(Role==ROLE_Authority)
	{
		if(Health>0 && !bool(Mover(Base)) && !FootRegion.Zone.bPainZone && !Region.Zone.bPainZone && (Physics==PHYS_Walking || Region.Zone.bWaterZone))
		{ if(LastSaveTime<=Level.TimeSeconds) { LastSaveLocation=Location; LastSaveTime=Level.TimeSeconds; } }
		else LastSaveTime=Level.TimeSeconds;
	}

	if(Health>0 && (!bool(WolfCoopGame(Level.Game))||WolfCoopGame(Level.Game).bRestoreDrownDamage) && !HeadRegion.Zone.bWaterZone && DrownHP>0)
	{if(Health<Default.Health) Health+=1; DrownHP-=1;}

	SpeechTime=0.000001;
	HitMarkerTime-=0.02;
	LastDamageTick-=0.005;

	RepTyping=bIsTyping;
}

function FellOutOfWorld()
{
	SetLocation(LastSaveLocation);
	Velocity=vect(0,0,0);
	Acceleration=vect(0,0,0);
}


simulated final function bool wTryToDuck(bool bCrouching)
{
	local vector Dummy,Offset,Start;
	local actor Blocked;

	if(!WolfCoopGame(Level.Game).bRealCrouch) return TryToDuck(bCrouching);

	if(bCrouching&&Health>0) { wSetCrouch(true); return true; }
	Start = Location;


	foreach BasedActors (class'Actor', Blocked) //Based Gigachad
	{
		if(Blocked!=None)
		return false;
	}

	Offset.Z = CollisionHeight+2*((Default.CollisionHeight*CurrentSize)-CollisionHeight);
	Blocked=(Trace(Dummy,Dummy,Start+Offset,Start,false,vect(1.f,1.f,0.f)*CollisionRadius)); if(Blocked!=None){return false;}

	wSetCrouch(false);
	return true;
}


simulated final function wSetCrouch(bool bCrouching)
{
	local float VHeight;
	local bool b1,b2,b3;
	local vector Offset;
	local float CollHeight;

	if(CrouchCheckTime==Level.TimeSeconds) return;
	else CrouchCheckTime = Level.TimeSeconds;
	
	if(bCrouching) 	VHeight = (Default.CollisionHeight*CurrentSize)*0.6;
	else 			VHeight = (Default.CollisionHeight*CurrentSize);
	
	if(CollisionHeight<VHeight)
	{
		b1=bCollideActors;
		b2=bBlockActors;
		b3=bBlockPlayers;
		SetCollision(false,false,false);
		Offset.Z=Default.CollisionHeight*CurrentSize - 0.6*(Default.CollisionHeight*CurrentSize);
		if(Physics!=PHYS_Walking)
		{
			CollHeight=CollisionHeight;
			SetCollisionSize(CollisionRadius,Default.CollisionHeight*CurrentSize);
			SetLocation(Location);
			SetCollisionSize(CollisionRadius,CollHeight);
		}
		else
		SetLocation(Location+Offset);
		SetCollision(b1,b2,b3);
	}
	SetCollisionSize(Default.CollisionRadius*CurrentSize,VHeight);
	PrePivot.Z = (Default.CollisionHeight*CurrentSize)-CollisionHeight;
	bForcedCrouch = bCrouching;
}

simulated event RenderOverlays(Canvas C)
{
	local rotator OldViewRot;
	
	OldViewRot=ViewRotation;

	if(ViewRotation.Pitch<49152) ViewRotation.Pitch-=512*(ViewRotation.Pitch/18000.f);
	else ViewRotation.Pitch+=512*(1-(ViewRotation.Pitch-49152)/16383.f);
	ViewRotation-=4*CamSpeedDif;
	ViewRotation.Yaw+=512*Normal(Velocity<<ViewRotation).Y*(FMin(VSize(Velocity)/300,1)**2);

	Super.RenderOverlays(C);
	
	ViewRotation=OldViewRot;
}

function PlayDuck()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	if ( (Weapon == None) || (Weapon.Mass < 20) )
		TweenAnim('DuckWlkS', 0.25);
	else
		TweenAnim('DuckWlkL', 0.25);
}

function PlayCrawling()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	if ( (Weapon == None) || (Weapon.Mass < 20) )
		LoopAnim('DuckWlkS');
	else
		LoopAnim('DuckWlkL');
}

simulated function Destroyed()
{if(bool(Respawner)) Respawner.Destroy(); Super.Destroyed();}

simulated state PlayerWalking
{
	event PlayerTick(float dT)
	{
		Global.PlayerTick(dT);
		Super.PlayerTick(dT);
	}

	function PlayerMove(float dT)
	{
		local vector X,Y,Z, NewAccel;
		local EDodgeDir OldDodge;
		local eDodgeDir DodgeMove;
		local rotator OldRotation;
		local float Speed2D;
		local bool    bSaveJump;
		local name AnimGroupName;

		if ( Physics==PHYS_Spider )
			GetAxes(ViewRotation,X,Y,Z);
		else GetAxes(Rotation,X,Y,Z);

		aForward *= 0.4;
		aStrafe  *= 0.4;
		aLookup  *= 0.24;
		aTurn    *= 0.24;

		// Update acceleration.
		NewAccel = aForward*X + aStrafe*Y;
		if ( Physics!=PHYS_Spider )
			NewAccel.Z = 0;
		// Check for Dodge move
		if ( DodgeDir == DODGE_Active )
			DodgeMove = DODGE_Active;
		else DodgeMove = DODGE_None;
		if (DodgeClickTime > 0.0)
		{
			if ( DodgeDir < DODGE_Active )
			{
				OldDodge = DodgeDir;
				DodgeDir = DODGE_None;
				if (bEdgeForward && bWasForward)
					DodgeDir = DODGE_Forward;
				if (bEdgeBack && bWasBack)
					DodgeDir = DODGE_Back;
				if (bEdgeLeft && bWasLeft)
					DodgeDir = DODGE_Left;
				if (bEdgeRight && bWasRight)
					DodgeDir = DODGE_Right;
				if ( DodgeDir == DODGE_None)
					DodgeDir = OldDodge;
				else if ( DodgeDir != OldDodge )
					DodgeClickTimer = DodgeClickTime + 0.5 * dT;
				else
					DodgeMove = DodgeDir;
			}

			if (DodgeDir == DODGE_Active && Physics == PHYS_Walking)
			{
				// force dodge completion in case if PHYS_Walking was set without calling Landed
				DodgeDir = DODGE_Done;
				DodgeClickTimer = 0;
			}

			if (DodgeDir == DODGE_Done)
			{
				DodgeClickTimer -= dT;
				if (DodgeClickTimer < -0.35)
				{
					DodgeDir = DODGE_None;
					DodgeClickTimer = DodgeClickTime;
				}
			}
			else if ((DodgeDir != DODGE_None) && (DodgeDir != DODGE_Active))
			{
				DodgeClickTimer -= dT;
				if (DodgeClickTimer < 0)
				{
					DodgeDir = DODGE_None;
					DodgeClickTimer = DodgeClickTime;
				}
			}
		}

		AnimGroupName = GetAnimGroup(AnimSequence);
		if ( (Physics == PHYS_Walking) && (AnimGroupName != 'Dodge') )
		{
			//if walking, look up/down stairs - unless player is rotating view
			if ( !bKeyboardLook && (bLook == 0) )
			{
				if ( bLookUpStairs )
					ViewRotation.Pitch = FindStairRotation(dT);
				else if ( bCenterView )
				{
					ViewRotation.Pitch = ViewRotation.Pitch & 65535;
					if (ViewRotation.Pitch > 32768)
						ViewRotation.Pitch -= 65536;
					ViewRotation.Pitch = ViewRotation.Pitch * (1 - 12 * FMin(0.0833, dT));
					if ( Abs(ViewRotation.Pitch) < 1000 )
						ViewRotation.Pitch = 0;
				}
			}

			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			//add bobbing when walking
			if ( !bShowMenu )
			{
				if ( Speed2D < 10 || GroundSpeed == 0 )
					BobTime += 0.2 * dT * FClamp(Region.Zone.ZoneTimeDilation,0.1,10.f);
				else
					BobTime += dT * FClamp(Region.Zone.ZoneTimeDilation,0.1,10.f) * (0.3 + 0.7 * Speed2D/GroundSpeed);
				WalkBob = Y * 0.65 * Bob * Speed2D * sin(-6.0 * BobTime);
				if ( Speed2D < 10 )
					WalkBob.Z = Bob * 30 * sin(12.0 * BobTime);
				else WalkBob.Z = Bob * Speed2D * sin(12.0 * BobTime);
			}
		}
		else if ( !bShowMenu )
		{
			BobTime = 0;
			WalkBob = WalkBob * (1 - FMin(1, 8 * dT));
		}

		// Update rotation.
		OldRotation = Rotation;
		UpdateRotation(dT, 1);

		if ( bPressedJump && (AnimGroupName == 'Dodge') )
		{
			bSaveJump = true;
			bPressedJump = false;
		}
		else
			bSaveJump = false;

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(dT, NewAccel, DodgeMove, OldRotation - Rotation);
		else
			ProcessMove(dT, NewAccel, DodgeMove, OldRotation - Rotation);
		bPressedJump = bSaveJump;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		local vector OldAccel;
		local vector X,Y,Z, Dir;

		OldAccel = Acceleration;
		Acceleration = NewAccel;
		bIsTurning = ( Abs(DeltaRot.Yaw/DeltaTime) > 5000 );
		if ( (DodgeMove == DODGE_Active) && (Physics == PHYS_Falling) )
			DodgeDir = DODGE_Active;
		else if ( (DodgeMove != DODGE_None) && (DodgeMove < DODGE_Active) )
			Dodge(DodgeMove);

		if(bPressedJump) DoJump();
		
		if ( !bIsCrouching )
		{
			if ( bDuck != 0 && wTryToDuck(true) )
			{
				bIsCrouching = true;
				PlayDuck();
			}
		}
		else if ( bDuck == 0 && wTryToDuck(false) )
		{
			OldAccel = vect(0,0,0);
			bIsCrouching = false;
		}
		
		if(GetAnimGroup(AnimSequence)=='Dodge') return;
		if ( !bIsCrouching )
		{
			if ( (!bAnimTransition || (AnimFrame > 0)) && (GetAnimGroup(AnimSequence) != 'Landing') )
			{
				if ( Acceleration != vect(0,0,0) )
				{
					if ( (GetAnimGroup(AnimSequence) == 'Waiting') || (GetAnimGroup(AnimSequence) == 'Gesture') || (GetAnimGroup(AnimSequence) == 'TakeHit') )
					{
						bAnimTransition = true;
						TweenToRunning(0.1);
					}
				}
				else if ( (Velocity.X * Velocity.X + Velocity.Y * Velocity.Y < 1000)
						  && (GetAnimGroup(AnimSequence) != 'Gesture') )
				{
					if ( GetAnimGroup(AnimSequence) == 'Waiting' )
					{
						if ( bIsTurning )
						{
							bAnimTransition = true;
							PlayTurning();
						}
					}
					else if ( !bIsTurning )
					{
						bAnimTransition = true;
						TweenToWaiting(0.2);
					}
				}
			}
		}
		else
		{
			if ( (OldAccel == vect(0,0,0)) && (Acceleration != vect(0,0,0)) )
				PlayCrawling();
			else if ( !bIsTurning && (Acceleration == vect(0,0,0)) && (AnimFrame > 0.1) )
				PlayDuck();
		}
	}
}


function PlayWaiting()
{
	local name newAnim;

	if ( (IsInState('PlayerSwimming')) || (Physics == PHYS_Swimming) )
	{
		BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
		if ( (Weapon == None) || (Weapon.Mass < 30) )
			LoopAnim('TreadSM');
		else
			LoopAnim('TreadLG');
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		ViewRotation.Pitch = ViewRotation.Pitch & 65535;
		If ( (ViewRotation.Pitch > RotationRate.Pitch)
			 && (ViewRotation.Pitch < 65536 - RotationRate.Pitch) )
		{
			If (ViewRotation.Pitch < 32768)
			{
				if ( (Weapon == None) || (Weapon.Mass < 30) )
					TweenAnim('AimUpSm', 0.3);
				else
					TweenAnim('AimUpLg', 0.3);
			}
			else
			{
				if ( (Weapon == None) || (Weapon.Mass < 30) )
					TweenAnim('AimDnSm', 0.3);
				else
					TweenAnim('AimDnLg', 0.3);
			}
		}
		else if ( (Weapon != None) && Weapon.bPointing)
		{
			if ( Weapon.bRapidFire && ((bFire != 0) || (bAltFire != 0)) )
				LoopAnim('StillFRRP');
			else if ( Weapon.Mass < 30 )
				TweenAnim('StillSMFR', 0.3);
			else
				TweenAnim('StillFRRP', 0.3);
		}
		else
		{
			if ( Weapon != None && FRand() < 0.1 )
			{
				if ( Weapon.Mass < 30 )
					PlayAnim('CockGun', 0.5 + 0.5 * FRand(), 0.3);
				else
					PlayAnim('CockGunL', 0.5 + 0.5 * FRand(), 0.3);
			}
			else if ( FRand() < 0.1 )
			{
				if ( Weapon == None || Weapon.Mass < 30 )
					PlayAnim('Look', 0.5 + 0.5 * FRand(), 0.3);
				else
					PlayAnim('LookL', 0.5 + 0.5 * FRand(), 0.3);
			}
			else
			{
				if ( (Weapon == None) || (Weapon.Mass < 30) )
				{
					if ( Health >= Default.Health*0.5)
						newAnim = 'Breath1';
					else
						newAnim = 'Breath2';
				}
				else
				{
					if ( Health >= Default.Health*0.5)
						newAnim = 'Breath1L';
					else
						newAnim = 'Breath2L';
				}

				if ( AnimSequence == newAnim )
					LoopAnim(newAnim, 0.3 + 0.7 * FRand());
				else
					PlayAnim(newAnim, 0.3 + 0.7 * FRand(), 0.25);
			}
		}
	}
}

function TweenToWaiting(float tweentime)
{
	if ( (IsInState('PlayerSwimming')) || (Physics == PHYS_Swimming) )
	{
		BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
		if ( (Weapon == None) || (Weapon.Mass < 20) )
			TweenAnim('TreadSM', tweentime);
		else
			TweenAnim('TreadLG', tweentime);
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		if ( (Weapon == None) || (Weapon.Mass < 20) )
		{
			if(Weapon!=None && Weapon.bPointing)
			TweenAnim('StillSMFR', tweentime);
			else
			TweenAnim('Breath1', tweentime);
		}
		else
		{
			if(Weapon!=None && Weapon.bPointing)
			TweenAnim('StillFRRP', tweentime);
			else
			TweenAnim('Breath1L', tweentime);
		}
	}
}


function TweenToWalking(float tweentime)
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		TweenAnim('Walk', tweentime);
	else if ( Weapon.bPointing || CarriedDecoration != None )
	{
		if (Weapon.Mass < 20)
			TweenAnim('WalkSMFR', tweentime);
		else
			TweenAnim('WalkLGFR', tweentime);
	}
	else
	{
		if (Weapon.Mass < 20)
			TweenAnim('WalkSM', tweentime);
		else
			TweenAnim('WalkLG', tweentime);
	}
}


function PlayTurning()
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if ( (Weapon == None) || (Weapon.Mass < 30) )
	{
		if(Weapon!=None && Weapon.bPointing)
			PlayAnim('TurnSM', 0.3, 0.3);
		else
			TweenAnim('Walk',0.3);
	}
	else
	{
		if(Weapon!=None)
		PlayAnim('TurnLG', 0.3, 0.3);
	}
}

simulated event PlayerTick(float dT)
{
	local rotator NewCamSpeedDif;
	// Movement Sway.
	NewCamSpeedDif.Yaw  +=80*FClamp((Velocity<<ViewRotation).Y/300,-1,1);
	NewCamSpeedDif.Roll +=80*FClamp((Velocity<<ViewRotation).Y/300,-1,1);
	NewCamSpeedDif.Pitch+=40*FClamp((Velocity<<ViewRotation).X/300,-1,1);

	if(LandedSpeedDif>0) {NewCamSpeedDif.Pitch+=400*FClamp(LandedSpeedDif/1000,-1,1);}
	else NewCamSpeedDif.Pitch+=200*FClamp(Velocity.Z/1000,-1,1);

	// Bobbing Sway.
	NewCamSpeedDif.Yaw  -=16*(WalkBob<<ViewRotation).Y;
	NewCamSpeedDif.Roll -=16*(WalkBob<<ViewRotation).Y;
	NewCamSpeedDif.Pitch-=16*(WalkBob<<ViewRotation).Z;
	// Aiming Sway.
	NewCamSpeedDif.Yaw  -=0.08*FClamp(aTurn  ,-500,500);
	NewCamSpeedDif.Roll -=0.08*FClamp(aTurn  ,-500,500);
	NewCamSpeedDif.Pitch-=0.08*FClamp(aLookUp,-500,500);
	
	CamSpeedDif+=FClamp(15*dT,0,1)*(NewCamSpeedDif-CamSpeedDif);

	if(LandedSpeedDif>0) LandedSpeedDif-=50;

	Super.PlayerTick(dT);
}


simulated function Landed(vector HitNormal)
{ LandedSpeedDif=-Velocity.Z*2; Super.Landed(HitNormal); }

state PlayerFlying
{
	event PlayerTick(float dT)
	{
		Global.PlayerTick(dT);
		Super.PlayerTick(dT);
	}
}

state CheatFlying
{
	ignores SeePlayer, HearNoise, Bump, TakeDamage, StartClimbing;

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		if ( VSize(NewAccel)<0.1 )
			Acceleration = vect(0,0,0);
		else
		{
			if(bRun!=0)
			Acceleration = Normal(NewAccel) * 1650;
			else
			Acceleration = Normal(NewAccel) * 550;
		}
		MoveSmooth(Acceleration * DeltaTime);
		Velocity = Acceleration;
	}

	event PlayerTick(float dT)
	{
		Global.PlayerTick(dT);
		Super.PlayerTick(dT);
	}
}

simulated event PostRender(Canvas C)
{
	if(HitMarkerTime>0.04)
	{
		if(Health<=0) HitMarkerTime=0;
		C.bNoSmooth=False;
		C.Style=3;
		if(HitMarkerHS||HitMarkerKill)
		{
			if(HitMarkerKill)
			{
				C.DrawColor.R=255*HitMarkerTime;
				C.DrawColor.G=0*HitMarkerTime;
				C.DrawColor.B=0*HitMarkerTime;
			}
			else
			{
				C.DrawColor.R=255*HitMarkerTime;
				C.DrawColor.G=128*HitMarkerTime;
				C.DrawColor.B=0*HitMarkerTime;
			}
			C.SetPos(0.5 * C.ClipX-(16*HitMarkerTime), 0.5 * C.ClipY-(16*HitMarkerTime));
			C.DrawRect(Texture'HitMarker',32*HitMarkerTime,32*HitMarkerTime);
		}
		C.DrawColor.R=255*HitMarkerTime;
		C.DrawColor.G=255*HitMarkerTime;
		C.DrawColor.B=255*HitMarkerTime;
		C.SetPos(0.5 * C.ClipX-(10*HitMarkerTime), 0.5 * C.ClipY-(10*HitMarkerTime));
		C.DrawRect(Texture'HitMarker',20*HitMarkerTime,20*HitMarkerTime);
		C.bNoSmooth=True;
		C.Style=1;
	}

	Super.PostRender(C);
}


simulated function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
					 Vector momentum, name damageType)
{
	local Inventory Inv;
	local bool bShielded;

	if(DamageType!='Drowned' && Damage>0)
	{
		bShielded=False;
		For(Inv=Inventory; Inv!=None; Inv=Inv.Inventory)
		{
			if(!Inv.bIsAnArmor) continue;
			else if(Inv.Charge<=0) bShielded=bShielded;
			else if(Inv.ArmorAbsorption>=100)
			bShielded=True;
			else if(Inv.ProtectionType1==DamageType||Inv.ProtectionType2==DamageType)
			bShielded=True;
		}
		if(DamageType=='Hacked' || DamageType=='Fell' || InstigatedBy==None || InstigatedBy==Self)
		{ClientShowHit(FMin(Damage/20.f,5)*Normal(vect(-50,0,0)>>ViewRotation),DamageType,bShielded);}
		else
		ClientShowHit(FMin(Damage/20.f,5)*Normal(HitLocation-Location),DamageType,bShielded);
	}

	if(RespawnImmunity>0) Damage=0;
	if(bGodMode || (bBuddha && Health<=1))
	{ReducedDamageType='All'; Damage=0;}

	if(DamageType=='Drowned' && HeadRegion.Zone.bWaterZone) DrownHP+=Damage;

	Super.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);
}

simulated event EncroachedBy( actor Other )
{if(wPlayer(Other)!=None) return; else Super.EncroachedBy(Other);}

simulated function Died(pawn Killer, name damageType, vector HitLocation)
{
	local PlayerPawn P;

	if(bGodMode || bBuddha) {Health=1; return;}
	if(WolfCoopGame(Level.Game)!=None && WolfCoopGame(Level.Game).bMarioSounds || wPRI(PlayerReplicationInfo).Holiday==3)
	{
		foreach allactors(class'PlayerPawn',P)
		P.ClientPlaySound(Sound'MarioDead');		
	}
	if(WolfCoopGame(Level.Game)!=None && WolfCoopGame(Level.Game).bEnableLives)
	{
		if(Lives>0)
		Lives--;
		if(Lives<=0)
		{
			if(WolfCoopGame(Level.Game).bAllowReviving)
			{	if(bool(LastSaveLocation))
				Respawner=Spawn(Class'wRespawner',Self,,LastSaveLocation);
				else
				Respawner=Spawn(Class'wRespawner',Self,,Location);
			}
			BroadcastMessage(GetHumanName()@"is OUT!",false,'RedCriticalEvent');
		}
	}
	ReviveProgress=0;
	bIsCrouching=False;
	wSetCrouch(False);
	Super.Died(Killer, DamageType, HitLocation);

}


simulated function rotator AdjustAim(float projSpeed, vector projStart, int aimerror, bool bLeadTarget, bool bWarnTarget)
{
	local vector HitNormal;
	local vector AdjustRot,AdjustLoc,AimSpot;
	
	if (bBehindView)
	{
		AdjustRot = vector(CalcCameraRotation);
		TraceShot(AdjustLoc,HitNormal,CalcCameraLocation + 32768*AdjustRot,CalcCameraLocation);
	}

	else
	{
		AdjustRot = vector(ViewRotation);
		AdjustLoc = projStart;
	}

	AimSpot = AdjustLoc + AdjustRot;
 
	return rotator(AimSpot - projStart);
}

exec function AdminLogin(string AdminPw)
{if(LoginAttempts>=3) return; else wAAM(Level.Game.GetAccessManager()).wAdminLogin(Self,AdminPw); if(wPRI(PlayerReplicationInfo).AdminLevel<=0) {LoginAttempts++; ClientMessage("Incorrect password,"@3-LoginAttempts@"login attempts left");}}

exec function Login(string AdminPw)
{AdminLogin(AdminPw);}

exec function GrantAdmin(int PawnID,int AdminLevel)
{
	local PlayerPawn P;
	local string AdminText;
	if(AdminLevel>=wPRI(PlayerReplicationInfo).AdminLevel) return;
	else
	{
		if(AdminLevel==1) AdminText="Helper";
		else if(AdminLevel==2) AdminText="Moderator";
		if(PawnID>0)
		{	Foreach allactors(class'PlayerPawn', P)
			{	if (PawnID == P.PlayerReplicationInfo.PlayerID)
				{wPRI(P.PlayerReplicationInfo).AdminLevel=AdminLevel;
				BroadCastMessage(GetHumanName()$"granted "$P.GetHumanName()@AdminText$" commands access");}
			}
		}
	}
}

simulated function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
	local vector View,NewLoc;
	local vector HL,HN;

	if((bFPBody||!PlayerReplicationInfo.bFeigningDeath)&&(ViewTarget==None||ViewTarget==Self))
	{
		if(bFPBody)
		{		
			if(AttachVert==0)
			AttachVert=Self.GetClosestVertex(Self.Location+(Self.CollisionHeight*vect(0,0,2)>>Self.Rotation),NewLoc);
			else NewLoc=Self.GetVertexPos(AttachVert,true);
			CameraLocation=NewLoc+(FPBodyAdjustment>>Rotation);
			CameraRotation=ViewRotation;
		}

		else
		{
			Dist*=0.5;
			CameraRotation = ViewRotation;

			if(Handedness>0)
			View=vect(-1,-0.4,0.45)*(vect(1,0,1)+(Handedness*vect(0,1,0)));
			else if (Handedness<0)
			View=vect(-1, 0.4,0.45)*(vect(1,0,1)+(Handedness*vect(0,-1,0)));
			else
			View=vect(-0.9,0.2,0.45);

			CameraLocation+=GetExtent()*View>>CameraRotation;
			CameraLocation+=GetExtent()*View*vect(-0.5,0,0)>>Rotation;
			if(!bool(Trace(HL,HN,CameraLocation+(Dist+20)*(View>>CameraRotation),CameraLocation,False)))
			HL=CameraLocation+Dist*(View>>CameraRotation); CameraLocation=HL-(20*(View>>CameraRotation));
		}
	}
	else
		Super.CalcBehindView(CameraLocation,CameraRotation,Dist);
}

simulated function RespawnMe()
{
	local Effects Ef;

	if(Health<=0)
	{
		if(Lives<=0) Lives=1;
		if(Respawner!=None)
		{Ef=Spawn( class 'ReSpawn',,,Respawner.Location ); SetLocation(Respawner.Location);}
		else
		Ef=Spawn( class 'ReSpawn',,,Location );
		Ef.DrawScale*=DrawScale;
		Respawner.Destroy();
		Respawner=None;
		BroadcastMessage(PlayerReplicationInfo.PlayerName@"has been revived!",false,'LowCriticalEvent');
		PlaySound(Sound'RevivedNotif');
		GoToState('PlayerWalking');
		Health=Default.Health*0.1;
		bHidden=False;
		if(CurrentSize!=1)
		SetCollisionSize(Default.CollisionRadius*CurrentSize,Default.CollisionHeight*CurrentSize);
		else
		SetCollisionSize(Default.CollisionRadius,Default.CollisionHeight);
		SetCollision(True,True,True);
		ViewTarget=None;
		bBehindView=False;
		RespawnImmunity=5;
		SetTimer(1,False,'DrainRespawnImmunity');
		SwitchToBestWeapon();
	}
}

exec function CheckPoint()
{
	local int OldHP;
	if(CheckPointTime>0)
	{
		if(!WolfCoopGame(Level.Game).bCheckPointHeals || Health>Default.Health)
		OldHP=Health;
		ServerReStartPlayer();
		CheckPointTime=0;
		if(OldHP>0) Health=OldHP;
	}
}

exec function AdminAddCheckpoint(int CPType,optional float cRadius,optional float cHeight,optional bool bEvent,optional name cEvent)
{
	local string MapName;
	local int I;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'AdminAddCheckpoint') )
	return;

	MapName=GetURLMap();
	I=array_size(WolfCoopGame(Level.Game).CheckPoints);
	WolfCoopGame(Level.Game).CheckPoints[I].CheckPointType=CPType;
	WolfCoopGame(Level.Game).CheckPoints[I].MapName=MapName;
	WolfCoopGame(Level.Game).CheckPoints[I].CPLocation=Location;
	WolfCoopGame(Level.Game).CheckPoints[I].CPRotation=Rotation;
	WolfCoopGame(Level.Game).CheckPoints[I].CPRadius=cRadius;
	WolfCoopGame(Level.Game).CheckPoints[I].CPHeight=cHeight;
	if(bEvent && bool(cEvent))
	{
		WolfCoopGame(Level.Game).CheckPoints[I].bEventEnabled=True;
		WolfCoopGame(Level.Game).CheckPoints[I].EventTag=cEvent;
	}
	else
	{
		WolfCoopGame(Level.Game).CheckPoints[I].bEventEnabled=False;
		WolfCoopGame(Level.Game).CheckPoints[I].EventTag='None';
	}
	WolfCoopGame(Level.Game).SaveConfig();
	BroadCastMessage("Admin added a Checkpoint (Type "$CPType$") for Map '"$MapName$"' at coordinates "$Location);
}

simulated function ServerReStartPlayer()
{
	local Effects Ef;
	
	if(Lives==1)
	ClientMessage("Last Life Left!",'RedCriticalEvent');
	if(Lives<=0) Lives=1;
	Super.ServerRestartPlayer();
	Respawner.Destroy();
	Respawner=None;
	Ef=Spawn( class 'ReSpawn',,,Location );
	Ef.DrawScale*=DrawScale;
	RespawnImmunity=5;
	SetTimer(1,False,'DrainRespawnImmunity');
	SwitchToBestWeapon();
}

State Dying
{
ignores SeePlayer, EnemyNotVisible, HearNoise, KilledBy, Trigger, Bump, HitWall, HeadZoneChange, FootZoneChange, ZoneChange, Falling, WarnTarget, Died, LongFall;

	exec function AltFire(optional float F)
	{
		if ( Role < ROLE_Authority )
		return;
		if(WolfCoopGame(Level.Game)==None || !WolfCoopGame(Level.Game).bEnableLives || Lives>0)
		{if(WolfCoopGame(Level.Game).bEnableLives && Lives<=0) ClientMessage(PlayerReplicationInfo.PlayerName@"has been revived!",'LowCriticalEvent'); ServerReStartPlayer();}
		else if(Level.NetMode==NM_Standalone)
		Super.AltFire();
		else
		ViewSelf();
	}
	
	exec function Fire(optional float F)
	{
		if ( Role < ROLE_Authority )
		return;
		if(WolfCoopGame(Level.Game)==None || !WolfCoopGame(Level.Game).bEnableLives || Lives>0)
		{if(WolfCoopGame(Level.Game).bEnableLives && Lives<=0) ClientMessage(PlayerReplicationInfo.PlayerName@"has been revived!",'LowCriticalEvent'); ServerReStartPlayer();}
		else if(Level.NetMode==NM_Standalone)
		Super.Fire();
		else
		ViewPlayerNum(-1);
	}

	exec function Jump( optional float F )
	{
		if ( Role < ROLE_Authority )
		return;
		if(WolfCoopGame(Level.Game)==None || !WolfCoopGame(Level.Game).bEnableLives || Lives>0)
		{if(WolfCoopGame(Level.Game).bEnableLives && Lives<=0) ClientMessage(PlayerReplicationInfo.PlayerName@"has been revived!",'LowCriticalEvent'); ServerReStartPlayer();}
		else if(Level.NetMode==NM_Standalone)
		Super.Jump();
		else

		bBehindView=!bBehindView;
	}
	
	function AFKChecker();
	
	function BeginState()
	{
		Super.BeginState();
	}

	function ActivateItem()
	{}
}


State EndGameSpectate
{
ignores SeePlayer, EnemyNotVisible, HearNoise, KilledBy, Trigger, Bump, HitWall, HeadZoneChange, FootZoneChange, ZoneChange, Falling, WarnTarget, Died, LongFall, PainTimer, Suicide, TakeDamage;

	exec function AltFire(optional float F)
	{
		if ( Role < ROLE_Authority )
		return;
		ViewSelf();
	}
	
	exec function Fire(optional float F)
	{
		if ( Role < ROLE_Authority )
		return;
		ViewPlayerNum(-1);
	}

	exec function Jump( optional float F )
	{
		if ( Role < ROLE_Authority )
		return;
		bBehindView=!bBehindView;
	}
	
	function AFKChecker();
	
	function ActivateItem()
	{}

	function Timer()
	{}

	exec function SwitchWeapon (byte F )
	{}

	exec function NextWeapon()
	{}
	
	exec function PrevWeapon()
	{}
	
	event Landed(vector HitNormal)
	{
		Global.Landed(HitNormal);
		Velocity.X = 0;
		Acceleration.X = 0;
		Velocity.Y = 0;
		Acceleration.Y = 0;
		Velocity.Z = 0;
		Acceleration.Z = 0;
	}
	
	function BeginState()
	{
		AmbientSound=None;
		AmbientGlow=255;
		bUnlit=True;
		Style=STY_Translucent;
		SetCollision(false,false,false);
		bBehindView=True;
		SetPhysics(PHYS_None);
	}

	function EndState()
	{
		AmbientSound=Default.AmbientSound;
		AmbientGlow=Default.AmbientGlow;
		bUnlit=Default.bUnlit;
		Style=Default.Style;
		SetCollision(true,true,true);
		SetPhysics(PHYS_Falling);
	}

	function ServerMove
	(
		float TimeStamp,
		vector Accel,
		vector ClientLoc,
		bool NewbRun,
		bool NewbDuck,
		bool NewbPressedJump,
		bool bFired,
		bool bAltFired,
		eDodgeDir DodgeMove,
		byte ClientRoll,
		int View
	)
	{
		Global.ServerMove(TimeStamp, Accel, ClientLoc, NewbRun, NewbDuck, NewbPressedJump,
						  bFired, bAltFired, DodgeMove, ClientRoll, (32767 & (Rotation.Pitch/2)) * 32768 + (32767 & (Rotation.Yaw/2)));
	}
	
	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		Acceleration=vect(0,0,0);
	}
	
	event PlayerTick(float DeltaTime)
	{
		Global.PlayerTick(DeltaTime);
		Weapon=None;
		RepTyping=bIsTyping;
		if(bUpdatePosition) ClientUpdatePosition();
		PlayerMove(DeltaTime);
	}
	
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

		if ( !bFrozen )
		{
			if ( bPressedJump )
				Fire(0);
			GetAxes(ViewRotation,X,Y,Z);
			// Update view rotation.
			aLookup  *= 0.24;
			aTurn    *= 0.24;
			ViewRotation.Yaw += 32.0 * DeltaTime * aTurn;
			ViewRotation.Pitch += 32.0 * DeltaTime * aLookUp;
			ViewRotation.Pitch = ViewRotation.Pitch & 65535;
			If ((ViewRotation.Pitch > 18000) && (ViewRotation.Pitch < 49152))
			{
				If (aLookUp > 0)
				ViewRotation.Pitch = 18000;
				else
					ViewRotation.Pitch = 49152;
			}
			if ( Role < ROLE_Authority ) // then save this move and replicate it
				ReplicateMove(DeltaTime, vect(0,0,0), DODGE_None, rot(0,0,0));
			bPressedJump = false;
		}
		ViewShake(DeltaTime);
		ViewFlash(DeltaTime);
	}

	function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
	{
		local vector View,HitLocation,HitNormal;
		local float ViewDist;
	
		CameraRotation = ViewRotation;
		View = vect(1,0,0) >> CameraRotation;
		if ( Trace( HitLocation, HitNormal, CameraLocation - (Dist + 30) * vector(CameraRotation), CameraLocation ) != None )
			ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
		else
			ViewDist = Dist;
		CameraLocation -= (ViewDist - 30) * View;
	}
}

simulated function PlayHit(float Damage, vector HitLocation, name damageType, float MomentumZ)
{
	local float rnd;
	local Bubble1 bub;
	local bool bServerGuessWeapon;
	local vector BloodOffset;
	local BloodBurst b;

	if(bGreenBlood)
	{	
		if ( (Damage <= 0) && (ReducedDamageType != 'All') )
			return;
	
		//DamageClass = class(damageType);
		if ( ReducedDamageType != 'All' ) //spawn some blood
		{
			if (damageType == 'Drowned')
			{
				bub = spawn(class 'Bubble1',,, Location
							+ 0.7 * CollisionRadius * vector(ViewRotation) + 0.3 * EyeHeight * vect(0,0,1));
				if (bub != None)
					bub.DrawScale = FRand()*0.06+0.04;
			}
			else if ( (damageType != 'Burned') && (damageType != 'Corroded')
					  && (damageType != 'Fell') )
				{
				BloodOffset = 0.2 * CollisionRadius * Normal(HitLocation - Location);
				BloodOffset.Z = BloodOffset.Z * 0.5;
				spawn(class'GreenBloodPuff',,, hitLocation + BloodOffset);
				b = spawn(class 'BloodBurst',self,'', hitLocation);
				b.GreenBlood();
			}
		}
	
		rnd = FClamp(Damage, 20, 60);
		if ( damageType == 'Burned' )
			ClientFlash( -0.009375 * rnd, rnd * vect(16.41, 11.719, 4.6875));
		else if ( damageType == 'corroded' )
			ClientFlash( -0.01171875 * rnd, rnd * vect(9.375, 14.0625, 4.6875));
		else if ( damageType == 'Drowned' )
			ClientFlash(-0.390, vect(312.5,468.75,468.75));
		else
			ClientFlash( -0.019 * rnd, rnd * vect(26.5, 4.5, 4.5));
	
		ShakeView(0.15 + 0.005 * Damage, Damage * 30, 0.3 * Damage);
		PlayTakeHitSound(Damage, damageType, 1);
		bServerGuessWeapon = ( ((Weapon != None) && Weapon.bPointing) || (GetAnimGroup(AnimSequence) == 'Dodge') );
		if (!bIsReducedCrouch)
			ClientPlayTakeHit(0.1, hitLocation, Damage, bServerGuessWeapon );
		if ( !bServerGuessWeapon
				&& ((Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer)) )
		{
			Enable('AnimEnd');
			BaseEyeHeight = Default.BaseEyeHeight;
			bAnimTransition = true;
			PlayTakeHit(0.1, hitLocation, Damage);
		}
	}
	else Super.PlayHit(Damage,HitLocation,damageType,MomentumZ);
}

simulated function PlayDeathHit(float Damage, vector HitLocation, name damageType)
{
	local Bubble1 bub;
	local BloodBurst b;

	if(bGreenBlood)
	{
		if ( Region.Zone.bDestructive && (Region.Zone.ExitActor != None) )
			Spawn(Region.Zone.ExitActor);
		if (HeadRegion.Zone.bWaterZone)
		{
			bub = spawn(class 'Bubble1',,, Location
						+ 0.3 * CollisionRadius * vector(Rotation) + 0.8 * EyeHeight * vect(0,0,1));
			if (bub != None)
				bub.DrawScale = FRand()*0.08+0.03;
			bub = spawn(class 'Bubble1',,, Location
						+ 0.2 * CollisionRadius * VRand() + 0.7 * EyeHeight * vect(0,0,1));
			if (bub != None)
				bub.DrawScale = FRand()*0.08+0.03;
			bub = spawn(class 'Bubble1',,, Location
						+ 0.3 * CollisionRadius * VRand() + 0.6 * EyeHeight * vect(0,0,1));
			if (bub != None)
				bub.DrawScale = FRand()*0.08+0.03;
		}
	
		if ( (damageType != 'Drowned') && (damageType != 'Corroded') )
			{b = spawn(class 'BloodBurst',self,'', hitLocation);
			b.GreenBlood();}
	}
	else Super.PlayDeathHit(Damage, HitLocation, damageType);
}


function AFKChecker()
{
	local playerpawn P;
	local int PlayerCount;

	PlayerCount=0;
	foreach allactors(class'playerpawn',p)
	{PlayerCount++;}

	if(bAFK&&PlayerCount>1&&WolfCoopGame(Level.Game).bEnableLives) return;
	if(Role==ROLE_Authority && Physics==PHYS_Walking && Level.NetMode!=NM_Standalone)
	{
		AFKCheck+=1;
		if(WolfCoopGame(Level.Game).AfkTimer<1 || Health<1 || NetConnection(Player)==None) AFKCheck=0;
		if(AFKCheck>=WolfCoopGame(Level.Game).AfkTimer && !wPRI(PlayerReplicationInfo).bVoteEnd)
		{
			if(!bAFK)
			{
				BroadCastmessage(PlayerReplicationInfo.PlayerName@"is now AFK");
				bAFK=True;
				if(PlayerCount>1)
				WolfCoopGame(Level.Game).CheckAlivePlayers();
			}
		}
		if(AFKCheck>=(WolfCoopGame(Level.Game).AfkTimer-10) && WolfCoopGame(Level.Game).AFKTimer-AFKCheck>0) ClientMessage("AFK in:" @(WolfCoopGame(Level.Game).AfkTimer-AFKCheck)@"seconds",'Pickup');
	}
}

event PlayerInput(float DeltaTime)
{
	Super.PlayerInput(DeltaTime);
	if(Level.Pauser!="") wPRI(PlayerReplicationInfo).CheckScoreBoardInfo();
	if(bEdgeForward||bEdgeBack||bEdgeLeft||bEdgeRight||bWasForward||bWasBack||bWasLeft||bWasRight||aLookUp!=0||aTurn!=0||
		bFire!=0||bAltFire!=0||aUp!=0||(Player.Console!=None&&Player.Console.bTyping)) AFKReset();
}


simulated function AFKReset()
{ if(bForcedAFK) return;
	AFKCheck=0;
	if(bAFK)
	{
		bAFK=False;
		BroadCastmessage(PlayerReplicationInfo.PlayerName@"is no longer AFK");
	}
}


//=====================================COMMANDS======================================================================//


exec function Restart(optional int PawnID)
{
	local wPlayer P;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'Revive') )
		return;

	
	if (PawnID > 0)
	{
		Foreach allactors(class'wPlayer', P)
		{
			P.ServerRestartPlayer();
			if(P.Health<P.Default.Health)
			P.Health=P.Default.Health;
			P.bHidden=False;
			return;
		}
	}

	else
	{
		ServerRestartPlayer();
		if(Health<Default.Health)
		Health=Default.Health;
		bHidden=False;
	}

	ClientMessage("Restart: Player not found");

}

exec function Revive(optional int PawnID)
{
	local wPlayer P;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'Revive') )
		return;

	
	if (PawnID > 0)
	{
		Foreach allactors(class'wPlayer', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID && P.Health <= 0)
			{
				P.RespawnMe();
				P.Health=P.Default.Health;
				P.bHidden=False;
				return;
			}
		}
	}

	else
	if(Health<=0)
	{
		RespawnMe();
		Health=Default.Health;
		bHidden=False;
		return;
	}

	ClientMessage("Revive: Already alive/Player not found");
}

exec function Say( string Msg )
{
	if(Msg=="") return;
	Super.Say(Msg);
}

exec function Taunt( name Sequence )
{
	if(VSize(Velocity)<50 && Health>0)
	if(HasAnim(Sequence) && GetAnimGroup(Sequence) == 'Gesture')
	{
		ServerTaunt(Sequence);
		PlayAnim(Sequence, 0.7, 0.2);
	}
}

exec function BehindView( Bool B )
{
	if (B && bFPBody)
	{bFPBody=False;}
	else if(!B && AttachVert!=0)
	{bFPBody=True;}
	else
	Super.BehindView(B);
}

exec function UToggleBehindView()
{
	if (bFPBody)
	{bFPBody=False; bBehindView=True;}
	else if (bBehindView && AttachVert!=0)
	{bFPBody=True;}
	else if(!bBehindView)
	bBehindView=True;
	else if(bBehindView)
	bBehindView=False;
}

exec function FPBody()
{
	if(!bFPBody)
	{bFPBody=True; bBehindView=True; AttachVert=Default.AttachVert;}
	else if (bFPBody)
	{bFPBody=False; bBehindView=False; AttachVert=0;}
}

exec function Explode()
{
	GibbedBy(Self);
}

exec function HurtMe(int Damage, float Momentum, name DamageType)
{
	if(PRI.AdminLevel>0)
	TakeDamage(Damage, Self, Location, VRand()*Momentum, DamageType);
}


exec function SummonP(int PawnID)
{
	local PlayerPawn P;
	local Effects E;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'SummonP') )
		return;

	Foreach allactors(class'PlayerPawn', P)
	{
		if (PawnID == P.PlayerReplicationInfo.PlayerID)
		{
			E=Spawn(class'QueenTeleportEffect',,,Self.Location + (40+P.CollisionRadius) * Vector(Rotation) + vect(0,0,1) * 15,ViewRotation);
			E.DrawScale=0.01*(P.CollisionHeight+P.CollisionRadius);
			E.PlaySound(Sound'Teleport1');
			P.SetLocation(Self.Location + (40+P.CollisionRadius) * Vector(Rotation) + vect(0,0,1) * 15);
			P.Velocity.X = 0;
			P.Acceleration.X = 0;
			P.Velocity.Y = 0;
			P.Acceleration.Y = 0;
			P.Velocity.Z = 0;
			P.Acceleration.Z = 0;
			return;
		}
	}
	return;

	ClientMessage("SummonP: No Player found");
}

exec function GoToP(int PawnID)
{
	local PlayerPawn P;
	local Effects E;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'GoToP') )
		return;

	Foreach allactors(class'PlayerPawn', P)
	{
		if (PawnID == P.PlayerReplicationInfo.PlayerID)
		{
			E=Spawn(class'QueenTeleportEffect',,,P.Location - (40+CollisionRadius) * Vector(P.Rotation) - vect(0,0,1) * 15,ViewRotation);
			E.DrawScale=0.01*(CollisionHeight+CollisionRadius);
			E.PlaySound(Sound'Teleport1');
			Self.SetLocation(P.Location - (40+CollisionRadius) * Vector(P.Rotation) - vect(0,0,1) * 15);
			Velocity.X = 0;
			Acceleration.X = 0;
			Velocity.Y = 0;
			Acceleration.Y = 0;
			Velocity.Z = 0;
			Acceleration.Z = 0;
			return;
		}
	}


	ClientMessage("GotoP: No Player found");
}

exec function SkipMap()
{
	local NavigationPoint N;
	local string Dest;
	
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'SkipMap') )
		return;

	For(n=level.navigationpointlist;n!=none;n=n.nextnavigationpoint)
		if( n.isa('teleporter') && ( InStr( Teleporter(N).URL, "#" ) > -1 || InStr( Teleporter(N).URL, "?" ) > -1 ) )
			Dest = Teleporter( N ).URL;

	BroadcastMessage("Level has been skipped to the next map",true,'CriticalEvent');			
	Log("Level has been skipped to: "$dest,'LOG_WATERMARK');
	
	Level.ServerTravel(dest,False);
}

exec function RestartMap()
{
	if(Level.NetMode==NM_Standalone)
	{ConsoleCommand("Open ?Restart"); return;}

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'RestartMap') )
		return;

	BroadcastMessage("Level is restarting",true,'CriticalEvent');			
	Log("Level has been manually restarted",'Log');
	
	ConsoleCommand("switchlevel "$getUrlMap());
}


exec function God()
{
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'God') )
		return;

	if ( bGodMode )
	{
		ReducedDamageType=Default.ReducedDamageType;
		bGodMode=False;
		ClientMessage("God mode off");
		return;
	}

	ReducedDamageType='All';
	bGodMode=True;
	ClientMessage("God Mode on");
}

exec function Buddha()
{
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'God') )
		return;

	if ( bBuddha )
	{
		bBuddha=False;
		ClientMessage("Buddha mode off");
		return;
	}

	bBuddha=True;
	ClientMessage("Buddha mode on");
}

exec function suicide()
{
//if(!RLCoopE(Level.Game).bStarted) return;
bBuddha=False; bGodMode=False; super.suicide(); if(Health>=-45) Health=-50;
}

exec function CustomTaunt( name Sequence, float Speed)
{
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'CustomTaunt') )
		return;

	if (HasAnim(Sequence) &&
		!bool(Acceleration) && !bIsCrouching)
	{
		ServerTaunt(Sequence);
		if(Speed==0)
		Speed=0.7;
		PlayAnim(Sequence, Speed, 0.2);
	}
}

function ServerTaunt(name Sequence )
{
	if (HasAnim(Sequence) &&
		!bool(Acceleration) && !bIsCrouching)
	{
		PlayAnim(Sequence, 0.7, 0.2);
	}
}

final simulated function ClientShowHit(vector HitLoc, name DamageType, bool bShielded)
{	
	local byte bProtect;

	if(bool(WolfHUD(MyHUD))) {if(bShielded) bProtect=1; WolfHUD(MyHUD).ShowHit(rotator(HitLoc).Yaw,DamageType,bProtect);}
}


exec function PSay(int PawnID, string Msg)
{
	local PlayerPawn P;
	local int I;
	local GameRules GR;

	foreach allactors(class'GameRules',GR)
	{
		if(GR.bNotifyMessages && !GR.AllowChat(Self,Msg)) return;
	}

	if(PawnID>=0)
	{
		Foreach allactors(class'PlayerPawn', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{
				ClientMessage("(PSay) You -->"@P.PlayerReplicationInfo.PlayerName$":"@Msg,,true);
				P.ClientMessage("(PSay)"@PlayerReplicationInfo.PlayerName@"--> You:"@Msg,,true);
			}
		}
	}
}


exec function Kill(int PawnID)
{
	local PlayerPawn P;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'Kill') )
		return;

	if(PawnID>0)
	{
		Foreach allactors(class'PlayerPawn', P)
		{
			if ((PawnID == P.PlayerReplicationInfo.PlayerID) && P.Health>0)
			{
				if( wPRI(P.PlayerReplicationInfo).AdminLevel>wPRI(PlayerReplicationInfo).Adminlevel)
				return;
				P.PlaySound(sound'lightn5a',,2,,16000);
				if(wPlayer(P)!=None)
				{
					wPlayer(P).bBuddha=False;
					wPlayer(P).bGodMode=False;
					P.Died(Self, 'Exploded', Location);	
					P.TakeDamage(666, Self, Location, Location*0, 'Exploded');
				}
				else P.KilledBy(Self);
				BroadCastMessage(P.PlayerReplicationInfo.PlayerName@"was slain by an admin! ("$PlayerReplicationInfo.PlayerName$")",true,'CriticalEvent');
			}
		}
	}
}

exec function Slap(int PawnID, int SlapDamage, float SlapMomentum)
{
	local PlayerPawn P;
	local vector SlapDirection;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'Slap') )
		return;

	if(PawnID>0)
	{
		Foreach allactors(class'PlayerPawn', P)
		{
			if ((PawnID == P.PlayerReplicationInfo.PlayerID) && P.Health>0)
			{
				SlapDirection=VRand()*(SlapMomentum*1000);
				SlapDirection.Z=1000*SlapMomentum;
				P.PlaySound(sound'slaphit1Ti',,2,,1000,1.25);
				P.TakeDamage(SlapDamage, Self, P.Location, SlapDirection, 'IgnoreArmor');
				BroadcastMessage(P.PlayerReplicationInfo.PlayerName@"was slapped by an admin ("$PlayerReplicationInfo.PlayerName$")");
			}
		}
	}
}


exec function AFK()
{
	if(wPRI(PlayerReplicationInfo).bVoteEnd)
	return;
	AFKCheck=0;
	bAFK=True;
	BroadCastmessage(PlayerReplicationInfo.PlayerName@"is now AFK");
}


exec function Resize(int PawnID, float Amount)
{
	local PlayerPawn P;
	if(!Level.Game.GetAccessManager().CanExecuteCheat(Self,'Resize'))
	return;
	if(Amount<=0)
	{ClientMessage("Usage: Resize ID Amount"); return;}
	if(PawnID>0)
	{	Foreach allactors(class'PlayerPawn', P)
		{	if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{if(bool(wPlayer(P))) wPlayer(P).CurrentSize=Amount; P.DrawScale=Amount; P.SetCollisionSize(P.Default.CollisionRadius*Amount,P.Default.CollisionHeight*Amount);}
		}
	}
	else {CurrentSize=Amount; DrawScale=Amount; SetCollisionSize(Default.CollisionRadius*Amount,Default.CollisionHeight*Amount);}
}


exec function KickID( int PawnID )
{
	local PlayerPawn P;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'KickID') )
	return;

	if(PawnID>0)
	{
		Foreach allactors(class'PlayerPawn', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{
				if( wPRI(P.PlayerReplicationInfo).AdminLevel <= wPRI(PlayerReplicationInfo).AdminLevel )
				{ClientMessage("You can't kick an admin of same or higher level");
				return;}
				BroadCastMessage(P.GetHumanName()@"has been kicked by an admin "$GetHumanName()$"");
				P.Destroy();
				return;
			}
		}
	}
	ClientMessage("Player not found");
}


exec function Kick( string S )
{
	local Pawn aPawn;

	if ( !Level.Game.GetAccessManager().CanExecuteCheatStr(Self,'Kick',S) )
		return;
	for ( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
		if( aPawn.bIsPlayer
			&&	aPawn.PlayerReplicationInfo.PlayerName~=S
			&&	(PlayerPawn(aPawn)==None || Viewport(PlayerPawn(aPawn).Player)==None) )
		{
			if( Level.Game.GetAccessManager().CanExecuteCheat(PlayerPawn(aPawn),'Kick') )
			ClientMessage("You can't kick an admin");
			else
			aPawn.Destroy();
			return;
		}
}


exec function KillPawns()
{
	local Pawn P;

	ForEach allactors(class 'Pawn', P)
	{
		if(P.IsA('PlayerPawn'))
		{
			if( Level.Game.GetAccessManager().CanExecuteCheat(PlayerPawn(P),'KillPawns') )
			P.ClientMessage(GetHumanName()@"deleted every Pawn in the map");
		}
	}

	if ( Level.NetMode==NM_Client )
	{
		Admin("KillPawns");
		Return; // We are a client, pass it to server.
	}
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'KillPawns') )
		return;
	ForEach AllActors(class 'Pawn', P)
	if (PlayerPawn(P) == None)
		P.Destroy();
}

exec function KillRadius(class<actor> aClass, float Radius)
{
	local Actor A;
	local PlayerPawn P;

	if( !Level.Game.GetAccessManager().CanExecuteCheatStr(Self,'KillAll',string(aClass)) )
		return;

	ForEach AllActors(class 'PlayerPawn', P)
	{
		if( Level.Game.GetAccessManager().CanExecuteCheat(P,'God') )
		P.ClientMessage(GetHumanName()@"deleted every "$aClass$" in a "$Radius$" radius");
	}

	ForEach RadiusActors(class 'Actor', A, Radius)
	{ if ( ClassIsChildOf(A.class, aClass) )
		A.Destroy();
	}
}

exec function KillAll(class<actor> aClass)
{
	local Actor A;
	local PlayerPawn P;

	if( !Level.Game.GetAccessManager().CanExecuteCheatStr(Self,'KillAll',string(aClass)) )
		return;

	ForEach allactors(class 'PlayerPawn', P)
	{
		if( Level.Game.GetAccessManager().CanExecuteCheat(P,'God') )
		P.ClientMessage(GetHumanName()@"deleted every "$aClass$" in the map");
	}

	ForEach AllActors(class 'Actor', A)
	if ( ClassIsChildOf(A.class, aClass) )
		A.Destroy();
}

exec function PlayersOnly()
{
	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'PlayersOnly') )
	return;

	Level.bPlayersOnly = !Level.bPlayersOnly;
}

event TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type)
{
	local string TimeString;
	local int I;	


	TimeString="["; if(Level.Hour<10) TimeString=TimeString$"0"; TimeString=TimeString$Level.Hour$":";
	if(Level.Minute<10) TimeString=TimeString$"0"; TimeString=TimeString$Level.Minute$"]"; S=TimeString@S;
	Super.TeamMessage(PRI, S, Type);
}

exec function GrantGod(int PawnID)
{
	local wPlayer P;

	if( !Level.Game.GetAccessManager().CanExecuteCheat(Self,'GrantGod') )
	return;

	if(PawnID>0)
	{
		Foreach allactors(class'wPlayer', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{
				if( Level.Game.GetAccessManager().CanExecuteCheat(P,'GrantGod') )
				{ClientMessage("Can't perform this on an admin"); return;}
				if(!P.bGodMode)
				{P.ClientMessage("Admin granted God Mode");
				P.bGodMode=True;}
				else
				{P.ClientMessage("Admin revoked God Mode");
				P.bGodMode=False;}
				return;
			}
		}
	}
	ClientMessage("Player not found");
}


exec function WipeItems(int PawnID)
{
	local wPlayer P;
	local Inventory Inv;
	local int i;

	if(!Level.Game.GetAccessManager().CanExecuteCheat(Self,'WipeItems'))
	return;
	else if(PawnID>0)
	{	Foreach allactors(class'wPlayer', P)
		{
			if (PawnID == P.PlayerReplicationInfo.PlayerID)
			{
				For(Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory)
				{
					if(!bool(Translator(Inv)))
					Inv.Destroy();
				}
				for(i=0; i<array_size(CollectedItems); i++)
				CollectedItems[I]=None;
				array_size(CollectedItems,0);
				BroadcastMessage(P.GetHumanName()@"'s Inventory was wiped by an Admin ("$GetHumanName()$")");
			}
		}
	}
}


exec function AddStart()
{
	local wPlayerstart Newstart;
	local PlayerPawn P;

	NewStart = Spawn(class'wPlayerStart',,,location,rotation);
	If( NewStart == None )
	{
		Clientmessage("Failed to create PlayerStart");
		return;
	}
	ForEach allactors(class 'PlayerPawn', P)
	{
		if( Level.Game.GetAccessManager().CanExecuteCheat(P,'AddStart') )
		P.ClientMessage(GetHumanName()@"added a new PlayerStart");
	}
}

exec function RemoveStarts()
{
	local PlayerStart Start;
	local PlayerPawn P;

	ForEach allactors(class 'PlayerStart', Start)
	{
		if(Start.IsA('wPlayerStart'))
		Start.Destroy();
		else
		Start.bEnabled=False;
	}
	ForEach allactors(class 'PlayerPawn', P)
	{
		if( Level.Game.GetAccessManager().CanExecuteCheat(P,'RemoveStart') )
		P.ClientMessage(GetHumanName()@"removed PlayerStarts");
	}
}

exec function Help()
{
	ClientMessage("=================USER COMMANDS==================");
	ClientMessage("Login/AdminLogin Password, PSay ID Message, AFK, Checkpoint");
	ClientMessage("=================USER COMMANDS==================");
	if( wPRI(PlayerReplicationInfo).AdminLevel>0 )
	{
		ClientMessage("=================ADMIN COMMANDS=================");
		if(wPRI(PlayerReplicationInfo).AdminLevel>=1)
		{ClientMessage("Revive ID, Restart ID, SummonP ID, GoToP ID, GrantGod ID, SkipMap");
		ClientMessage("Buddha, Resize ID Amount, RestartMap");}
		if(wPRI(PlayerReplicationInfo).AdminLevel>=2)
		ClientMessage("KillPawns, Kill ID, Kick Name, KickID ID, SwitchLevel Map, SwitchCoopLevel Map, Admin Seta Actor Range Property");
		if(wPRI(PlayerReplicationInfo).AdminLevel>=3)
		ClientMessage("PlayersOnly, Admin Set Actor Property, AdminAddCheckpoint Type Radius Height EventTriggered EventTag");
		ClientMessage("=================ADMIN COMMANDS=================");
	}
}


exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local string OriginalClass;

	if( !Level.Game.GetAccessManager().CanExecuteCheatStr(Self,'Summon',ClassName) )
		return;
	OriginalClass = ClassName;
	if ( InStr(ClassName,".")==-1 )
		ClassName = "UnrealI."$ClassName;
	log( "Fabricate " $ ClassName );
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class',True) );
	if ( NewClass!=None )
	{
		if ( NewClass.Default.bStatic )
			ClientMessage("Cannot spawn a bStatic actor" @ NewClass);
		else if ( NewClass.Default.bNoDelete )
			ClientMessage("Cannot spawn a bNoDelete actor" @ NewClass);
		else if ( Spawn( NewClass,,,Location + (40+NewClass.Default.CollisionRadius) * Vector(Rotation) + vect(0,0,1) * 15,ViewRotation)==None )
			ClientMessage("Failed to spawn an actor" @ NewClass);
	}
	else
	{
		if ( InStr(OriginalClass,".")==-1 )
		ClassName = "WolfCoop."$OriginalClass;
		log( "Fabricate " $ ClassName );
		NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class',True) );
		if ( NewClass!=None )
		{
			if ( NewClass.Default.bStatic )
				ClientMessage("Cannot spawn a bStatic actor" @ NewClass);
			else if ( NewClass.Default.bNoDelete )
				ClientMessage("Cannot spawn a bNoDelete actor" @ NewClass);
			else if ( Spawn( NewClass,,,Location + (40+NewClass.Default.CollisionRadius) * Vector(Rotation) + vect(0,0,1) * 15,ViewRotation)==None )
				ClientMessage("Failed to spawn an actor" @ NewClass);
		}
		else
		{
			if ( InStr(OriginalClass,".")==-1 )
			ClassName = "Upak."$OriginalClass;
			log( "Fabricate " $ ClassName );
			NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class',True) );
			if ( NewClass!=None )
			{
				if ( NewClass.Default.bStatic )
					ClientMessage("Cannot spawn a bStatic actor" @ NewClass);
				else if ( NewClass.Default.bNoDelete )
					ClientMessage("Cannot spawn a bNoDelete actor" @ NewClass);
				else if ( Spawn( NewClass,,,Location + (40+NewClass.Default.CollisionRadius) * Vector(Rotation) + vect(0,0,1) * 15,ViewRotation)==None )
					ClientMessage("Failed to spawn an actor" @ NewClass);
			}
			else ClientMessage("Unable to load class" @ OriginalClass);
		}
	}
}

simulated function PlayHitMarker(name DamageType, optional bool bKillMarker)
{
	if(bKillMarker)
	{
		HitMarkerTime=1;
		HitMarkerHS=False;
		HitMarkerKill=True;
		ClientPlaySound(Sound'AmbAncient.TileHit4');
	}
	else
	{
		HitMarkerHS=False;
		HitMarkerKill=False;
		HitMarkerTime=1;
		if(DamageType=='Decapitated')
		{
			ClientPlaySound(Sound'AmbAncient.TileHit4');
			HitMarkerHS=True;
		}
		else
		ClientPlaySound(Sound'AmbAncient.TileHit3');
	}
}

defaultproperties
{
				CurrentSize=1.000000
				Password="AdminPassword"
				Bob=0.004000
				WeaponPriority(1)="thecrimsonking"
				WeaponPriority(2)="U96AutoMag"
				WeaponPriority(3)="RLBow"
				WeaponPriority(4)="ShockRifle"
				WeaponPriority(5)="K_bow"
				WeaponPriority(6)="Eightball"
				WeaponPriority(7)="FlakCannon"
				WeaponPriority(8)="QuadShot"
				WeaponPriority(9)="CS_M4A1"
				WeaponPriority(10)="GESBioRifle"
				WeaponPriority(11)="CARifle"
				WeaponPriority(12)="ASMD"
				WeaponPriority(13)="Minigun"
				WeaponPriority(14)="Stinger"
				WeaponPriority(15)="K_Fists"
				WeaponPriority(16)="crystalstaff"
				WeaponPriority(17)="ucombatshotgun"
				WeaponPriority(18)="MyAutomag"
				WeaponPriority(19)="EARifle"
				WeaponPriority(20)="RazorJack"
				WeaponPriority(21)="AutoMag"
				WeaponPriority(22)="Rifle"
				WeaponPriority(23)="MadnessSword"
				WeaponPriority(24)="rlburstsmg"
				WeaponPriority(25)="MadnessMag"
				WeaponPriority(26)="rlbquadshot"
				WeaponPriority(27)="RLRevolver"
				WeaponPriority(28)="RLAutomag"
				PlayerReplicationInfoClass=Class'WolfCoop.wPRI'
				bAlwaysRelevant=True
}
