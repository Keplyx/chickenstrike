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

int eggs = 0;
char eggsModel[] = "models/props/cs_italy/eggplant01.mdl";

char carryHModel[] = "models/hostage/hostage_carry.mdl";
char armHModel[] = "models/hostage/v_hostage_arm.mdl";

ArrayList hostagesList;
int eggsList[20];
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
					CreateEgg(i);
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


void CreateEgg(int hostage)
{
	int i = hostagesList.FindValue(hostage);
	eggs = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(eggs))
	{
		SetEntityModel(eggs, eggsModel);
		DispatchKeyValue(eggs, "solid", "0");
		float pos[3];
		GetEntPropVector(hostage, Prop_Send, "m_vecOrigin", pos);
		pos[0] += 20;
		TeleportEntity(eggs, pos, NULL_VECTOR, NULL_VECTOR);
		//Spawn it!
		DispatchSpawn(eggs);
		ActivateEntity(eggs);
		eggsList[i] = eggs;
	}
}


public void RescueHostage(int client_index, int hostage)
{
	int i = hostagesList.FindValue(hostage);
	hasHostage[client_index] = false;
	SetVariantString(""); AcceptEntityInput(eggsList[i], "SetParent");
	float pos[3];
	GetClientAbsOrigin(client_index, pos);
	TeleportEntity(eggsList[i], pos, NULL_VECTOR, NULL_VECTOR);
}


public void GrabHostage(int client_index, int hostage)
{
	int i = hostagesList.FindValue(hostage);
	hasHostage[client_index] = true;
	// Prevent hostage from appearing on death/rescue
	SDKHook(hostage, SDKHook_SetTransmit, Hook_SetTransmit);
	
	CreateFakeHostage(hostage);
	//Move eggs on chicken
	SetVariantString("!activator"); AcceptEntityInput(eggsList[i], "SetParent", client_index, eggsList[i], 0);
	//Reset rotation and pos
	float rot[3];
	float pos[3];
	pos[2] += 20;
	TeleportEntity(eggsList[i], pos, rot, NULL_VECTOR);
	
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

void ResetData() // Crashing server
{
	for (int i = 0; i < sizeof(eggsList); i++)
	{
		if (IsValidEdict(eggsList[i]) && eggsList[i] != 0)
		{
			RemoveEdict(eggsList[i]);
		}
		eggsList[i] = 0;
		modelsList[i] = "";
	}
	for (int i = 0; i < sizeof(hasHostage); i++)
	{
		hasHostage[i] = false;
	}
	
}
