CC = ./addons/sourcemod/scripting/spcomp
INC = addons/sourcemod/scripting/include

compile: addons/sourcemod/scripting/karma.sp
	$(CC) addons/sourcemod/scripting/karma.sp -oaddons/sourcemod/plugins/karma.smx -i$(INC)