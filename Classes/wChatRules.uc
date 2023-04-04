//=============================================================================
// wChatRules.
//=============================================================================
class wChatRules extends GameRules config(WolfCoop);

var() config bool bVerbose;
var() string BannedWords[24];

//Simple Slurs filter

function PostBeginPlay()
{
	if( Level.Game.GameRules==None )
	Level.Game.GameRules = Self;
	else Level.Game.GameRules.AddRules(Self);
}


function bool AllowChat( PlayerPawn Chatting, out string Msg )
{
	local string Minute, Hour;
	local GameRules G;
	local int I;
	local bool bBlockMessage;
	local String Filter;
	local wPRI PRI;

	Filter=Msg;

	if(Chatting.Level.Minute<10) Minute="0"$Chatting.Level.Minute;
	else Minute=""$Chatting.Level.Minute;
	if(Chatting.Level.Hour<10) Hour="0"$Chatting.Level.Hour;
	else Hour=""$Chatting.Level.Hour;

	if ( Level.Game.GameRules!=None )
	{
		for ( G=Level.Game.GameRules; G!=None; G=G.NextRules )
			if ( G!=Self && G.bNotifyMessages && !G.AllowChat(Chatting,Msg) )
				Return false;
	} //Custom GameRules compatibility


	for(I=0; I<24; I++)
	{
		if(InStr((Locs(Filter)),BannedWords[i])>=0)
		bBlockMessage=True;
	}

	if(InStr((Locs(Filter)),"voteend")>=0)
	{
		if(wPlayer(Chatting)!=None && Spectator(Chatting)==None && WolfCoopGame(Level.Game).bEnableVoteEnd && !WolfCoopGame(Level.Game).bNoChatVoteEnd && !WolfCoopGame(Level.Game).bEndTimerPunish && (!WolfCoopGame(Level.Game).bEnableLives || (wPlayer(Chatting).Health>0 || wPlayer(Chatting).Lives>0)))
		{
			wPRI(Chatting.PlayerReplicationInfo).bVoteEnd=!wPRI(Chatting.PlayerReplicationInfo).bVoteEnd;
			WolfCoopGame(Level.Game).VoteEndCheck();
			if(wPRI(Chatting.PlayerReplicationInfo).bVoteEnd) BroadCastMessage(Chatting.GetHumanName()@"voted to end");
			else BroadCastMessage(Chatting.GetHumanName()@"revoked their end vote");
			return false;
		}
	}

	if(InStr((Locs(Filter)),"!c")>=0 || InStr((Locs(Filter)),"!checkpoint")>=0)
	{
		if(wPlayer(Chatting)!=None && Spectator(Chatting)==None && (wPlayer(Chatting).Health>0 || wPlayer(Chatting).Lives>0) && WolfCoopGame(Level.Game).bAllowCheckpointRelocate)
		{
			if(wPlayer(Chatting).CheckPointTime>0)
			wPlayer(Chatting).CheckPoint();
			return false;
		}
	}

	if(InStr((Locs(Filter)),"!ignore")>=0 || InStr((Locs(Filter)),"!n")>=0)
	{
		if(wPlayer(Chatting)!=None && Spectator(Chatting)==None && (wPlayer(Chatting).Health>0 || wPlayer(Chatting).Lives>0) && WolfCoopGame(Level.Game).bAllowCheckpointRelocate)
		{
			if(wPlayer(Chatting).CheckPointTime>0)
			wPlayer(Chatting).CheckPointTime=0;
			return false;
		}
	}


	if(bBlockMessage)
	{
		foreach allactors(class'wPRI', PRI)
		{
			if(PRI.AdminLevel>0)
			PlayerPawn(PRI.Owner).ClientMessage("Chat Message Blocked: "$Chatting.PlayerReplicationInfo.PlayerName$": ["$Hour$":"$Minute$"] "$Msg,'DeathMessage',True);
			log("Chat Message Blocked: "$Chatting.PlayerReplicationInfo.PlayerName$": ["$Hour$":"$Minute$"] "$Msg,'BlockedMessage');
			return false;
		}
	}

	//Msg="["$Hour$":"$Minute$"]"@Msg;

	log(Chatting.PlayerReplicationInfo.PlayerName$": ["$Hour$":"$Minute$"] "$Msg,'RLChat');
	Return True;
}


