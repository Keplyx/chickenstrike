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
 
stock bool IsValidClient(int client_index)
{ 
    if (client_index <= 0 || client_index > MaxClients || !IsClientConnected(client_index))
    {
        return false; 
    }
    return IsClientInGame(client_index); 
}  

stock bool IsClientCT(int client_index)
{
	return GetClientTeam(client_index) == CS_TEAM_CT;
}


stock int GetRandomPlayer()
{
	int client_index;
	if (GetClientCount(true) > 0)
	{
		do
		{
		client_index = GetRandomInt(1, MAXPLAYERS);
		}
		while (!IsValidClient(client_index));
		return client_index;
	}
	return 0;
}