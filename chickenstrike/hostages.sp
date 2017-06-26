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
#include <sdkhooks>

char eggModel[] = "models/chicken/festive_egg.mdl";
char eggBoxModel[] = "models/props_junk/garbage_sixpackbox01a_fullsheet.mdl"

char carryHModel[] = "models/hostage/hostage_carry.mdl";
char armHModel[] = "models/hostage/v_hostage_arm.mdl";

ArrayList hostagesList;
int eggsList[20][7];
char modelsList[20][128];
float spawnPointsList[20][2][3];

bool hasHostage[MAXPLAYERS + 1];

// Place eggs next to hostages, chicken will save eggs instead of hostage

public void SpawnEggs()
{
	hostagesList = new ArrayList();
	ResetData();
	for (int i = MAXPLAYERS; i <= GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			char classname[64];
			if(GetEdictClassname(i, classname, sizeof(classname))){
				if(StrEqual(classname, "hostage_entity",false))
				{
					hostagesList.Push(i);
					CreateEggs(i);
					GetHostageModel(i);
					GetHostageSpawn(i);
				}
			}
		}
	}
}

void GetHostageSpawn(int hostage)
{
	int i = hostagesList.FindValue(hostage);
	GetEntPropVector(hostage, Prop_Send, "m_vecOrigin", spawnPointsList[i][0]);
	GetEntPropVector(hostage, Prop_Send, "m_angRotation", spawnPointsList[i][1]);
	
}

void GetHostageModel(int hostage)
{
	int i = hostagesList.FindValue(hostage);
	char modelName[PLATFORM_MAX_PATH];
	GetEntPropString(hostage, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	Format(modelsList[i], sizeof(modelsList[]), "%s", modelName);
	//PrintToServer("hostage model: %s", modelsList[i]);
}


void CreateEggs(int hostage)
{
	CreateEggBox(hostage);
	int h = hostagesList.FindValue(hostage);
	for (int i = 1; i < sizeof(eggsList[]); i++)
	{
		eggsList[h][i] = CreateEntityByName("prop_dynamic_override");
		if (IsValidEntity(eggsList[h][i]))
		{
			SetEntityModel(eggsList[h][i], eggModel);
			DispatchKeyValue(eggsList[h][i], "solid", "0");
			SetVariantString("!activator"); AcceptEntityInput(eggsList[h][i], "SetParent", eggsList[h][0], eggsList[h][i], 0);
			float pos[3];
			pos[1] += 5;
			pos[0] += 1.5;
			if (i % 2)
				pos[1] -= i*(1.7);
			else
			{
				pos[1] -= (i - 1)*(1.7);
				pos[0] -= 3;
			}
			TeleportEntity(eggsList[h][i], pos, NULL_VECTOR, NULL_VECTOR);
			
			//Spawn it!
			DispatchSpawn(eggsList[h][i]);
			ActivateEntity(eggsList[h][i]);
		}
	}
	
}

void CreateEggBox(int hostage)
{
	int h = hostagesList.FindValue(hostage);
	eggsList[h][0] = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(eggsList[h][0]))
	{
		SetEntityModel(eggsList[h][0], eggModel);
		DispatchKeyValue(eggsList[h][0], "solid", "0");
		float pos[3];
		GetEntPropVector(hostage, Prop_Send, "m_vecOrigin", pos);
		pos[0] += 20;
		pos[2] += 5;
		TeleportEntity(eggsList[h][0], pos, NULL_VECTOR, NULL_VECTOR);
		//Spawn it!
		DispatchSpawn(eggsList[h][0]);
		ActivateEntity(eggsList[h][0]);
	}
}

public void RescueHostage(int client_index, int hostage)
{
	int i = hostagesList.FindValue(hostage);
	hasHostage[client_index] = false;
	SetVariantString(""); AcceptEntityInput(eggsList[i][0], "SetParent");
	float pos[3];
	GetClientAbsOrigin(client_index, pos);
	TeleportEntity(eggsList[i][0], pos, NULL_VECTOR, NULL_VECTOR);
}


public void GrabHostage(int client_index, int hostage)
{
	int i = hostagesList.FindValue(hostage);
	hasHostage[client_index] = true;
	// Prevent hostage from appearing on death/rescue
	SDKHook(hostage, SDKHook_SetTransmit, Hook_SetTransmit);
	
	CreateFakeHostage(hostage);
	//Move eggs on chicken
	SetVariantString("!activator"); AcceptEntityInput(eggsList[i][0], "SetParent", client_index, eggsList[i][0], 0);
	//Reset rotation and pos
	float rot[3];
	float pos[3];
	pos[0] -= 3;
	pos[2] += 15;
	TeleportEntity(eggsList[i][0], pos, rot, NULL_VECTOR);
	
	// Hide the real hostage
	CreateTimer(0.1, HideCarriedHostage, client_index);
}

void CreateFakeHostage(int hostage)
{
	int i = hostagesList.FindValue(hostage);
	int fakeH = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(fakeH))
	{
		SetEntityModel(fakeH, modelsList[i]);
		//DispatchKeyValue(fakeH, "solid", "1"); // Can get the player stuck
		TeleportEntity(fakeH, spawnPointsList[i][0], spawnPointsList[i][1], NULL_VECTOR);
		//Spawn it!
		DispatchSpawn(fakeH);
		ActivateEntity(fakeH);
		SetVariantString("Waiting"); AcceptEntityInput(fakeH, "SetAnimation");
	}
}

public Action HideCarriedHostage(Handle timer, any ref)
{
	for (int i = MAXPLAYERS; i <= GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			char modelName[PLATFORM_MAX_PATH];
			GetEntPropString(i, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
			if(StrEqual(carryHModel, modelName,false) || StrEqual(armHModel, modelName,false))
			{
				SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
	}
}

void ResetData()
{
	for (int i = 0; i < sizeof(eggsList); i++)
	{
		for (int j = 0; j < sizeof(eggsList[]); j++)
		{
			if (IsValidEdict(eggsList[i][j]) && eggsList[i][j] != 0)
			{
				RemoveEdict(eggsList[i][j]);
			}
			eggsList[i][j] = 0;
			modelsList[i] = "";
		}
	}
	for (int i = 0; i < sizeof(hasHostage); i++)
	{
		hasHostage[i] = false;
	}
	
}
