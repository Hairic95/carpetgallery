import { ClientSocket } from "../models/clientSocket";
import { ProtocolHelper } from "./protocol-handler";
import { LoggerHelper } from "../helpers/logger-helper";
import { GameEntity } from "../models/game-entity";
import { Vector2 } from "../models/vector2";

export class GameServerHandler {
  public connectedClients: ClientSocket[] = [];
  public entities: GameEntity[] = [];
  entityDespawnDistance = 5;

  constructor() {
    setInterval(() => {
      for (const entity of this.entities) {
        if (
          this.connectedClients.filter((el) => {
            const x_distance = el.mapCoordinates.x - entity.mapCoordinates.x;
            const y_distance = el.mapCoordinates.y - entity.mapCoordinates.y;
            return (
              x_distance <= this.entityDespawnDistance &&
              x_distance >= -this.entityDespawnDistance &&
              y_distance <= this.entityDespawnDistance &&
              y_distance >= -this.entityDespawnDistance
            );
          }).length === 0
        ) {
          this.removeEntity(entity.id);
        }
      }
    }, 3 * 60 * 1000);

    setInterval(() => {
      console.log("Connected client count: " + this.connectedClients.length);
      console.log("Entity count: " + this.entities.length);
    }, 10 * 1000);
  }

  public addClient(clientSocket: ClientSocket) {
    try {
      this.connectedClients.push(clientSocket);
    } catch (err: any) {
      LoggerHelper.logError(
        `[GameServerHandler.addClient()] An error had occurred while adding a client: ${err}`
      );
      throw err;
    }
  }

  public addEntity(newEntity: GameEntity): void {
    this.entities.push(newEntity);
  }
  public removeEntity(entityId: string): void {
    const index = this.entities.findIndex((el) => el.id === entityId);
    this.entities.splice(index, 1);
  }
  public removeEntityInRoom(mapCoordinates: Vector2): void {
    const entitiesToRemove = this.getRoomEntities(mapCoordinates);
    for (const entity of entitiesToRemove) {
    }
  }

  public getEntity(entityId: string): GameEntity | undefined {
    return this.entities.find((el) => el.id === entityId);
  }
  public getRoomEntities(mapCoordinates: Vector2): GameEntity[] {
    return this.entities.filter(
      (el) =>
        el.mapCoordinates.x === mapCoordinates.x &&
        el.mapCoordinates.y === mapCoordinates.y
    );
  }

  public removeClient(clientId: String) {
    try {
      // 1) Remove the client from the connected client list
      const clientIndex: number = this.connectedClients.findIndex(
        (el) => el.id === clientId
      );
      if (clientIndex > -1) {
        this.connectedClients.splice(clientIndex, 1);
      } else {
        LoggerHelper.logWarn(
          `[GameServerHandler.removeClient()] attempted to remove an inexistant client`
        );
      }
      for (const entity of this.entities.filter(
        (el) => el.currentOwnerId === clientId
      )) {
        entity.currentOwnerId = null;
      }
      ProtocolHelper.sendPlayerDisconnectToAll(this, clientId);
    } catch (err: any) {
      LoggerHelper.logError(
        `[GameServerHandler.removeClient()] An error had occurred while removing a client: ${err}`
      );
      throw err;
    }
  }
}
