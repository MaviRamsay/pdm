/*
* Private Death Match v0.1
* Website: pawn-wiki.ru
** � Mavi, 2017 - 2020
* August, 2020
*/


/* ####################### Libs ####################### */

#include <a_samp>
#include <Pawn.CMD>
#include <sscanf2>
#include <foreach>
#include <colandreas>
#include <3dtrug>

#define TDW_DIALOG_SKIP_ARGS // ����� �� ��������, ������ ����� ��������� tdw_dialog! 
#include "../sources/libs/tdw_dialog"

/* ####################### Defines ####################### */

#define FILTERSCRIPT 

#define MAX_LOCATIONS MAX_PLAYERS // ���-�� ����. ������� (default = max players)
#define MAX_LOCATION_PLAYERS (10) // ���-�� ����. ������� � ����� �������

/*
* �������� ���������� ����,
* ������ ������ �����, ����� ������ ��������� ����� ����� ��� ������
* �������� �������� ��������� ����� ������ ������
*/
#define MAP_DIALOG_STRING_LENGTH (44) 
#define WEAPON_DIALOG_STRING_LENGTH (108)  

// ������� ����-����� 
#define ClearDeathMessageToPlayer(%0) for(new f; f<6;f++) SendDeathMessageToPlayer(%0, 6000, 5005, 255)
/* ###################################################### */

enum LOCATION_INFO_
{
	lCreator,
	lMap,
	lWorld,
	lWeaponPackID
}
new LocationInfo[MAX_LOCATIONS][LOCATION_INFO_];

enum PLAYER_INFO_
{
	pLocation,
	pSelectedLocation,
	bool: IsCreator,
	bool: IsSpawnedInLoc,
	Float:lastX,
	Float:lastY,
	Float:lastZ,
	pWorld, 
	pInterior,
	bool:pInvite,
	pInviteSender,
	pTabClickID
}
new PlayerInfo[MAX_PLAYERS][PLAYER_INFO_];

new Iterator: LocationPlayers[MAX_LOCATIONS]<MAX_PLAYERS>;

new MapNames[][] = // �������� ����
{
	"Old Country",
	"Ghetto Factory",
	"Rancho",
	"Mountain"
};

new WeaponInfo[][] = // weapon 1, weapon 2, string
{
	{24, 31, "Desert Eagle & M4A1"},
	{24, 25, "Desert Eagle & Shotgun"},
	{24, 33, "Desert Eagle & Rifle"},
	{31, 25, "M4A1 & Shotgun"},
	{31, 33, "M4A1 & Rifle"},
	{25, 33, "Shotgun & Rifle"}
};

new Float: MapGangZoneInfo[][] = // min_x, min_y, max_x, max_y
{
	{-470.0, 2180.0, -340.0, 2297.0}, // Old Country
	{2326.0, -2149.0, 2550.0, -2061.0}, // Ghetto Factory
	{-775.0, 906.5, -629.0, 1008.5}, // Rancho
	{973.0, -383.0, 1163.0, -276.0} // Mountain
};

new MapGangzone[sizeof MapGangZoneInfo];
/* ################################################## */

static const LOCATION_INFO_EOS[LOCATION_INFO_] =
{
	-1, 
	-1,
	-1,
	-1
};

static const PLAYER_INFO_EOS[PLAYER_INFO_] =
{
	-1, 
	-1,
	false,
	false,
	0.0,
	0.0,
	0.0,
	0, 
	0, 
	false,
	-1,
	0
};

/* ################################################# */
main(){}

public OnFilterScriptInit()
{
	for(new l = 0; l < MAX_LOCATIONS; l++)
	{
		LocationInfo[l] = LOCATION_INFO_EOS;
	}

	foreach(new p : Player)
	{
		PlayerInfo[p] = PLAYER_INFO_EOS;
	}

	for(new g = 0; g < sizeof MapGangzone; g++)
	{
		MapGangzone[g] = GangZoneCreate(MapGangZoneInfo[g][0], MapGangZoneInfo[g][1], MapGangZoneInfo[g][2], MapGangZoneInfo[g][3]);
	}

	Iter_Init(LocationPlayers);

	print("Private Death Match loaded");
	return 1;
}

