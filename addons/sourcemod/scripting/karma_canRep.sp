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

File contains all the functions required to determine
if a player can modify reputation

*/

public query_canRep( Handle o, Handle h, const char[] e, any data ){
	int client = GetClientOfUserId( data )

	if( !IsClientInGame(client) )
		return
	if( h == null )
		printTErr( h, e )
	else{
		while( SQL_FetchRow(h) ){

			int lastRep_inMinutes = SQL_FetchInt( h, 0 )
			
			if( lastRep_inMinutes > GetConVarInt(minTime) ){
				char target[64]
				char reason[64]
				
				int minus_rep = SQL_FetchInt( h, 1 )
				SQL_FetchString( h, 2, target, sizeof(target) )
				SQL_FetchString( h, 3, reason, sizeof(reason) )

				/* determine which client is target */
				char targetName[MAX_NAME_LENGTH]
				int target_list[MAXPLAYERS]
				int target_count
				bool tn_is_ml
				target_count = ProcessTargetString( target, 0, target_list, MAXPLAYERS, 0, targetName, sizeof(targetName), tn_is_ml )
				int target_id = target_list[0]

				/* ensure no targeting error */
				if( target_count != 1 ){
					ReplyToTargetError( client, target_count )
					return
				}

				/* ensure not targeting self */
				if( target_id == client ){
					if( isSource_2013 ){
						CPrintToChat( client, "{GREEN}You cannot target yourself!" )
					}
					else{
						PrintToChat( client, "You cannot target yourself!")
					}
					return
				}

				modReputation( getSteamID( client ), targetName, getSteamID( target_id ) , reason, minus_rep, 1 )
			}
			else{
				if( isSource_2013 ){
					CPrintToChat( client, "{green}You can rep after %d minutes!", GetConVarInt(minTime) - lastRep_inMinutes )
				}
				else{
					PrintToChat( client, "You can rep after %d minutes! ", GetConVarInt(minTime) - lastRep_inMinutes )
				}
			}
		}
	}
}