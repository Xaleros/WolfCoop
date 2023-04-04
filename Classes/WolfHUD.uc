//=============================================================================
// WolfHUD.
//=============================================================================
class WolfHUD extends UnrealHUD;

var float DeathTime;
var array<int> HitRot;
var array<float> HitTick;
var array<name> HitType;
var array<byte> HitShielded;
var LevelInfo CurrentLevel;



simulated function PostBeginPlay()
{
	MOTDFadeOutTime=0;
	Super(HUD).PostBeginPlay();
}


simulated function PostRender(canvas Canvas)
{
	local float fVal;
	local string S;
	local int Hours, Minutes, Seconds;
	local string MinuteString, SecondString;


	HUDSetup(canvas);
	

	if ( PlayerPawn(Owner) != None )
	{
		if(PlayerPawn(Owner).PlayerReplicationInfo==None) return;
		if(PlayerPawn(Owner).bShowMenu) DisplayMenu(Canvas);
		if(PlayerPawn(Owner).bShowScores || Level.Pauser!="")
		{
			if ( ( PlayerPawn(Owner).Weapon != None ) && ( !PlayerPawn(Owner).Weapon.bOwnsCrossHair ) )
				DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8, 0.5 * Canvas.ClipY - 8);
			if ( (PlayerPawn(Owner).Scoring == None) && (PlayerPawn(Owner).ScoringType != None) )
				PlayerPawn(Owner).Scoring = Spawn(PlayerPawn(Owner).ScoringType, PlayerPawn(Owner));
			if ( PlayerPawn(Owner).Scoring != None )
				PlayerPawn(Owner).Scoring.ShowScores(Canvas);
		}
		else if ( (PlayerPawn(Owner).Weapon != None) && (Level.LevelAction == LEVACT_None) )
		{
			Canvas.Font = Font'WhiteFont';
			PlayerPawn(Owner).Weapon.PostRender(Canvas);
			if ( !PlayerPawn(Owner).Weapon.bOwnsCrossHair )
				DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8, 0.5 * Canvas.ClipY - 8);
		}
		if ( PlayerPawn(Owner).ProgressTimeOut > Level.TimeSeconds )
			DisplayProgressMessage(Canvas);
	}

	DrawHits(Canvas);
	
	if(wPRI(PlayerPawn(Owner).PlayerReplicationInfo).EndTimer>0)
	{
		Canvas.Style=1;
		if(wPRI(PlayerPawn(Owner).PlayerReplicationInfo).EndTimer<=10)
		Canvas.DrawColor=MakeColor(255,0,0);
		else
		Canvas.DrawColor=MakeColor(255,255,255);
		Canvas.Font=Font(DynamicLoadObject("UWindowFonts.UTFont36", class'Font'));
		Canvas.SetPos(0,Canvas.ClipY*0.15);
		Canvas.bCenter=True;
		Canvas.DrawText(wPRI(PlayerPawn(Owner).PlayerReplicationInfo).EndTimer);
		Canvas.bCenter=False;
		Canvas.DrawColor=MakeColor(255,255,255,255);
	}

	if(wPlayer(Owner).CheckPointTime>0)
	{
		Canvas.Style=3;
		Canvas.DrawColor=MakeColor(200,200,200);
		Canvas.Font=Font'u96f_tech';
		Canvas.SetPos(0,Canvas.ClipY*0.55);
		Canvas.bCenter=True;
		Canvas.DrawText("Type !Checkpoint or !c in chat to quickly respawn to the new Checkpoint ("$wPlayer(Owner).CheckPointTime$")");
		Canvas.SetPos(0,Canvas.ClipY*0.55+12);
		Canvas.DrawText("(Type !n or !ignore in chat to dismiss)");
		Canvas.bCenter=False;
		Canvas.Style=1;
		Canvas.DrawColor=MakeColor(255,255,255,255);
	}

	if(wPlayer(Owner)!=None && wPlayer(Owner).ReviveTarget!=None && wPlayer(Owner).ReviveTarget.ReviveProgress>0)
	{
		fVal=FClamp(wPlayer(Owner).ReviveTarget.ReviveProgress/1,0,1);
		Canvas.DrawColor=MakeColor(255,255,255);
		Canvas.SetPos(Canvas.ClipX/2-256, Canvas.ClipY*0.69);
		Canvas.Style=4;
		Canvas.DrawTileStretched(Texture'ModulatedIcon',Canvas.CurX,Canvas.CurY,Canvas.CurX+512,Canvas.CurY+20);
		Canvas.Style=3;
		Canvas.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',Canvas.CurX,Canvas.CurY,Canvas.CurX+512,Canvas.CurY+20);
		if(wPlayer(Owner).ReviveTarget.ReviveProgress>0.5)
		{
			Canvas.DrawColor.R=255-255*FClamp((wPlayer(Owner).ReviveTarget.ReviveProgress-0.5)/0.5,0,1);
			Canvas.DrawColor.G=255;
			Canvas.DrawColor.B=0;
		}
		else
		{
			Canvas.DrawColor.R=255;
			Canvas.DrawColor.G=255*FClamp(wPlayer(Owner).ReviveTarget.ReviveProgress/0.5,0,1);
			Canvas.DrawColor.B=0;
		}
		Canvas.DrawTileStretched(Texture'WhiteTexture',Canvas.CurX+1,Canvas.CurY+1,Canvas.CurX+1+510*fVal,Canvas.CurY+19);
		Canvas.CurY-=46;
		Canvas.DrawColor=MakeColor(255,255,255);
		Canvas.Font=Font(DynamicLoadObject("UWindowFonts.UTFont36", class'Font'));
		Canvas.DrawText("Reviving "$wPlayer(Owner).ReviveTarget.GetHumanName()$"!");
		Canvas.CurY+=46;
		Canvas.Style=1;
	}

	if(wPlayer(Owner)!=None && wPlayer(Owner).Health<0 && wPlayer(Owner).ReviveProgress>0)
	{
		fVal=FClamp(wPlayer(Owner).ReviveProgress/1,0,1);
		Canvas.DrawColor=MakeColor(255,255,255);
		Canvas.SetPos(Canvas.ClipX/2-256, Canvas.ClipY*0.69);
		Canvas.Style=4;
		Canvas.DrawTileStretched(Texture'ModulatedIcon',Canvas.CurX,Canvas.CurY,Canvas.CurX+512,Canvas.CurY+20);
		Canvas.Style=3;
		Canvas.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',Canvas.CurX,Canvas.CurY,Canvas.CurX+512,Canvas.CurY+20);
		if(wPlayer(Owner).ReviveProgress>0.5)
		{
			Canvas.DrawColor.R=255-255*FClamp((wPlayer(Owner).ReviveProgress-0.75)/0.25,0,1);
			Canvas.DrawColor.G=255;
			Canvas.DrawColor.B=0;
		}
		else
		{
			Canvas.DrawColor.R=255;
			Canvas.DrawColor.G=255*FClamp(wPlayer(Owner).ReviveProgress/0.75,0,1);
			Canvas.DrawColor.B=0;
		}
		Canvas.DrawTileStretched(Texture'WhiteTexture',Canvas.CurX+1,Canvas.CurY+1,Canvas.CurX+1+510*fVal,Canvas.CurY+19);
		Canvas.CurY-=46;
		Canvas.DrawColor=MakeColor(255,255,255);
		Canvas.Font=Font(DynamicLoadObject("UWindowFonts.UTFont36", class'Font'));
		Canvas.DrawText("Being Revived!");
		Canvas.CurY+=46;
		Canvas.Style=1;
	}

	//'You Are Dead' Text
	DrawGameOver(Canvas);

	// Message of the Day / Map Info Header
	if (MOTDFadeOutTime != 0.0)
		DrawMOTD(Canvas);

	Canvas.DrawColor=MakeColor(255,255,255);

	// Display Identification Info
	DrawIdentifyInfo(Canvas, 0, Canvas.ClipY*0.5 + 32.0);

	if (HudMode==5 || Spectator(Owner)!=None || wSpectator(Owner)!=None)
	Return;

	if (Canvas.ClipX<1280 && HudMode < 2) HudMode = 2;


		// Display Armor
		If( HudMode<=1 ) DrawArmor(Canvas, Canvas.ClipX*0.35, Canvas.ClipY-160, False);
		else if (HudMode<=3) DrawArmor(Canvas, 0, Canvas.ClipY-64,False);
		else if (HudMode==4) DrawArmor(Canvas, 0, 0,False);
		ArmorOffset = 0;
	
		// Display Ammo
		if (HudMode<=1) DrawAmmo(Canvas, Canvas.ClipX*0.6335, Canvas.ClipY-128);
		else DrawAmmo(Canvas, Canvas.ClipX-32, Canvas.ClipY-64);
	
		// Display Health
		if (HudMode<2) DrawHealth(Canvas, Canvas.ClipX*0.35, Canvas.ClipY-128);
		else if (HudMode==3||HudMode==2) DrawHealth(Canvas, 0, Canvas.ClipY-32);
		else if (HudMode==4) DrawHealth(Canvas, 0, Canvas.ClipY-32);


		// Display Weapons
		if(HudMode<2) DrawWeapons(Canvas, Canvas.ClipX/2-48, Canvas.ClipY-128);
		else DrawWeapons(Canvas, Canvas.ClipX-96, Canvas.ClipY-32);


		// Display Inventory
	if (HudMode<2) DrawInventory(Canvas, Canvas.ClipX/2-48, Canvas.ClipY-192,False);//96
	else if (HudMode==2) DrawInventory(Canvas, Canvas.ClipX-96, Canvas.ClipY-96,False);
	else if (HudMode==3) DrawInventory(Canvas, Canvas.ClipX-96, 0,False);
	else if (HudMode==4) DrawInventory(Canvas, Canvas.ClipX-96, 0,False);
	
	Canvas.Font = Font'u96f_tech';
	
	// Display Crosshair
	if(bool(Pawn(Owner).Weapon))
	{
		if(Level.LevelAction==LEVACT_None) { Canvas.Font=Font'WhiteFont'; PlayerPawn(Owner).Weapon.PostRender(Canvas); }
		if(PlayerPawn(Owner).Weapon.bOwnsCrosshair) DrawCrossHair(Canvas, Canvas.ClipX/2-8, Canvas.ClipY/2-8);
	}
	
	// Team Game Synopsis
	if ( (PlayerPawn(Owner).GameReplicationInfo != None) && PlayerPawn(Owner).GameReplicationInfo.bTeamGame)
		DrawTeamGameSynopsis(Canvas);

	Canvas.DrawColor=MakeColor(255,255,255);
	Canvas.Style=1;	
}

