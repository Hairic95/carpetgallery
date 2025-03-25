export enum EAction {
  Connect = "Connect",

  GetUsers = "GetUsers",
  PlayerJoin = "PlayerJoin",
  PlayerLeft = "PlayerLeft",

  GetLobbies = "GetLobbies",
  GetOwnLobby = "GetOwnLobby",
  CreateLobby = "CreateLobby",
  JoinLobby = "JoinLobby",
  LobbyChanged = "LobbyChanged",
  LeaveLobby = "LeaveLobby",

  GameStarted = "GameStarted",

  MessageToLobby = "MessageToLobby",
  Heartbeat = "Heartbeat",

  GetSeed = "GetSeed",
  SetSeed = "SetSeed",
}

export enum EGenericAction {
  UpdatePlayerPosition = "UpdatePlayerPosition",
  UpdateWeapon = "UpdateWeapon",
}
