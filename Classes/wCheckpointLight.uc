//=============================================================================
// wCheckpointLight.
//=============================================================================
class wCheckpointLight expands FlashLightBeam;

function tick (float DT)
{
	Super.tick(DT);
	if(!bool(Owner))
	Destroy();
}

defaultproperties
{
				LightEffect=LE_WateryShimmer
				LightBrightness=255
				LightHue=140
				LightSaturation=255
				LightRadius=24
}
