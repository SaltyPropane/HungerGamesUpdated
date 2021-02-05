#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Salty"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <cstrike>


#pragma newdecls required

//ConVars
ConVar g_cvFriendlyFire;
float g_fctSpawnLocation[3];
bool CanPluginRun;
bool g_bHungerGamesDay;



public Plugin myinfo = 
{
	name = "HungerGamesDay",
	author = PLUGIN_AUTHOR,
	description = "HungerGamesDay",
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
    AddFileToDownloadsTable("sound/hungergames/cannon.mp3");
    PrecacheSound("hungergames/cannon.mp3");
}

public void OnMapStart()
{
    CanPluginRun = true;
    InitPrecache();
}

void ChangePluginRun()
{
    CanPluginRun = false;
}

void setFreezeTimer()
{
    CreateTimer(1.0, setFreeze);
}

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



public Action setFreeze(Handle timer)
{
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

void setffTimer()
{
    CreateTimer(45.0, setFF);
}

public Action setFF(Handle timer)
{
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

void setUnFreezeTimer()
{
    CreateTimer(5.0, unFreeze);
}

public Action unFreeze(Handle timer)
{
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

    if(CanPluginRun == false)
    {   
        ReplyToCommand(client, "This day can only be used once per map.");
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

    setFreezeTimer();
    setUnFreezeTimer();
    setffTimer();
    g_bHungerGamesDay = true;
    ChangePluginRun();
    return Plugin_Handled;
    
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
        EmitSoundToAll("hungergames/cannon.mp3");
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
        g_cvFriendlyFire.SetBool(false);
        g_bHungerGamesDay = false;
    }
}
