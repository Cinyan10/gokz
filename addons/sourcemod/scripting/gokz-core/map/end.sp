/*
    Hooks between specifically named end destinations and GOKZ
*/



static bool endExists[GOKZ_MAX_COURSES];
static float endOrigin[GOKZ_MAX_COURSES];
static float endAngles[GOKZ_MAX_COURSES];



// =====[ EVENTS ]=====

void OnEntitySpawned_MapEnd(int entity)
{
    char buffer[32];

    GetEntityClassname(entity, buffer, sizeof(buffer));
	if (!StrEqual("info_teleport_destination", buffer, false))
	{
		return;
	}
	
	if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
	{
		return;
	}
	
	if (StrEqual(GOKZ_END_NAME, buffer, false))
	{
		StoreEnd(0, entity);
	}
    else
	{
		int course = GetEndBonusNumber(entity);
		if (GOKZ_IsValidCourse(course, true))
		{
			StoreEnd(course, entity);
		}
	}
}

void OnMapStart_MapEnd()
{
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		endExists[course] = false;
	}
}



// =====[ PRIVATE ]=====

static void StoreEnd(int course, int entity)
{
    float origin[3], angles[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
    angles[2] = 0.0; // Roll should always be 0.0

    endExists[course] = true;
    endOrigin[course] = origin;
    endAngles[course] = angles;
}

static int GetEndBonusNumber(int entity)
{
	return GOKZ_MatchIntFromEntityName(entity, RE_BonusEnd, 1);
} 