//=============================================================================
// wSkaarjPlayer.
//=============================================================================
class wSkaarjPlayer extends wPlayer;

var float AnimSpeed;

Replication
{
	reliable if ( Role<ROLE_Authority )
	ReplicateGunFix;
}

simulated function WalkStep()
{
	local sound step;
	local float decision;

	if ( Level.NetMode==NM_DedicatedServer )
		Return; // We don't preform this on dedicated servers.

	if( Level.FootprintManager==None || !Level.FootprintManager.Static.OverrideFootstep(Self,step,WetSteps) )
	{
		decision = FRand();
		if ( decision < 0.34 )
			Step = Footstep1;
		else if (decision < 0.67 )
			Step = Footstep2;
		else
			Step = Footstep3;
	}
	if( step==None )
		return;
	PlaySound(step, SLOT_Interact, 0.5, false, 400.0, 1.0);
}

simulated function RunStep()
{
	local sound step;
	local float decision;

	if ( (Level.Game != None) && (Level.Game.Difficulty > 1) )
		MakeNoise(0.05 * Level.Game.Difficulty);
	if ( Level.NetMode==NM_DedicatedServer )
		Return; // We don't preform this on dedicated servers.

	if( Level.FootprintManager==None || !Level.FootprintManager.Static.OverrideFootstep(Self,step,WetSteps) )
	{
		decision = FRand();
		if ( decision < 0.34 )
			Step = Footstep1;
		else if (decision < 0.67 )
			Step = Footstep2;
		else
			Step = Footstep3;
	}
	if( step==None )
		return;
	PlaySound(step, SLOT_Interact, 2, false, 800.0, 1.0);
}

//-----------------------------------------------------------------------------
// Animation functions

function PlayDodge(eDodgeDir DodgeMove)
{
	Velocity.Z = 210;
	if ( DodgeMove == DODGE_Left )
		PlayAnim('LeftDodge', 1.35, 0.06);
	else if ( DodgeMove == DODGE_Right )
		PlayAnim('RightDodge', 1.35, 0.06);
	else if ( DodgeMove == DODGE_Forward )
		PlayAnim('Lunge', 1.2, 0.06);
	else
		PlayDuck();
}

function PlayTurning()
{
		BaseEyeHeight = Default.BaseEyeHeight;

		if(Weapon!=None&&Weapon.bPointing)
			PlayAnim('WalkFire', 0.3, 0.3);
		else
			PlayAnim('Turn', 0.3, 0.3);
}

function TweenToWalking(float tweentime)
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		TweenAnim('Walk', tweentime);
	else if ( Weapon.bPointing || CarriedDecoration != None )
		TweenAnim('WalkFire', tweentime);
	else
		TweenAnim('Walk', tweentime);
}

function TweenToRunning(float tweentime)
{
	local vector X,Y,Z, Dir;

	BaseEyeHeight = Default.BaseEyeHeight;
	if (bIsWalking)
	{
		TweenToWalking(0.1);
		return;
	}

	GetAxes(Rotation, X,Y,Z);
	Dir = Normal(Acceleration);
	if ( (Dir Dot X < 0.75) && (Dir != vect(0,0,0)) )
	{
		// strafing
		if ( Dir Dot Y > 0 ) {
			if ( Weapon.bPointing )
				LoopAnim('StrafeLeftFr',2,0.2);
			else
				LoopAnim('StrafeLeft',2,0.2);
		}
		else 
		{
			if ( Weapon.bPointing )
				LoopAnim('StrafeRightFr',2,0.2);
			else
				LoopAnim('StrafeRight',2,0.2);
		}
		if (Dir Dot X < -0.75) 
		{
			if (Weapon == None)
				LoopAnim('Jog');
			else if ( Weapon.bPointing ) 
			{
				if (Weapon.Mass < 20)
					LoopAnim('JogFire');
				else
					LoopAnim('JogFire');
			}
			else
			{
				if (Weapon.Mass < 20)
					LoopAnim('Jog');
				else
					LoopAnim('Jog');
			}
		}
	}
	else if (Weapon == None)
		PlayAnim('Jog', 0.9, tweentime);
	else if ( Weapon.bPointing )
	{
		if (Weapon.Mass < 20)
			PlayAnim('JogFire', 0.9, tweentime);
		else
			PlayAnim('JogFire', 0.9, tweentime);
	}
	else
	{
		if (Weapon.Mass < 20)
			PlayAnim('Jog', 0.9, tweentime);
		else
			PlayAnim('Jog', 0.9, tweentime);
	} 
}

