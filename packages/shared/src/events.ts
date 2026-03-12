export enum ClientEvent {
  JOIN_WORLD = 'join_world',
  LEAVE_WORLD = 'leave_world',
  MOVE = 'move',
  CHAT = 'chat',
  INTERACT = 'interact',
}

export enum ServerEvent {
  WORLD_STATE = 'world_state',
  CHUNK_UPDATE = 'chunk_update',
  PLAYER_JOINED = 'player_joined',
  PLAYER_LEFT = 'player_left',
  PLAYER_MOVED = 'player_moved',
  CHAT_MESSAGE = 'chat_message',
  ERROR = 'error',
}
