#include <sourcemod>
#include <dbi>
#include <updater>
#include <steamtools>

#define UPDATE_URL "http://dev.yusufali.ca/plugins/karma/master/"
#define PLUGIN_NAME "PlayTF2 Karma System"
#define AUTHOR "Yusuf Ali"
#define VERSION "0.0"
#define URL "https://github.com/yusuf-a/tf2Skill"
#define STEAMID 32
#define QUERY_SIZE 512

Handle db = null
Handle can_karma = null

public OnPluginStart(){
	SQL_TConnect( gotDB, "default" )

	RegConsoleCmd( "sm_rep", getRep )
	RegConsoleCmd( "sm_giverep", giveRep )

	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}
	can_karma = CreateArray( MaxClients, 0 )
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
	return Plugin_Handled
}
public Action giveRep( client, args ){
	
	return Plugin_Handled
}