function PlayWalking()
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		LoopAnim('Walk',1.1);
	else if ( Weapon.bPointing || (CarriedDecoration != None) )
		LoopAnim('WalkFire',1.1);
	else
		LoopAnim('Walk',1.1);
}

function PlayRunning()
{
	local vector X,Y,Z, Dir;

	BaseEyeHeight = Default.BaseEyeHeight;

	// determine facing direction
	GetAxes(Rotation, X,Y,Z);
	Dir = Normal(Acceleration);
	if ( (Dir Dot X < 0.75) && (Dir != vect(0,0,0)) )
	{
		// strafing
		if ( Dir Dot Y > 0 ) {
			if ( Weapon.bPointing )
				LoopAnim('StrafeLeftFr',2,0.2);
			else
				LoopAnim('StrafeLeft',2,0.2);
		}
		else 
		{
			if ( Weapon.bPointing )
				LoopAnim('StrafeRightFr',2,0.2);
			else
				LoopAnim('StrafeRight',2,0.2);
		}
		if (Dir Dot X < -0.75) 
		{
			if (Weapon == None)
				LoopAnim('Jog');
			else if ( Weapon.bPointing ) 
			{
				if (Weapon.Mass < 20)
					LoopAnim('JogFire');
				else
					LoopAnim('JogFire');
			}
			else
			{
				if (Weapon.Mass < 20)
					LoopAnim('Jog');
				else
					LoopAnim('Jog');
			}
		}
	}
	else if (Weapon == None)
		LoopAnim('Jog');
	else if ( Weapon.bPointing ) 
	{
		if (Weapon.Mass < 20)
			LoopAnim('JogFire');
		else
			LoopAnim('JogFire');
	}
	else
	{
		if (Weapon.Mass < 20)
			LoopAnim('Jog');
		else
			LoopAnim('Jog');
	}
}

function PlayRising()
{
	BaseEyeHeight = 0.4 * Default.BaseEyeHeight;
	PlayAnim('Getup', 0.7, 0.1);
}

function PlayFeignDeath()
{
	BaseEyeHeight = 0;
	PlayAnim('Death3',0.7);
}

function PlayDying(name DamageType, vector HitLoc)
{

	local vector X,Y,Z, HitVec, HitVec2D;
	local float dotp;
	local carcass carc;

	BaseEyeHeight = Default.BaseEyeHeight;
	PlayDyingSound();

	if ( FRand() < 0.15 )
	{
		PlayAnim('Death4',0.7,0.1);
		return;
	}

	// check for big hit
	if ( (Velocity.Z > 250) && (FRand() < 0.7) )
	{
		PlayAnim('Death2', 0.7, 0.1);
		return;
	}

	// check for head hit
	if ( ((DamageType == 'Decapitated') || (HitLoc.Z - Location.Z > 0.6 * CollisionHeight))
			&& !Level.Game.bVeryLowGore )
	{
		DamageType = 'Decapitated';
		PlayAnim('Death5', 0.7, 0.1);
		if ( Level.NetMode != NM_Client )
		{
			carc = Spawn(class 'CreatureChunks',,, Location + CollisionHeight * vect(0,0,0.8), Rotation + rot(3000,0,16384) );
			if (carc != None)
			{
				carc.Mesh = mesh 'SkaarjHead';
				carc.Initfor(self);
				carc.Velocity = Velocity + VSize(Velocity) * VRand();
				carc.Velocity.Z = FMax(carc.Velocity.Z, Velocity.Z);
				ViewTarget = carc;
			}
		}
		return;
	}


	if ( FRand() < 0.15)
	{
		PlayAnim('Death3', 0.7, 0.1);
		return;
	}

	GetAxes(Rotation,X,Y,Z);
	X.Z = 0;
	HitVec = Normal(HitLoc - Location);
	HitVec2D= HitVec;
	HitVec2D.Z = 0;
	dotp = HitVec2D dot X;

	if (Abs(dotp) > 0.71) //then hit in front or back
		PlayAnim('Death3', 0.7, 0.1);
	else
	{
		dotp = HitVec dot Y;
		if (dotp > 0.0)
			PlayAnim('Death', 0.7, 0.1);
		else
			PlayAnim('Death4', 0.7, 0.1);
	}
}

