import { describe, it, expect } from 'vitest';
import { ClientEvent, ServerEvent } from '../types.js';

describe('Shared exports', () => {
  it('should export events', () => {
    expect(ClientEvent.MOVE).toBe('c2s:move');
    expect(ClientEvent.CHAT).toBe('c2s:chat');
    expect(ClientEvent.JOIN_WORLD).toBe('c2s:join_world');
    
    expect(ServerEvent.PLAYER_MOVED).toBe('s2c:player_moved');
    expect(ServerEvent.CHAT_MESSAGE).toBe('s2c:chat_message');
    expect(ServerEvent.CHUNK_UPDATE).toBe('s2c:chunk_update');
  });
});