simulated function DrawMOTD(Canvas C)
{
	local float fVal;
	local float XL,YL,SYL;

	// Join Text.
	if(MOTDFadeOutTime<4)
	{	C.Style=5; C.DrawColor=MakeColor(0,0,0,255*FClamp(2-MOTDFadeOutTime,0,1)); C.SetPos(0,0);
		//C.DrawRect(Texture'BlackTexture',C.ClipX,C.ClipY);
		fVal=FClamp(2*sin(Pi*(FMax(MOTDFadeOutTime-1,0)/3)),0,1);
		C.Font = Font'u96f_huge'; C.StrLen(caps(Level.Title),XL,YL);
		if(XL>(C.ClipX/4))
		{
			C.Font = Font'u96f_huge';
			C.StrLen(caps(Level.Title),XL,YL); C.DrawColor=MakeColor(0*fVal,255*fVal,0*fVal);
			C.Style=3;	C.SetPos(C.ClipX/2-XL/2-8*MOTDFadeOutTime,C.ClipY/4.85-(YL-4)); C.DrawText(caps(Level.Title));
			C.Font = Font'u96f_tech';
			SYL=YL; C.StrLen("Entering:",XL,YL); C.DrawColor=MakeColor(255*fVal,255*fVal,255*fVal);
			C.Style=3; C.SetPos(C.ClipX/2-XL/2-32*MOTDFadeOutTime,C.ClipY/4.85-(SYL+YL)); C.DrawText("Entering:");
			C.StrLen("By:"@Level.Author,XL,YL); C.DrawColor=MakeColor(255*fVal,255*fVal,255*fVal);
			C.Style=3; C.SetPos(C.ClipX/2-XL/2+16*MOTDFadeOutTime,C.ClipY/4.85+4); C.DrawText("By:"@Level.Author);
		}
		else
		{
			C.Font = Font'u96f_huge';
			C.StrLen(caps(Level.Title),XL,YL); C.DrawColor=MakeColor(0*fVal,255*fVal,0*fVal);
			C.Style=3;	C.SetPos(C.ClipX/1.25-XL/2-8*MOTDFadeOutTime,C.ClipY/1.3-(YL-4)); C.DrawText(caps(Level.Title));
			C.Font = Font'u96f_tech';
			SYL=YL; C.StrLen("Entering:",XL,YL); C.DrawColor=MakeColor(255*fVal,255*fVal,255*fVal);
			C.Style=3; C.SetPos(C.ClipX/1.25-XL/2-32*MOTDFadeOutTime,C.ClipY/1.3-(SYL+YL)); C.DrawText("Entering:");
			C.StrLen("By:"@Level.Author,XL,YL); C.DrawColor=MakeColor(255*fVal,255*fVal,255*fVal);
			C.Style=3; C.SetPos(C.ClipX/1.25-XL/2+16*MOTDFadeOutTime,C.ClipY/1.3+4); C.DrawText("By:"@Level.Author);
		}
	}
}

simulated function DrawDeathPanels(Canvas C)
{
	local vector CamSize;
	local int I;
	
/*	if(RLSpectator(Owner)!=None && RLSpectator(Owner).bBeingAllowed) return;

	C.SetPos(0,0);
	C.DrawRect(Texture'BlackTexture',C.ClipX,C.ClipY);

	if(RLPlayer(PlayerPawn(Owner).ViewTarget)!=None && !PlayerPawn(Owner).bBehindView)
	{
		DrawPlayerHUD(C, 0,0, C.ClipX, C.ClipY, RLPlayer(PlayerPawn(Owner).ViewTarget));
		return;
	}

	ForEach AllActors(class'PlayerPawn',P)
	if(P!=Owner && !RLPRI(P.PlayerReplicationInfo).bVoteEnd && RLPRI(P.PlayerReplicationInfo).bInvader==RLPRI(Pawn(Owner).PlayerReplicationInfo).bInvader && P.Health>0 && Array_Size(Players)<9) Players[Array_Size(Players)]=P;
	if(Array_Size(Players)==0) return;
		
	For(I=0; I<Array_Size(Players); I++)
	{
		P=Players[I];
		if(Array_Size(Players)==9)
		{
			CamSize=(C.ClipX/3)*vect(1,0,0) + (C.ClipY/3)*vect(0,1,0);
			DrawPlayerHUD(C, CamSize.X*(I%3), CamSize.Y*(I/3), CamSize.X, CamSize.Y, P);
		}
		else if(Array_Size(Players)==7 || Array_Size(Players)==8)
		{
			CamSize=(C.ClipX/4)*vect(1,0,0) + (C.ClipY/2)*vect(0,1,0);
			DrawPlayerHUD(C, CamSize.X*(I%4), CamSize.Y*(I/4), CamSize.X, CamSize.Y, P);
		}
		else if(Array_Size(Players)==5 || Array_Size(Players)==6)
		{
			CamSize=(C.ClipX/3)*vect(1,0,0) + (C.ClipY/2)*vect(0,1,0);
			DrawPlayerHUD(C, CamSize.X*(I%3), CamSize.Y*(I/3), CamSize.X, CamSize.Y, P);
		}
		else if(Array_Size(Players)==3 || Array_Size(Players)==4)
		{
			CamSize=(C.ClipX/2)*vect(1,0,0) + (C.ClipY/2)*vect(0,1,0);
			DrawPlayerHUD(C, CamSize.X*(I%2), CamSize.Y*(I/2), CamSize.X, CamSize.Y, P);
		}
		else if(Array_Size(Players)==2)
		{
			CamSize=(C.ClipX/2)*vect(1,0,0) + C.ClipY*vect(0,1,0);
			DrawPlayerHUD(C, CamSize.X*I, 0, CamSize.X, CamSize.Y, P);
		}
		else DrawPlayerHUD(C, 0,0, C.ClipX,C.ClipY, P);
	}*/
}

