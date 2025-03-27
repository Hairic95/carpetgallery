import { LoggerHelper } from "../helpers/logger-helper";
import { Vector2 } from "./vector2";

export class GameEntity {
  id: string;
  position: Vector2;
  mapCoordinates: Vector2;
  type: string;
  currentOwnerId: string;

  constructor(
    id: string,
    position: Vector2,
    mapCoordinates: Vector2,
    type: string,
    currentOwnerId: string
  ) {
    try {
      this.id = id;
      this.position = position;
      this.mapCoordinates = mapCoordinates;
      this.type = type;
      this.currentOwnerId = currentOwnerId;
    } catch (err) {
      LoggerHelper.logError(
        `An error had occurred while creating the Client Socket: ${err}`
      );
    }
  }
}
