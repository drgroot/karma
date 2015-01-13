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


#include "karma_getRep.sp"
#include "karma_giveRep.sp"
#include "karma_canRep.sp"
#include "karma_modRep.sp"
#include "karma_stock.sp"