public OnFilterScriptExit()
{
	for(new l = 0; l < MAX_LOCATIONS; l++)
	{
		LocationInfo[l] = LOCATION_INFO_EOS;
	}

	foreach(new p : Player)
	{
		PlayerInfo[p] = PLAYER_INFO_EOS;
	}
	
	print("Private Death Match unloaded");

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID && PlayerInfo[playerid][IsSpawnedInLoc] && PlayerInfo[killerid][IsSpawnedInLoc])
	{
		new loc = PlayerInfo[killerid][pLocation];

		foreach(new p : LocationPlayers[loc])
		{
			SendDeathMessageToPlayer(p, killerid, playerid, reason);	
		}
	}

	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	if(playerid == clickedplayerid) return 1;

	if(LocationInfo[playerid][lCreator] == playerid) 
	{
		PlayerInfo[playerid][pTabClickID] = clickedplayerid;
		Dialog_Show(playerid, "OnClickDialog");
	}

	return 1;
}

public OnPlayerConnect(playerid)
{
	foreach(new p : Player)
	{
		PlayerInfo[p] = PLAYER_INFO_EOS;
	}
}

public OnPlayerDisconnect(playerid, reason)
{
	if(LocationInfo[playerid][lCreator] == playerid)
	{
		DeleteLocation(playerid, "������� ���� �������, ��������� ������� �� ����.");
	}
	
	foreach(new p : Player)
	{
		PlayerInfo[p] = PLAYER_INFO_EOS;
	}
}

public OnPlayerSpawn(playerid)
{
	if(PlayerInfo[playerid][IsSpawnedInLoc]) 
	{
		new 
			Float:x, 
			Float:y, 
			Float:z, 
			loc = PlayerInfo[playerid][pLocation],
			map = LocationInfo[loc][lMap], 
			world = LocationInfo[loc][lWorld];

		RandomCoordinateToRect(MapGangZoneInfo[map][0], MapGangZoneInfo[map][1], MapGangZoneInfo[map][2], MapGangZoneInfo[map][3], x, y, z);

		SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), x, y, z, 0.0, 0, 0, 0, 0, 0, 0);
		SetPlayerVirtualWorld(playerid, world);

		GivePlayerWeapon(playerid, WeaponInfo[LocationInfo[loc][lWeaponPackID]][0], 9999);
		GivePlayerWeapon(playerid, WeaponInfo[LocationInfo[loc][lWeaponPackID]][1], 9999);
	}

	return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(PlayerInfo[playerid][pInvite])
	{
		if(newkeys & KEY_YES || newkeys & KEY_NO) 
		{
			{
				static const fmt_msg[] = "%s {027D0E}������ ���� �����������!";
				static const fmt_msg2[] = "%s {BC2C2C}��������� �� ������ �����������!";

				new name[MAX_PLAYER_NAME - 3], message[sizeof fmt_msg + MAX_PLAYER_NAME - 3];

				GetPlayerName(playerid, name, sizeof name);
				format(message, sizeof message, (newkeys & KEY_YES) ? fmt_msg : fmt_msg2, name);
				SendClientMessage(PlayerInfo[playerid][pInviteSender], 0xFFFFFFFF, message);
			}

			if(newkeys & KEY_YES) AddPlayerToLocation(playerid, PlayerInfo[playerid][pInviteSender]);

			PlayerInfo[playerid][pInvite] = false;
			PlayerInfo[playerid][pInviteSender] = -1;
		}
	}
}
/* ########################################################## */

CMD:createpdm(playerid, params[]) 
{
	if(PlayerInfo[playerid][pLocation] != -1) return SendClientMessage(playerid, 0xACACACFF, !"������� �������� ������� �������!");
	return Dialog_Show(playerid, "SelectMap");
}

CMD:pexit(playerid, params[])
{
	if(!PlayerInfo[playerid][IsSpawnedInLoc]) return SendClientMessage(playerid, 0xACACACFF, !"�� �� � �������!");

	new loc = PlayerInfo[playerid][pLocation];
	if(LocationInfo[loc][lCreator] != playerid)
	{
		Iter_Remove(LocationPlayers[loc], playerid);
		RemovePlayerAtLocation(playerid);

		SendClientMessage(playerid, 0x027D0EFF, !"�� ������� �������� �����!");
	}
	else Dialog_Show(playerid, "LeaveLocation");

	return 1;
}

