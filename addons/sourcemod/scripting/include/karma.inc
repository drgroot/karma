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

#if defined _karma_system_redux_included_
	#endinput
#endif
#define _karma_system_redux_included_

/*

	Returns a player's karma given userid

	@param userid		Userid of player
	@param callback		Callback function when it is complete
	
	@return 			void
*/
native karma_redux_getKarma( userid, callback )


