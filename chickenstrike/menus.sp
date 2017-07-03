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

#include <menus>

#define IDLE "#idle"
#define PANIC "#panic"

char chickenIdleSounds[][] =  { "ambient/creatures/chicken_idle_01.wav", "ambient/creatures/chicken_idle_02.wav", "ambient/creatures/chicken_idle_03.wav" }
char chickenPanicSounds[][] =  { "ambient/creatures/chicken_panic_01.wav", "ambient/creatures/chicken_panic_02.wav", "ambient/creatures/chicken_panic_03.wav", "ambient/creatures/chicken_panic_04.wav" }

public void Menu_Taunt(int client_index, int args)
{
	Menu menu = new Menu(MenuHandler_Taunt);
	menu.SetTitle("Taunt Menu");
	menu.AddItem(IDLE, "Idle sound");
	menu.AddItem(PANIC, "Panic sound");
	menu.ExitButton = true;
	menu.Display(client_index, MENU_TIME_FOREVER);
}


public int MenuHandler_Taunt(Menu menu, MenuAction action, int param1, int params)
{
	if (action == MenuAction_Select)
	{
		char buffer[64];
		menu.GetItem(params, buffer, sizeof(buffer));
		if (StrEqual(buffer, IDLE))
		PlayRandomIdleSound(param1);
		else if (StrEqual(buffer, PANIC))
		PlayRandomPanicSound(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void PlayRandomPanicSound(int client_index)
{
	int rdmSound = GetRandomInt(0, sizeof(chickenPanicSounds) - 1);
	EmitSoundToAll(chickenPanicSounds[rdmSound], client_index);
	PrintToConsole(client_index, "Playing panic sound");
}

void PlayRandomIdleSound(int client_index)
{
	int rdmSound = GetRandomInt(0, sizeof(chickenIdleSounds) - 1);
	EmitSoundToAll(chickenIdleSounds[rdmSound], client_index);
	PrintToConsole(client_index, "Playing idle sound");
}
