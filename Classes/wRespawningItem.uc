//=============================================================================
// wRespawningItem.
//=============================================================================
class wRespawningItem expands Actor;

simulated function PostBeginPlay()
{
	if(Inventory(Owner)!=None && Inventory(Owner).bRotatingPickup)
	{DesiredRotation=Owner.DesiredRotation; RotationRate=Owner.RotationRate; SetPhysics(PHYS_Rotating);}
	Super.PostBeginPlay();
}

function Tick(float DT)
{
	local int i;
	if(Owner!=None && Owner.bHidden)
	{
		Mesh=Owner.Mesh;
		DrawType=Owner.DrawType;
		DrawScale=Owner.DrawScale;
		Fatness=Owner.Fatness;
		Skin=Owner.Skin;
		for(i=0; i<8; i++)
		MultiSkins[i]=Owner.MultiSkins[i];
	}
	else Destroy();
}

defaultproperties
{
	ScaleGlow=0.5
	CollisionRadius=0.0
	CollisionHeight=0.0
	Mesh=LodMesh'UnrealShare.ArmorM'
	RotationRate=(Yaw=5000)
	DesiredRotation=(Yaw=30000)
	DrawType=DT_Mesh
	Style=STY_Translucent
	bUnlit=True
	bFixedRotationDir=True
}
