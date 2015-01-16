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

This file contains general stock functions to 
do some general operations

*/

public general_Tquery( Handle o, Handle h, const char[] e, any data ){
	printTErr( h, e )
	return
}

char[] getSteamID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3, steam_id, STEAMID )
	return steam_id
}

char[] esc_getSteamID( client, bool validate=true ){
	char steam_id[STEAMID*2+1]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3 , steam_id, STEAMID, validate )
	SQL_EscapeString( db, steam_id, steam_id, sizeof(steam_id)  )
	return steam_id
}

printTErr( Handle hndle, const char[] error ){
	if( hndle == null ){
		LogError( "Karma - Query Failed: %s", error )
		return 0
	}
	return 1
}

public gotDB( Handle o, Handle h, const char[] e, any data){
	if( h == null )
		LogError("Database failure: %s", e)
	else
		db = h
}
public OnLibraryAdded(	const char[] name	){
	 if(	StrEqual( name, "updater" )	){
		Updater_AddPlugin( UPDATE_URL )
	 }
}
public Updater_OnPluginUpdated(){
	ReloadPlugin()
}