simulated function DrawGameOver(Canvas C)
{

	C.Style=5;

	if(DeathTime>0)
	{
		C.SetPos(C.ClipX*0.25,C.ClipY*0.25);
		C.DrawColor.R=255*DeathTime;
		C.DrawColor.G=255*DeathTime;
		C.DrawColor.B=255*DeathTime;
		C.DrawColor.A=255*DeathTime;
		C.DrawRect(Texture'GameOver',C.ClipX*0.5,C.ClipY*0.25); 
	}
	C.Style=1;
	C.DrawColor=MakeColor(255,255,255);
}

simulated function DrawPlayerHUD(Canvas C, float X, float Y, float XL, float YL, PlayerPawn P)
{
	local vector CamLoc;
	local rotator CamRot;
	
	if(PlayerPawn(Owner).ViewTarget==P && !PlayerPawn(Owner).bBehindView)
	{
		CamLoc=P.Location + ((P.CollisionHeight*vect(0,0,0.8))>>P.Rotation) + ((P.CollisionRadius*vect(-1.5,0.75,0))>>P.ViewRotation);
		CamRot=P.ViewRotation;
	}
	else
	{
		CamLoc=P.Location + ((P.CollisionHeight*vect(0,0,0.8))>>P.Rotation) + ((P.CollisionRadius*vect(-1.5,0.75,0))>>P.Rotation);
		CamRot=P.Rotation;
	}
	C.DrawPortal(X,Y, XL, YL, P, CamLoc, CamRot, PlayerPawn(Owner).FOVAngle);
	if(PlayerPawn(Owner).ViewTarget==P)
	{
		C.DrawColor.R=0;
		C.DrawColor.G=255;
		C.DrawColor.B=0;
		C.Style=2;
		C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection', X,Y, X+XL,Y+YL);
		C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection', X+2,Y+2, X+XL-2,Y+YL-2);
		C.DrawColor.R=255;
		C.DrawColor.G=255;
		C.DrawColor.B=255;
		C.Style=1;
	}
	
	C.DrawColor.R=255;
	C.DrawColor.G=255;
	C.DrawColor.B=255;
	C.Font=Font(DynamicLoadObject("UWindowFonts.Tahoma12", class'Font'));
	C.SetPos(X+6,Y+YL-16);
	C.DrawText(P.PlayerReplicationInfo.PlayerName);
}

simulated function bool TraceIdentify(canvas Canvas)
{
	local actor Other;
	local vector HitLocation, HitNormal, StartTrace, EndTrace;

	if(Pawn(PlayerPawn(Owner).ViewTarget)!=None)
	{
		IdentifyTarget=Pawn(PlayerPawn(Owner).ViewTarget);
		IdentifyFadeTime = 3.0;
		return true;
	}

	StartTrace = Owner.Location;
	StartTrace.Z += Pawn(Owner).BaseEyeHeight;

	EndTrace = StartTrace + vector(Pawn(Owner).ViewRotation) * 1000.0;

	Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

	if ( (Pawn(Other) != None) )
	{
		IdentifyTarget = Pawn(Other);
		IdentifyFadeTime = 3.0;
	}

	if ( IdentifyFadeTime == 0.0 )
		return false;

	if ( (IdentifyTarget == None) ||
		 (IdentifyTarget.bHidden) )
		return false;

	return true;
}


simulated function DrawIdentifyInfo(canvas Canvas, float PosX, float PosY)
{
	local float XL, YL, Health;
	local string XTra, TargetName;

	if (!TraceIdentify(Canvas))
		return;

	Canvas.Font = font'u96f_tech';
	Canvas.Style = 3;
	if(IdentifyTarget != none)
	{
		Xtra="";
		if( IdentifyTarget.playerreplicationinfo != None  )
		{
			if( wPlayer(IdentifyTarget)!=None && wPlayer(IdentifyTarget).RepTyping )
				xTra = "(Typing...)";
			else if( wPlayer(IdentifyTarget)!=None && wPlayer(IdentifyTarget).bAFK )
				xTra = "(AFK)";
			Canvas.Drawcolor.R = 0;
			Canvas.Drawcolor.G = 255 *(IdentifyFadeTime / 3.0);
			Canvas.Drawcolor.B = 0;
			Canvas.StrLen( IdentifyTarget.PlayerReplicationInfo.PlayerName@xtra, XL, YL );	
			Canvas.SetPos( (Canvas.ClipX/2) - (XL/2), (Canvas.ClipY*0.66) - YL );
			Canvas.DrawText(IdentifyTarget.Playerreplicationinfo.PlayerName@xtra );
		}
		else
		{
			if( IdentifyTarget.MenuName!="" )
			TargetName=IdentifyTarget.MenuName;
			else
			TargetName=""$IdentifyTarget.Class.Name;
			if(ScriptedPawn(IdentifyTarget)!=None && ScriptedPawn(IdentifyTarget).bIsBoss)
			{
				Canvas.DrawColor.R = 255 *(IdentifyFadeTime / 3.0);
				Canvas.DrawColor.G = 200 *(IdentifyFadeTime / 3.0);
				Canvas.DrawColor.B = 48 *(IdentifyFadeTime / 3.0);
			}
			else
			{
				Canvas.DrawColor.R = 255 *(IdentifyFadeTime / 3.0);
				Canvas.DrawColor.G = 255 *(IdentifyFadeTime / 3.0);
				Canvas.DrawColor.B = 255 *(IdentifyFadeTime / 3.0);
			}
			if(IdentifyTarget.NameArticle~=" the ")
			{TargetName="The "$TargetName;}

			Canvas.StrLen( TargetName, XL, YL );
			Canvas.SetPos( (Canvas.ClipX/2) - (XL/2), (Canvas.ClipY*0.66) - YL );
			Canvas.DrawText( TargetName );
		}

		Canvas.Drawcolor.R = 255 *(IdentifyFadeTime / 3.0);
		Canvas.Drawcolor.G = 255 *(IdentifyFadeTime / 3.0);
		Canvas.Drawcolor.B = 255 *(IdentifyFadeTime / 3.0);

		if(LeglessKrall(IdentifyTarget)!=None || (WarLord(IdentifyTarget)!=None && WarLord(IdentifyTarget).bTeleportWhenHurt && WarLord(IdentifyTarget).IsInState('Teleporting')))
		{
			Canvas.StrLen( "HP:"@1, XL, YL );
			Canvas.SetPos( (Canvas.clipx/2) - (XL/2), (Canvas.ClipY*0.66)+4 );
			//Canvas.DrawText( "HP:"@IdentifyTarget.Health );
			Canvas.DrawText( "HP:" );
	
			Canvas.DrawColor.R=255;
			Canvas.DrawColor.G=1;
			Canvas.DrawColor.B=0;

	
			Canvas.Drawcolor.R = Canvas.DrawColor.R * (IdentifyFadeTime / 3.0);
			Canvas.Drawcolor.G = Canvas.DrawColor.G * (IdentifyFadeTime / 3.0);
			Canvas.Drawcolor.B = Canvas.DrawColor.B * (IdentifyFadeTime / 3.0);
			
			if( IdentifyTarget.Health <= 0 )
			{
				Canvas.Drawcolor.R=255 * (IdentifyFadeTime / 3.0); Canvas.DrawColor.G=0; Canvas.DrawColor.B=0;
				Canvas.SetPos( (Canvas.clipx/2) - (XL/2) + 30, (Canvas.ClipY*0.66) +4 );
				Canvas.StrLen( "HP:"@0, XL, YL );
				Canvas.DrawText( 0 );
			}
			else
			{
				Canvas.SetPos( (Canvas.clipx/2) - (XL/2) + 30, (Canvas.ClipY*0.66) +4 );
				Canvas.DrawText( 1 );
			}
		}
		else
		{
			Canvas.StrLen( "HP:"@IdentifyTarget.Health, XL, YL );
			Canvas.SetPos( (Canvas.clipx/2) - (XL/2), (Canvas.ClipY*0.66)+4 );
			//Canvas.DrawText( "HP:"@IdentifyTarget.Health );
			Canvas.DrawText( "HP:" );
	
			Health=float(IdentifyTarget.Health)/float(IdentifyTarget.Default.Health);
			if(Health>1)
			{
				Canvas.DrawColor.R=0;
				Canvas.DrawColor.G=255;
				Canvas.DrawColor.B=255*FClamp(Health-1.0,0,1);
			}
			else if(Health>0.75)
			{
				Canvas.DrawColor.R=255-255*FClamp((Health-0.75)/0.25,0,1);
				Canvas.DrawColor.G=255;
				Canvas.DrawColor.B=0;
			}
			else
			{
				Canvas.DrawColor.R=255;
				Canvas.DrawColor.G=255*FClamp(Health/0.75,0,1);
				Canvas.DrawColor.B=0;
			}
	
			Canvas.Drawcolor.R = Canvas.DrawColor.R * (IdentifyFadeTime / 3.0);
			Canvas.Drawcolor.G = Canvas.DrawColor.G * (IdentifyFadeTime / 3.0);
			Canvas.Drawcolor.B = Canvas.DrawColor.B * (IdentifyFadeTime / 3.0);
			
			if( IdentifyTarget.Health <= 0 )
			{
				Canvas.Drawcolor.R=255 * (IdentifyFadeTime / 3.0); Canvas.DrawColor.G=0; Canvas.DrawColor.B=0;
				Canvas.SetPos( (Canvas.clipx/2) - (XL/2) + 30, (Canvas.ClipY*0.66) +4 );
				Canvas.StrLen( "HP:"@0, XL, YL );
				Canvas.DrawText( 0 );
			}
			else
			{
				Canvas.SetPos( (Canvas.clipx/2) - (XL/2) + 30, (Canvas.ClipY*0.66) +4 );
				Canvas.DrawText( IdentifyTarget.Health );
			}
		}
	}

	if(IdentifyTarget==wPlayer(Owner).LastDamageTarget && wPlayer(Owner).LastDamageTick>0)
	{
		Canvas.DrawColor.R = 255*wPlayer(Owner).LastDamageTick;
		Canvas.DrawColor.G = 0;
		Canvas.DrawColor.B = 0;
		Canvas.StrLen( "-"$wPlayer(Owner).LastDamageAmount, XL, YL );
		Canvas.SetPos( (Canvas.clipx/2) - (XL/2), (Canvas.ClipY*0.66) +16 );
		Canvas.DrawText( "-"$wPlayer(Owner).LastDamageAmount );

	}

	Canvas.Style = 1;
	Canvas.DrawColor.R = 255;
	Canvas.DrawColor.G = 255;
	Canvas.DrawColor.B = 255;
}