function string ExecAdminCmd(PlayerPawn Other, string Cmd)
{
	if ( Left(Cmd,3) ~= "Set" )
	{
		if(InStr((Locs(Cmd)),"adminlevel")>=0)
		{if(wPRI(Other.PlayerReplicationInfo).AdminLevel>0) Other.ClientMessage("Nice Try ;)"); return Other.ConsoleCommand("");}
		if ( Left(Cmd,4) ~= "SetA" )
		{
			if(wPRI(Other.PlayerReplicationInfo).AdminLevel<=1)
			{if(wPRI(Other.PlayerReplicationInfo).AdminLevel>0) /*Other.ClientMessage("Admin Level (2) Required to use this command");*/ return Other.ConsoleCommand("");}
			else
			SetActorProperty(Other,Right(Cmd,Len(Cmd)-5));
		}
		else if(wPRI(Other.PlayerReplicationInfo).AdminLevel<=2)
		{if(wPRI(Other.PlayerReplicationInfo).AdminLevel>0) /*Other.ClientMessage("Admin Level (3) Required to use this command");*/ return Other.ConsoleCommand("");}
	}
	else if ( Left(Cmd,5) ~= "TSetA" )
	TraceSetActorProperty(Other,Right(Cmd,Len(Cmd)-6));

	if ( NextRules!=None )
		Return NextRules.ExecAdminCmd(Other,Cmd);
	if ( wPRI(Other.PlayerReplicationInfo).AdminLevel<=1 )
		Return "";

	return Super.ExecAdminCmd(Other,Cmd);
}

function SetActorProperty(PlayerPawn Sender, string Cmd)
{
	local class<Actor> ActorClass;
	local Actor A, Reply;
	local string S, AProperty[16], AValue[16];
	local int i, Radius, ACount;
	local bool bAll;

//	admin SetA <Radius> <Class> <Property> <Value> <Property> <Value> <Property> <Value> <Property> <Value>

	if ( Cmd == "" )
	{
		Sender.ClientMessage("Missing input.");
		return;
	}

	S = Left(Cmd,InStr(Cmd," "));

	Radius = Int(S);

	if ( Radius <= 0 )
	bAll = True;
	else
	Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);

	S = Left(Cmd,InStr(Cmd," "));

	ActorClass = GetActorClass(Sender,S);

	if ( ActorClass == None )
	return;

	Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);

	S = "Changing actor properties of";
	if ( bAll )
	S @= "all"@ActorClass@"in"@Left(String(Self),InStr(String(Self),"."))$".";
	else
	S @= ActorClass@"within a radius of"@Radius$".";

	Sender.ClientMessage(S);

	for ( i = 0; i < ArrayCount(AProperty); i++ )
	{
		if ( InStr(Cmd," ") == -1 )
		break;

		S = Left(Cmd,InStr(Cmd," "));

		AProperty[i] = S;

		Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);

		if ( InStr(Cmd," ") != -1 )
		S = Left(Cmd,InStr(Cmd," "));
		else
		S = Cmd;

		AValue[i] = S;

		Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);
	}

	ForEach AllActors( ActorClass, A )
	{
		if ( !bAll && (VSize(A.Location-Sender.Location) > Radius) )
		continue;

		ACount++;

		for ( i = 0; i < ArrayCount(AProperty); i++ )
		if ( (AProperty[i] != "") && (AValue[i] != "") && (!SpecialProperty(A,AProperty[i],AValue[i])) )
		A.SetPropertyText(AProperty[i],AValue[i]);

		Reply = A;
	}

	if ( ACount == 0 )
	Sender.ClientMessage("No"@ActorClass@"found.");
	else
	Sender.ClientMessage("Found"@ACount@ActorClass$".");

	if ( !bVerbose || (Reply == None) )
	return;

	Sender.ClientMessage("-------------------------");
	for ( i = 0; i < ArrayCount(AProperty); i++ )
	if ( Reply.GetPropertyText(AProperty[i]) != "" )
	Sender.ClientMessage(AProperty[i]$":"@Reply.GetPropertyText(AProperty[i]));
	else if ( (AProperty[i] ~= "GotoState") || (AProperty[i] ~= "Disable") || (AProperty[i] ~= "Enable") || (AProperty[i] ~= "Reset") || (AProperty[i] ~= "PlayAnim") || (AProperty[i] ~= "LoopAnim") )
	Sender.ClientMessage(AProperty[i]$"():"@AValue[i]);
	Sender.ClientMessage("-------------------------");
}

