export enum EAction {
  Connect = "Connect",

  GetUsers = "GetUsers",
  PlayerJoin = "PlayerJoin",
  PlayerLeft = "PlayerLeft",

  GameStarted = "GameStarted",

  MessageToLobby = "MessageToLobby",
  Heartbeat = "Heartbeat",

  GetSeed = "GetSeed",
  SetSeed = "SetSeed",

  AddEntity = "AddEntity",
  AddedEntity = "AddedEntity",
  UpdatedEntity = "UpdatedEntity",
  RemoveEntity = "RemoveEntity",
  RemoveEntitiesFromRoom = "RemoveEntitiesFromRoom",
  GetRoomData = "GetRoomData",
  SetRoomData = "SetRoomData",
}

export enum EGenericAction {
  UpdatePlayerPosition = "UpdatePlayerPosition",
  UpdateWeapon = "UpdateWeapon",
}