/*simulated function DrawIdentifyInfo(canvas C, float PosX, float PosY) // Project Gryphon Health Bar attempt
{
	local float Health,fVal,XL,YL,OverHealth;
	local vector HudLoc;

	if(	!TraceIdentify(C) || IdentifyTarget.bHidden || IdentifyTarget.Health<=0 ) return;

	C.Font = Font(DynamicLoadObject("UWindowFonts.UTFont14B", class'Font'));
	fVal=FClamp(1.0-VSize(IdentifyTarget.Location-C.GetCameraCoords().Origin)/1000,0,1);
	HudLoc=C.WorldToScreen(IdentifyTarget.Location+IdentifyTarget.CollisionHeight*vect(0,0,1.4), Health);
	if(HudLoc.Z!=-1 && HudLoc.X<C.ClipX)
	{
			Health=float(IdentifyTarget.Health)/float(IdentifyTarget.Default.Health);
			if(Health>1)
			{
				C.DrawColor.R=0;
				C.DrawColor.G=255;
				C.DrawColor.B=255*FClamp(Health-1.0,0,1);
			}
			else if(Health>0.75)
			{
				C.DrawColor.R=255-255*FClamp((Health-0.75)/0.25,0,1);
				C.DrawColor.G=255;
				C.DrawColor.B=0;
			}
			else
			{
				C.DrawColor.R=255;
				C.DrawColor.G=255*FClamp(Health/0.75,0,1);
				C.DrawColor.B=0;
			}
			fVal=FClamp(1.0-VSize(IdentifyTarget.Location-C.GetCameraCoords().Origin)/1000,0,1);
			C.DrawColor.R=255*fVal;
			C.DrawColor.G=255*fVal;
			C.DrawColor.B=255*fVal;

			if(bool(PlayerPawn(IdentifyTarget))||bool(Bots(IdentifyTarget)))
			{
				C.StrLen(IdentifyTarget.GetHumanName(),XL,YL);
				C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*2));
				if(wPlayer(IdentifyTarget)!=None && wPlayer(IdentifyTarget).bAFK)
				C.DrawText(IdentifyTarget.GetHumanName()@"(AFK)");
				else if(wPlayer(IdentifyTarget)!=None && wPlayer(IdentifyTarget).RepTyping)
				C.DrawText(IdentifyTarget.GetHumanName()@"(Typing)");
				else
				C.DrawText(IdentifyTarget.GetHumanName());
			}
			else if(IdentifyTarget.MenuName!="")
			{
				if(IdentifyTarget.NameArticle~=" the ")
				C.StrLen("The "$IdentifyTarget.MenuName,XL,YL);
				else
				C.StrLen(IdentifyTarget.MenuName,XL,YL);
				if(bool(ScriptedPawn(IdentifyTarget)) && ScriptedPawn(IdentifyTarget).bIsBoss)
				{	C.DrawColor.R=255*fVal;
					C.DrawColor.G=200*fVal;
					C.DrawColor.B=48*fVal;
					C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*2));
					C.Style=3;
					C.DrawRect(Texture'UnrealShare.Effect56.FireEffect56',XL,YL);
					C.Style=1;
				}				
				C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*2));
				if(IdentifyTarget.NameArticle~=" the ")
				C.DrawText("The "$IdentifyTarget.MenuName);
				else
				C.DrawText(IdentifyTarget.MenuName);
			}
			else
			{
				if(IdentifyTarget.NameArticle~=" the ")
				C.StrLen("The "$IdentifyTarget.Class.Name,XL,YL);
				else
				C.StrLen(IdentifyTarget.Class.Name,XL,YL);
				if(bool(ScriptedPawn(IdentifyTarget)) && ScriptedPawn(IdentifyTarget).bIsBoss)
				{
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=200*fVal;
					C.DrawColor.B=48*fVal;
					C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*2));
					C.Style=3;
					C.DrawRect(Texture'UnrealShare.Effect56.FireEffect56',XL,YL);
					C.Style=1;
				}
				C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*2));
				if(IdentifyTarget.NameArticle~=" the ")
				C.DrawText("The "$IdentifyTarget.Class.Name);
				else
				C.DrawText(IdentifyTarget.Class.Name);
			}

			C.SetPos((HudLoc.X-int(XL/2))-15,HudLoc.Y-int(YL*1));

			C.DrawColor.R=255*fVal;
			C.DrawColor.G=255*fVal;
			C.DrawColor.B=255*fVal;
			C.Style=4;
			if(fVal>0.2)
			C.DrawTileStretched(Texture'ModulatedIcon',C.CurX,C.CurY,C.CurX+60,C.CurY+8);
			C.Style=3;

			if(Health>1)
			{
				if(Health>6)
				{
					C.DrawColor.R=20*fVal;
					C.DrawColor.G=20*fVal;
					C.DrawColor.B=20*fVal;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*6.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=150*fVal;
					C.DrawColor.G=150*fVal;
					C.DrawColor.B=150*fVal;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				else if(Health>5)
				{
					C.DrawColor.R=150*fVal;
					C.DrawColor.G=150*fVal;
					C.DrawColor.B=150*fVal;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*5.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=200*fVal;
					C.DrawColor.G=120*fVal;
					C.DrawColor.B=0;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				else if(Health>4)
				{
					C.DrawColor.R=200*fVal;
					C.DrawColor.G=120*fVal;
					C.DrawColor.B=0;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*4.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=60*fVal;
					C.DrawColor.G=0;
					C.DrawColor.B=200*fVal;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				else if(Health>3)
				{
					C.DrawColor.R=60*fVal;
					C.DrawColor.G=0;
					C.DrawColor.B=200*fVal;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*3.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=0;
					C.DrawColor.G=50*fVal;
					C.DrawColor.B=200*fVal;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				else if(Health>2)
				{
					C.DrawColor.R=0;
					C.DrawColor.G=50*fVal;
					C.DrawColor.B=200*fVal;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*2.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=0;
					C.DrawColor.G=150*fVal;
					C.DrawColor.B=0;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				else
				{
					C.DrawColor.R=0;
					C.DrawColor.G=150*fVal;
					C.DrawColor.B=0;
					OverHealth=FClamp(((IdentifyTarget.Health*1.0)-(IdentifyTarget.Default.Health*1.0))/(IdentifyTarget.Default.Health*1.0),0,1);
					C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=200*fVal;
					C.DrawColor.G=0;
					C.DrawColor.B=0;
					C.DrawTileStretched(Texture'HUDLine',C.CurX+60,C.CurY+1,C.CurX+(60*OverHealth),C.CurY+7);
					C.DrawColor.R=255*fVal;
					C.DrawColor.G=255*fVal;
					C.DrawColor.B=255*fVal;
					C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*OverHealth),C.CurY+8);
				}
				Health=1;
			}

			C.DrawColor.R=255*fVal;
			C.DrawColor.G=0;
			C.DrawColor.B=0;
			C.DrawTileStretched(Texture'HUDLine',C.CurX+1,C.CurY+1,C.CurX+(60*Health),C.CurY+7);
			C.DrawColor.R=255*fVal;
			C.DrawColor.G=255*fVal;
			C.DrawColor.B=255*fVal;
			C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+(60*Health),C.CurY+8);
			C.DrawTileStretched(Texture'UnrealShare.Icons.IconSelection',C.CurX,C.CurY,C.CurX+60,C.CurY+8);
			C.CurX+=2;
			C.Font = Font'u96f_tech';
			C.DrawText(IdentifyTarget.Health);
			C.DrawColor.R=0;
			C.DrawColor.G=255;
			C.DrawColor.B=0;
	}
}*/

