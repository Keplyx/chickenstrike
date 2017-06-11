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

char fridgeModel[] = "models/props_urban/fridge002.mdl";
int eggs = 0;


public void SpawnEggs()
{
//	RemoveEggs();
	int fridge = FindFridge();
	if (IsValidEntity(fridge) && fridge > MAXPLAYERS)
	{
		eggs = CreateEntityByName("hostage_entity");
		if (IsValidEntity(eggs))
		{
			PrintToChatAll("Spawning eggs");
			float pos[3];
			GetEntPropVector(fridge, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(eggs, pos, NULL_VECTOR, NULL_VECTOR);
		
			DispatchSpawn(eggs);
			ActivateEntity(eggs);
		}
	}
}

public void RemoveEggs() // Crashing server
{
	if (IsValidEntity(eggs))
	{
		RemoveEdict(eggs);
	}
}

int FindFridge() //Can't find fridge model
{
	for (int i = MAXPLAYERS; i < 2048; i++)
	{
		if (IsValidEntity(i))
		{
			char model_name[128];
			GetEntPropString(i, Prop_Data, "m_ModelName", model_name, sizeof(model_name));
			PrintToServer("%s", model_name);
			if (StrEqual(model_name, fridgeModel)){
				PrintToChatAll("%s", model_name);
				return i;
			}
		}
	}
	PrintToChatAll("no fridge found");
	return 0;
}