CMD:pinvite(playerid, params[])
{
	if(LocationInfo[playerid][lCreator] != playerid) return SendClientMessage(playerid, 0xACACACFF, !"��� �������");
	if(Iter_Count(LocationPlayers[playerid]) >= MAX_LOCATION_PLAYERS) return SendClientMessage(playerid, 0xACACACFF, "� ������� ��� ������ ����");

	extract params -> new id; else return SendClientMessage(playerid, 0xFFFFFFFF, !"�������: /pinvite [id]");

	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xACACACFF, !"������ ��� � ����.");
	if(playerid == id) return SendClientMessage(playerid, 0xACACACFF, !"�� ������� ���� ID!");
	if(PlayerInfo[id][pInvite]) return SendClientMessage(playerid, 0xACACACFF, !"� ������ ��� ������� ������ ������");
	if(PlayerInfo[id][pLocation] != -1) return SendClientMessage(playerid, 0xACACACFF, !"����� � ������ �������");

	{
		static const fmt_msg[] = "%s {056D9A}���������� ��� ������������ � ����� �������. ��� �� �� ��� ��������?"; 
		new message[sizeof fmt_msg + MAX_PLAYER_NAME - 3], name[MAX_PLAYER_NAME-3];
		GetPlayerName(playerid, name, sizeof name);

		format(message, sizeof message, fmt_msg, name);
		SendClientMessage(id, 0xFFFFFFFF, message);
		SendClientMessage(id, 0xFFFFFFFF, !"{4ABB05}""Y"" - �����������. {F3051E}""N"" - ����������");
	}

	PlayerInfo[id][pInvite] = true;
	PlayerInfo[id][pInviteSender] = playerid;

	return SendClientMessage(playerid, 0x027D0EFF, !"����������� ������� ����������! �������� ������...");
}

CMD:pkick(playerid, params[])
{
	if(LocationInfo[playerid][lCreator] != playerid) return SendClientMessage(playerid, 0xACACACFF, !"��� �������");

	extract params -> new id; else return SendClientMessage(playerid, 0xFFFFFFFF, !"�������: /pkick [id]");

	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, 0xACACACFF, !"������ ��� � ����.");
	if(playerid == id) return SendClientMessage(playerid, 0xACACACFF, !"�� ������� ���� ID!");
	if(PlayerInfo[id][pLocation] != playerid) return SendClientMessage(playerid, 0xACACACFF, !"����� �� ��������� � ����� �������");

	Iter_Remove(LocationPlayers[PlayerInfo[id][pLocation]], playerid);
	RemovePlayerAtLocation(id);

	SendClientMessage(playerid, 0x027D0EFF, !"����� �������� �� �������.");
	return SendClientMessage(id, 0xF90627FF, !"��������� ������� �������� ��� �� �������");
}

/* ###################### Dialogs ########################### */


dtempl SelectMap(playerid)
{
	new body[MAP_DIALOG_STRING_LENGTH];
	for(new m = 0; m < sizeof MapNames; m++) 
	{
		strcat(body, MapNames[m]);
		strcat(body, "\n");
	}

	Dialog_Open(playerid, dfunc:SelectMap, DIALOG_STYLE_LIST, "����� | {BC2C2C}�����", body, "�������", "������");
}

dialog SelectMap(playerid, response, listitem)
{
	if(response) 
	{
		PlayerInfo[playerid][pSelectedLocation] = listitem;

		{
			new message[41];
			format(message, sizeof message, "������� ������� � {FFFFFF}""%s""", MapNames[listitem]);
			SendClientMessage(playerid, 0x027D0EFF, message);
		}

		Dialog_Show(playerid, "SelectWeapon");
	}
	else if(PlayerInfo[playerid][pLocation] != -1) PlayerInfo[playerid][pLocation] = -1;
}

dtempl SelectWeapon(playerid)
{
	new body[WEAPON_DIALOG_STRING_LENGTH];

	for(new w = 0; w < sizeof WeaponInfo; w++) 
	{
		strcat(body, WeaponInfo[w][2]);
		strcat(body, "\n");
	}

	Dialog_Open(playerid, dfunc:SelectWeapon, DIALOG_STYLE_LIST, "����� | {BC2C2C}������", body, "�������", "�����");
}

