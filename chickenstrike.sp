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
#include <sdktools_sound>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>

#pragma newdecls required;

#include "chickenstrike/chickenplayer.sp"
#include "chickenstrike/customweapons.sp"
#include "chickenstrike/weapons.sp"
#include "chickenstrike/menus.sp"
#include "chickenstrike/hostages.sp"
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

int chickenOP;
int nextChickenOP = -1;

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
	PrecacheModel(eggModel, true);
	PrecacheModel(eggBoxModel, true);
	
	AddCommandListener(JoinTeam, "jointeam");
	
	AddNormalSoundHook(NormalSoundHook);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("hostage_follows", Event_HostageFollow);
	HookEvent("hostage_rescued", Event_HostageRescue);
	CreateConVars(VERSION);
	RegisterCommands();
	
	collisionOffsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	//Throws Error
	//LoopIngameClients(i)
	//	OnClientPostAdminCheck(i);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
			OnClientPostAdminCheck(i);
	}
	
	if (lateload)
	ServerCommand("mp_restartgame 1");
	
	PrintToServer("*************************************");
	PrintToServer("* Chicken Strike successfuly loaded *");
	PrintToServer("*************************************");
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	
	if(IsValidClient(entity) && StrContains(sample, "footsteps/new/") != -1)
	{
		if (!IsClientCT(entity))
		{
			float pos[3];
			GetClientAbsOrigin(entity, pos)
			EmitSoundToAll(sample, entity, channel, level, SND_NOFLAGS, volume, pitch, _, pos);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
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
	int ref = EntIndexToEntRef(client_index);
	if (IsClientCT(client_index))
	{
		//Get player's viewmodel for future hiding
		clientsViewmodels[client_index] = GetViewModelIndex(client_index);
		// Set the player to a chicken after a little delay, so every player is on T
		CreateTimer(0.1, Timer_SetChicken, ref);
	}
	//Remove player collisions
	SetEntData(client_index, collisionOffsets, 2, 1, true);
	// Set money to max
	CreateTimer(0.1, Timer_SetMoney, ref);
}

public void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	DisableChicken(client_index);
}

public void Event_HostageFollow(Event event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	int hostage = GetEventInt(event, "hostage");
	GrabHostage(client_index, hostage);
}

public void Event_HostageRescue(Event event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	int hostage = GetEventInt(event, "hostage");
	RescueHostage(client_index, hostage);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllItems();
	SpawnEggs();
	
	// Prevent the game from entering a restart game loop if only 2 players
	if ((GetTeamClientCount(CS_TEAM_T) > 1 || GetTeamClientCount(CS_TEAM_CT) > 1) && nextChickenOP <= 0)
		ChooseOP();
	else if (nextChickenOP > 0)
	{
		chickenOP = nextChickenOP;
		BalanceTeams();
		nextChickenOP = -1;
	}
	CPrintToChatAll("{yellow}Open the buy menu by pressing {white}[S]");
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
	SendConVarValue(client_index, FindConVar("sv_footsteps"), "0");
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
}


public Action JoinTeam(int client_index, const char[] command, int argc)
{ 
	if(!IsValidClient(client_index) || argc < 1)
		return Plugin_Handled;
		
	char arg[16];
	GetCmdArg(1, arg, sizeof(arg));
	int destTeam = StringToInt(arg);
	
	if ((GetClientTeam(client_index) == CS_TEAM_CT || GetClientTeam(client_index) == CS_TEAM_T) && destTeam != CS_TEAM_SPECTATOR)
	{
		CPrintToChat(client_index, "{lightred}Switching teams isn't allowed!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void ChooseOP()
{
	chickenOP = GetRandomPlayer();
	BalanceTeams();
}

public void BalanceTeams()
{
	if (GetClientTeam(chickenOP) == CS_TEAM_CT)
	{
		CreateTimer(0.1,  Timer_SwitchAllT);
	}
	else if (GetClientTeam(chickenOP) == CS_TEAM_T)
	{
		ChangeClientTeam(chickenOP, CS_TEAM_CT);
		int ref = EntIndexToEntRef(chickenOP);
		CreateTimer(0.1,  Timer_Respawn, ref);
		CreateTimer(0.2,  Timer_SwitchAllT);
	}
}

public Action Timer_SwitchAllT(Handle timer, any ref)
{
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientCT(i) && i != chickenOP)
		{
			DisableChicken(i);
			ChangeClientTeam(i, CS_TEAM_T);
			ref = EntIndexToEntRef(i);
			CreateTimer(0.1,  Timer_Respawn, ref);
		}
	}
}

public Action Timer_Respawn(Handle timer, any ref)
{
	int client_index = EntRefToEntIndex(ref);
	CS_RespawnPlayer(client_index);
}

public Action Timer_SetChicken(Handle timer, any ref) 
{
	int client_index = EntRefToEntIndex(ref);
	//Transformation!!
	if (IsValidClient(client_index) && IsClientCT(client_index))
		SetChicken(client_index);
}

public Action Timer_SetMoney(Handle timer, any ref) 
{
	int client_index = EntRefToEntIndex(ref);
	if (IsClientCT(client_index))
		SetEntProp(client_index, Prop_Send, "m_iAccount", 1000); //Chicken OP can only buy nades/pistols
	else if (IsValidClient(client_index))
		SetEntProp(client_index, Prop_Send, "m_iAccount", 16000); //Can buy all
}


public Action Timer_WelcomeMessage(Handle timer, int client_index)
{
	if (cvar_welcome_message.BoolValue && IsValidClient(client_index))
	{
		//Welcome message (white text in red box)
		CPrintToChat(client_index, "{darkred}********************************");
		CPrintToChat(client_index, "{darkred}* {default}Welcome to Chicken Strike");
		CPrintToChat(client_index, "{darkred}*            {default}Made by Keplyx");
		CPrintToChat(client_index, "{darkred}********************************");
	}
}

public Action SetOP(int client_index, int args)
{
	if (args < 1)
	{
		PrintToConsole(client_index, "Usage: cs_setop <name>");
		PrintToConsole(client_index, "Set the specified player as the Chicken OP");
		return Plugin_Handled;
	}
	
	char name[32];
	int target = -1;
	GetCmdArg(1, name, sizeof(name));
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		char other[32];
		GetClientName(i, other, sizeof(other));
		if (StrEqual(name, other))
		{
			target = i;
		}
	}
	if (target == -1)
	{
		PrintToConsole(client_index, "Could not find any player with the name: \"%s\"", name);
		PrintToConsole(client_index, "Available players:");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i))
			{
				continue;
			}
			char player[32];
			GetClientName(i, player, sizeof(player));
			PrintToConsole(client_index, "\"%s\"", player);
		}
		return Plugin_Handled;
	}
	PrintToConsole(client_index, "Setting \"%s\" as Chicken OP", name);
	CPrintToChatAll("{green}\"%s\"{default} is the new Chicken OP! Restarting game...", name);
	nextChickenOP = target;
	CS_TerminateRound(0.1, CSRoundEnd_Draw, false);
	
	return Plugin_Handled;
}


