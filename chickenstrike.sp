/*
*   This file is part of Chicken Strike.
*   Copyright (C) 2017  Keplyx
*
*   This program is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program. If not, see <http://www.gnu.org/licenses/>.
*/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>
#include <menus>

#pragma newdecls required;

#include "chickenstrike/chickenplayer.sp"
#include "chickenstrike/customweapons.sp"
#include "chickenstrike/weapons.sp"
#include "chickenstrike/menus.sp"
#include "chickenstrike/init.sp"
#include "chickenstrike/utils.sp"

/*  BUGS
*
*   Reload while ammo full //Y U DO DIS
*   Foot shadow under chicken (client side thirdperson only) // Does it really need a fix?
*
*/


/*  New in this version
*
*	
*/

//Gamemode: T must stop the CT chicken from saving hostages, eggs, or killing everyone

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

#define LoopIngameClients(%1) for(int %1 = 1; %1 <= MaxClients; ++%1)\
if (IsClientInGame( % 1))

#define LoopIngamePlayers(%1) for(int %1 = 1; %1 <= MaxClients; ++%1)\
if (IsClientInGame( % 1) && !IsFakeClient( % 1))

#define LoopAlivePlayers(%1) for(int %1 = 1;%1 <= MaxClients; ++%1)\
if (IsClientInGame( % 1) && IsPlayerAlive( % 1))

#define VERSION "0.1"
#define PLUGIN_NAME "Chicken Strike",

int collisionOffsets;

bool lateload;

public Plugin myinfo =
{
	name = PLUGIN_NAME
	author = "Keplyx",
	description = "There's only one who can take down a squad of terrorists and save the hostages, call him in.",
	version = VERSION,
	url = "https://github.com/Keplyx/chickenstrike"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	PrecacheModel(chickenModel, true);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	
	CreateConVars(VERSION);
	
	collisionOffsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	//Throws Error
	//LoopIngameClients(i)
	//	OnClientPostAdminCheck(i);
	
	if (lateload)
	ServerCommand("mp_restartgame 1");
	
	PrintToServer("*************************************");
	PrintToServer("* Chicken Strike successfuly loaded *");
	PrintToServer("*************************************");
}


public void OnConfigsExecuted()
{
	IntiCvars();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientCT(victim))
	{
		DisableChicken(victim);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientCT(client_index))
	{
		//Get player's viewmodel for future hiding
		clientsViewmodels[client_index] = GetViewModelIndex(client_index);
		//Transformation!!
		SetChicken(client_index);
	}
	//Remove player collisions
	SetEntData(client_index, collisionOffsets, 2, 1, true);
}

public void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientCT(client_index))
	{
		DisableChicken(client_index);
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllItems();
	CPrintToChatAll("{yellow}Open the buy menu bu pressing {white}[S]");
	//Setup buy menu
	canBuyAll = true;
	CreateTimer(GetConVarFloat(cvar_custombuymenu), Timer_BuyMenu);
}