function TraceSetActorProperty(PlayerPawn Sender, string Cmd)
{
	local Actor A;
	local string S, AProperty[16], AValue[16];
	local int i;
	local vector Dummy;

//	admin TSetA <Property> <Value> <Property> <Value> <Property> <Value> <Property> <Value>

	if ( Cmd == "" )
	{
		Sender.ClientMessage("Missing input.");
		return;
	}

	A = Sender.TraceShot(Dummy,Dummy,Sender.Location+vect(0,0,1)*Sender.EyeHeight+Vector(Sender.ViewRotation)*50000,Sender.Location+vect(0,0,1)*Sender.EyeHeight);

	if ( (A == Level) || (A == None) )
	{
		Sender.ClientMessage("No actor found.");
		return;
	}

	Sender.ClientMessage("Changing properties of"@A.Class);

	for ( i = 0; i < ArrayCount(AProperty); i++ )
	{
		if ( InStr(Cmd," ") == -1 )
		break;

		S = Left(Cmd,InStr(Cmd," "));

		AProperty[i] = S;

		Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);

		if ( InStr(Cmd," ") != -1 )
		S = Left(Cmd,InStr(Cmd," "));
		else
		S = Cmd;

		AValue[i] = S;

		Cmd = Right(Cmd,Len(Cmd)-Len(S)-1);
	}

	for ( i = 0; i < ArrayCount(AProperty); i++ )
	if ( (AProperty[i] != "") && (AValue[i] != "") && (!SpecialProperty(A,AProperty[i],AValue[i])) )
	A.SetPropertyText(AProperty[i],AValue[i]);

	if ( !bVerbose )
	return;

	Sender.ClientMessage("-------------------------");
	for ( i = 0; i < ArrayCount(AProperty); i++ )
	if ( A.GetPropertyText(AProperty[i]) != "" )
	Sender.ClientMessage(AProperty[i]$":"@A.GetPropertyText(AProperty[i]));
	else if ( (AProperty[i] ~= "GotoState") || (AProperty[i] ~= "Disable") || (AProperty[i] ~= "Enable") || (AProperty[i] ~= "Reset") || (AProperty[i] ~= "PlayAnim") || (AProperty[i] ~= "LoopAnim") )
	Sender.ClientMessage(AProperty[i]$"():"@AValue[i]);
	Sender.ClientMessage("-------------------------");
}

function bool SpecialProperty(Actor A, string Property, string Value)
{
	if ( Property ~= "Skin" )
	{
		A.SetPropertyText(Property,Value);
		A.MultiSkins[1] = A.Skin;
		return True;
	}
	else if ( Property ~= "CollisionHeight" )
	{
		A.SetCollisionSize(A.CollisionRadius,Float(Value));
		return True;
	}
	else if ( Property ~= "CollisionRadius" )
	{
		A.SetCollisionSize(Float(Value),A.CollisionHeight);
		return True;
	}
	else if ( Property ~= "bCollideActors" )
	{
		A.SetCollision(Bool(Value));
		return True;
	}
	else if ( Property ~= "Physics" )
	{
		SpecialPhysics(A,Value);
		return True;
	}
	else if ( Property ~= "Location" )
	{
		A.SetLocation(StringToVector(Value));
		return True;
	}
	else if ( Property ~= "Rotation" )
	{
		A.SetRotation(StringToRotator(Value));
		return True;
	}
	else if ( Property ~= "GotoState" )
	{
		A.GotoState(StringToName(Value));
		return True;
	}
	else if ( Property ~= "Disable" )
	{
		A.Disable(StringToName(Value));
		return True;
	}
	else if ( Property ~= "Enable" )
	{
		A.Enable(StringToName(Value));
		return True;
	}
	else if ( Property ~= "Reset" )
	{
		A.Reset();
		return True;
	}
	else if ( (Property ~= "PlayAnim") || (Property ~= "LoopAnim") )
	{
		ActorAnimation(A,Value,InStr(Caps(Property),"LOOP") != -1);
		return True;
	}

	return False;
}

