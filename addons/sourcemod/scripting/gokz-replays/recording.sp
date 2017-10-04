/*
	Recording
	
	Bot replay recording logic and processes.
	
	Records data every time OnPlayerRunCmd is called.
	If the player misses the server record, then the recording will 
	immediately stop and be discarded. Upon beating the server record, 
	a binary file will be written 	with a 'header' containing 
	information	about the run, followed by the recorded tick data 
	from OnPlayerRunCmd.
*/



static bool recording[MAXPLAYERS + 1];
static bool recordingPaused[MAXPLAYERS + 1];
static ArrayList recordedTickData[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

void StartRecording(int client)
{
	DiscardRecording(client);
	recording[client] = true;
	ResumeRecording(client);
}

bool SaveRecording(int client, int course, float time, int teleportsUsed)
{
	if (!recording[client])
	{
		return;
	}
	
	// Prepare data
	int mode = GOKZ_GetOption(client, Option_Mode);
	int style = GOKZ_GetOption(client, Option_Style);
	int timeType = GOKZ_GetCurrentTimeType(client);
	
	// Setup file path and file
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), 
		"%s/%s/%d_%s_%s_%s.%s", 
		REPLAY_DIRECTORY, gC_CurrentMap, course, gC_ModeNamesShort[mode], gC_StyleNamesShort[style], gC_TimeTypeNames[timeType], REPLAY_FILE_EXTENSION);
	if (FileExists(path))
	{
		DeleteFile(path);
	}
	else
	{  // New replay so add it to replay info cache
		AddToReplayInfoCache(course, mode, style, timeType);
		SortReplayInfoCache();
	}
	
	File file = OpenFile(path, "wb");
	
	// Prepare more data
	char steamID2[24], ip[16], alias[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, steamID2, sizeof(steamID2));
	GetClientIP(client, ip, sizeof(ip));
	GetClientName(client, alias, sizeof(alias));
	int tickCount = recordedTickData[client].Length;
	
	// Write header
	file.WriteInt32(REPLAY_MAGIC_NUMBER);
	file.WriteInt8(REPLAY_FORMAT_VERSION);
	file.WriteInt8(strlen(GOKZ_VERSION));
	file.WriteString(GOKZ_VERSION, false);
	file.WriteInt8(strlen(gC_CurrentMap));
	file.WriteString(gC_CurrentMap, false);
	file.WriteInt32(course);
	file.WriteInt32(mode);
	file.WriteInt32(style);
	file.WriteInt32(view_as<int>(time));
	file.WriteInt32(teleportsUsed);
	file.WriteInt32(GetSteamAccountID(client));
	file.WriteInt8(strlen(steamID2));
	file.WriteString(steamID2, false);
	file.WriteInt8(strlen(ip));
	file.WriteString(ip, false);
	file.WriteInt8(strlen(alias));
	file.WriteString(alias, false);
	file.WriteInt32(tickCount);
	
	// Write tick data
	any tickData[TICK_DATA_BLOCKSIZE];
	for (int i = 0; i < tickCount; i++)
	{
		recordedTickData[client].GetArray(i, tickData, TICK_DATA_BLOCKSIZE);
		file.Write(tickData, TICK_DATA_BLOCKSIZE, 4);
	}
	file.Close();
	
	// Discard recorded data
	recordedTickData[client].Clear();
	recording[client] = false;
}

void DiscardRecording(int client)
{
	recording[client] = false;
	recordedTickData[client].Clear();
}

void PauseRecording(int client)
{
	recordingPaused[client] = true;
}

void ResumeRecording(int client)
{
	recordingPaused[client] = false;
}



// =========================  LISTENERS  ========================= //

void OnClientPutInServer_Recording(int client)
{
	if (recordedTickData[client] == INVALID_HANDLE)
	{
		recordedTickData[client] = new ArrayList(TICK_DATA_BLOCKSIZE, 0);
	}
	else
	{  // Just in case it isn't cleared when the client disconnects via GOKZ_OnTimerStopped
		recordedTickData[client].Clear();
	}
}

void OnPlayerRunCmd_Recording(int client, int buttons)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (recording[client] && !recordingPaused[client])
	{
		int tick = GetArraySize(recordedTickData[client]);
		recordedTickData[client].Resize(tick + 1);
		
		float origin[3], angles[3];
		Movement_GetOrigin(client, origin);
		Movement_GetEyeAngles(client, angles);
		int flags = GetEntityFlags(client);
		
		recordedTickData[client].Set(tick, origin[0], 0);
		recordedTickData[client].Set(tick, origin[1], 1);
		recordedTickData[client].Set(tick, origin[2], 2);
		recordedTickData[client].Set(tick, angles[0], 3);
		recordedTickData[client].Set(tick, angles[1], 4);
		// Don't bother tracking eye angle roll (angles[2]) - not used
		recordedTickData[client].Set(tick, buttons, 5);
		recordedTickData[client].Set(tick, flags, 6);
	}
}

void GOKZ_OnTimerStart_Recording(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	StartRecording(client);
}

void GOKZ_OnTimerEnd_Recording(int client, int course, float time, int teleportsUsed)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	SaveRecording(client, course, time, teleportsUsed);
}

void GOKZ_OnPause_Recording(int client)
{
	PauseRecording(client);
}

void GOKZ_OnResume_Recording(int client)
{
	ResumeRecording(client);
}

void GOKZ_OnTimerStopped_Recording(int client)
{
	DiscardRecording(client);
}

void GOKZ_OnCountedTeleport_Recording(int client)
{
	if (gB_NubRecordMissed[client])
	{
		DiscardRecording(client);
	}
}

void GOKZ_LR_OnRecordMissed_Recording(int client, int recordType)
{
	// If missed PRO record or both records, then can no longer beat a server record
	if (recordType == RecordType_NubAndPro || recordType == RecordType_Pro)
	{
		DiscardRecording(client);
	}
	// If on a NUB run and missed NUB record, then can no longer beat a server record
	// Otherwise wait to see if they teleport before stopping the recording
	if (recordType == RecordType_Nub)
	{
		if (GOKZ_GetTeleportCount(client) > 0)
		{
			DiscardRecording(client);
		}
	}
} 