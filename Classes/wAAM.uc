//=============================================================================
// wAAM.
//=============================================================================
class wAAM extends AdminAccessManager config(WolfCoopAdmin);

var() globalconfig private string AAM_AdminPassword,AAM_ModeratorPassword,AAM_HelperPassword;

function AdminLogin( PlayerPawn Other )
{Other.bAdmin=True; wAdminLogin(Other,Other.Password);}

function wAdminLogin(PlayerPawn Other, String AdminPw)
{
	local String AdminLevelText;

	if(Level.NetMode==NM_Standalone)
	{wPRI(Other.PlayerReplicationInfo).AdminLevel=3; Other.bAdmin=True; return;}
	else Other.bAdmin=False;

	if(AdminPw~=AAM_AdminPassword)
	{wPRI(Other.PlayerReplicationInfo).AdminLevel=3; Other.bAdmin=True; Log("Administrator"@Other.GetHumanName()@"logged in",Class.Name);}
	else if(AdminPw~=AAM_ModeratorPassword)
	{wPRI(Other.PlayerReplicationInfo).AdminLevel=2; Log("Moderator"@Other.GetHumanName()@"logged in",Class.Name);}
	else if(AdminPw~=AAM_HelperPassword)
	{wPRI(Other.PlayerReplicationInfo).AdminLevel=1; Log("Helper"@Other.GetHumanName()@"logged in",Class.Name);}
	else
	{Other.ClientMessage("The Admin Password you entered is incorrect"); wPRI(Other.PlayerReplicationInfo).AdminLevel=0; Log("Player"@Other.GetHumanName()@"logged in",Class.Name);}

	if(wPRI(Other.PlayerReplicationInfo).AdminLevel>0)
	{
		Other.ClientMessage("You logged in as a Level "$wPRI(Other.PlayerReplicationInfo).AdminLevel$" Admin");
	}

	//Log(ReplaceStr(AdminLoginText,"%s",Other.GetHumanName()),Class.Name);
}

function AdminLogout( PlayerPawn Other )
{
	if( Other==None || wPRI(Other.PlayerReplicationInfo).AdminLevel<=0 )
		return;
	Other.bAdmin = false;
	wPRI(Other.PlayerReplicationInfo).AdminLevel=0;
	Log(ReplaceStr(AdminLogoutText,"%s",Other.GetHumanName()),Class.Name);
	Log(Other.GetHumanName()@"logged out",Class.Name);
}

function bool CanExecuteCheat( PlayerPawn Other, name N )
{
	if(Other.bAdmin) return true;

	if( N=='ViewPlayerNum' || N=='ViewClass' )
	{
		if(Other.IsA('Spectator')) return true;
		else if(Other.Health>0 && Level.Game.bNoCheating && wPRI(Other.PlayerReplicationInfo).AdminLevel<=0 ) return false;
		else return true;
	}
	if( wPRI(Other.PlayerReplicationInfo).AdminLevel<=0 && NetConnection(Other.Player)!=None )
		{return false;}
	if(wPRI(Other.PlayerReplicationInfo).AdminLevel<=1 && (N=='KillPawns' || N=='Kill' || N=='Kick' || N=='KickID' || N=='SwitchLevel' || N=='SwitchCoopLevel' || N=='SkipMap' || N=='KillAll' || N=='WipeItems' || N=='Slap' || N=='GrantExp') && NetConnection(Other.Player)!=None )
		{return false;}
	if(wPRI(Other.PlayerReplicationInfo).AdminLevel<=2 && (N=='PlayersOnly' || N=='Set' || N=='AdminAddCheckpoint') && NetConnection(Other.Player)!=None )
		{return false;}

	if( bLogCheatUseage )
		Log(ReplaceStr(ReplaceStr(CheatUsedStr,"%s",Other.GetHumanName()),"%c",string(N)),Class.Name);
	return true;
}
function bool CanExecuteCheatStr( PlayerPawn Other, name N, string Parms )
{
	if( wPRI(Other.PlayerReplicationInfo).AdminLevel<=0 && NetConnection(Other.Player)!=None )
		return false;
	if( bLogCheatUseage )
		Log(ReplaceStr(ReplaceStr(CheatUsedStr,"%s",Other.GetHumanName()),"%c",N@Parms),Class.Name);
	return true;
}

defaultproperties
{
				AAM_AdminPassword="AdminPassword"
				AAM_ModeratorPassword="ModeratorPassword"
				AAM_HelperPassword="HelperPassword"
}