public void OnClientPostAdminCheck(int client_index)
{
	SDKHook(client_index, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	SDKHookEx(client_index, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
	//Displays the welcome message 3 sec after player's connection so he can see it
	CreateTimer(3.0, Timer_WelcomeMessage, client_index);
}

public void OnClientDisconnect(int client_index)
{
	DisableChicken(client_index);
	ResetClientItems(client_index);
}

public void OnEntityCreated(int entity_index, const char[] classname)
{
	if (StrEqual(classname, "decoy_projectile", false) && GetConVarBool(cvar_customdecoy))
	{
		SDKHook(entity_index, SDKHook_ThinkPost, Hook_OnGrenadeThinkPost);
	}
	if (StrEqual(classname, "hegrenade_projectile", false) && GetConVarBool(cvar_customhe))
	{
		CreateTimer(0.0, Timer_DefuseGrenade, entity_index);
		SDKHook(entity_index, SDKHook_StartTouch, StartTouchHegrenade);
	}
}

public Action StartTouchHegrenade(int iEntity, int iEntity2)
{
    int iRef = EntIndexToEntRef(iEntity);
    CreateTimer(1.0, Timer_CreateExpChicken, iRef);
}

public Action Timer_CreateExpChicken(Handle timer, any ref)
{
	int entity_index = EntRefToEntIndex(ref);
	if (entity_index != INVALID_ENT_REFERENCE){
		float fVelocity[3];
		GetEntPropVector(entity_index, Prop_Send, "m_vecVelocity", fVelocity);
		if (fVelocity[0] == 0.0 && fVelocity[1] == 0.0 && fVelocity[2] == 0.0)
		{
			float fOrigin[3];
			GetEntPropVector(entity_index, Prop_Send, "m_vecOrigin", fOrigin);
			int owner = GetEntPropEnt(entity_index, Prop_Send, "m_hOwnerEntity");
			ExplosiveChicken(fOrigin, owner);
			AcceptEntityInput(entity_index, "Kill");
		}
	}
}

public Action Timer_DefuseGrenade(Handle timer, any ref)
{
	int ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	SetEntProp(ent, Prop_Data, "m_nNextThinkTick", -1);
}

public Action Timer_WelcomeMessage(Handle timer, int client_index)
{
	if (cvar_welcome_message.BoolValue && IsClientConnected(client_index) && IsClientInGame(client_index))
	{
		//Welcome message (white text in red box)
		CPrintToChat(client_index, "{darkred}********************************");
		CPrintToChat(client_index, "{darkred}* {default}Welcome to Chicken Strike");
		CPrintToChat(client_index, "{darkred}*            {default}Made by Keplyx");
		CPrintToChat(client_index, "{darkred}********************************");
	}
}

public Action Timer_BuyMenu(Handle timer, any userid) {
	
	CloseBuyMenus();
}

public Action Timer_BuyMenuPlayer(Handle timer, any userid) {
	int client_index = EntRefToEntIndex(userid);
	if (IsValidClient(client_index))
	{
		ClosePlayerBuyMenu(client_index);
	}
}

public Action OnPlayerRunCmd(int client_index, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client_index))
	return Plugin_Continue;
	
	// Disable non-forward movement :3
	if (vel[1] != 0)
	vel[1] = 0.0;
	//Block backward movement if +use is not pressed
	if (!(buttons & IN_USE))
	{
		if (vel[0] < 0)
		vel[0] = 0.0;
	}
	
	//Change player's animations based on key pressed
	isWalking[client_index] = (buttons & IN_SPEED) || (buttons & IN_DUCK);
	isMoving[client_index] = vel[0] > 0.0 || vel[0] < 0.0;
	if (isMoving[client_index] || (buttons & IN_JUMP) || IsValidEntity(weapons[client_index]) || !(GetEntityFlags(client_index) & FL_ONGROUND))
	SetRotationLock(client_index, true);
	else
	SetRotationLock(client_index, false);
	
	if ((buttons & IN_JUMP) && !(GetEntityFlags(client_index) & FL_ONGROUND))
	{
		SlowPlayerFall(client_index);
	}
	
	//Block crouch but not crouch-jump
	if ((buttons & IN_DUCK) && (GetEntityFlags(client_index) & FL_ONGROUND))
	{
		buttons &= ~IN_DUCK;
		return Plugin_Continue;
	}
	
	//Disable knife cuts
	if (StrEqual(currentWeaponName[client_index], "knife", false))
	{
		float fUnlockTime = GetGameTime() + 1.0;
		
		SetEntPropFloat(client_index, Prop_Send, "m_flNextAttack", fUnlockTime);
		
		int knife = GetPlayerWeaponSlot(client_index, CS_SLOT_KNIFE)
		if (knife > 0)
		SetEntPropFloat(knife, Prop_Send, "m_flNextPrimaryAttack", fUnlockTime);
	}
	
	
	// Commands
	if ((buttons & IN_MOVELEFT) && canBuyAll && canBuy[client_index])
	{
		Menu_Buy(client_index, 0);
	}
	else if (buttons & IN_MOVERIGHT)
	{
		Menu_Taunt(client_index, 0);
	}
	
	return Plugin_Changed;
}

