//=============================================================================
// wFemale.
//=============================================================================
class wFemale extends wPlayer abstract;

function PlayDying(name DamageType, vector HitLoc)
{
	local vector X,Y,Z, HitVec, HitVec2D;
	local float dotp;
	local carcass carc;

	BaseEyeHeight = Default.BaseEyeHeight;
	PlayDyingSound();

	if ( DamageType == 'Suicided' )
	{
		PlayAnim('Dead1', 0.7, 0.1);
		return;
	}

	if ( FRand() < 0.15 )
	{
		PlayAnim('Dead3',0.7,0.1);
		return;
	}

	// check for big hit
	if ( (Velocity.Z > 250) && (FRand() < 0.7) )
	{
		PlayAnim('Dead2', 0.7, 0.1);
		return;
	}

	// check for head hit
	if ( ((DamageType == 'Decapitated') || (HitLoc.Z - Location.Z > 0.6 * CollisionHeight)) && !class'GameInfo'.Default.bVeryLowGore )
	{
		DamageType = 'Decapitated';
		if ( Level.NetMode != NM_Client )
		{
			carc = Spawn(class 'FemaleHead',,, Location + CollisionHeight * vect(0,0,0.8), Rotation + rot(3000,0,16384) );
			if (carc != None)
			{
				carc.Initfor(self);
				carc.Velocity = Velocity + VSize(Velocity) * VRand();
				carc.Velocity.Z = FMax(carc.Velocity.Z, Velocity.Z);
				ViewTarget = carc;
			}
		}
		PlayAnim('Dead6', 0.7, 0.1);
		return;
	}


	if ( FRand() < 0.15)
	{
		PlayAnim('Dead1', 0.7, 0.1);
		return;
	}

	GetAxes(Rotation,X,Y,Z);
	X.Z = 0;
	HitVec = Normal(HitLoc - Location);
	HitVec2D= HitVec;
	HitVec2D.Z = 0;
	dotp = HitVec2D dot X;

	if (Abs(dotp) > 0.71) //then hit in front or back
		PlayAnim('Dead4', 0.7, 0.1);
	else
	{
		dotp = HitVec dot Y;
		if (!class'GameInfo'.Default.bVeryLowGore && ((dotp > 0.0 && bool(wFemaleOne(Self))) || (dotp < 0.0 && bool(wFemaleTwo(Self)))) )
		{
			PlayAnim('Dead7', 0.7, 0.1);
			carc = Spawn(class 'Arm1');
			if (carc != None)
			{
				carc.Initfor(self);
				carc.Velocity = Velocity + VSize(Velocity) * VRand();
				carc.Velocity.Z = FMax(carc.Velocity.Z, Velocity.Z);
			}
		}
		else
			PlayAnim('Dead5', 0.7, 0.1);
	}
}

defaultproperties
{
	CurrentSize=0.0
	drown=Sound'UnrealShare.Female.mdrown2fem'
	breathagain=Sound'UnrealShare.Female.hgasp3fem'
	HitSound3=Sound'UnrealShare.Female.linjur3fem'
	HitSound4=Sound'UnrealShare.Female.hinjur4fem'
	Die2=Sound'UnrealShare.Female.death3cfem'
	Die3=Sound'UnrealShare.Female.death2afem'
	Die4=Sound'UnrealShare.Female.death4cfem'
	GaspSound=Sound'UnrealShare.Female.lgasp1fem'
	UWHit1=Sound'UnrealShare.Female.FUWHit1'
	UWHit2=Sound'UnrealShare.Male.MUWHit2'
	LandGrunt=Sound'UnrealShare.Female.lland1fem'
	JumpSound=Sound'UnrealShare.Female.jump1fem'
	CarcassType=Class'UnrealShare.FemaleBody'
	HitSound1=Sound'UnrealShare.Female.linjur1fem'
	HitSound2=Sound'UnrealShare.Female.linjur2fem'
	Die=Sound'UnrealShare.Female.death1dfem'
	bIsFemale=True
}
