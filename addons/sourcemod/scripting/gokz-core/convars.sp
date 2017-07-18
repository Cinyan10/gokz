/*
	ConVars
	
	ConVars for server control over features of the plugin.
*/



ConVar gCV_ChatProcessing;
ConVar gCV_ChatPrefix;
ConVar gCV_ConnectionMessages;
ConVar gCV_DefaultMode;
ConVar gCV_PlayerModelT;
ConVar gCV_PlayerModelCT;
ConVar gCV_PlayerModelAlpha;

ConVar gCV_DisableImmunityAlpha;
ConVar gCV_FullAlltalk;



// =========================  PUBLIC  ========================= //

void CreateConVars()
{
	gCV_ChatProcessing = CreateConVar("gokz_chat_processing", "1", "Whether GOKZ processes player chat messages.", _, true, 0.0, true, 1.0);
	gCV_ChatPrefix = CreateConVar("gokz_chat_prefix", "{grey}[{green}KZ{grey}] ", "Chat prefix used for GOKZ messages.");
	gCV_ConnectionMessages = CreateConVar("gokz_connection_messages", "1", "Whether GOKZ handles connection and disconnection messages.", _, true, 0.0, true, 1.0);
	gCV_DefaultMode = CreateConVar("gokz_default_mode", "1", "Default movement mode (0 = Vanilla, 1 = SimpleKZ, 2 = KZTimer).", _, true, 0.0, true, 2.0);
	gCV_PlayerModelT = CreateConVar("gokz_player_model_t", "models/player/tm_leet_varianta.mdl", "Model to change Terrorists to (applies after map change).");
	gCV_PlayerModelCT = CreateConVar("gokz_player_model_ct", "models/player/ctm_idf_variantc.mdl", "Model to change Counter-Terrorists to (applies after map change).");
	gCV_PlayerModelAlpha = CreateConVar("gokz_player_model_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	
	gCV_DisableImmunityAlpha = FindConVar("sv_disable_immunity_alpha");
	gCV_FullAlltalk = FindConVar("sv_full_alltalk");
	
	HookConVarChange(gCV_PlayerModelAlpha, OnConVarChanged_PlayerModelAlpha);
}



// =========================  LISTENERS  ========================= //

public void OnConVarChanged_PlayerModelAlpha(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			UpdatePlayerModelAlpha(client);
		}
	}
} 