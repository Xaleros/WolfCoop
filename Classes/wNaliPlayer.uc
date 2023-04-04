//=============================================================================
// wNaliPlayer.
//=============================================================================
class wNaliPlayer extends wPlayer;


function PlayTurning()
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if(Weapon!=None&&Weapon.bPointing)
	PlayAnim('WalkFire',0.3,0.3);
	else
	PlayAnim('Turn', 0.3, 0.3);
}

function TweenToWalking(float tweentime)
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		TweenAnim('Walk', tweentime);
	else if ( Weapon.bPointing || (CarriedDecoration != None) )
		TweenAnim('WalkFire', tweentime);
	else
		TweenAnim('Walk', tweentime);
}

function TweenToRunning(float tweentime)
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (bIsWalking)
		TweenToWalking(0.1);
	else if (Weapon == None)
		PlayAnim('Run', 1, tweentime);
	else if ( Weapon.bPointing )
		PlayAnim('RunFire', 1, tweentime);
	else
		PlayAnim('Run', 1, tweentime);
}

function PlayWalking()
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		LoopAnim('Walk');
	else if ( Weapon.bPointing || (CarriedDecoration != None) )
		LoopAnim('WalkFire');
	else
		LoopAnim('Walk');
}

function PlayRunning()
{
	BaseEyeHeight = Default.BaseEyeHeight;
	if (Weapon == None)
		LoopAnim('Run');
	else if ( Weapon.bPointing )
		LoopAnim('RunFire');
	else
		LoopAnim('Run');
}

function PlayRising()
{
	BaseEyeHeight = 0.4 * Default.BaseEyeHeight;
	TweenAnim('DuckWalk', 0.7);
}

function PlayFeignDeath()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	PlayAnim('Levitate', 0.3, 1.0);
}

function PlayDying(name DamageType, vector HitLoc)
{
	local vector X,Y,Z, HitVec;
	local float dotp;

	BaseEyeHeight = Default.BaseEyeHeight;
	PlayDyingSound();

	if ( FRand() < 0.15 )
	{
		PlayAnim('Dead',0.7,0.1);
		return;
	}

	// check for big hit
	if ( (Velocity.Z > 250) && (FRand() < 0.7) )
	{
		PlayAnim('Dead4', 0.7, 0.1);
		return;
	}

	// check for head hit
	if ( (DamageType == 'Decapitated') || (HitLoc.Z - Location.Z > 0.6 * CollisionHeight) )
	{
		DamageType = 'Decapitated';
		PlayAnim('Dead3', 0.7, 0.1);
		return;
	}

	GetAxes(Rotation,X,Y,Z);
	HitVec = Normal(HitLoc - Location);
	dotp = HitVec dot Y;
	if (dotp > 0.0)
		PlayAnim('Dead', 0.7, 0.1);
	else
		PlayAnim('Dead2', 0.7, 0.1);
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
		TweenAnim('Landed', 0.12);
	else if ( !IsAnimating() )
	{
		if ( GetAnimGroup(AnimSequence) == 'TakeHit' )
			AnimEnd();
		else
			TweenAnim('Landed', 0.12);
	}
}

function PlayInAir()
{
	BaseEyeHeight =  Default.BaseEyeHeight;
	TweenAnim('RunFire', 0.4);
}

function PlayDuck()
{
	BaseEyeHeight = 0.5*Default.BaseEyeHeight;
	TweenAnim('DuckWalk', 0.25);
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
		TweenAnim('Tread', tweentime);
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		if(!Weapon.bPointing)
		TweenAnim('Breath', tweentime);
		else
		TweenAnim('StilFire', tweentime);
	}
}

