//=============================================================================
// wXmasLightsMut.
//=============================================================================
class wXmasLightsMut expands Mutator;


simulated function PostBeginPlay()
{
	local actor act;
	local playerpawn p;

	if(Role == ROLE_Authority && Level.NetMode != NM_Standalone)
	return;

	foreach allactors(class'actor',act)
	{
		if(bool(ZoneInfo(Act)))
		ZoneInfo(Act).AmbientHue=RandRange(0,255);

		if(FRand()<0.5)
		Act.LightHue=RandRange(0,110);
		else
		Act.LightHue=RandRange(245,255);
		Act.LightSaturation=RandRange(0,128);
	}
	foreach allactors(class'PlayerPawn',P)
	{
		P.ConsoleCommand("Flush");
	}

	log("Merry Xmas and Happy New Year!");	
}

defaultproperties
{
				bAlwaysRelevant=True
				DrawType=DT_Mesh
}