//FIXME - add death first frames as alternate takehit anims!!!

function PlayGutHit(float tweentime)
{
	if ( AnimSequence == 'GutHit' )
	{
		if (FRand() < 0.5)
			TweenAnim('LeftHit', tweentime);
		else
			TweenAnim('RightHit', tweentime);
	}
	else
		TweenAnim('GutHit', tweentime);
}

function PlayHeadHit(float tweentime)
{
	if ( AnimSequence == 'HeadHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('HeadHit', tweentime);
}

function PlayLeftHit(float tweentime)
{
	if ( AnimSequence == 'LeftHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('LeftHit', tweentime);
}

function PlayRightHit(float tweentime)
{
	if ( AnimSequence == 'RightHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('RightHit', tweentime);
}

function PlayLanded(float impactVel)
{
	impactVel = impactVel/JumpZ;
	impactVel = 0.1 * impactVel * impactVel;
	BaseEyeHeight = Default.BaseEyeHeight;

	if ( Role == ROLE_Authority )
	{
		if ( impactVel > 0.17 )
			PlaySound(LandGrunt, SLOT_Talk, FMin(5, 5 * impactVel),false,1200,FRand()*0.4+0.8);
		if( Level.FootprintManager!=None )
			Level.FootprintManager.Static.PlayLandingNoise(Self,1,impactVel);
		else if ( !FootRegion.Zone.bWaterZone && (impactVel > 0.01) )
			PlaySound(Land, SLOT_Interact, FClamp(4.5 * impactVel,0.5,6), false, 1000, 1.0);
	}

	if ( (GetAnimGroup(AnimSequence) == 'Dodge') && IsAnimating() )
		return;
	if ( (impactVel > 0.06) || (GetAnimGroup(AnimSequence) == 'Jumping') )
		TweenAnim('Land', 0.12);
	else if ( !IsAnimating() )
	{
		if ( GetAnimGroup(AnimSequence) == 'TakeHit' )
			AnimEnd();
		else
			TweenAnim('Land', 0.12);
	}
}

function PlayInAir()
{
	BaseEyeHeight =  Default.BaseEyeHeight;
	TweenAnim('Jump2', 0.4);
}

function PlayDuck()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	TweenAnim('Duck', 0.25);
}

function PlayCrawling()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	LoopAnim('DuckWalk');
}

function TweenToWaiting(float tweentime)
{
	if ( IsInState('PlayerSwimming') || Physics==PHYS_Swimming )
	{
		BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
		TweenAnim('Swim', tweentime);
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		if(!Weapon.bPointing)
		TweenAnim('Breath2', tweentime);
		else
		TweenAnim('Firing', tweentime);
	}
}

function PlayWaiting()
{
	local name newAnim;

	if ( IsInState('PlayerSwimming') || (Physics==PHYS_Swimming) )
	{
		BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
		LoopAnim('Swim');
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		if ( (Weapon != None) && Weapon.bPointing )
			TweenAnim('Firing', 0.3);
		else
		{
			if ( FRand() < 0.2 )
				newAnim = 'Breath';
			else
				newAnim = 'Breath2';

			if ( AnimSequence == newAnim )
				LoopAnim(newAnim, 0.3 + 0.7 * FRand());
			else
				PlayAnim(newAnim, 0.3 + 0.7 * FRand(), 0.25);
		}
	}
}

function PlayFiring()
{
	// switch animation sequence mid-stream if needed
	if (AnimSequence == 'Jog')
		AnimSequence = 'JogFire';
	else if (AnimSequence == 'Walk')
		AnimSequence = 'WalkFire';
	else if ( AnimSequence == 'InAir' )
		TweenAnim('JogFire', 0.03);
	else if ( (GetAnimGroup(AnimSequence) != 'Attack')
			  && (GetAnimGroup(AnimSequence) != 'MovingAttack')
			  && (GetAnimGroup(AnimSequence) != 'Dodge')
			  && (AnimSequence != 'Swim') )
		TweenAnim('Firing', 0.02);
}

function PlayWeaponSwitch(Weapon NewWeapon)
{
}

function PlaySwimming()
{
	BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
	LoopAnim('Swim');
}

function TweenToSwimming(float tweentime)
{
	BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
	TweenAnim('Swim',tweentime);
}

function SwimAnimUpdate(bool bNotForward)
{
	if ( !bAnimTransition && (GetAnimGroup(AnimSequence) != 'Gesture') && (AnimSequence != 'Swim') )
		TweenToSwimming(0.1);
}


exec function Taunt( name Sequence )
{
	if(VSize(Velocity)<50 && Health>0 && Physics==PHYS_Walking && !IsInState('EndGameSpectate'))
	{
		if(Sequence=='Victory1')
		{ReplicateGunFix(); return;}
		else if(Sequence=='wave')
		{Sequence='Shield';
		ServerTaunt(Sequence);
		PlayAnim(Sequence, 1, 0.15);
		GoToState('SkaarjTaunt');
		return;}

		else if(HasAnim(Sequence) && GetAnimGroup(Sequence) == 'Gesture')
		{
			ServerTaunt(Sequence);
			PlayAnim(Sequence, 0.7, 0.2);
		}
	}
}

simulated function ReplicateGunFix()
{GoToState('GunFixing');}


simulated state GunFixing
{
ignores SeePlayer, HearNoise, Bump, StartClimbing;

	function ZoneChange( ZoneInfo NewZone )
	{
		if (NewZone.bWaterZone)
		{
			setPhysics(PHYS_Swimming);
			GotoState('PlayerSwimming');
		}
	}

	function PlayChatting()
	{
	}

	exec function Taunt( name Sequence )
	{
	}

	function AnimEnd()
	{
		if(AnimSequence=='HeadUp')
		{LoopAnim('Looking', AnimSpeed,0.2); if(Role == ROLE_Authority) PlaySound(Sound'roam11s',Slot_TALK);}
		else if(AnimSequence=='GunFix'||AnimSequence=='GunCheck'||AnimSequence=='Looking')
		{AnimSpeed=0.3 + 0.6 * FRand(); LoopAnim('gunfix',AnimSpeed,0.2);}
		else if (Role == ROLE_Authority && Health > 0)
		{GotoState('PlayerWalking');
		LastUpdateTime = -1;}
	}

	exec function Fire(optional float F)
	{
		PlayAnim('GunCheck',AnimSpeed);
	}

	exec function AltFire(optional float F)
	{
		PlayAnim('HeadUp',AnimSpeed);
	}

	function Rise()
	{
		if (!bRising && !bUpdatePosition)
		{
				BaseEyeHeight = Default.BaseEyeHeight;
				bRising = true;
				TweenAnim('Breath2',0.7); 
				Enable('AnimEnd');
		}
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		if ( bPressedJump || (NewAccel.Z > 0) )
			Rise();
		Acceleration = vect(0,0,0);
	}

	event PlayerTick( float DeltaTime )
	{
		if ( bUpdatePosition )
			ClientUpdatePosition();

		PlayerMove(DeltaTime);
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

	function PlayerMove( float DeltaTime)
	{
		local rotator currentRot;
		local vector NewAccel;

		aLookup  *= 0.24;
		aTurn    *= 0.24;

		// Update acceleration.
		if ( !IsAnimating() && (aForward != 0) || (aStrafe != 0) )
			NewAccel = vect(0,0,1);
		else
			NewAccel = vect(0,0,0);

		// Update view rotation.
		currentRot = Rotation;
		UpdateRotation(DeltaTime, 1);
		SetRotation(currentRot);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, NewAccel, DODGE_None, Rot(0,0,0));
		else
			ProcessMove(DeltaTime, NewAccel, DODGE_None, Rot(0,0,0));
		bPressedJump = false;
	}

	function PlayTakeHit(float tweentime, vector HitLoc, int Damage)
	{
		if ( IsAnimating() )
		{Enable('AnimEnd');
		Global.PlayTakeHit(tweentime, HitLoc, Damage);}
	}

	function ChangedWeapon()
	{
		Inventory.ChangedWeapon();
		Weapon = None;
	}

	function EndState()
	{PlayerReplicationInfo.bFeigningDeath = false;}

	function BeginState()
	{
		local rotator NewRot;

		AnimSpeed=0.3 + 0.6 * FRand();
		if (Role == ROLE_Authority && CarriedDecoration != none)
			DropDecoration();
		NewRot = Rotation;
		NewRot.Pitch = 0;
		SetRotation(NewRot);
		BaseEyeHeight = -0.5 * CollisionHeight;
		bIsCrouching = false;
		bPressedJump = false;
		bRising = false;
		PlayAnim('GunFix',AnimSpeed,0.7); 
		Enable('AnimEnd');
		PlayerReplicationInfo.bFeigningDeath = true;
	}
}

simulated state SkaarjTaunt
{
	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		if ( bPressedJump || (NewAccel.Z > 0) )
		GoToState('PlayerWalking');
	}
Begin:
	FinishAnim();
	GoToState('PlayerWalking');
}

