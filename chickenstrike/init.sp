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

ConVar cvar_customdecoy = null;
ConVar cvar_customhe = null;
ConVar cvar_custombuymenu = null;

public void CreateConVars(char[] version)
{
	CreateConVar("chickenwars_version", version, "Chicken Strike", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_viewModel = CreateConVar("cw_viewmodel", "0", "Show view model? 0 = no, 1 = yes", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_welcome_message = CreateConVar("cw_welcomemessage", "1", "Displays a welcome message to new players. 0 = no message, 1 = display message", FCVAR_NOTIFY, true, 0.0, true, 1.0);		
	cvar_customdecoy = CreateConVar("cw_customdecoy", "1", "Set whether to enable custom decoys. 0 = disabled, 1 = enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_customhe = CreateConVar("cw_customhe", "1", "Set whether to enable custom HE grenades. 0 = disabled, 1 = enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_custombuymenu = CreateConVar("cw_custombuymenu", "20", "Set how much time the custom buy menu should be displayed after player spawn. 0 = disabled, x = x seconds", FCVAR_NOTIFY, true, 0.0, true, 3600.0);
	
	AutoExecConfig(true, "chickenstrike");
}

public void IntiCvars()
{
	//Set team names
	SetConVarString(FindConVar("mp_teamname_1"), "Chicken OP");
	
	//Enable hiding of players
	SetConVarBool(FindConVar("sv_disable_immunity_alpha"), true);
	
	//Disable footsteps
	SetConVarFloat(FindConVar("sv_footstep_sound_frequency"), 500.0);
	
	//Disable the event if any (easter, halloween, xmas...)
	SetConVarBool(FindConVar("sv_holiday_mode"), false);
	
	//Set healthshot paramaters
	SetConVarInt(FindConVar("healthshot_health"), 50);
	SetConVarInt(FindConVar("ammo_item_limit_healthshot"), 2);
}