simulated function bool DisplayMessages( canvas Canvas )
{
	local float XL, YL, SaveX;
	local int I, J, J2, J3, J4, YPos;
	local float PickupColor,PickupMessageTick[12],RedMessageTick[12];
	local console Console;
	local MessageStruct ShortMessages[12], PickupMessages[4], CriticalMessage[4], FuckUSweeny;
	local string MessageString[12], PickupMessageStrings[4], CriticalMessageStrings[4];
	local name MsgType;
	local color SaveColor;

	Console = PlayerPawn(Owner).Player.Console;

	Canvas.Font = Font(DynamicLoadObject("UWindowFonts.UTFont14B", class'Font'));

	//Canvas.Font = Font'WhiteFont';
	//Canvas.Font = Canvas.MedFont;

	if ( !Console.Viewport.Actor.bShowMenu )
		DrawTypingPrompt(Canvas, Console);

	if ( (Console.TextLines > 0) && (!Console.Viewport.Actor.bShowMenu || Console.Viewport.Actor.bShowScores) )
	{
		Canvas.bCenter = false;
		Canvas.Style = 1;
		Canvas.Font = Font(DynamicLoadObject("UWindowFonts.UTFont14B", class'Font'));

		J = Console.TopLine;
		I = 0;
		while ( (I < 12) && (J >= 0) )
		{
			MsgType = Console.GetMsgType(J);
			if ((MsgType != '') && (MsgType != 'Log'))
			{
				MessageString[I] = Console.GetMsgText(J);
				if ( (MessageString[I] != "") && (Console.GetMsgTick(J) > 0.0) )
				{
					if ( (MsgType == 'Event') || (MsgType == 'DeathMessage') || (MsgType == 'CriticalEvent') || (MsgType == 'LowCriticalEvent') || (MsgType == 'RedCriticalEvent') || (MsgType == 'Pickup') )
					{
						ShortMessages[I].PRI = None;
						ShortMessages[I].Type = MsgType;
						PickupMessageTick[I]=Console.GetMsgTick(J);
						RedMessageTick[I]=Console.GetMsgTick(J);
						I++;
					}
					else if ( (MsgType == 'Say') || (MsgType == 'TeamSay') )
					{
						ShortMessages[I].PRI = Console.GetMsgPlayer(J);
						ShortMessages[I].Type = MsgType;
						I++;
					}
				}
			}
			J--;
		}

		J  = 0;
		J2 = 0;
		J3 = 0;
		J4 = 0;
		
		for ( I=0; I<12; I++ )
		if ( Len(MessageString[11 - I])!=0 )	
		{
			Canvas.Font = Font(DynamicLoadObject("UWindowFonts.UTFont14B", class'Font'));
			Canvas.bCenter = false;
			YPos = Canvas.ClipY/1.465 + J;
			if ( !DrawMessageHeader(Canvas, ShortMessages[11 - I], YPos) )
			{
				if (ShortMessages[11 - I].Type == 'DeathMessage')
				Canvas.DrawColor = RedColor;
				else
				{
					Canvas.DrawColor.r = 200;
					Canvas.DrawColor.g = 200;
					Canvas.DrawColor.b = 200;
				}
				Canvas.SetPos(0, YPos);
			}
			if ( !SpecialType(ShortMessages[11 - I].Type) )
			{
				if(ShortMessages[11 - I].PRI!=None)
				{
					if(ShortMessages[11-I].PRI.bIsSpectator)
					Canvas.StrLen(ShortMessages[11 - I].PRI.PlayerName$":(Spectating) "$MessageString[11-I],XL,YL);
					else if(Pawn(ShortMessages[11-I].PRI.Owner).Health<=0)
					Canvas.StrLen(ShortMessages[11 - I].PRI.PlayerName$":(Dead) "$MessageString[11-I],XL,YL);
					else
					Canvas.StrLen(ShortMessages[11 - I].PRI.PlayerName$": "$MessageString[11-I],XL,YL);
				}
				else
				Canvas.StrLen(MessageString[11-I],XL,YL);
				Canvas.Style=4;
				SaveColor=Canvas.DrawColor;
				Canvas.DrawColor=MakeColor(255,255,255,255);
				SaveX=Canvas.CurX;
				Canvas.SetPos(0,YPos);
				Canvas.DrawRect(Texture'ModulatedIcon',XL+2,YL);
				Canvas.DrawColor=SaveColor;
				Canvas.Style=1;
				if(ShortMessages[11 - I].Type!='Say'&&ShortMessages[11 - I].Type!='TeamSay')
				{
					Canvas.SetPos(0,YPos);
					Canvas.DrawText(MessageString[11-I], false );}
					else
					{Canvas.SetPos(SaveX,YPos);
					Canvas.DrawText(MessageString[11-I], false );
					Canvas.SetPos(0,YPos);
					FuckUSweeny=ShortMessages[11-I];
					Canvas.MakeColor(0,255,0);
					Canvas.DrawText(ShortMessages[11-I].PRI.PlayerName$": ", false );
				}
				Canvas.DrawColor=MakeColor(255,255,255,255);
				J+=YL;
			}
			else
			{
				Canvas.Font = Font'u96f_tech';
				Canvas.bCenter = true;
				if ( ShortMessages[11-I].Type=='Pickup' )
				{
					if ( Level.bHighDetailMode )
						Canvas.Style = ERenderStyle.STY_Translucent;
					else
						Canvas.Style = ERenderStyle.STY_Normal;
					PickupColor = 42.0 * FMin(6, PickupMessageTick[11-I]);
					Canvas.DrawColor.r = PickupColor;
					Canvas.DrawColor.g = PickupColor;
					Canvas.DrawColor.b = PickupColor;
					Canvas.SetPos(0, (Canvas.ClipY*0.7)+J2);
					Canvas.StrLen(MessageString[11-I],XL,YL);
					Canvas.DrawText( MessageString[11-I], true );
					J2+=YL;
				}
				if ( ShortMessages[11-I].Type=='CriticalEvent' )
				{
					Canvas.Style=1;
					Canvas.DrawColor.r = 0;
					Canvas.DrawColor.g = 128;
					Canvas.DrawColor.b = 255;
					Canvas.SetPos(0, Console.FrameY/2 + 32+J3);
					Canvas.StrLen(MessageString[11-I],XL,YL);
					Canvas.DrawText( MessageString[11-I], true );
					J3+=YL;
				}	
				if ( ShortMessages[11-I].Type=='LowCriticalEvent' )
				{
					Canvas.Style=1;
					Canvas.DrawColor.r = 0;
					Canvas.DrawColor.g = 128;
					Canvas.DrawColor.b = 255;
					Canvas.SetPos(0, Console.FrameY/2 + 32+J3);
					Canvas.StrLen(MessageString[11-I],XL,YL);
					Canvas.DrawText( MessageString[11-I], true );
					J3+=YL;
				}	
				if ( ShortMessages[11-I].Type=='RedCriticalEvent' )
				{
					if ( Level.bHighDetailMode )
						Canvas.Style = ERenderStyle.STY_Translucent;
					else
						Canvas.Style = ERenderStyle.STY_Normal;
					Canvas.DrawColor.r = 255.0 * FMin(6, 0.5*RedMessageTick[11-I]);
					Canvas.DrawColor.g = 16.0;
					Canvas.DrawColor.b = 16.0;
					Canvas.SetPos(0, Canvas.ClipY*0.35+J4);
					Canvas.StrLen(MessageString[11-I],XL,YL);
					Canvas.DrawText( MessageString[11-I], true );
					J4+=YL;
				}
			}
		}
	}
	Canvas.bCenter = false;
	Canvas.Style = 1;
	Canvas.DrawColor=MakeColor(255,255,255,255);

	return true;
}

