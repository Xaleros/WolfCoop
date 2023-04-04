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
				bUnlit=True
				bFixedRotationDir=True
				DrawType=DT_Mesh
				Style=STY_Translucent
				Mesh=LodMesh'UnrealShare.ArmorM'
				ScaleGlow=0.500000
				CollisionRadius=0.000000
				CollisionHeight=0.000000
				RotationRate=(Yaw=5000)
				DesiredRotation=(Yaw=30000)
}
