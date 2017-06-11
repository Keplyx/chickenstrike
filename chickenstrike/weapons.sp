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

#include <sdktools>

int weapons[MAXPLAYERS];
int clientsViewmodels[MAXPLAYERS + 1];
char currentWeaponName[MAXPLAYERS + 1][32];

public void DisplaySwitching(int client_index)
{
	//Tell visible + weapon switched to
	char buffer[128];
	Format(buffer, sizeof(buffer), "<font color='#ffffff' size='30'>Switched to %s</font>", currentWeaponName[client_index]);
	PrintHintText(client_index, buffer);
}


public void CreateFakeWeapon(int client_index, int weapon_index)
{
	DeleteFakeWeapon(client_index);
	char weapon_name[32];
	GetEdictClassname(weapon_index, weapon_name, sizeof weapon_name);

	weapons[client_index] = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(weapons[client_index]))
	{
		SetVariantString("!activator");
		AcceptEntityInput(weapons[client_index], "SetParent", client_index, weapons[client_index], 0);
		SetModel(client_index, weapon_index, weapon_name)
		//Make sure the gun is not solid
		DispatchKeyValue(weapons[client_index], "solid", "0");
		//Spawn it!
		DispatchSpawn(weapons[client_index]);
		ActivateEntity(weapons[client_index]);
	}
}

public void SetModel(int client_index, int weapon_index, char[] classname)
{
	if (StrEqual(classname, "weapon_smokegrenade", false) || StrEqual(classname, "weapon_decoy", false) || StrEqual(classname, "weapon_tagrenade", false) || StrEqual(classname, "weapon_molotov", false) || StrEqual(classname, "weapon_incgrenade", false) || StrEqual(classname, "weapon_hegrenade", false))
	{
		SetWeaponPos(client_index, 1);
	}
	else if (StrEqual(classname, "weapon_healthshot", false))
	{
		SetWeaponPos(client_index, 2);
	}
	else if (StrEqual(classname, "weapon_knife", false))
	{
		SetWeaponPos(client_index, 3);
	}
	else
	{
		SetWeaponPos(client_index, 0);
	}
	char modelName[128];
	GetEntPropString(weapon_index, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	SetEntityModel(weapons[client_index], modelName);
}

public void SetWeaponPos(int client_index, int type)
{
	//Put the gun at the chicken's side
	float rot[3];
	float pos[3];
	if (type == 0) // normal
	{
		pos[0] = -17.0;
		pos[1] = -2.0;
		pos[2] = 15.0;
	}
	else if (type == 1) // grenade
	{
		pos[0] = 0.0;
		pos[1] = -5.0;
		pos[2] = 15.0;
	}
	else if (type == 2) // healthshot
	{
		pos[0] = -7.0;
		pos[1] = -23.0;
		pos[2] = 5.0;
		rot[2] = 90.0;
	}
	else if (type == 3) // knife
	{
		pos[0] = 6.0;
		pos[1] = 5.0;
		pos[2] = 19.0;
		rot[0] = 90.0;
		rot[1] = 90.0;
	}
	
	TeleportEntity(weapons[client_index], pos, rot, NULL_VECTOR);
}

public void DeleteFakeWeapon(int client_index)
{
	if (IsValidEntity(weapons[client_index]) && weapons[client_index] > MAXPLAYERS)
	{
		RemoveEdict(weapons[client_index]);
		weapons[client_index] = -1;
	}
}

public void SetWeaponVisibility(int client_index, int weapon, bool enabled)
{
	if (weapon != -1)
	{
		int worldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		if (worldModel != -1)
		{
			if (!enabled)
				SDKHook(worldModel, SDKHook_SetTransmit, Hook_SetTransmit);
			else
				SDKUnhook(worldModel, SDKHook_SetTransmit, Hook_SetTransmit)
		}
	}
}

public int GetViewModelIndex(int client_index)
{
	int index = MAXPLAYERS;
	while ((index = FindEntityByClassname(index, "predicted_viewmodel")) != -1)
	{
		int owner = GetEntPropEnt(index, Prop_Send, "m_hOwner");
		
		if (owner != client_index)
			continue;
		
		return index;
	}
	return -1;
}

public void GetCurrentWeaponName(int client_index, int weapon_index)
{
	//Simply removes weapon prefix from the classname
	char weaponName[32];
	GetEdictClassname(weapon_index, weaponName, sizeof weaponName);
	ReplaceString(weaponName, sizeof weaponName, "weapon_", "");
	currentWeaponName[client_index] = weaponName;
}

public void SetViewModel(int client_index, bool enabled)
{
	int EntEffects = GetEntProp(clientsViewmodels[client_index], Prop_Send, "m_fEffects");
	if (enabled)
		EntEffects |= ~32;
	else
		EntEffects |= 32; // Set to Nodraw
	SetEntProp(clientsViewmodels[client_index], Prop_Send, "m_fEffects", EntEffects);
}
