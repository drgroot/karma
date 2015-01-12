#include <sourcemod>
#include <dbi>
#include <updater>
#include <morecolors>

#define UPDATE_URL "http://dev.yusufali.ca/plugins/karma/master/"
#define PLUGIN_NAME "Karma System REDUX"
#define AUTHOR "Yusuf Ali"
#define VERSION "0.0"
#define URL "http://git.yusufali.ca/yusuf_ali/karma"
#define STEAMID 32
#define QUERY_SIZE 512

Handle db = null
Handle minTime = null
Handle uppBund = null
Handle lowBund = null

public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	SQL_TConnect( gotDB, "default" )

	CreateConVar( "sm_karma_version", VERSION, "", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED )
	minTime = CreateConVar( "sm_karma_minTime", "90", "Cool down time to give/remove fame", FCVAR_NOTIFY )
	uppBund = CreateConVar( "sm_karma_upp", "25", "Required upper bound to display fame globally" )
	lowBund = CreateConVar( "sm_karma_low","-10", "Required lower bound to display fame globally" )

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
				CPrintToChat( client, "Your a nobody, you have no rep" )
			}
			else if( rep <= GetConVarInt(lowBund) ){
				CPrintToChatAll( "Fagtard: {green}%s{normal} has {red}%d{normal} rep. What a turd.",
				name, rep )
			}
			else if( rep >= GetConVarInt(uppBund) ){
				CPrintToChatAll( "Player: {green}%s{normal} has {green}%d{normal} rep.",
				name, rep )
			}
			else{
				CPrintToChat( client, "Your have {GREEN}%d{NORMAL} reputation", rep )	
			}
		}
	}
}

public Action giveRep( client, args ){
	char command[64]
	char target[64*2+1]
	char reason[64*2+1]
	int minus_rep = 1

	GetCmdArg( 0, command, sizeof(command) )
	GetCmdArg( 1, target, 64 )
	GetCmdArg( 2, reason, 64 )

	/* ensure correct syntax is being used */
	if( GetCmdArgs() == 0 && strcmp(command,"sm_rep") == 0){
		getRep( client, args )
		return Plugin_Handled
	}
	else{

		if( GetCmdArgs() != 2 ){
			CPrintToChat( client, "Usage: %s <target> \"<reason>\"", command )
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
					CPrintToChat( client, "{GREEN}You cannot target yourself!" )
					return
				}

				modReputation( target_id, getSteamID( client ), targetName, getSteamID( target_id ) , reason, minus_rep, 1 )
			}
			else{
				CPrintToChat( client, "{green}You can modify reputation after %d minutes!", lastRep_inMinutes - GetConVarInt(minTime) )
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
	"INSERT INTO players_reputation (rep, steamID, reason, `from`) VALUES ( %d, '%s', '%s', '%s')"
	, amount_change, esc_targetstID, esc_reason, esc_clientstID  )
	
	SQL_TQuery( db, general_Tquery, query, 0 )

	if( updateTime == 1 ){
		Format( query, sizeof(query),
		"UPDATE players SET lastRep = now() WHERE steamID = '%s'"
		, clientstID )
		SQL_TQuery( db, general_Tquery, query, 0 )

		/* Notify client of change */
		if( amount_change > 0 ){
			CPrintToChat( client, "Your rep has increased by {GREEN}%d{DEFAULT} reason: {ORANGE}%s"
				, amount_change, reason)
		}
		else{
			CPrintToChat( client, "Your rep has decreased by {RED}%d{DEFAULT} reason: {ORANGE}%s"
				, amount_change, reason )
		}
	}
	else{
		CPrintToChatAll("Player: %s has had their rep change by {GREEN}%d{DEFAULT} reason: {ORANGE}%s "
			, targetName, amount_change, reason )
	}
}
public general_Tquery( Handle o, Handle h, const char[] e, any data ){
	printTErr( h, e )
	return
}

public OnClientPostAdminCheck( client ){
	if( IsNotClient(client) )
		return

	char query[QUERY_SIZE]
	char esc_steamID[STEAMID*2+1]

	SQL_EscapeString( db, getSteamID(client), esc_steamID, sizeof(esc_steamID) )
	Format( query, sizeof(query),
	"INSERT IGNORE INTO players (steamID) VALUES('%s')", esc_steamID)

	SQL_TQuery( db, general_Tquery, query, 0 )
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
bool IsNotClient( client ) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
		return true;
	return false;
}