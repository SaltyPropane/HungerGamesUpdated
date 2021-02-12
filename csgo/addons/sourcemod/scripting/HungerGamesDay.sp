#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Salty"
#define PLUGIN_VERSION "69.00"

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <cstrike>



//Globals
int Tcolors[MAXPLAYERS + 1][4];
int dayCount = 0;
//beacon shit
bool g_bBeacon[MAXPLAYERS + 1];
int g_iModelSprite;
int g_iHaloSprite;

#pragma newdecls required

//ConVars
ConVar g_cvFriendlyFire;
float g_fctSpawnLocation[3];
bool g_bHungerGamesDay;

Handle g_hSetFreeze;
Handle g_hStartSound;
Handle g_hSetFf;
Handle g_hunFreeze;

public Plugin myinfo = 
{
	name = "HungerGamesDay",
	author = PLUGIN_AUTHOR,
	description = "Hunger Games day for Jailbreak servers.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_hg", Command_HungerGames, ADMFLAG_CHANGEMAP);
    g_cvFriendlyFire = FindConVar("mp_teammates_are_enemies");
    HookEvent("round_end", Event_OnRoundEnd);
    HookEvent("player_death",Event_PlayerDeath);
}

void InitPrecache()
{
    AddFileToDownloadsTable("sound/hungergames/cannon1.mp3");
    AddFileToDownloadsTable("sound/hungergames/countdown.mp3");
    PrecacheSound("hungergames/countdown.mp3");
    PrecacheSound("hungergames/cannon1.mp3");

    //BeaconShit
    AddFileToDownloadsTable("materials/warden/physbeam.vmt");
    AddFileToDownloadsTable("materials/warden/physbeam.vtf");
    AddFileToDownloadsTable("materials/warden/energysplash.vmt");
    AddFileToDownloadsTable("materials/warden/energysplash.vmt");
    g_iModelSprite = PrecacheModel("materials/warden/physbeam.vmt", false);
    g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt", false);
}


public void OnMapStart()
{
    InitPrecache();
    dayCount = 0;
}


//BeaconShit
/////////////////////////////////////////////////////////////////
void ToggleBeacon(int iTarget)
{
    g_bBeacon[iTarget] = !g_bBeacon[iTarget];
    if (g_bBeacon[iTarget])
    {
        CreateTimer(5.0, Timer_Beacon, GetClientSerial(iTarget), TIMER_REPEAT);
    }
}

public Action Timer_Beacon(Handle timer, any serial)
{
    int iTarget = GetClientFromSerial(serial);
    if (!iTarget || !g_bBeacon[iTarget])
        return Plugin_Stop;

    float fTargetPos[3];
    GetClientAbsOrigin(iTarget, fTargetPos);

    TE_SetupBeamRingPoint(fTargetPos, 20.0, 200.0, g_iModelSprite,
                          g_iHaloSprite, 0, 60, 1.0, 7.0, 0.5,
                          view_as<int>({255, 0, 0, 255}), 3, 0);
    TE_SendToAll();
    
    return Plugin_Continue;
}

    





/////////////////////////////////////////////////////////////////

public void OnClientDisconnect(int client)
{
    g_bBeacon[client] = false;
}




//Finds the ct spawn
void FindCTSpawn()
{
    int iCTSpawn = FindEntityByClassname(-1, "info_player_counterterrorist");
    if (iCTSpawn == -1)
    {
        PrintToChatAll("Failed to find CT spawn.");
        return;
    }
    GetEntPropVector(iCTSpawn, Prop_Send, "m_vecOrigin", g_fctSpawnLocation);
}

//Teleports players to ct spawn
void teleport()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            TeleportEntity(i, g_fctSpawnLocation, NULL_VECTOR, NULL_VECTOR);
        }
    }
}


public Action StartSound(Handle timer)
{
    g_hStartSound = null;
    EmitSoundToAll("hungergames/countdown.mp3");
}

