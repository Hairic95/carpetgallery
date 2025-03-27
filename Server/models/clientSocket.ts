import WebSocket = require("ws");
import { Vector2 } from "./vector2";
import { LoggerHelper } from "../helpers/logger-helper";

export class ClientSocket {
  username: string;
  socket: WebSocket;
  id: string;
  position: Vector2;
  mapCoordinates: Vector2;
  logoutTimeout: NodeJS.Timeout;

  constructor(
    socket: WebSocket,
    id: string,
    position: Vector2 = new Vector2(0, 0),
    mapCoordinates = new Vector2(0, 0)
  ) {
    try {
      this.socket = socket;
      this.id = id;
      this.position = position;
      this.mapCoordinates = mapCoordinates;

      this.logoutTimeout = setTimeout(() => {
        LoggerHelper.logWarn(`Closing socket ${this.id}. No validation.`);
        this.socket.close();
      }, 4 * 1000);
    } catch (err) {
      LoggerHelper.logError(
        `An error had occurred while creating the Client Socket: ${err}`
      );
    }
  }
}
