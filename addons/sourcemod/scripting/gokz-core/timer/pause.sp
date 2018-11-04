/*	
	Pause
	
	Pausing and resuming functionality.
*/



#define PAUSE_COOLDOWN 1.0

static bool paused[MAXPLAYERS + 1];
static bool pausedOnLadder[MAXPLAYERS + 1];
static float lastPauseTime[MAXPLAYERS + 1];
static bool hasPausedInThisRun[MAXPLAYERS + 1];
static float lastResumeTime[MAXPLAYERS + 1];
static bool hasResumedInThisRun[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetPaused(int client)
{
	return paused[client];
}

void SetPausedOnLadder(int client, bool onLadder)
{
	pausedOnLadder[client] = onLadder;
}

void Pause(int client)
{
	if (paused[client])
	{
		return;
	}
	if (GetTimerRunning(client) && hasResumedInThisRun[client]
		 && GetEngineTime() - lastResumeTime[client] < PAUSE_COOLDOWN)
	{
		GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Just Resumed)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	if (GetTimerRunning(client)
		 && !Movement_GetOnGround(client)
		 && !(Movement_GetSpeed(client) == 0 && Movement_GetVerticalVelocity(client) == 0))
	{
		GOKZ_PrintToChat(client, true, "%t", "Can't Pause (Midair)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnPause(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Pause
	paused[client] = true;
	pausedOnLadder[client] = Movement_GetMoveType(client) == MOVETYPE_LADDER;
	Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
	Movement_SetMoveType(client, MOVETYPE_NONE);
	if (GetTimerRunning(client))
	{
		hasPausedInThisRun[client] = true;
		lastPauseTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnPause_Post(client);
}

void Resume(int client)
{
	if (!paused[client])
	{
		return;
	}
	if (GetTimerRunning(client) && hasPausedInThisRun[client]
		 && GetEngineTime() - lastPauseTime[client] < PAUSE_COOLDOWN)
	{
		GOKZ_PrintToChat(client, true, "%t", "Can't Resume (Just Paused)");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnResume(client, result);
	if (result != Plugin_Continue)
	{
		return;
	}
	
	// Resume
	if (pausedOnLadder[client])
	{
		Movement_SetMoveType(client, MOVETYPE_LADDER);
	}
	else
	{
		Movement_SetMoveType(client, MOVETYPE_WALK);
	}
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

void TogglePause(int client)
{
	if (paused[client])
	{
		Resume(client);
	}
	else
	{
		Pause(client);
	}
}



// =====[ LISTENERS ]=====

void SetupClientPause(int client)
{
	paused[client] = false;
}

void OnTimerStart_Pause(int client)
{
	hasPausedInThisRun[client] = false;
	hasResumedInThisRun[client] = false;
	GOKZ_Resume(client);
}

void OnChangeMoveType_Pause(int client, MoveType newMoveType)
{
	// Check if player has escaped MOVETYPE_NONE
	if (!paused[client] || newMoveType == MOVETYPE_NONE)
	{
		return;
	}
	
	// Player has escaped MOVETYPE_NONE, so resume
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

void OnPlayerSpawn_Pause(int client)
{
	if (!paused[client])
	{
		return;
	}
	
	// Player has left paused state by spawning in, so resume
	paused[client] = false;
	if (GetTimerRunning(client))
	{
		hasResumedInThisRun[client] = true;
		lastResumeTime[client] = GetEngineTime();
	}
	
	// Call Post Forward
	Call_GOKZ_OnResume_Post(client);
}

void OnJoinTeam_Pause(int client, int team)
{
	// Only handle joining spectators. Joining other teams is handled by OnPlayerSpawn.
	if (team == CS_TEAM_SPECTATOR)
	{
		paused[client] = true;
		
		if (GetTimerRunning(client))
		{
			hasPausedInThisRun[client] = true;
			lastPauseTime[client] = GetEngineTime();
		}
		
		// Call Post Forward
		Call_GOKZ_OnPause_Post(client);
	}
} 