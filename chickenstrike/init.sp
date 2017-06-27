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

ConVar cvar_viewModel = null;
ConVar cvar_welcome_message = null;
ConVar cvar_healthfactor = null;
ConVar cvar_sprintspeed = null;
ConVar cvar_customdecoy = null;
ConVar cvar_customflash = null;

public void CreateConVars(char[] version)
{
	CreateConVar("chickenstrike_version", version, "Chicken Strike", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_viewModel = CreateConVar("cs_viewmodel", "0", "Show view model? 0 = no, 1 = yes", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_welcome_message = CreateConVar("cs_welcomemessage", "1", "Displays a welcome message to new players. 0 = no message, 1 = display message", FCVAR_NOTIFY, true, 0.0, true, 1.0);		
	cvar_healthfactor = CreateConVar("cs_healthfactor", "30", "How much health per T the CT must have.", FCVAR_NOTIFY, true, 1.0, true, 1000.0);
	cvar_sprintspeed = CreateConVar("cs_sprintspeed", "220", "Set chickenOP's sprint speed. 250 = human speed, 0.36 = chicken run speed, 0.12 = chicken walk speed", FCVAR_NOTIFY, true, 0.01, true, 220.0);
	cvar_customdecoy = CreateConVar("cs_customdecoy", "1", "Set whether to enable custom decoys for the Chicken OP. 0 = disabled, 1 = enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_customflash = CreateConVar("cs_customflash", "1", "Set whether to enable custom flashes for the Chicken OP. 0 = disabled, 1 = enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "chickenstrike");
}

public void RegisterCommands()
{
	RegAdminCmd("cs_setop", SetOP, ADMFLAG_GENERIC, "Set a specified player to the Chicken OP");
	RegConsoleCmd("cs_credits", DisplayCredits, "Display Chicken Strike credits")
	RegConsoleCmd("say !cs_credits", DisplayCredits, "Display Chicken Strike credits")
	RegConsoleCmd("cs_help", DisplayHelp, "Display Chicken Strike help")
	RegConsoleCmd("say !cs_help", DisplayHelp, "Display Chicken Strike help")
}

public void IntiCvars()
{
	//Set team names
	SetConVarString(FindConVar("mp_teamname_1"), "Chicken OP");
	//Enable hiding of players
	SetConVarBool(FindConVar("sv_disable_immunity_alpha"), true);
	//Disable auto balance
	SetConVarBool(FindConVar("mp_autoteambalance"), false);
	SetConVarBool(FindConVar("mp_autokick"), false);
	
	//Disable the event if any (easter, halloween, xmas...)
	SetConVarBool(FindConVar("sv_holiday_mode"), false);
	
	//Set healthshot paramaters
	SetConVarInt(FindConVar("healthshot_health"), 50);
	SetConVarInt(FindConVar("ammo_item_limit_healthshot"), 1);
	SetConVarInt(FindConVar("mp_death_drop_grenade"), 0);
	SetConVarInt(FindConVar("mp_death_drop_defuser"), 0);
	
	 
	SetConVarInt(FindConVar("mp_playercashawards"), 0);
	SetConVarInt(FindConVar("mp_teamcashawards"), 0);
	
	
}