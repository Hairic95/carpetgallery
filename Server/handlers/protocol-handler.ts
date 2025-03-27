import { v4 } from "uuid";
import { EAction, EGenericAction } from "../base/enumerators";
import { ClientSocket } from "../models/clientSocket";
import { Message } from "../models/message";

import { GameServerHandler } from "./game-server-handler";
import { Constants } from "../base/constants";
import { LoggerHelper } from "../helpers/logger-helper";
import { seed } from "../configuration.json";
import { GameEntity } from "../models/game-entity";

export class ProtocolHelper {
  public static sendPlayerDisconnectToAll = (
    gameServer: GameServerHandler,
    playerDisconnectedId: String
  ) => {
    const playerDisconnectedMessage: Message = new Message(EAction.PlayerLeft, {
      webId: playerDisconnectedId,
    });
    try {
      for (const client of gameServer.connectedClients) {
        try {
          client.socket.send(playerDisconnectedMessage.toString());
        } catch (err: any) {
          LoggerHelper.logError(
            `[ProtocolHelper.sendPlayerDisconnectToAll()] An error had occurred while sending message to client ${client.id}. \n Error: ${err}`
          );
        }
      }
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendPlayerDisconnectToAll()] An error had occurred while notifing a server disconnection: ${err}`
      );
    }
  };

  public static sendPlayerConnectionToAll = (
    gameServer: GameServerHandler,
    playerClient: ClientSocket
  ) => {
    const playerConnectedMessage: Message = new Message(EAction.PlayerJoin, {
      username: playerClient.username,
      id: playerClient.id,
      position: playerClient.position,
      map_coordinates: playerClient.mapCoordinates,
    });
    try {
      for (const client of gameServer.connectedClients) {
        try {
          if (client.id != playerClient.id) {
            client.socket.send(playerConnectedMessage.toString());
          }
        } catch (err: any) {
          LoggerHelper.logError(
            `[ProtocolHelper.sendPlayerConnectionToAll()] An error had occurred while sending message to client ${client.id}. \n Error: ${err}`
          );
        }
      }
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendPlayerConnectionToAll()] An error had occurred while notifing a server disconnection: ${err}`
      );
    }
  };

  public static parseReceivingMessage = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      switch (message.action) {
        case EAction.Connect:
          ProtocolHelper.connectToServer(gameServer, clientSocket, message);
          break;
        case EAction.GetUsers:
          ProtocolHelper.sendUserList(gameServer, clientSocket);
          break;
        case EAction.Heartbeat:
          ProtocolHelper.processHeartbeat(gameServer, clientSocket);
          break;
        case EAction.MessageToLobby:
          ProtocolHelper.sendMessageToLobby(gameServer, clientSocket, message);
          break;
        case EAction.GetSeed:
          ProtocolHelper.sendMessageToClient(
            clientSocket,
            new Message(EAction.SetSeed, { seed: seed })
          );
          break;
        case EAction.AddEntity:
          ProtocolHelper.addEntity(gameServer, clientSocket, message);
          break;
        case EAction.GetRoomData:
          ProtocolHelper.sendRoomData(gameServer, clientSocket, message);
          break;
      }
    } catch (err) {
      LoggerHelper.logError(
        `[ProtocolHelper.parseReceivingMessage()] An error had occurred while parsing a message: ${err}`
      );
    }
  };

  private static connectToServer = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      LoggerHelper.logInfo("Connection attempt...");
      if (message.payload.secretKey === Constants.SecretKey) {
        clearTimeout(clientSocket.logoutTimeout);
        clientSocket.username = message.payload.username;
        clientSocket.position = message.payload.position;

        clientSocket.mapCoordinates = message.payload.map_coordinates;
        LoggerHelper.logInfo(`Connection confirmed for ${clientSocket.id}`);
        ProtocolHelper.sendPlayerConnectionToAll(gameServer, clientSocket);

        // Send response
        const connectMessage: Message = new Message(EAction.Connect, {
          success: true,
          webId: clientSocket.id,
        });
        clientSocket.socket.send(connectMessage.toString());

        // Notifies other clients
      } else {
        LoggerHelper.logWarn(`Connection failed for ${clientSocket.id}`);
        clearTimeout(clientSocket.logoutTimeout);
        clientSocket.socket.close();
        return false;
      }
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.connectToServer()] An error had occurred while parsing a message: ${err}`
      );
    }
  };

  public static sendUserList = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket
  ) => {
    try {
      const userListMessage: Message = new Message(EAction.GetUsers, {
        success: true,
        users: gameServer.connectedClients.map((el) => {
          return {
            username: el.username,
            id: el.id,
            position: el.position,
            map_coordinates: el.mapCoordinates,
          };
        }),
      });
      clientSocket.socket.send(userListMessage.toString());
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendUserList()] An error had occurred while parsing a message: ${err}`
      );
    }
  };

  public static sendGameStarted(clientSocket: ClientSocket) {
    try {
      const lobbyListMessage: Message = new Message(EAction.GameStarted, {});
      clientSocket.socket.send(lobbyListMessage.toString());
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendGameStarted()] An error had occurred while parsing a message: ${err}`
      );
    }
  }

  /**
   *
   * @param gameServer
   * @param clientSocket
   */
  private static processHeartbeat = (gameServer, clientSocket) => {
    try {
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.processHeartbeat()] An error had occurred while parsing a message: ${err}`
      );
    }
  };

  /**
   *
   * @param gameServer
   * @param clientSocket
   * @param message
   */
  private static sendMessageToLobby = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      if (!!message.payload.map_coordinates) {
        const oldRoomCoordinates = clientSocket.mapCoordinates;
        clientSocket.mapCoordinates = message.payload.map_coordinates;
        const masterlessEntities = gameServer
          .getRoomEntities(oldRoomCoordinates)
          .filter((el) => el.currentOwnerId === clientSocket.id);

        const otherClient = gameServer.connectedClients.find(
          (el) =>
            el.mapCoordinates.x == oldRoomCoordinates.x &&
            el.mapCoordinates.y == oldRoomCoordinates.y
        );

        for (const entity of masterlessEntities) {
          if (!!otherClient) {
            entity.currentOwnerId = otherClient.id;
            otherClient.socket.send(
              new Message(EAction.UpdatedEntity, { entity: entity }).toString()
            );
          } else {
            entity.currentOwnerId = null;
          }
        }
      }
      if (!!message.payload.entity_id && !!message.payload.position) {
        const entity = gameServer.getEntity(message.payload.entity_id);
        if (entity) {
          entity.position = message.payload.position;
        } else {
          clientSocket.position = message.payload.position;
        }
      }
      const lobbyMessage = new Message(EAction.MessageToLobby, message.payload);
      for (const player of gameServer.connectedClients) {
        if (clientSocket.id !== player.id) {
          player.socket.send(lobbyMessage.toString());
        }
      }
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendMessageToLobby()] An error had occurred while parsing a message: ${err}`
      );
    }
  };
  /**
   *
   * @param gameServer
   * @param clientSocket
   * @param message
   */
  private static sendMessageToClient = (
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      clientSocket.socket.send(message.toString());
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendMessageToLobby()] An error had occurred while parsing a message: ${err}`
      );
    }
  };
  /**
   *
   * @param gameServer
   * @param clientSocket
   * @param message
   */
  private static addEntity = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      gameServer.addEntity(
        new GameEntity(
          message.payload.id,
          message.payload.position,
          message.payload.map_coordinates,
          message.payload.type,
          clientSocket.id
        )
      );
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendMessageToLobby()] An error had occurred while parsing a message: ${err}`
      );
    }
  };
  /**
   *
   * @param gameServer
   * @param clientSocket
   * @param message
   */
  private static sendRoomData = (
    gameServer: GameServerHandler,
    clientSocket: ClientSocket,
    message: Message
  ) => {
    try {
      const roomEntities: GameEntity[] = gameServer.getRoomEntities(
        message.payload.map_coordinates
      );
      for (const entity of roomEntities.filter(
        (el) => el.currentOwnerId === null
      )) {
        entity.currentOwnerId = clientSocket.id;
      }
      clientSocket.socket.send(
        new Message(EAction.SetRoomData, {
          entities: roomEntities,
        }).toString()
      );
    } catch (err: any) {
      LoggerHelper.logError(
        `[ProtocolHelper.sendMessageToLobby()] An error had occurred while parsing a message: ${err}`
      );
    }
  };
}