simulated function bool SpecialType(Name Type)
{
	if (Type == '') return true;
	if (Type == 'Log') return true;
	if (Type == 'Pickup') return true;
	if (Type == 'CriticalEvent') return true;
	if (Type == 'LowCriticalEvent') return true;
	if (Type == 'RedCriticalEvent') return true;
	return false;
}

simulated function float DrawNextMessagePart( Canvas Canvas, coerce string MString, float XOffset, int YPos )
{
	local float XL, YL;

	Canvas.SetPos(XOffset, YPos);
	Canvas.StrLen( MString, XL, YL );
	XOffset += XL;
	Canvas.DrawText( MString, false );
	return XOffset;
}

simulated function bool DrawMessageHeader(Canvas Canvas, MessageStruct ShortMessage, int YPos)
{
	local float XOffset;

	//XOffset=Canvas.ClipX/8;

	if ( ShortMessage.Type=='Say' ) Canvas.DrawColor = GreenColor;
	else if ( ShortMessage.Type=='TeamSay' ) // 227f: Show teamchat in yellow.
	{
		Canvas.DrawColor.R = 255;
		Canvas.DrawColor.G = 255;
		Canvas.DrawColor.B = 0;
	}
	else return false;

	//XOffset += ArmorOffset;
	Canvas.SetPos(XOffset, YPos);
	if ( ShortMessage.PRI!=None && !ShortMessage.PRI.bDeleteMe )
	{
		if(ShortMessage.PRI.bIsSpectator)
			XOffset = DrawNextMessagePart(Canvas, ShortMessage.PRI.PlayerName$":(Spectating) ", XOffset, YPos);
		else if(Pawn(ShortMessage.PRI.Owner).Health<=0)
			XOffset = DrawNextMessagePart(Canvas, ShortMessage.PRI.PlayerName$":(Dead) ", XOffset, YPos);
		else
			XOffset = DrawNextMessagePart(Canvas, ShortMessage.PRI.PlayerName$": ", XOffset, YPos);
	}
	else
	XOffset = DrawNextMessagePart(Canvas, SomeoneName$": ", XOffset, YPos);
	Canvas.SetPos( XOffset, YPos);
	//Canvas.SetPos(4 + XOffset,Canvas.ClipY/2);

	if ( ShortMessage.Type=='Say' ) Canvas.DrawColor = GreenColor;
	else if ( ShortMessage.Type=='TeamSay' ) // 227f: Show teamchat in yellow.
	{
		Canvas.DrawColor.R = 255;
		Canvas.DrawColor.G = 255;
		Canvas.DrawColor.B = 0;
	}

	return true;
}

simulated function DrawInventory(Canvas Canvas, int X, int Y, bool bDrawOne)
{
	local bool bGotNext, bGotPrev, bGotSelected;
	local inventory Inv,Prev, Next, SelectedItem;
	local translator Translator;
	local int j;

	if ( Owner.Inventory==None) Return;
	bGotSelected = False;
	bGotNext = false;
	bGotPrev = false;
	Prev = None;
	Next = None;
	SelectedItem = Pawn(Owner).SelectedItem;

	for ( Inv=Owner.Inventory; Inv!=None && j++ < 500; Inv=Inv.Inventory )
	{
		if ( !bDrawOne ) // if drawing more than one inventory, find next and previous items
		{
			if ( Inv == SelectedItem )
				bGotSelected = True;
			else if ( Inv.bActivatable )
			{
				if ( bGotSelected )
				{
					if ( !bGotNext )
					{
						Next = Inv;
						bGotNext = true;
					}
					else if ( !bGotPrev )
						Prev = Inv;
				}
				else
				{
					if ( Next == None )
						Next = Prev;
					Prev = Inv;
					bGotPrev = True;
				}
			}
		}

		if ( Translator(Inv) != None )
			Translator = Translator(Inv);
	}

	// List Translator messages if activated
	if ( Translator!=None )
	{
		if ( Translator.bCurrentlyActivated )
		{
			Translator.DrawTranslator(Canvas);
			HUDSetup(Canvas);
		}
		else
			bFlashTranslator = ( Translator.bNewMessage || Translator.bNotNewMessage );
	}

	if ( HUDMode == 5 )
		return;

	if ( SelectedItem != None )
	{
		Count++;
		if (Count>20) Count=0;

		if (Prev!=None)
		{
			if ( Prev.bActive || (bFlashTranslator && (Translator == Prev) && (Count>15)) )
			{
				Canvas.DrawColor.b = 0;
				Canvas.DrawColor.g = 0;
			}
			Canvas.Style=3;
			DrawHudIcon(Canvas, X, Y, Prev);
			if ( (Pickup(Prev) != None) && Pickup(Prev).bCanHaveMultipleCopies  && PickUp(Prev).NumCopies>0 )
				DrawNumberOf(Canvas,Pickup(Prev).NumCopies+1,X,Y);
			Canvas.DrawColor.b = 255;
			Canvas.DrawColor.g = 255;
		}
		else
		DrawEmptyIcon(Canvas,X,Y);
		if ( SelectedItem.Icon != None )
		{
			Canvas.Style=3;
			if ( SelectedItem.bActive || (bFlashTranslator && (Translator == SelectedItem) && (Count>15)) )
			{
				Canvas.DrawColor.b = 0;
				Canvas.DrawColor.g = 0;
			}
			if ( (Next==None) && (Prev==None) && !bDrawOne) DrawHudIcon(Canvas, X+64, Y, SelectedItem);
			else DrawHudIcon(Canvas, X+32, Y, SelectedItem);
			Canvas.Style = 2;
			Canvas.CurX = X+32;
			if ( (Next==None) && (Prev==None) && !bDrawOne ) Canvas.CurX = X+64;
			Canvas.CurY = Y;
			Canvas.DrawIcon(texture'IconSelection', 1.0);
			if ( (Pickup(SelectedItem) != None)
					&& Pickup(SelectedItem).bCanHaveMultipleCopies  && PickUp(SelectedItem).NumCopies>0 )
				DrawNumberOf(Canvas,Pickup(SelectedItem).NumCopies+1,Canvas.CurX-32,Y);
			Canvas.DrawColor.b = 255;
			Canvas.DrawColor.g = 255;
		}
		if (Next!=None)
		{
			Canvas.Style=3;
			if ( Next.bActive || (bFlashTranslator && (Translator == Next) && (Count>15)) )
			{
				Canvas.DrawColor.b = 0;
				Canvas.DrawColor.g = 0;
			}
			DrawHudIcon(Canvas, X+64, Y, Next);
			if ( (Pickup(Next) != None) && Pickup(Next).bCanHaveMultipleCopies && PickUp(Next).NumCopies>0 )
				DrawNumberOf(Canvas,Pickup(Next).NumCopies+1,Canvas.CurX-32,Y);
			Canvas.DrawColor.b = 255;
			Canvas.DrawColor.g = 255;
		}
		else if(Prev==None)
		DrawEmptyIcon(Canvas,X+32,Y);
		else
		DrawEmptyIcon(Canvas,X+64,Y);
	}
	else
	{
		DrawEmptyIcon(Canvas,X,Y);
		DrawEmptyIcon(Canvas,X+32,Y);
		DrawEmptyIcon(Canvas,X+64,Y);
	}
	Canvas.Style=ERenderStyle.STY_Normal;
}