public Action setFreeze(Handle timer)
{
    g_hSetFreeze = null;
    SetHudTextParams(-1.0, 0.1, 5.0, 255, 0, 0, 255, 0, 5.0, 0.25, 0.25);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            SetEntityMoveType(i, MOVETYPE_NONE);
        }
    }

    
    for(int i = 1; i <= 5; i++)
    {
        PrintToChatAll(" \x02[SM] \x0CT's are now Frozen for 5 seconds.");
    }
    FindCTSpawn();
    teleport();
}

public Action setFF(Handle timer)
{
    g_hSetFf = null;
    g_cvFriendlyFire.SetBool(true);

    SetHudTextParams(-1.0, 0.1, 5.0, 255, 0, 0, 255, 0, 5.0, 0.25, 0.25);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i))
        {
            ShowHudText(i, 1, "Hunger Games is now active. Shoot other T's to win.");
        }
    }
}

public Action unFreeze(Handle timer)
{
    g_hunFreeze = null;
    SetHudTextParams(-1.0, 0.1, 5.0, 255, 0, 0, 255, 0, 5.0, 0.25, 0.25);
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T && GetEntityMoveType(i) == MOVETYPE_NONE)
            {
                SetEntityMoveType(i, MOVETYPE_WALK);
                ShowHudText(i, -1, "You are now unfrozen. Go get guns!");
            }
    }
}

public Action Command_HungerGames(int client, int args)
{
    if(dayCount >= 3)
    {
        ReplyToCommand(client, "This day has been used 3 times already for this map.");
        return Plugin_Handled;
    }

    SetHudTextParams(-1.0, 0.1, 5.0, 255, 0, 0, 255, 0, 2.0, 0.25, 0.25);

    for( int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i))
        {
            ShowHudText(i, -1, "It is now a Hunger Games Day.");
        }
    }

    //Sets CT Health
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            SetEntityHealth(i, 32000);
        }
    }
    
    //gets T's Colors and stores them in Tcolors
    for(int i = 1;i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            GetEntityRenderColor(i, Tcolors[i][0], Tcolors[i][1], Tcolors[i][2], Tcolors[i][3]);
            SetEntityRenderColor(i, 252, 0, 0, 255);
        }
    }


    g_hSetFreeze = CreateTimer(1.0, setFreeze);
    g_hunFreeze = CreateTimer(5.0, unFreeze);
    
    //countdown timer
    g_hStartSound = CreateTimer(24.0, StartSound);
    dayCount++;
    PrintToConsoleAll("%i",dayCount);
    g_hSetFf = CreateTimer(45.0, setFF);
    g_bHungerGamesDay = true;
    return Plugin_Handled;
    
}

void removeWeapon(int target)
{
    for(int i = 0; i < 5; i++)
    {
        int weapon = GetPlayerWeaponSlot(target, i);

        while(weapon > 0)
        {
            RemovePlayerItem(target, weapon);
            AcceptEntityInput(weapon, "Kill");
            weapon = GetPlayerWeaponSlot(target, i);
        }
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(!g_bHungerGamesDay)
    {
        return;
    }


    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T)
    {
        EmitSoundToAll("hungergames/cannon1.mp3");
    }

    int count = 0;
    //checks to see how many are alive
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            count++;
        }
    }
    if(count <= 5)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
            {
                ToggleBeacon(i);
            }
        }

    }

    if(count <= 1)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
            {
                removeWeapon(i);
            }
        } 
    }


    if(count <= 1)
    {
        g_cvFriendlyFire.SetBool(false);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
            {
                SetEntityHealth(i, 100);
            }
        } 
    }
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(g_bHungerGamesDay)
    {
        delete g_hSetFf;
        delete g_hSetFreeze;
        delete g_hunFreeze;
        delete g_hStartSound;

        g_cvFriendlyFire.SetBool(false);
        g_bHungerGamesDay = false;
    }
}
