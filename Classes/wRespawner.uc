//=============================================================================
// wRespawner.
//=============================================================================
class wRespawner expands Actor;

var bool bReviving;

simulated function PostBeginPlay()
{
	local int i;
	if(PlayerPawn(Owner)!=None)
	{
		Mesh=Owner.Mesh;
		Skin=Owner.Skin;
		for(i=0; i<8; i++)
		MultiSkins[i]=Owner.MultiSkins[i];
		DrawScale=Owner.DrawScale;
		Fatness=Owner.Fatness;
		if(wPlayer(Owner)!=None)
		SetCollisionSize(wPlayer(Owner).Default.CollisionRadius*wPlayer(Owner).CurrentSize,wPlayer(Owner).Default.CollisionHeight*wPlayer(Owner).CurrentSize);
		else
		SetCollisionSize(Owner.Default.CollisionRadius,Owner.Default.CollisionHeight);
	}
	else Destroy();
	Super.PostBeginPlay();
}


simulated function Tick(float DT)
{
	local PlayerPawn P;
	local int Multiplier;

/*	if(wPlayer(Owner)!=None)
	{
		foreach VisibleCollidingActors(class'PlayerPawn',P,50)
		{
			if(P.Health>0)
			{wPlayer(Owner).ReviveProgress+=0.001; bReviving=True;}
			if(wPlayer(P)!=None)
			wPlayer(P).ReviveTarget=wPlayer(Owner);
			if(wPlayer(Owner).ReviveProgress>=1)
			ReviveOwner();
		}
	}*/

	Multiplier=0;
	bReviving=False;
	foreach TouchingActors(class'PlayerPawn',P)
	{
		if(P!=None && P!=Owner && P.Health>0)
		{
			bReviving=True;
			if(wPlayer(P)!=None) wPlayer(P).ReviveTarget=wPlayer(Owner);
			Multiplier++;
		}
	}


	if(bReviving)
	{
		wPlayer(Owner).ReviveProgress+=(0.2*dT)*Multiplier;
		if(wPlayer(Owner).ReviveProgress>=1)
		ReviveOwner();
	}
	else
	{
		if(wPlayer(Owner).ReviveProgress>0)
		wPlayer(Owner).ReviveProgress-=0.4*dT;
	}
	Super.Tick(DT);
}

function ReviveOwner()
{
	local PlayerPawn P;

	wPlayer(Owner).RespawnMe();
	foreach VisibleCollidingActors(class'PlayerPawn',P,50)
	{
		if(P.Health>0)
		P.PlayerReplicationInfo.Score+=50;
		if(wPlayer(P)!=None && wPlayer(P).ReviveTarget==Owner) wPlayer(P).ReviveTarget=None;
	}
	Owner.SetCollision(False);
	Owner.SetLocation(Location);
	Owner.SetCollision(True);
	Destroy();
}
/*
singular function Touch(Actor Other)
{
	if(PlayerPawn(Owner)!=None)
	{
		if(PlayerPawn(Other)!=None && PlayerPawn(Other)!=Owner)
		{
			if(Pawn(Other).Health>0)
			{
				bReviving=True;
				if(wPlayer(Other)!=None) wPlayer(Other).ReviveTarget=wPlayer(Owner);
				Multiplier++;
			}
		}
	}
}


singular function Untouch(Actor Other)
{
	local PlayerPawn P;
	if(PlayerPawn(Other)!=None && PlayerPawn(Other)!=Owner)
	{
		Multiplier--;
		foreach TouchingActors(Class'PlayerPawn',P)
		{
			if(P!=None) return;
		}
		bReviving=False;
	}
}

//////
simulated function Touch(Actor Other)
{
	if(PlayerPawn(Owner)!=None)
	{
		if(PlayerPawn(Other)!=None && PlayerPawn(Other)!=Owner)
		{	if(wPlayer(Owner)!=None) wPlayer(Owner).RespawnMe();
			else PlayerPawn(Owner).ServerReStartPlayer();
			PlayerPawn(Other).PlayerReplicationInfo.Score+=50;
			Owner.SetCollision(False);
			Owner.SetLocation(Location);
			Owner.SetCollision(True);
			Destroy();
		}
	}
}
*/

defaultproperties
{
				bAlwaysRelevant=True
				bCollideActors=True
				RemoteRole=ROLE_SimulatedProxy
				LifeSpan=99999.000000
				AnimSequence="GutHit"
				DrawType=DT_Mesh
				Style=STY_Translucent
				Mesh=LodMesh'UnrealShare.Female1'
				ScaleGlow=2.000000
				AmbientGlow=255
				CollisionRadius=17.000000
				CollisionHeight=39.000000
				Mass=1.000000
}