function PlayWaiting()
{
	local name newAnim;

	if ( IsInState('PlayerSwimming') || (Physics==PHYS_Swimming) )
	{
		BaseEyeHeight = 0.7 * Default.BaseEyeHeight;
		LoopAnim('Tread');
	}
	else
	{
		BaseEyeHeight = Default.BaseEyeHeight;
		if ( (Weapon != None) && Weapon.bPointing )
			TweenAnim('StilFire', 0.3);
		else
		{
			if ( FRand() < 0.2 )
				newAnim = 'Cough';
			else if ( FRand() < 0.3 )
				newAnim = 'Sweat';
			else
				newAnim = 'Breath';

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
	if (AnimSequence == 'Run')
		AnimSequence = 'RunFire';
	else if (AnimSequence == 'Walk')
		AnimSequence = 'WalkFire';
	else if ( (GetAnimGroup(AnimSequence) != 'Attack')
			  && (GetAnimGroup(AnimSequence) != 'MovingAttack')
			  && (GetAnimGroup(AnimSequence) != 'Dodge')
			  && (AnimSequence != 'Swim') )
		TweenAnim('StilFire', 0.02);
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

function NormallyVisible()
{
	bHidden = false;
	Style = STY_Normal;
	ScaleGlow = 1.0;
}

state FeigningDeath
{
	ignores SeePlayer, HearNoise, Bump, Fire, AltFire;

	event PlayerTick( float DeltaTime )
	{
		Super.PlayerTick(DeltaTime);

		if ( (Role == ROLE_Authority) && !IsAnimating() && !bHidden )
		{
			Style = STY_Translucent;
			ScaleGlow -= DeltaTime;
			if ( ScaleGlow < 0.3 )
				bHidden = true;
		}
	}

	function PlayTakeHit(float tweentime, vector HitLoc, int Damage)
	{
		NormallyVisible();
		Global.PlayTakeHit(tweentime, HitLoc, Damage);
	}

	function PlayDying(name DamageType, vector HitLocation)
	{
		NormallyVisible();
		Global.PlayDying(DamageType, HitLocation);
	}

	function Landed(vector HitNormal)
	{
		NormallyVisible();
		Super.Landed(HitNormal);
	}

	function EndState()
	{
		Super.EndState();
		if ( (Role == ROLE_Authority) && !bHidden && (Style == STY_Translucent) )
			NormallyVisible();
	}
}

state PlayerSwimming
{
	ignores SeePlayer, HearNoise, Bump;

	function BeginState()
	{
		Super.BeginState();
		NormallyVisible();
	}
}

state PlayerWalking
{
	ignores SeePlayer, HearNoise, Bump;

	exec function Fire( optional float F )
	{
		NormallyVisible();
		Super.Fire(F);
	}

	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
						 Vector momentum, name damageType)
	{
		NormallyVisible();
		Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		Super.ProcessMove(DeltaTime, NewAccel, DodgeMove, DeltaRot);
		if ( (Role == ROLE_Authority) && (Style == STY_Translucent) )
		{
			ScaleGlow = VSize(Velocity)/GroundSpeed;
			bHidden = (ScaleGlow < 0.35);
		}
	}

	function EndState()
	{
		NormallyVisible();
		Super.EndState();
	}
}


exec function Taunt( name Sequence )
{
	if(Sequence=='Wave')
	PlaySound(Sound'Follow1n');

	if(Sequence=='Victory1')
	PlaySound(Sound'Pray1n');

	if(Sequence=='Taunt1')
	{Sequence='Bow2';
	ServerTaunt(Sequence);
	PlaySound(Sound'Bowing1n');
	PlayAnim('Bow2', 1, 0.2);
	GoToState('NaliTaunt');}
	
	else if(HasAnim(Sequence) && GetAnimGroup(Sequence) == 'Gesture')
	{
		ServerTaunt(Sequence);
		PlayAnim(Sequence, 0.7, 0.2);
	}
}


simulated state NaliTaunt
{
	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		if ( bPressedJump || (NewAccel.Z > 0) )
		GoToState('PlayerWalking');
	}
	function HealNearby()
	{
		local wPlayer P;
		local int i;
		local Effects Ef;

		foreach radiusactors(class'wPlayer',P,100)
		{
			i=0;
			if(P.Health<P.Default.Health)
			{
				while(P.Health<P.Default.Health && i<5)
				{
					P.Health++;
					i++;
				}
				P.PlaySound(Sound'Health2');
				Ef=Spawn(class'ReSpawn',,,P.Location,P.Rotation);
				Ef.DrawScale*=P.DrawScale;
				P.ClientMessage("Healed by Nali Magic +5");
			}
		}
	}
Begin:
	FinishAnim();
	HealNearby();
	GoToState('PlayerWalking');
}

defaultproperties
{
				drown=Sound'UnrealShare.Male.MDrown1'
				breathagain=Sound'UnrealShare.Male.MGasp1'
				Footstep1=Sound'UnrealShare.Cow.walkC'
				Footstep2=Sound'UnrealShare.Cow.walkC'
				Footstep3=Sound'UnrealShare.Cow.walkC'
				HitSound3=Sound'UnrealShare.Nali.injur1n'
				HitSound4=Sound'UnrealShare.Nali.injur2n'
				Die2=Sound'UnrealShare.Nali.death2n'
				Die3=Sound'UnrealShare.Nali.death2n'
				Die4=Sound'UnrealShare.Nali.death2n'
				GaspSound=Sound'UnrealShare.Male.MGasp2'
				UWHit1=Sound'UnrealShare.Male.MUWHit1'
				UWHit2=Sound'UnrealShare.Male.MUWHit2'
				LandGrunt=Sound'UnrealShare.Male.lland01'
				CarcassType=Class'UnrealShare.NaliCarcass'
				JumpSound=Sound'UnrealShare.Male.MJump1'
				bSinglePlayer=False
				GroundSpeed=320.000000
				JumpZ=360.000000
				BaseEyeHeight=32.000000
				EyeHeight=32.000000
				Health=80
				HitSound1=Sound'UnrealShare.Nali.fear1n'
				HitSound2=Sound'UnrealShare.Nali.cringe2n'
				Die=Sound'UnrealShare.Nali.death1n'
				MenuName="Nali"
				Skin=Texture'UnrealShare.Skins.JNali1'
				Mesh=LodMesh'UnrealI.Nali2'
				CollisionRadius=24.000000
				CollisionHeight=48.000000
				Buoyancy=98.000000
}