dialog SelectWeapon(playerid, response, listitem)
{
	if(response) 
	{
		{
			new message[46];
			format(message, sizeof message, "������ ����� � {FFFFFF}%s", WeaponInfo[listitem][2]);
			SendClientMessage(playerid, 0x027D0EFF, message);
		}

		LocationInfo[playerid][lCreator] = playerid;
		LocationInfo[playerid][lMap] = PlayerInfo[playerid][pSelectedLocation];
		LocationInfo[playerid][lWorld] = playerid + INVALID_PLAYER_ID;
		LocationInfo[playerid][lWeaponPackID] = listitem;

		SendClientMessage(playerid, 0x027D0EFF, !"������� ������� �������. ���������� ������ �������� {FFFFFF}""/pinvite"" {027D0E}��� �������� �� ��� � TAB");
		SendClientMessage(playerid, 0xEEF90AFF, !"�������� ������� ����� �������� {EEF90A}""/pexit"". {FFFFFF}���� �������� ������� �� - ��� ����� ������� �������������!");

		AddPlayerToLocation(playerid, playerid);
	}
	else Dialog_Show(playerid, "SelectMap");
}
dtempl LeaveLocation(playerid)
{
	Dialog_Open(playerid, dfunc:LeaveLocation, DIALOG_STYLE_MSGBOX, !"����� | {BC2C2C}�������������", 
	!"�� ����� ������ �������� � {BC2C2C}������� �������?", !"��", !"���");
}
dialog LeaveLocation(playerid, response)
{
	if(response)
	{
		DeleteLocation(playerid, "������� ���� ������� ����������. ��� ������ ���� ���������");

		SendClientMessage(playerid, 0x027D0EFF, !"������� ������� ���� �������. ��� ��������� ���� ���������");
	}
}

dtempl OnClickDialog(playerid)
{
	Dialog_Open(playerid, dfunc:OnClickDialog, DIALOG_STYLE_LIST, !"��������", !"���������� � �������\n��������� �� �������", !"�������", !"������");
}

dialog OnClickDialog(playerid, response, listitem)
{
	if(response)
	{
		new params[3];
		valstr(params, PlayerInfo[playerid][pTabClickID]);

		if(listitem == 0) 
			callcmd::pinvite(playerid, params);
		else 
			callcmd::pkick(playerid, params);

		PlayerInfo[playerid][pTabClickID] = -1;
	}
}
/* *************************************************** */

stock RandomCoordinateToRect(Float:min_x, Float:min_y, Float:max_x, Float:max_y, &Float: posX, &Float: posY, &Float: posZ)
{
	do
	{
		GetRandomPointInRectangle(min_x, min_y, max_x, max_y, posX, posY);
		CA_FindZ_For2DCoord(posX, posY, posZ);
	}
	while(IsPointInWater(posX, posY, posZ));
}  

stock AddPlayerToLocation(playerid, loc)
{
	new 
		Float:x,
		Float:y, 
		Float:z, 
		map = LocationInfo[loc][lMap];
	
	GetPlayerPos(playerid, PlayerInfo[playerid][lastX], PlayerInfo[playerid][lastY], PlayerInfo[playerid][lastZ]);

	PlayerInfo[playerid][pWorld] = GetPlayerVirtualWorld(playerid);
	PlayerInfo[playerid][pInterior] = GetPlayerInterior(playerid);
	PlayerInfo[playerid][pLocation] = loc;
	PlayerInfo[playerid][IsSpawnedInLoc] = true;
			
	RandomCoordinateToRect(MapGangZoneInfo[map][0], MapGangZoneInfo[map][1], MapGangZoneInfo[map][2], MapGangZoneInfo[map][3], x, y, z);
	Iter_Add(LocationPlayers[loc], playerid);
	GangZoneShowForPlayer(playerid, MapGangzone[map], 0xF00000AA);
	
	SetSpawnInfo(playerid, NO_TEAM, GetPlayerSkin(playerid), x, y, z, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
}

stock RemovePlayerAtLocation(p)
{
	GangZoneHideForPlayer(p, MapGangzone[LocationInfo[PlayerInfo[p][pLocation]][lMap]]);

	PlayerInfo[p][pLocation] = -1;
	PlayerInfo[p][IsSpawnedInLoc] = false;
	ClearDeathMessageToPlayer(p);
	ResetPlayerWeapons(p);		

	SetPlayerPos(p, PlayerInfo[p][lastX], PlayerInfo[p][lastY], PlayerInfo[p][lastZ]);
	SetPlayerVirtualWorld(p, PlayerInfo[p][pWorld]);
	SetPlayerInterior(p, PlayerInfo[p][pInterior]);

	SetSpawnInfo(p, NO_TEAM, GetPlayerSkin(p), 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
}

stock DeleteLocation(loc, const reason[])
{
	foreach(new p : LocationPlayers[loc])
	{
		RemovePlayerAtLocation(p);
		SendClientMessage(p, 0xBC2C2CFF, reason);
	}

	Iter_Clear(LocationPlayers[loc]);
	LocationInfo[loc] = LOCATION_INFO_EOS;
}