defaultproperties
{
	animspeed=0.0
	drown=Sound'UnrealI.Skaarj.SKPDrown1'
	breathagain=Sound'UnrealI.Skaarj.SKPGasp1'
	Footstep1=Sound'UnrealShare.Cow.walkC'
	Footstep2=Sound'UnrealShare.Cow.walkC'
	Footstep3=Sound'UnrealShare.Cow.walkC'
	HitSound3=Sound'UnrealI.Skaarj.SKPInjur3'
	HitSound4=Sound'UnrealI.Skaarj.SKPInjur4'
	Die2=Sound'UnrealI.Skaarj.SKPDeath2'
	Die3=Sound'UnrealI.Skaarj.SKPDeath3'
	Die4=Sound'UnrealI.Skaarj.SKPDeath3'
	GaspSound=Sound'UnrealI.Skaarj.SKPGasp1'
	UWHit1=Sound'UnrealShare.Male.MUWHit1'
	UWHit2=Sound'UnrealShare.Male.MUWHit2'
	LandGrunt=Sound'UnrealI.Skaarj.Land1SK'
	JumpSound=Sound'UnrealI.Skaarj.SKPJump1'
	CarcassType=Class'UnrealI.TrooperCarcass'
	bSinglePlayer=False
	Health=120
	JumpZ=360.0
	BaseEyeHeight=32.0
	EyeHeight=24.75
	HitSound1=Sound'UnrealI.Skaarj.SKPInjur1'
	HitSound2=Sound'UnrealI.Skaarj.SKPInjur2'
	Die=Sound'UnrealI.Skaarj.SKPDeath1'
	MenuName="Skaarj"
	CollisionRadius=22.0
	Mass=120.0
	Buoyancy=118.8
	Skin=Texture'UnrealI.Skins.sktrooper2'
	Mesh=LodMesh'UnrealI.sktrooper'
	Fatness=120
}