public Action Timer_BuyMenu(Handle timer, any userid) 
{
	CloseBuyMenus();
}

public Action OnPlayerRunCmd(int client_index, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client_index))
	return Plugin_Continue;
	
	if (IsClientCT(client_index))
	{
		//Change player's animations based on key pressed
		isMoving[client_index] = (vel[0] > 0.0 || vel[0] < 0.0 || vel[1] > 0.0 || vel[1] < 0.0);
		isWalking[client_index] = (buttons & IN_SPEED) && !(buttons & IN_DUCK) && isMoving[client_index];
		isSprinting[client_index] = (buttons & IN_DUCK) && isMoving[client_index];
		
		if (!hasHostage[client_index])
		{
			if ((buttons & IN_JUMP) && !(GetEntityFlags(client_index) & FL_ONGROUND))
			{
				SlowPlayerFall(client_index);
			}
			// Super jump
			if ((buttons & IN_JUMP) && (buttons & IN_SPEED) && (GetEntityFlags(client_index) & FL_ONGROUND))
			{
				SuperJump(client_index);
			}
			// Dash
			if ((buttons & IN_JUMP) && (buttons & IN_DUCK) && (GetEntityFlags(client_index) & FL_ONGROUND))
			{
				Dash(client_index);
			}
		}
		//Block crouch but not crouch-jump
		if ((buttons & IN_DUCK) && (GetEntityFlags(client_index) & FL_ONGROUND))
		{
			buttons &= ~IN_DUCK;
			return Plugin_Continue;
		}
	}
	else
	{
		if ((buttons & IN_BACK) && canBuyAll)
		{
			Menu_Buy(client_index, 0);
		}
	}
	return Plugin_Changed;
}


public void Hook_WeaponSwitchPost(int client_index, int weapon_index)
{
	if (IsClientCT(client_index))
	{
		//Hide the real weapon (which can't be moved because of the bonemerge attribute in the model) and creates a fake one, moved to the chicken's side
		SetWeaponVisibility(client_index, weapon_index, false);
		CreateFakeWeapon(client_index, weapon_index);
		GetCurrentWeaponName(client_index, weapon_index);
		DisplaySwitching(client_index); //Displayer weapon switching to warn players
		SDKHook(weapon_index, SDKHook_ReloadPost, Hook_WeaponReloadPost);
	}
	else
	{
		//If player is not a CT make his weapons visible and don't create a fake one
		SetWeaponVisibility(client_index, weapon_index, true);
	}
}

public void Hook_OnPostThinkPost(int entity_index)
{
	if (IsValidClient(entity_index) && IsClientCT(entity_index))
	{
		SetViewModel(entity_index, GetConVarBool(cvar_viewModel)); //Hide viewmodel based on cvar
		healthFactor = GetConVarInt(cvar_healthfactor);
		chickenSprintSpeed = GetConVarFloat(cvar_sprintspeed);
	}
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
		char buffer[64];
		GetEntityClassname(entity_index, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "decoy_projectile") && IsClientCT(client_index)){
			float fOrigin[3];
			GetEntPropVector(entity_index, Prop_Send, "m_vecOrigin", fOrigin);
			ChickenDecoy(client_index, fOrigin, weapons[client_index]);
			AcceptEntityInput(entity_index, "Kill");
		}
	}
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
