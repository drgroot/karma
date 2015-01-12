#include <sourcemod>
#include <dbi>
#include <updater>
#include <morecolors>

#define UPDATE_URL "http://dev.yusufali.ca/plugins/karma/master/"
#define PLUGIN_NAME "Karma System REDUX"
#define AUTHOR "Yusuf Ali"
#define VERSION "0.0"
#define URL "https://github.com/yusuf-a/tf2Skill"
#define STEAMID 32
#define QUERY_SIZE 512

Handle db = null
int reputation_hours = 6

public OnPluginStart(){
	SQL_TConnect( gotDB, "default" )

	RegConsoleCmd( "sm_karma", getRep )

	RegConsoleCmd( "sm_rep", giveRep )
	RegConsoleCmd( "sm_plusrep", giveRep )
	RegConsoleCmd( "sm_praise", giveRep )
	RegConsoleCmd( "sm_minusrep", giveRep )
	RegConsoleCmd( "sm_smite", giveRep )

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
				CPrintToChatAll( "Fagtard: {green}%s {normal} has {red}%d {normal} rep. What a turd.",
				name, rep )
			}
			else{
				CPrintToChatAll( "Player: {green}%s {normal} has {green}%d {normal} rep.",
				name, rep )
			}
		}
	}
}

public Action giveRep( client, args ){
	char steamID[STEAMID]
	char command[64]
	char target[64*2+1]
	char reason[64*2+1]
	int minus_rep = 1

	GetCmdArg( 0, command, sizeof(command) )
	GetCmdArg( 1, target, 64 )
	GetCmdArg( 2, reason, 64 )
	steamID = getSteamID( client )

	if( strcmp(command, "sm_smite", true) == 1 || strcmp(command, "sm_minusrep", true) == 1  )
		minus_rep = -1

	/* escape strings */
	SQL_EscapeString( db, target, target, sizeof(target) )
	SQL_EscapeString( db, reason, reason, sizeof(reason) )

	char query[QUERY_SIZE]
	Format( query, sizeof(query), 
	"SELECT TIMESTAMPDIFF(HOUR, lastRep, now() ),%d, '%s','%s' FROM players WHERE steamID = '%s'"
	, steamID, minus_rep, target, reason )

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

			if( lastRep_inHours > reputation_hours ){
				char target[64]
				char reason[64]
				char client_steamID[STEAMID]
				
				int minus_rep = SQL_FetchInt( h, 1 )
				SQL_FetchString( h, 2, target, sizeof(target) )
				SQL_FetchString( h, 3, reason, sizeof(reason) )
				client_steamID = getSteamID( client )

				/* determine which client is target */
				char targetName[MAX_NAME_LENGTH]
				char targetSteamID[STEAMID]
				int target_list[MAXPLAYERS]
				int target_count
				bool tn_is_ml
				target_count = ProcessTargetString( target, client, target_list, MAXPLAYERS, 0, targetName, sizeof(targetName), tn_is_ml )
				int target_id = target_list[0]

				/* ensure no targeting error */
				if( target_count != 1 ){
					ReplyToTargetError( client, target_count )
					return
				}

				/* ensure not targeting self */
				if( target_id == client ){
					CPrintToChat( client, "{GREEN} You cannot target yourself!" )
					return
				}

				targetSteamID = getSteamID( target_id )
				
				modReputation( client, client_steamID, targetName, targetSteamID, reason, minus_rep, 1 )
			}
			else{
				CPrintToChat( client, "{green} You can modify reputation after %d hours!", reputation_hours - lastRep_inHours )
			}
		}
	}
}



modReputation( 
	int client
	, const char[] clientstID
	, const char[] targetName
	, const char[] targetstID
	, const char[] reason 
	, int amount_change
	, int updateTime ){

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
	"INSERT INTO reputation_log (rep, steamID, reason, from) VALUES ( %d, '%s', '%s', '%s')"
	, amount_change, esc_targetstID, esc_reason, esc_clientstID  )

	SQL_TQuery( db, general_Tquery, query, 0 )

	if( updateTime == 1 ){
		Format( query, sizeof(query),
		"UPDATE players SET lastRep = now() WHERE steamID = '%s'"
		, clientstID )
		SQL_TQuery( db, general_Tquery, query, 0 )

		/* Notify client of change */
		if( amount_change > 0 ){
			CPrintToChat( client, "Your rep has increased by {GREEN} %d {DEFAULT} reason: {ORANGE} %s"
				, amount_change, reason)
		}
		else{
			CPrintToChat( client, "Your rep has decreased by {RED} %d {DEFAULT} reason: {ORANGE} %s"
				, amount_change, reason )
		}
	}
	else{
		CPrintToChatAll("Player: %s has had their rep change by {GREEN}%d {DEFAULT} reason: {ORANGE} %s "
			, targetName, amount_change, reason )
	}
}
public general_Tquery( Handle o, Handle h, const char[] e, any data ){
	printTErr( h, e )
	return
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