public void Hook_WeaponSwitchPost(int client_index, int weapon_index)
{
	if (GetEntityRenderMode(client_index) == RENDER_NONE)
	{
		//Hide the real weapon (which can't be moved because of the bonemerge attribute in the model) and creates a fake one, moved to the chicken's side
		SetWeaponVisibility(client_index, weapon_index, false);
		CreateFakeWeapon(client_index, weapon_index);
	}
	else
	{
		//If player is visible (not a chicken??) make his weapons visible and don't create a fake one
		SetWeaponVisibility(client_index, weapon_index, true);
	}
	GetCurrentWeaponName(client_index, weapon_index);
	DisplaySwitching(client_index); //Displayer weapon switching to warn players
	SDKHook(weapon_index, SDKHook_ReloadPost, Hook_WeaponReloadPost);
}

public void Hook_OnPostThinkPost(int entity_index)
{
	SetViewModel(entity_index, GetConVarBool(cvar_viewModel)); //Hide viewmodel based on cvar
}

public void Hook_OnGrenadeThinkPost(int entity_index)
{
	//Manage the grenades
	//When it stops moving, kill the entity and replace it by chickens!
	float fVelocity[3];
	GetEntPropVector(entity_index, Prop_Send, "m_vecVelocity", fVelocity);
	if (fVelocity[0] == 0.0 && fVelocity[1] == 0.0 && fVelocity[2] == 0.0)
	{
		int client_index = GetEntPropEnt(entity_index, Prop_Data, "m_hOwnerEntity")
		float fOrigin[3];
		GetEntPropVector(entity_index, Prop_Send, "m_vecOrigin", fOrigin);
		
		char buffer[64];
		GetEntityClassname(entity_index, buffer, sizeof(buffer));
		if (StrEqual(buffer, "decoy_projectile"))
		ChickenDecoy(client_index, fOrigin, weapons[client_index]);
		AcceptEntityInput(entity_index, "Kill");
	}
}

public void Hook_OnChickenThinkPost(int entity_index)
{
	float area[3] =  { 80.0, 80.0, 80.0 };
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidClient(i))
		{
			
			//int owner = GetEntPropEnt(entity_index, Prop_Send, "m_hOwnerEntity");
			//if (GetClientTeam(i) != GetClientTeam(owner))
			//{
				float fOrigin[3];
				GetClientAbsOrigin(i, fOrigin);
				float pos[3];
				GetEntPropVector(entity_index, Prop_Send, "m_vecOrigin", pos);
				bool inside = false;
				for (int j = 0; j < sizeof(area); j++)
				{
					inside = fOrigin[j] < pos[j] + area[j] && fOrigin[j] > pos[j] - area[j];
					if (!inside)
						break;
				}
				if (inside)
					createExplosion(pos);
			//}
		}
	}
}

public void createExplosion(float pos[3])
{
	int entity = CreateEntityByName("env_explosion");
	if (IsValidEntity(entity))
	{
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		DispatchKeyValue(entity, "iMagnitude", "100"); 
		SetVariantString("!activator");
		AcceptEntityInput(entity, "Explode", entity, entity);
		AcceptEntityInput(entity, "Kill");
	}
}


public bool TRDontHitSelf(int entity, int mask, any data) //Trace hull filter
{
	if (entity == data)return false;
	return true;
}


public Action Hook_WeaponReloadPost(int weapon) //Bug: gets called if ammo is full and player pressing reload key
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	//EmitSoundToAll(chickenPanicSounds[0], owner); //Disabled to prevent spam
	PrintHintText(owner, "<font color='#ff0000' size='30'>RELOADING</font>");
}

public Action Hook_SetTransmit(int entity, int client)
{
	return Plugin_Handled;
}
