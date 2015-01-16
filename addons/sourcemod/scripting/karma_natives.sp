/*
This file is part of Karma Redux.

Karma Redux is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Karma Redux is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Karma Redux.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
	this file deals with all natives associated with karma redux
*/
public native_get_karma( Handle plugin, numParams ){
	int userid = GetNativeCell( 1 )
	int client = GetClientOfUserId( userid )

	if( !IsClientInGame(client) )
		return ThrowNativeError( SP_ERROR_NATIVE, "Client not connected" )

	char query[QUERY_SIZE]
	Format( query, sizeof(query),
"SELECT SUM(rep),%d FROM players_reputation WHERE steamID = '%s' "
	, userid, esc_getSteamID(client) )

	SQL_TQuery( db, native_get_karma_callback, query, plugin )
	AddToForward( g_player_karma, plugin, GetNativeCell(2) )
	
	return 1
}

public native_get_karma_callback( Handle o, Handle h, const char[] e, any plugin ){
	int userid = -1
	int karma = 0

	while( SQL_FetchRow(h) ){
		karma = SQL_FetchInt( h, 1 )
		userid = SQL_FetchInt( h, 2 )
	}

	Call_StartForward( g_player_karma )
	Call_PushCell( userid )
	Call_PushCell( karma )
	Call_Finish()
	RemoveAllFromForward( g_player_karma, plugin )
}