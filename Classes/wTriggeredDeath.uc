//=============================================================================
// wTriggeredDeath.
//=============================================================================
class wTriggeredDeath expands TriggeredDeath;


auto state Enabled
{
	function Touch( Actor Other )
	{
		//local inventory Inv;
		local Pawn P;
		local GameRules GR;

		if ( Other.bIsPawn )
		{
			P = Pawn(Other);
			if (P.Health <= 0)
				return;

			for (GR = Level.Game.GameRules; GR != none; GR = GR.NextRules )
				if (GR.bHandleDeaths && GR.PreventDeath(P, none, DeathName))
					return;

			if (PlayerPawn(Other) != none)
				InitTriggeredPlayerPawnDeath(PlayerPawn(Other));
			else
				KillVictim(P);
		}
	}
}

defaultproperties
{
}
