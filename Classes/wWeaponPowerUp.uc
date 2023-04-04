//=============================================================================
// wWeaponPowerUp.
//=============================================================================
class wWeaponPowerUp expands WeaponPowerUp;


auto state Pickup
{
	function Touch( actor Other )
	{
		local inventory inv;

		if ( Pawn(Other)!=None && Pawn(Other).bIsPlayer)
		Level.Game.PickupQuery(Pawn(Other), Self);
	}
}

defaultproperties
{
}