simulated function DrawHits(Canvas C)
{
	local float Scale;
	local float fVal;
	local int I;
	
	Scale=FMin(C.ClipX,C.ClipY)/1024;
	C.bNoSmooth=False; C.Style=3;
	
	For(I=0; I<Array_Size(HitTick); I++)
	{

		fVal=FMin(HitTick[I]/0.5,1);
		C.SetTile3DOffset(True,,(((HitRot[I]&65535)-(PlayerPawn(Owner).ViewRotation.Yaw&65535))&65535)*rot(0,0,1));
		if(wPlayer(Owner)!=None && wPlayer(Owner).bGodMode)
		{	C.DrawColor=MakeColor(128*fVal,128*fVal,128*fVal);
			C.SetPos(C.ClipX/2-64*Scale,C.ClipY/2-(128-16*fVal)*Scale);
			C.DrawRect(Texture'HitIndicator',128*Scale,64*Scale);
		}
		else
		{	if(HitShielded[I]>0)
			C.DrawColor=MakeColor(128*fVal,192*fVal,255*fVal);
			else if(HitType[I]=='Corroded')
			C.DrawColor=MakeColor(0,255*fVal,0);
			else if(HitType[I]=='Burned')
			C.DrawColor=MakeColor(255*fVal,128*fVal,0);
			else if(HitType[I]=='Jolted')
			C.DrawColor=MakeColor(128*fVal,128*fVal,255*fVal);
			else
			C.DrawColor=MakeColor(255*fVal,0,0);
			C.SetPos(C.ClipX/2-80*Scale,C.ClipY/2-(208-16*fVal)*Scale);
			C.DrawRect(Texture'HitIndicator',192*Scale,96*Scale);
		}
	}

	C.Reset(); C.SpaceX=0; C.bNoSmooth=True;
	C.DrawColor=MakeColor(255,255,255,255);
	C.Font = Font'u96f_huge'; C.Style=1;
	C.SetTile3DOffset(False);
}

simulated function Tick(float dT)
{
	local int I;

	if(Level!=CurrentLevel) MOTDFadeOutTime=0;
	CurrentLevel=Level;	

	IdentifyFadeTime -= dT;
	if (IdentifyFadeTime < 0.0)
		IdentifyFadeTime = 0.0;

	MOTDFadeOutTime += dT;
	if (MOTDFadeOutTime < 0.0)
		MOTDFadeOutTime = 0.0;
	

	//if(bool(Pawn(Owner).bExtra0)) RadialTick=FClamp(RadialTick+5*dT,0,1);
	//else RadialTick=FClamp(RadialTick-5*dT,0,1);

	if(wPRI(Pawn(Owner).PlayerReplicationInfo).bGameOver)
	{
		if(DeathTime<0.99)
		DeathTime+=0.005;
		else DeathTime=1;
	}
	else DeathTime=0;

	For(I=0; I<Array_Size(HitTick); I++)
	{
		HitTick[I]-=dT; if(HitTick[I]<=0)
		{	Array_Remove(HitRot,I);
			Array_Remove(HitTick,I);
			Array_Remove(HitType,I);
			Array_Remove(HitShielded,I);
		}
	}
}

final simulated function ShowHit(int RotYaw, name DamageType, byte bShielded)
{
	local int I;
	
	I=Array_Size(HitRot);
	HitRot[I] =RotYaw;
	HitTick[I]=1.f;
	HitType[I]=DamageType;
	HitShielded[I]=bShielded;
}

simulated function DrawNumberOf(Canvas Canvas, int NumberOf, int X, int Y)
{
	if (NumberOf<=0) Return;

	Canvas.CurX = X + 4; //TT: +14
	Canvas.CurY = Y + 20;
	//NumberOf++;
	if (NumberOf<1000) Canvas.CurX+=6;
	if (NumberOf<100) Canvas.CurX+=6;
	if (NumberOf<10) Canvas.CurX+=6;
	Canvas.Font = Font'WhiteFont';
	Canvas.DrawText(NumberOf,False);
}



simulated function DrawWeapons(Canvas Canvas, int X, int Y)
{
	local int HalfHUDX,HalfHUDY;
	local inventory inv;
	local int i;
	local float AmmoIconSize,AmmoColor;

	Canvas.Font = Font'TinyFont';
	HalfHUDX = X;
	HalfHUDY = Y;
	Canvas.CurX = HalfHudX;
	Canvas.CurY = HalfHudY;
	//Canvas.DrawIcon(Texture'HD_HalfHud', 1.0);
	Canvas.Style=4;
	Canvas.DrawRect(Texture'ModulatedIcon',96,32);
	Canvas.CurX-=96;
	Canvas.Style=3;
	Canvas.DrawRect(Texture'HalfHudHD',96,32);


	for(Inv=Owner.Inventory; Inv!=None; Inv=Inv.Inventory)
	{
		if ( Inv.InventoryGroup>0 && (Weapon(Inv)!=None) )
		{
			if (Pawn(Owner).Weapon == Inv) Canvas.Font = Font'TinyWhiteFont';
			else Canvas.Font = Font'TinyFont';
			Canvas.CurX = HalfHudX-4+Inv.InventoryGroup*9;
			Canvas.CurY = HalfHudY+3;
			if (Inv.InventoryGroup<10) Canvas.DrawText(Inv.InventoryGroup,False);
			else Canvas.DrawText("0",False);
		}
		if( Ammo(Inv)!=None )
		{
			for (i=0; i<10; i++)
			{
				if (Ammo(Inv).UsedInWeaponSlot[i]==1)
				{
					Canvas.CurX = HalfHudX+i*9;
					if (i==0) Canvas.CurX = HalfHudX+10*9;
					Canvas.CurX -= 6;
					Canvas.CurY = HalfHudY+13;
					AmmoIconSize = 16.0*FMin(1.0,(float(Ammo(Inv).AmmoAmount)/float(Ammo(Inv).MaxAmmo)));
					Canvas.Font = Font'TinyRedFont';
					if (AmmoIconSize<8 && Ammo(Inv).AmmoAmount<10 && Ammo(Inv).AmmoAmount>0)
					{
						Canvas.CurX += 2.5;
						Canvas.CurY += 5;
						Canvas.Font = Font'TinyRedFont';
						Canvas.DrawText(Ammo(Inv).AmmoAmount,False);
						Canvas.CurY -= 12;
						Canvas.CurX -= 7;
					}
					Canvas.CurY += 16-AmmoIconSize;
					Canvas.DrawColor.g = 255;
					Canvas.DrawColor.r = 0;
					Canvas.DrawColor.b = 0;
					AmmoColor=FClamp(float(Ammo(Inv).AmmoAmount)/float(Ammo(Inv).MaxAmmo),0,1);
					if (AmmoColor<=0.5)
					{
						Canvas.DrawColor.r = 255*(1-AmmoColor);
						Canvas.DrawColor.g = 255*(AmmoColor*2);
					}
					if (Ammo(Inv).AmmoAmount >0)
					{
						Canvas.DrawTile(Texture'HudGreenAmmo',7,AmmoIconSize,0,0,7,AmmoIconSize);
					}
					Canvas.DrawColor.g = 255;
					Canvas.DrawColor.r = 255;
					Canvas.DrawColor.b = 255;
				}
			}
		}
	}
	Canvas.Style=1;
}


