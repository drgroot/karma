#include <sourcemod>
#include <dbi>
#include <updater>
#include <morecolors>

#define UPDATE_URL "http://dev.yusufali.ca/plugins/karma/master/"
#define PLUGIN_NAME "PlayTF2 Karma System"
#define AUTHOR "Yusuf Ali"
#define VERSION "0.0"
#define URL "https://github.com/yusuf-a/tf2Skill"
#define STEAMID 32
#define QUERY_SIZE 512

Handle db = null

public OnPluginStart(){
	SQL_TConnect( gotDB, "default" )

	RegConsoleCmd( "sm_rep", getRep )
	RegConsoleCmd( "sm_plusrep", giveRep )
	//RegConsoleCmd( "sm_minusrep", )

	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}
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

/* 
	
	Methods for plugin commands

*/
public Action getRep( client, args ){
	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
		"SELECT sum(rep) FROM reputation_log WHERE steamID = '%s'", steamID)

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
				CPrintToChat( client, "Your a nobody, you have no rep" )
			}
			else if( rep < -10 ){
				CPrintToChatAll( "Fagtard: {green}%s {normal} has {red}%d {normal} rep.",
				name, rep )
			}
			else{
				CPrintToChatAll( "Player: {green}%s {normal} has {green}%d {normal} rep!",
				name, rep )
			}
		}
	}
}

public Action giveRep( client, args ){
	char steamID[STEAMID]
	steamID = getSteamID( client )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
"SELECT TIMESTAMPDIFF(HOUR, lastRep, now() ) FROM players WHERE steamID = '%s'"
	, steamID)

	SQL_TQuery( db, query_canRep, query, GetClientUserId(client) )
	
	return Plugin_Handled
}
public query_canRep( Handle o, Handle h, const char[] e, any data ){
	int client = GetClientOfUserId( data )

	if( !IsClientInGame(client) )
		return
	if( h == null )
		printTErr( h, e )
	else{
		while( SQL_FetchRow(h) ){
			int lastRep_inHours = SQL_FetchInt( h, 0 )

			if( lastRep_inHours > 6 ){
				// can give rep
			}
			else{
				CPrintToChat( client, "{green} You can give rep once every 6 hours!" )
			}
		}
	}
}


char[] getSteamID( client ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3, steam_id, STEAMID )
	return steam_id
}
printTErr( Handle hndle, const char[] error ){
	if( hndle == null ){
		LogError( "Karma - Query Failed: %s", error )
		return 0
	}
	return 1
}