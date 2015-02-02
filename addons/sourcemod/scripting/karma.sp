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

Handle minTime_repeat = null
Handle minTime = null
Handle uppBund = null
Handle lowBund = null

Handle sm_ban = null
Handle sm_kick = null
Handle sm_mute = null

bool isSource_2013 = true

public Plugin myinfo = {name = PLUGIN_NAME,author = AUTHOR,description = "",version = VERSION,url = URL};

public OnPluginStart(){
	SQL_TConnect( gotDB, "karma_redux" )

	CreateConVar( "sm_karma_redux_version", VERSION, "", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED )

	minTime_repeat = CreateConVar( "sm_karma_repeatTime", "300", "Cool down time (minutes) to give/remove fame to the same person", FCVAR_NOTIFY )
	minTime = CreateConVar( "sm_karma_minTime", "90", "Cool down time (minutes) to give/remove fame", FCVAR_NOTIFY )
	uppBund = CreateConVar( "sm_karma_upp", "25", "Required upper bound to display fame globally" )
	lowBund = CreateConVar( "sm_karma_low","-10", "Required lower bound to display fame globally" )

	sm_ban = CreateConVar( "sm_karma_ban", "-1", "Amount to defame for being banned" )
	sm_kick = CreateConVar("sm_karma_kick","-1", "Amount to defame for being kicked" )
	sm_mute = CreateConVar("sm_karma_mute","-1", "Amount to defame for being muted" )

	HookEvent("player_disconnect", Event_discon, EventHookMode_Post )

	RegConsoleCmd( "sm_karma", getRep )
	RegConsoleCmd( "sm_rep", giveRep )
	RegConsoleCmd( "sm_plusrep", giveRep )
	RegConsoleCmd( "sm_praise", giveRep )
	RegConsoleCmd( "sm_minusrep", giveRep )
	RegConsoleCmd( "sm_smite", giveRep )

	/* determine if source 2014 or higher */
	isSource_2013 = ( GetEngineVersion() != Engine_CSGO )

	if(	LibraryExists( "updater" )	){
		Updater_AddPlugin(UPDATE_URL)
	}
}

/* when a player sends a request to get their reputation */
#include "karma_getRep.sp"

/* triggered when player says !smite etc rep */
#include "karma_giveRep.sp"

/* determine if player can give rep */
#include "karma_canRep.sp"

/* master function to modify reputation */
#include "karma_modRep.sp"

/* stock functions */
#include "karma_stock.sp"

/* 
	hook for disconnect event
*/
public Action Event_discon( Handle event, const char[] name, bool dB ){
	char reason[STEAMID]
	GetEventString( event, "reason", reason, sizeof(reason) )

	/* ensure it was a kick */
	if( strcmp(reason,"kick") != 0 )
		return Plugin_Continue

	char steamID[STEAMID]
	char p_name[MAX_NAME_LENGTH]

	GetEventString( event, "name", p_name, sizeof(p_name) )
	GetEventString( event, "networkid", steamID, sizeof(steamID) )
	modReputation(
		//0
		 "console"
		, p_name
		, steamID
		, "kicked"
		, GetConVarInt( sm_kick )
		, 0)

	return Plugin_Continue
}

/* 
	forwards for reducing rep upon ban
*/
public Action OnBanClient( client, time, fgs, const char[] r
	, const char[] m, const char[] c, any admin ){

	char ban_nme[MAX_NAME_LENGTH]
	GetClientName( client, ban_nme, MAX_NAME_LENGTH )
	modReputation( 
		//client
		 getSteamID(admin)
		, ban_nme
		, getSteamID(client)
		, r
		, GetConVarInt( sm_ban )
		, 0 )

	return Plugin_Continue
}

/* 
	forwards for when muted/gaged
*/
public Action BaseComm_OnClientMute( client, bool muteState ){
	if( !muteState )
		return Plugin_Continue

	char client_name[MAX_NAME_LENGTH]
	GetClientName( client, client_name, MAX_NAME_LENGTH )
	modReputation(
		//client
		 "console"
		, client_name
		, getSteamID(client)
		, "muted"
		, GetConVarInt( sm_mute )
		, 0
	)

	return Plugin_Continue
}
public Action BaseComm_OnClientGag( client, bool gagState ){
	if( !gagState )
		return Plugin_Continue

	char client_name[MAX_NAME_LENGTH]
	GetClientName( client, client_name, MAX_NAME_LENGTH )
	modReputation(
		//client
		 "console"
		, client_name
		, getSteamID(client)
		, "gagged"
		, GetConVarInt( sm_mute )
		, 0
	)

	return Plugin_Continue
}