simulated function DrawIconValue(Canvas Canvas, int Amount)
{
	local int TempX,TempY;

	//if (HudMode!=1&&HudMode!=2) Return;

	TempX = Canvas.CurX;
	TempY = Canvas.CurY;
	Canvas.CurX -= 30; //-=20
	Canvas.CurY -= 8; //-=5
	if (Amount<1000) Canvas.CurX+=6;
	if (Amount<100) Canvas.CurX+=6;
	if (Amount<10) Canvas.CurX+=6;
	Canvas.Font = Font'WhiteFont';//Font'TinyFont';
	Canvas.DrawText(Amount,False);
	Canvas.Font = Canvas.LargeFont;
	Canvas.CurX = TempX;
	Canvas.CurY = TempY;
}

simulated function DrawHudIcon(Canvas Canvas, int X, int Y, Inventory Item)
{
	Local int Width;
	Width = Canvas.CurX;
	Canvas.CurX = X;
	Canvas.CurY = Y;
	DrawModulatedIcon(Canvas,X,Y);
	Canvas.Style=3;
	if (Item.Icon==None)
	{/*if(Class'HUD'.Default.HudScaler>1.25) Canvas.DrawRect(Texture'ItemIconHD',32,32); else*/ Canvas.DrawRect(Texture'ItemIcon',32,32);}
	else
	{
		if(bool(Weapon(Item)) && Weapon(Item).Icon==Class'Weapon'.Default.Icon && bool(Weapon(Item).AmmoType))
		Canvas.DrawRect(Weapon(Item).AmmoType.Icon,32,32);
		else
		Canvas.DrawRect(Item.Icon,32,32);
	}
	Canvas.CurX -= 30;
	Canvas.CurY += 28;
	if ( /*!Item.bIsAnArmor &&*/ !Item.IsA('Weapon') && Item.Charge>0)
		Canvas.DrawTile(Texture'HudLine',fMin(27.0,27.0*(float(Item.Charge)/float(Item.Default.Charge))),2.0,0,0,32.0,2.0);
	Canvas.CurX = Width + 32;
	Canvas.Style=1;
}

simulated function DrawEmptyIcon(Canvas Canvas,int X,int Y)
{
	Local int Width;
	Width = Canvas.CurX;
	Canvas.CurX = X;
	Canvas.CurY = Y;
	DrawModulatedIcon(Canvas,X,Y);
	Canvas.Style=3;
//	if(Class'HUD'.Default.HudScaler>1.25) 227j/227k is a disappointment
//	Canvas.DrawRect(Texture'ItemIconHD',32,32);
//	else
	Canvas.DrawRect(Texture'ItemIcon',32,32);
	Canvas.Style=1;
	Canvas.CurX = Width;
}

simulated function DrawModulatedIcon(Canvas Canvas,int X,int Y)
{
	Local int Width;
	Width = Canvas.CurX;
	Canvas.CurX = X;
	Canvas.CurY = Y;
	Canvas.Style=4;
	Canvas.DrawRect(Texture'ModulatedIcon',32,32);
	Canvas.Style=1;
	Canvas.CurX = Width;
}

simulated function DrawAmmo(Canvas Canvas, int X, int Y)
{
	//DrawModulatedIcon(Canvas,X,Y);
	if ( (Pawn(Owner).Weapon == None) || (Pawn(Owner).Weapon.AmmoType == None) )
	{DrawEmptyIcon(Canvas,X,Y);
	return;}
	Canvas.CurY = Y;
	Canvas.CurX = X;
	if (Pawn(Owner).Weapon.AmmoType.AmmoAmount < 10)
		Canvas.Font = Font'LargeRedFont';
	else
		Canvas.Font = Font'LargeFont';
	Canvas.Style=3;
	if (HudMode!=1)
	{
		if (Pawn(Owner).Weapon.AmmoType.Icon!=None) {DrawModulatedIcon(Canvas,X,Y); Canvas.Style=3; Canvas.DrawRect(Pawn(Owner).Weapon.AmmoType.Icon,32,32);} Canvas.CurX -= 50;

		if (Pawn(Owner).Weapon.AmmoType.AmmoAmount>=1000) Canvas.CurX -= 16;
		if (Pawn(Owner).Weapon.AmmoType.AmmoAmount>=100) Canvas.CurX -= 16;
		if (Pawn(Owner).Weapon.AmmoType.AmmoAmount>=10) Canvas.CurX -= 16;
		Canvas.Style=1;
		Canvas.DrawText(Pawn(Owner).Weapon.AmmoType.AmmoAmount,False);
		Canvas.CurY = Canvas.ClipY-32;
	}
	else{ //Canvas.CurX+=16;
	if (Pawn(Owner).Weapon.AmmoType.Icon!=None) {DrawModulatedIcon(Canvas,X,Y); Canvas.Style=3; Canvas.DrawRect(Pawn(Owner).Weapon.AmmoType.Icon,32,32);} }
	Canvas.CurY += 29;
	Canvas.Style=1;
	if(HudMode==1)
	DrawIconValue(Canvas, Pawn(Owner).Weapon.AmmoType.AmmoAmount);

	Canvas.CurX = X+2;
	Canvas.CurY = Y+29;

	if (HudMode!=1)
	Canvas.DrawTile(Texture'HudLine',FMin(27.0*(float(Pawn(Owner).Weapon.AmmoType.AmmoAmount)/float(Pawn(Owner).Weapon.AmmoType.MaxAmmo)),27),2.0,0,0,32.0,2.0);

	Canvas.DrawColor.R=255; Canvas.DrawColor.G=255; Canvas.DrawColor.B=255;
}

simulated function DrawHealth(Canvas Canvas, int X, int Y)
{
	local int SaveX;

	Canvas.CurY = Y;
	Canvas.CurX = X;
	if (Pawn(Owner).Health <= Pawn(Owner).Default.Health*0.25)
		Canvas.Font = Font'LargeRedFont';
	else
		Canvas.Font = Font'LargeFont';
	DrawModulatedIcon(Canvas,X,Y);
	Canvas.Style=3;
	Canvas.DrawIcon(Texture'IconHealth', 1.0);
	Canvas.CurY += 29;
	if(HudMode==1)
	DrawIconValue(Canvas, Max(0,Pawn(Owner).Health));
	Canvas.CurY -= 29;
	Canvas.Style=1;
	if (HudMode!=1)
	{
		if (HudMode!=1) Canvas.DrawText(Max(0,Pawn(Owner).Health),False);
		Canvas.CurY = Y+29;
		Canvas.CurX = X+2;
		SaveX=Canvas.CurX;
		Canvas.DrawTile(Texture'HudLine',FMin(27.0*(float(Pawn(Owner).Health)/float(Pawn(Owner).Default.Health)),27),2.0,0,0,32.0,2.0);
	}
}

simulated function DrawTypingPrompt(Canvas C, Console Console)
{
	local string TypingPrompt;
	local float XL, YL;

	if(!Console.bTyping) return;
	C.Style=4;
	C.DrawColor=MakeColor(255,255,255,255);
	if(Console.TypingOffset>=0&&Console.TypingOffset<Len(Console.TypedStr))
		 TypingPrompt = "(> "$Left(Console.TypedStr,Console.TypingOffset)$"_"$Mid(Console.TypedStr,Console.TypingOffset);
	else TypingPrompt = "(> "$Console.TypedStr$"_";
	//C.Font = C.MedFont; C.Font=Font'WhiteFont';
	C.StrLen(TypingPrompt,XL,YL);
	C.SetPos(2,(C.ClipY/1.6)-2);
	C.DrawRect(Texture'ModulatedIcon',XL+2,YL+4);
	C.DrawColor=MakeColor(000,255,000);
	C.SetPos(2,C.ClipY/1.6);
	C.Style=1;
	C.DrawText(TypingPrompt,False);
}

defaultproperties
{
}