function SpecialPhysics(Actor A, string sPhysics)
{
	if ( sPhysics ~= "PHYS_None" )
	A.SetPhysics(PHYS_None);
	else if ( sPhysics ~= "PHYS_Falling" )
	A.SetPhysics(PHYS_Falling);
	else if ( sPhysics ~= "PHYS_Rotating" )
	A.SetPhysics(PHYS_Rotating);
	else if ( sPhysics ~= "PHYS_Projectile" )
	A.SetPhysics(PHYS_Projectile);
}

function vector StringToVector(string S)
{
	local vector Result;

	S = Right(S,Len(S)-3);

	Result.X = Float(Left(S,InStr(S,",")));

	S = Right(S,Len(S)-InStr(S,",")-3);

	Result.Y = Float(Left(S,InStr(S,",")));

	S = Right(S,Len(S)-InStr(S,",")-3);

	Result.Z = Float(Left(S,InStr(S,")")));

	return Result;
}

function rotator StringToRotator(string S)
{
	local rotator Result;

	S = Right(S,Len(S)-7);

	Result.Pitch = Float(Left(S,InStr(S,",")));

	S = Right(S,Len(S)-InStr(S,",")-5);

	Result.Yaw = Float(Left(S,InStr(S,",")));

	S = Right(S,Len(S)-InStr(S,",")-6);

	Result.Roll = Float(Left(S,InStr(S,")")));

	return Result;
}

function ActorAnimation(Actor A, string Cmd, bool bLoop)
{
	local float Rate;

	if ( A.Mesh == None )
	return;

	Rate = 1;

	if ( InStr(Cmd,"#") != -1 )
	{
		Rate = Float(Right(Cmd,Len(Cmd)-InStr(Cmd,"#")-1));

		if ( Rate != 0 )
		Rate = FClamp(Rate,0.01,10);

		Cmd = Left(Cmd,InStr(Cmd,"#"));
	}

	if ( !A.HasAnim(StringToName(Cmd)) )
	return;

	if ( bLoop )
	A.LoopAnim(StringToName(Cmd),Rate);
	else
	A.PlayAnim(StringToName(Cmd),Rate);
}

function class<Actor> GetActorClass(PlayerPawn Sender, string ClassName)
{
	local class<Actor> ActorClass;

	if ( ClassName == "" )
	{
		Sender.ClientMessage("No class specified.");
		return None;
	}

	ActorClass = class<Actor>(DynamicLoadObject(ClassName,class'Class',True));

	if ( ActorClass == None )
	ActorClass = class<Actor>(DynamicLoadObject("WolfCoop."$ClassName,class'Class',True));

	if ( ActorClass == None )
	ActorClass = class<Actor>(DynamicLoadObject("UnrealI."$ClassName,class'Class',True));

	if ( ActorClass == None )
	ActorClass = class<Actor>(DynamicLoadObject("UnrealShare."$ClassName,class'Class',True));

	if ( ActorClass == None )
	ActorClass = class<Actor>(DynamicLoadObject("Engine."$ClassName,class'Class',True));

	if ( ActorClass == None )
	{
		Sender.ClientMessage("Can't find class '"$ClassName$"'.");
		return None;
	}

	return ActorClass;
}

defaultproperties
{
				BannedWords(0)="nigg"
				BannedWords(1)="n1gg"
				BannedWords(2)="nlgg"
				BannedWords(3)="n i g g"
				BannedWords(4)="n 1 g g"
				BannedWords(5)="nig g"
				BannedWords(6)="n1g g"
				BannedWords(7)="nlg g"
				BannedWords(8)="shemale"
				BannedWords(9)="tranny"
				BannedWords(10)="trannie"
				BannedWords(11)="fag"
				BannedWords(12)="f a g"
				BannedWords(13)="f4g"
				BannedWords(14)="f 4 g"
				BannedWords(15)="nigger"
				BannedWords(16)="n1gger"
				BannedWords(17)="n1gg3r"
				BannedWords(18)="nlgger"
				BannedWords(19)="nlgg3r"
				BannedWords(20)="n i g g e r"
				BannedWords(21)="n 1 g g e r"
				BannedWords(22)="n 1 g g 3 r"
				BannedWords(23)="n l g g e r"
				bNotifyMessages=True
}
