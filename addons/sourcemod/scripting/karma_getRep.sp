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

This function handles when a query is done to return
a players rep or karma

*/

public Action getRep( client, args ){
	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
		"SELECT sum(rep) FROM players_reputation WHERE steamID = '%s'", steamID)

	SQL_TQuery( db, query_getRep, query, GetClientUserId(client) )

	return Plugin_Handled
}

public query_getRep( Handle o, Handle h, const char[] e, any data ){
	int client = GetClientOfUserId( data )

	if( !IsClientInGame(client) )
		return
	if( h == null )
		printTErr( h, e )
	else{
		while( SQL_FetchRow(h) ){
			int rep = SQL_FetchInt( h, 0 )

			char name[MAX_NAME_LENGTH]
			GetClientName( client, name, sizeof(name) )

			if( rep == 0){
				PrintToChat( client, "Your a nobody, you have no rep" )
			}
			else if( rep <= GetConVarInt(lowBund) ){
				if( isSource_2013 ){
					CPrintToChatAll( "Fagtard: {green}%s{DEFAULT} has {red}%d{DEFAULT} rep. What a turd.",
					name, rep )
				}
				else{
					PrintToChatAll( "Fagtard: %s has %d rep. What a turd.", name, rep )
				}
			}
			else if( rep >= GetConVarInt(uppBund) ){
				if( isSource_2013 ){
					CPrintToChatAll( "Player: {green}%s{DEFAULT} has {green}%d{DEFAULT} rep.",
					name, rep )
				}
				else{
					PrintToChatAll( "Player: %s has %d rep.", name, rep )
				}
			}
			else{
				if( isSource_2013 ){
					CPrintToChat( client, "Your have {GREEN}%d{DEFAULT} reputation", rep )	
				}
				else{
					PrintToChat( client, "You have %d reputation", rep )
				}
			}
		}
	}
}