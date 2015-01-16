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

File contains functions to actually modify the
reputation ones it has been verfied

*/ 

modReputation( 
	//int client 					// target's clientID
	 const char[] clientstID 	// client's steamID
	, const char[] targetName 	// target's name
	, const char[] targetstID 	// target's steamID
	, const char[] reason 		// reason for modification
	, int amount_change 		// amount of rep to change by
	, int updateTime ){			// 1 | 0, update lastRep time or not

	/* decl buffs for escape strings */
	char esc_clientstID[STEAMID*2+1]
	char esc_targetstID[STEAMID*2+1]
	char esc_reason[64*2+1]

	/* escape string */
	SQL_EscapeString( db, clientstID, esc_clientstID, sizeof(esc_clientstID) )
	SQL_EscapeString( db, targetstID, esc_targetstID, sizeof(esc_targetstID) )
	SQL_EscapeString( db, reason, esc_reason, sizeof(esc_reason) )

	/* insert into reputation log */
	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
	"INSERT INTO players_reputation (rep, steamID, reason, `from`) VALUES ( %d, '%s', '%s', '%s')"
	, amount_change, esc_targetstID, esc_reason, esc_clientstID  )
	
	SQL_TQuery( db, general_Tquery, query, 0 )

	if( updateTime == 1 ){
		Format( query, sizeof(query),
		"UPDATE players SET lastRep = now() WHERE steamID = '%s'"
		, clientstID )
		SQL_TQuery( db, general_Tquery, query, 0 )
	}

	/* Notify client of change */
	if( amount_change > 0 ){
		if( isSource_2013 ){
			CPrintToChatAll( "%s's rep has increased by {GREEN}%d{DEFAULT}. reason: {ORANGE}%s"
					, targetName , amount_change, reason)
		}
		else{
			PrintToChatAll( "%s's rep has increased by %d. reason: %s", targetName, amount_change, reason )
		}
	}
	else{
		if( isSource_2013 ){
			CPrintToChatAll( "%s's rep has decreased by {RED}%d{DEFAULT}. reason: {ORANGE}%s"
					, targetName, -1*amount_change, reason )
		}
		else{
			PrintToChatAll( "%s's rep has decreased by %s. reason: %s", targetName, -1*amount_change, reason )
		}
	}
}