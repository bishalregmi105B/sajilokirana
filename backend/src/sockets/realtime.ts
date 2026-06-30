/**
 * Socket.io realtime layer (Part D.3).
 *
 * Events (server → client):
 *   order:broadcast      → candidate shops (a new order is up for grabs)
 *   order:confirmed      → customer + losing shops (order is taken)
 *   order:assigned       → driver (you've got a batch)
 *   driver:location      → customer tracking screen (live driver ping)
 *   order:status_changed → all relevant parties
 *
 * Clients join role-scoped rooms so we can fan out efficiently:
 *   shop:<shopId>, driver:<driverId>, customer:<userId>, order:<orderId>
 */
import { Server as SocketServer, Socket } from 'socket.io';
import { Server as HttpServer } from 'http';
import { authService } from '../services/authService';

export interface RealtimeEvent {
  name: string;
  payload: unknown;
}

class RealtimeService {
  private io: SocketServer | null = null;

  init(httpServer: HttpServer): SocketServer {
    this.io = new SocketServer(httpServer, {
      cors: { origin: '*', methods: ['GET', 'POST'] },
    });

    this.io.use((socket: Socket, next) => {
      // Auth: client passes token in handshake auth.
      const token = (socket.handshake.auth as { token?: string }).token;
      if (!token) return next(new Error('auth: missing token'));
      try {
        const payload = authService.verifyToken(token);
        (socket.data as Record<string, unknown>).actor = {
          id: payload.sub,
          phone: payload.phone,
          role: payload.role,
        };
        next();
      } catch {
        next(new Error('auth: invalid token'));
      }
    });

    this.io.on('connection', (socket: Socket) => {
      const actor = socket.data.actor as
        | { id: string; role: string }
        | undefined;
      if (!actor) {
        socket.disconnect();
        return;
      }

      // Auto-join the role room.
      socket.join(`${actor.role}:${actor.id}`);

      socket.on('join', (room: string) => {
        // Allow clients to join an order/tracking room.
        if (/^(order|customer):.+$/.test(room)) {
          socket.join(room);
        }
      });

      // Driver location stream (Part D.3): driver emits, we broadcast to the
      // relevant order rooms so the customer tracking screen updates.
      socket.on('driver:location', (msg: unknown) => {
        this.onDriverLocation(actor, msg);
      });
    });

    console.log('[socket.io] realtime layer initialized');
    return this.io;
  }

  get instance(): SocketServer {
    if (!this.io) throw new Error('RealtimeService not initialized');
    return this.io;
  }

  // ── fan-out helpers used by the dispatch engine ───────────────────────────

  /** Broadcast a new order to candidate shops. */
  emitOrderBroadcast(candidateShopIds: string[], order: unknown): void {
    if (!this.io) return;
    for (const shopId of candidateShopIds) {
      this.io.to(`shop:${shopId}`).emit('order:broadcast', order);
    }
  }

  /** Notify customer + losing shops that the order is taken. */
  emitOrderConfirmed(orderId: string, customerId: string, losingShopIds: string[], winner: unknown): void {
    if (!this.io) return;
    this.io.to(`customer:${customerId}`).emit('order:confirmed', winner);
    this.io.to(`order:${orderId}`).emit('order:confirmed', winner);
    for (const shopId of losingShopIds) {
      this.io.to(`shop:${shopId}`).emit('order:confirmed', { orderId, taken: true });
    }
  }

  /** Notify the assigned driver about their batch. */
  emitOrderAssigned(driverId: string, batch: unknown): void {
    this.io?.to(`driver:${driverId}`).emit('order:assigned', batch);
  }

  /** Push a status change to everyone watching an order. */
  emitStatusChanged(orderId: string, status: string): void {
    this.io?.to(`order:${orderId}`).emit('order:status_changed', { orderId, status });
  }

  /** Broadcast a driver location ping to the order's tracking room. */
  emitDriverLocation(orderId: string, lat: number, lng: number): void {
    this.io?.to(`order:${orderId}`).emit('driver:location', { lat, lng });
  }

  private onDriverLocation(actor: { id: string; role: string }, msg: unknown): void {
    if (actor.role !== 'driver') return; // only drivers stream location
    const { lat, lng, orderId } = (msg ?? {}) as {
      lat?: number;
      lng?: number;
      orderId?: string;
    };
    if (typeof lat !== 'number' || typeof lng !== 'number') return;
    if (orderId) this.emitDriverLocation(orderId, lat, lng);
  }
}

export const realtime = new RealtimeService();
