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

This file contains the functions that are 
triggered when a player uses commands to 
modify rep or karma

*/

public Action giveRep( client, args ){
	char command[64]
	char target[MAX_NAME_LENGTH*2+1]
	char reason[64*2+1]
	int minus_rep = 1

	GetCmdArg( 0, command, sizeof(command) )
	GetCmdArg( 1, target, MAX_NAME_LENGTH )
	GetCmdArg( 2, reason, 64 )

	/* ensure correct syntax is being used */
	if( GetCmdArgs() == 0 && strcmp(command,"sm_rep") == 0){
		getRep( client, args )
		return Plugin_Handled
	}
	else{

		if( GetCmdArgs() != 2 ){
			PrintToChat( client, "Usage: %s <target> \"<reason>\"", command )
			return Plugin_Handled
		}

		if( strcmp(command, "sm_smite") == 0 || strcmp(command, "sm_minusrep") == 0  )
			minus_rep = -1

		/* escape strings */
		SQL_EscapeString( db, target, target, sizeof(target) )
		SQL_EscapeString( db, reason, reason, sizeof(reason) )

		char query[QUERY_SIZE]
		Format( query, sizeof(query), 
		"SELECT TIMESTAMPDIFF(MINUTE, lastRep, now() ),%d, '%s','%s' FROM players WHERE steamID = '%s'"
		, minus_rep, target, reason, getSteamID( client ) )
		
		SQL_TQuery( db, query_canRep, query, GetClientUserId(client) )
		
		return Plugin_Handled

	}
}