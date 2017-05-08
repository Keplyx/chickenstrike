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

public void ChickenDecoy(int client_index, float pos[3], int currentWeapon) //Change grenade into an armed chicken!!!!!!!
{
	int entity = CreateEntityByName("chicken");
	if (IsValidEntity(entity))
	{
		//Random orientation
		float rot[3];
		rot[1] = GetRandomFloat(0.0, 360.0);
		TeleportEntity(entity, pos, rot, NULL_VECTOR);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		int weapon = CreateEntityByName("prop_dynamic_override");
		if (IsValidEntity(weapon) && currentWeapon > MAXPLAYERS)
		{
			//Get the player's current gun
			char m_ModelName[PLATFORM_MAX_PATH];
			GetEntPropString(currentWeapon, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
			SetEntityModel(weapon, m_ModelName);
			
			SetVariantString("!activator");
			AcceptEntityInput(weapon, "SetParent", entity, weapon, 0);
			//Put the gun at the chicken's side
			float gunPos[] =  { -17.0, -2.0, 15.0 };
			float gunRot[3];
			TeleportEntity(weapon, gunPos, gunRot, NULL_VECTOR);
			//Make sure the gun is not solid
			DispatchKeyValue(weapon, "solid", "0");
			//Spawn it!
			DispatchSpawn(weapon);
			ActivateEntity(weapon);
		}
	}
}

public void ExplosiveChicken(float pos[3], int client_index) //Creates a chicken wich will explode when an enemy goes near it
{
	int entity = CreateEntityByName("chicken");
	if (IsValidEntity(entity))
	{
		//Random orientation
		float rot[3];
		rot[1] = GetRandomFloat(0.0, 360.0);
		TeleportEntity(entity, pos, rot, NULL_VECTOR);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		//SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client_index);
		SDKHook(entity, SDKHook_ThinkPost, Hook_OnChickenThinkPost);
	}
}
