extends Node

# SERVER
const Server_SecretKey = "YOUR_SECRET_KEY_HERE_NEVER_SHOW_IT_:)"
#const Server_SecretKey = "5b810842-3c82-4da3-83aa-3b3ff1f03ab7"

# Change to your server url, currently set to the localhost
const Server_WSUrl = "ws://127.0.0.1:6900"
#const Server_WSUrl = "wss://game.hairiclilred.com"

# ACTIONS

const Action_Connect = "Connect"

const Action_GetUsers = "GetUsers"
const Action_PlayerJoin = "PlayerJoin"
const Action_PlayerLeft = "PlayerLeft"

const Action_GetLobbies = "GetLobbies"
const Action_GetOwnLobby = "GetOwnLobby"
const Action_CreateLobby = "CreateLobby"
const Action_JoinLobby = "JoinLobby"
const Action_LeaveLobby = "LeaveLobby"
const Action_LobbyChanged = "LobbyChanged"
const Action_GetUsersInLobby = "GetUsersInLobby"
const Action_MapSelected = "MapSelected"

const Action_GameStarted = "GameStarted"

const Action_MessageToRoom = "MessageToRoom"
const Action_MessageToServer = "MessageToServer"
const Action_Heartbeat = "Heartbeat"

const Action_GetSeed = "GetSeed"
const Action_SetSeed = "SetSeed"

const Action_AddEntity = "AddEntity"
const Action_AddedEntity = "AddedEntity"
const Action_UpdatedEntity = "UpdatedEntity"
const Action_RemoveEntity = "RemoveEntity"
const Action_RemoveEntitiesFromRoom = "RemoveEntitiesFromRoom"
const Action_GetRoomData = "GetRoomData"
const Action_SetRoomData = "SetRoomData"

# GENERIC MESSAGES

const GenericAction_EntityHardUpdatePosition = "EntityHardUpdatePosition"
const GenericAction_EntityUpdatePosition = "EntityUpdatePosition"
const GenericAction_EntityUpdateState = "EntityUpdateState"
const GenericAction_EntityMiscProcessData = "EntityMiscProcessData"
const GenericAction_EntityMiscOneOff = "EntityMiscOneOff"
const GenericAction_EntityDeath = "EntityDeath"
const GenericAction_EntitySpawn = "EntitySpawn"
const GenericAction_EntityUpdateFlip = "EntityUpdateFlip"
const GenericAction_EntityUpdateMapCoordinates = "EntityUpdateMapCoordinates"

# ENTITIES TYPES

const EntityType_Player = "Player"
const EntityType_Bullet = "Bullet"
