// lib/index.js (GRAND UNIFICATION - FINAL & FULLY WORKING CODE)

// PresenceLobby class me koi badlaav nahi hai.
export class PresenceLobby {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map();
  }

  async fetch(request) {
    const url = new URL(request.url);
    
    if (url.pathname === '/internal/is-user-online') {
        const userIdToCheck = url.searchParams.get('userId');
        if (!userIdToCheck) {
            return new Response('userId is required', { status: 400 });
        }
        const isOnline = this.sessions.has(userIdToCheck);
        return new Response(JSON.stringify({ isOnline: isOnline }), {
            headers: { 'Content-Type': 'application/json' },
        });
    }

    if (url.pathname === '/internal/notify-new-message') {
        try {
            const { receiverId, notificationPayload } = await request.json();
            const receiverSession = this.sessions.get(receiverId);

            if (receiverSession) {
                console.log(`PresenceLobby: Sending NEW_MESSAGE_NOTIFICATION to ${receiverId}.`);
                receiverSession.send(JSON.stringify({
                    type: 'NEW_MESSAGE_NOTIFICATION',
                    payload: notificationPayload,
                }));
            } else {
                console.log(`PresenceLobby: Receiver ${receiverId} is not connected.`);
            }
            return new Response('Notification processed.', { status: 200 });

        } catch (e) {
            console.error("Error in PresenceLobby notify endpoint:", e);
            return new Response('Error processing notification.', { status: 500 });
        }
    }

    const userId = url.searchParams.get('userId');
    if (!userId) {
      return new Response('userId is required', { status: 400 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.handleSession(server, userId);
    return new Response(null, { status: 101, webSocket: client });
  }

  async handleSession(webSocket, userId) {
    webSocket.accept();
    
    for (const [existingUserId, _] of this.sessions.entries()) {
        webSocket.send(JSON.stringify({ type: 'PRESENCE_UPDATE', userId: existingUserId, status: 'online' }));
    }

    this.sessions.set(userId, webSocket);
    this.broadcast({ type: 'PRESENCE_UPDATE', userId: userId, status: 'online' });

    const closeOrErrorHandler = () => {
        this.sessions.delete(userId);
        this.broadcast({ type: 'PRESENCE_UPDATE', userId: userId, status: 'offline' });
    };

    webSocket.addEventListener('close', closeOrErrorHandler);
    webSocket.addEventListener('error', closeOrErrorHandler);
  }

  broadcast(message) {
    const serializedMessage = JSON.stringify(message);
    for (const sessionWs of this.sessions.values()) {
      try {
        sessionWs.send(serializedMessage);
      } catch (err) {}
    }
  }
}


// ============== CHAT ROOM CLASS ME BADE BADLAAV KIYE GAYE HAIN ==============
export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = [];
  }

  async fetch(request) {
    const url = new URL(request.url);

    // === BUG FIX START: NAYA INTERNAL ENDPOINT JO HTTP MESSAGES KO HANDLE KAREGA ===
    if (request.method === 'POST' && url.pathname.endsWith('/internal/http-message')) {
        try {
            const { senderId, receiverId, content, chatId } = await request.json();
            // Ab hum message ko process karne ke liye naye internal function ko call karenge
            await this._processNewMessage(senderId, receiverId, content, chatId);
            return new Response(JSON.stringify({ success: true, message: 'Message processed by DO!'}), { 
                status: 200, 
                headers: { 'Content-Type': 'application/json' }
            });
        } catch(e) {
            console.error("Error processing HTTP message in DO:", e);
            return new Response('Internal Server Error in DO', { status: 500 });
        }
    }
    // === BUG FIX END ===

    const senderId = url.searchParams.get('senderId');
    if (senderId) {
        // This is a WebSocket upgrade request
        const pair = new WebSocketPair();
        const [client, server] = Object.values(pair);
        this.handleSession(server, senderId);
        return new Response(null, { status: 101, webSocket: client });
    }

    return new Response('Invalid request for ChatRoom', { status: 400 });
  }

  // === BUG FIX START: NAYA REUSABLE FUNCTION JO SAARA MESSAGE LOGIC HANDLE KAREGA ===
  async _processNewMessage(senderId, receiverId, content, chatId) {
    console.log(`--- Processing new message from ${senderId} to ${receiverId} ---`);
    
    // ================== BLOCKING LOGIC START ==================
    try {
      // Step 1: Receiver ka data laao, bilkul waise hi jaise aap 'getUserData' me laate hain
      const firestoreUrl = `https://firestore.googleapis.com/v1/projects/lovz-7598d/databases/(default)/documents/users/${receiverId}`;
      const accessToken = await this.getFirebaseAccessToken();
      
      const response = await fetch(firestoreUrl, {
          headers: { 'Authorization': `Bearer ${accessToken}` }
      });

      if (response.ok) {
          const data = await response.json();
          // Step 2: 'blockedUsers' array ko check karo
          const blockedUsersField = data.fields?.blockedUsers?.arrayValue?.values;
          if (blockedUsersField) {
              const blockedUsersList = blockedUsersField.map(value => value.stringValue);
              if (blockedUsersList.includes(senderId)) {
                  // Step 3: Agar sender block hai, to message ko drop kar do
                  console.log(`[BLOCK] Message from ${senderId} to ${receiverId} was blocked.`);
                  // Chup-chaap function se return ho jao, kuch na karo.
                  return; 
              }
          }
      } else {
        // Agar receiver ka data nahi milta, to bhi safety ke liye message drop kar do
        console.warn(`Could not fetch receiver data for blocking check. Dropping message for safety.`);
        return;
      }

    } catch (error) {
        console.error("Error during blocking check:", error);
        // Agar check karte samay koi error aaye, to message drop kar do
        return; 
    }
    // =================== BLOCKING LOGIC END ===================

    // Agar upar ka logic pass ho jaata hai, to hi message aage process hoga
    const ps = this.env.DB.prepare('INSERT INTO messages (chat_id, sender_id, receiver_id, content) VALUES (?, ?, ?, ?) RETURNING id, created_at')
                           .bind(chatId, senderId, receiverId, content);
    const result = await ps.first();
    const messageId = result ? result.id : null;
    const createdAt = result ? result.created_at : new Date().toISOString();
    console.log(`Message saved to D1 with ID: ${messageId}.`);

    const messagePayload = { 
        content: content, id: messageId, status: 'sent', chat_id: chatId, sender_id: senderId, created_at: createdAt
    };

    // Baaki ka function bilkul waisa hi rahega...
    const messageToSend = JSON.stringify({ type: 'NEW_MESSAGE', payload: messagePayload });
    for (const session of this.sessions) {
      try { session.ws.send(messageToSend); } catch (err) { this.sessions = this.sessions.filter(s => s !== session); }
    }
    console.log("Broadcasted live message to connected chat clients.");
    
    await this.notifyPresenceLobby(chatId, senderId, receiverId, content, createdAt);

    const lobbyId = this.env.PRESENCE_LOBBY.idFromName('global-lobby');
    const lobbyStub = this.env.PRESENCE_LOBBY.get(lobbyId);
    const response = await lobbyStub.fetch(`https://dummy-url.com/internal/is-user-online?userId=${receiverId}`);
    const { isOnline } = await response.json();

    if (isOnline) {
      console.log(`Receiver ${receiverId} is online GLOBALLY. Sending delivered tick.`);
      await this.updateStatusInDB(messageId, 'delivered');
      await this.sendStatusUpdate(senderId, messageId, 'delivered');
     } else {
      console.log(`Receiver ${receiverId} is offline GLOBALLY. Sending push notification.`);
      await this.sendPushNotification(senderId, receiverId, content, String(chatId));
      await this.updateStatusInDB(messageId, 'delivered');
      await this.sendStatusUpdate(senderId, messageId, 'delivered');
    }
    console.log("--- Message processing finished ---");
  }
  // === BUG FIX END ===


  async handleSession(webSocket, senderId) {
    webSocket.accept();
    for (const existingSession of this.sessions) {
      webSocket.send(JSON.stringify({ type: 'PRESENCE_UPDATE', senderId: existingSession.senderId, status: 'online' }));
    }
    this.sessions.push({ ws: webSocket, senderId: senderId });
    this.broadcast(JSON.stringify({ type: 'PRESENCE_UPDATE', senderId: senderId, status: 'online' }), senderId);

    webSocket.addEventListener('message', async (msg) => {
      try {
        const data = JSON.parse(msg.data);
        const { type } = data;
        switch (type) {
          case 'NEW_MESSAGE': {
            const { receiverId, content, chatId } = data.payload;
            // Ab hum saara kaam naye reusable function ko de denge
            await this._processNewMessage(senderId, receiverId, content, chatId);
            break;
          }
          case 'MESSAGES_READ': {
            console.log(`--- Messages Read Event Received from ${senderId} ---`);
            const { chatId } = data;
            const readerId = senderId;
            const ps = this.env.DB.prepare("UPDATE messages SET status = 'read' WHERE chat_id = ? AND receiver_id = ? AND status = 'delivered' RETURNING id, sender_id")
                                   .bind(chatId, readerId);
            const { results } = await ps.run();
            console.log(`${results.length} messages marked as read.`);
            for (const row of results) {
              await this.sendStatusUpdate(row.sender_id, row.id, 'read');
            }
            if (results.length > 0) {
              const lastMessagePs = this.env.DB.prepare("SELECT content, created_at, sender_id FROM messages WHERE chat_id = ? ORDER BY created_at DESC LIMIT 1").bind(chatId);
              const lastMessage = await lastMessagePs.first();
              if(lastMessage) {
                await this.notifyPresenceLobby(chatId, lastMessage.sender_id, readerId, lastMessage.content, lastMessage.created_at);
              }
            }
            break;
          }
        }
      } catch (err) {
        console.error("DO Error handling message:", err);
      }
    });

    const closeOrErrorHandler = () => {
      this.sessions = this.sessions.filter(s => s.ws !== webSocket);
      this.broadcast(JSON.stringify({ type: 'PRESENCE_UPDATE', senderId: senderId, status: 'offline' }), senderId);
    };
    webSocket.addEventListener('close', closeOrErrorHandler);
    webSocket.addEventListener('error', closeOrErrorHandler);
  }

  broadcast(message, excludeSenderId = null) {
    const recipients = this.sessions.filter(s => s.senderId !== excludeSenderId);
    for (const session of recipients) {
      try {
        session.ws.send(message);
      } catch (err) {
        this.sessions = this.sessions.filter(s => s !== session);
      }
    }
  }

  async updateStatusInDB(messageId, status) {
    if (!messageId) return;
    console.log(`Updating message ${messageId} to status: ${status}`);
    const ps = this.env.DB.prepare('UPDATE messages SET status = ? WHERE id = ?').bind(status, messageId);
    await ps.run();
  }

  async sendStatusUpdate(targetUserId, messageId, status) {
    if (!messageId) return;
    const targetSession = this.sessions.find(s => s.senderId === targetUserId);
    if (targetSession) {
      console.log(`Sending status update to ${targetUserId} for message ${messageId}: ${status}`);
      targetSession.ws.send(JSON.stringify({
        type: 'STATUS_UPDATE',
        messageId: messageId,
        status: status
      }));
    }
  }

  async notifyPresenceLobby(chatId, senderId, receiverId, lastMessageContent, timestamp) {
    try {
        console.log(`Notifying PresenceLobby about new message for receiver ${receiverId}`);
        const ps = this.env.DB.prepare("SELECT COUNT(*) as count FROM messages WHERE chat_id = ? AND receiver_id = ? AND status != 'read'")
                               .bind(chatId, receiverId);
        const result = await ps.first();
        const unreadCount = result ? result.count : 0;
        console.log(`Calculated unread count for receiver ${receiverId} is ${unreadCount}`);
        const lobbyId = this.env.PRESENCE_LOBBY.idFromName('global-lobby');
        const lobbyStub = this.env.PRESENCE_LOBBY.get(lobbyId);
        const notificationPayload = {
            chatId: chatId,
            lastMessage: lastMessageContent,
            lastMessageSenderId: senderId,
            lastMessageTimestamp: timestamp,
            unreadCount: unreadCount,
        };
        await lobbyStub.fetch('https://dummy-url.com/internal/notify-new-message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ receiverId: receiverId, notificationPayload: notificationPayload })
        });
        console.log(`Successfully sent notification report to PresenceLobby for receiver ${receiverId}.`);
    } catch (e) {
        console.error("Error in notifyPresenceLobby:", e);
    }
  }


  async sendPushNotification(senderId, receiverId, messageContent, chatId) {
    try {
      const senderDataPromise = this.getUserData(senderId);
      const receiverDataPromise = this.getUserData(receiverId);
      const [senderData, receiverData] = await Promise.all([senderDataPromise, receiverDataPromise]);
      if (!receiverData || !receiverData.fcmToken) {
        console.log(`Receiver ${receiverId} has no FCM token.`);
        return;
      }
      const senderName = senderData ? senderData.name : 'Someone';
      const fcmToken = receiverData.fcmToken;
      const accessToken = await this.getFirebaseAccessToken();
      const notificationPayload = {
        message: {
          token: fcmToken,
          notification: { title: `New message from ${senderName}`, body: messageContent },
          data: { chatId: chatId }
        }
      };
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/lovz-7598d/messages:send`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(notificationPayload),
      });
      if (response.ok) {
        console.log('Successfully sent FCM notification.');
      } else {
        const errorBody = await response.text();
        console.error('Failed to send FCM notification:', response.status, errorBody);
      }
    } catch (e) {
      console.error("Error in sendPushNotification:", e);
    }
  }

  async getUserData(userId) {
    try {
      const firestoreUrl = `https://firestore.googleapis.com/v1/projects/lovz-7598d/databases/(default)/documents/users/${userId}`;
      const accessToken = await this.getFirebaseAccessToken();
      
      const response = await fetch(firestoreUrl, {
          headers: { 'Authorization': `Bearer ${accessToken}` }
      });

      if (!response.ok) {
        const errorBody = await response.text();
        console.error(`Failed to fetch user data for ${userId}:`, response.status, errorBody);
        return null;
      }

      const data = await response.json();
      const name = data.fields?.name?.stringValue ?? 'Unknown';
      const fcmToken = data.fields?.fcmToken?.stringValue;

      return { name, fcmToken };

    } catch (e) {
      console.error(`Exception in getUserData for ${userId}:`, e);
      return null;
    }
  }

  async getFirebaseAccessToken() {
    const serviceAccount = JSON.parse(this.env.FIREBASE_SERVICE_ACCOUNT);
    const header = { alg: 'RS256', typ: 'JWT' };
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now, exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging'
    };
    const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    const dataToSign = `${encodedHeader}.${encodedPayload}`;
    const key = await crypto.subtle.importKey('pkcs8', (str => new Uint8Array(atob(str).split('').map(c => c.charCodeAt(0))))(serviceAccount.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '')), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
    const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(dataToSign));
    const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    const jwt = `${dataToSign}.${encodedSignature}`;
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
    });
    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  }
}

// === IS POORE FUNCTION KO NAYE AUR SAHI CODE SE REPLACE KAREIN ===
async function handleChatSummariesRequest(request, env) {
  const url = new URL(request.url);
  const userId = url.searchParams.get('userId');

  if (!userId) {
    return new Response('User ID is required', { status: 400 });
  }

  try {
    // === YAHI HAI FINAL, WORKING SQL QUERY ===
    const ps = env.DB.prepare(
      `SELECT 
        c.id AS chatId,
        m.content AS lastMessage,
        m.sender_id AS lastMessageSenderId,
        m.created_at AS lastMessageTimestamp,
        CASE
          WHEN c.user1_id = ?1 THEN 
            (SELECT COUNT(*) FROM messages msg WHERE msg.chat_id = c.id AND msg.receiver_id = ?1 AND msg.status != 'read')
          WHEN c.user2_id = ?1 THEN 
            (SELECT COUNT(*) FROM messages msg WHERE msg.chat_id = c.id AND msg.receiver_id = ?1 AND msg.status != 'read')
          ELSE 0
        END AS unreadCount
      FROM chats c
      JOIN messages m ON m.id = (
        SELECT id FROM messages 
        WHERE chat_id = c.id 
        ORDER BY created_at DESC 
        LIMIT 1
      )
      WHERE c.user1_id = ?1 OR c.user2_id = ?1`
    ).bind(userId);
    
    const { results } = await ps.all();
    // ===========================================
    
    console.log(`[handleChatSummariesRequest] Found ${results.length} chats for user ${userId}.`);

    const formattedResults = results.map(row => ({
      ...row,
      lastMessageTimestamp: row.lastMessageTimestamp ? new Date(row.lastMessageTimestamp).toISOString() : null,
    }));

    return new Response(JSON.stringify(formattedResults), {
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (e) {
    console.error('Error fetching chat summaries:', e);
    return new Response(`Database error: ${e.message}`, { status: 500 });
  }
}
// ==========================================================

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/presence') {
      const id = env.PRESENCE_LOBBY.idFromName('global-lobby');
      const stub = env.PRESENCE_LOBBY.get(id);
      return stub.fetch(request);
    }

    if (url.pathname.startsWith('/api/websocket/')) {
      const chatId = url.pathname.split('/')[3];
      if (!chatId) return new Response('Invalid WebSocket URL', { status: 400 });
      const id = env.CHAT_ROOM.idFromName(chatId);
      const stub = env.CHAT_ROOM.get(id);
      return stub.fetch(request);
    }

    // === BUG FIX: Naya internal route jo ChatRoom DO ko call karega ===
    // Yeh zaroori hai taaki handleNewMessage ChatRoom DO ko forward kar sake.
    if (url.pathname.startsWith('/chat/')) {
        const pathSegments = url.pathname.split('/');
        // URL is /chat/{chatId}/internal/http-message
        if(pathSegments.length === 5 && pathSegments[3] === 'internal' && pathSegments[4] === 'http-message') {
            const chatId = pathSegments[2];
            if (!chatId) return new Response('Invalid internal route', { status: 400 });
            const id = env.CHAT_ROOM.idFromName(chatId);
            const stub = env.CHAT_ROOM.get(id);
            return stub.fetch(request);
        }
    }

    // === YEH DO NAYI IF CONDITIONS ADD KI GAYI HAIN ===
    if (request.method === 'POST' && url.pathname === '/api/crush') {
      return await handleCrush(request, env);
    }
    if (request.method === 'GET' && url.pathname === '/api/crushes-me') {
      return await handleCrushesMe(request, env);
    }
    // ================================================

    if (request.method === 'GET' && url.pathname === '/api/chats') {
      return await handleGetChats(request, env);
    }
    if (request.method === 'POST' && url.pathname === '/api/message') {
      return await handleNewMessage(request, env);
    }
    if (request.method === 'POST') {
      return await handleImageUpload(request, env);
    }
    if (request.method === 'GET' && url.pathname === '/api/history') {
      return await handleHistoryRequest(request, env);
    }

    // === YEH NAYI IF CONDITION YAHAAN ADD KAREIN ===
    if (request.method === 'GET' && url.pathname === '/api/chat-summaries') {
      return await handleChatSummariesRequest(request, env);
    }
    // ===============================================

    return new Response('Not Found', { status: 404 });
  },
};


// ============== handleNewMessage FUNCTION KO POORI TARAH SE BADAL DIYA GAYA HAI ==============
async function handleNewMessage(request, env) {
  try {
    const { senderId, receiverId, content } = await request.json();
    if (!senderId || !receiverId || !content) {
      return new Response('Missing required fields', { status: 400 });
    }

    // Step 1: Chat ID dhoondho ya banao
    const userIds = [senderId, receiverId].sort();
    const user1 = userIds[0];
    const user2 = userIds[1];
    let ps = env.DB.prepare('SELECT id FROM chats WHERE user1_id = ? AND user2_id = ?').bind(user1, user2);
    let chat = await ps.first();
    let chatId;
    if (chat) {
      chatId = chat.id;
    } else {
      ps = env.DB.prepare('INSERT INTO chats (user1_id, user2_id) VALUES (?, ?) RETURNING id').bind(user1, user2);
      const result = await ps.first();
      chatId = result.id;
    }

    // === BUG FIX START: AB HUM MESSAGE KHUD SAVE NAHI KARENGE ===
    // Step 2: Sahi ChatRoom Durable Object ka reference (stub) haasil karo
    const id = env.CHAT_ROOM.idFromName(chatId.toString());
    const chatRoomStub = env.CHAT_ROOM.get(id);

    // Step 3: Message ki saari zimmedaari ChatRoom DO ko saunp do
    console.log(`Forwarding HTTP message to ChatRoom DO for chatId: ${chatId}`);
    
    // Naye internal endpoint ko call karo.
    const url = new URL(request.url);
    const durableObjectUrl = `${url.origin}/chat/${chatId}/internal/http-message`;

    const forwardRequest = new Request(durableObjectUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ senderId, receiverId, content, chatId }),
    });

    return chatRoomStub.fetch(forwardRequest);
    // === BUG FIX END ===

  } catch (e) {
    console.error("Error in handleNewMessage:", e);
    return new Response(`Error saving message: ${e.message}`, { status: 500 });
  }
}

async function handleGetChats(request, env) {
  const url = new URL(request.url);
    const userId = url.searchParams.get('userId');
  if (!userId) {
    return new Response('userId query parameter is required.', { status: 400 });
  }
  try {
    // Step 1: D1 se saare chats laao (jaisa pehle tha)
    const ps = env.DB.prepare(
      `SELECT c.id as chat_id, c.user1_id, c.user2_id, (SELECT m.content FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message, (SELECT m.created_at FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_timestamp FROM chats c WHERE c.user1_id = ? OR c.user2_id = ? ORDER BY last_message_timestamp DESC`
    ).bind(userId, userId);
    const { results: allChats } = await ps.all();

    if (allChats.length === 0) {
        return new Response(JSON.stringify([]), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    // Step 2: Firestore se sabhi users ka blocking data laao
    const chatRoom = new ChatRoom(null, env); // Helper class ka instance banaya
    const accessToken = await chatRoom.getFirebaseAccessToken();
    
    // Sabhi other users ki IDs nikaalo taaki ek hi baar me data laa sakein
    const otherUserIds = [...new Set(allChats.map(chat => chat.user1_id === userId ? chat.user2_id : chat.user1_id))];
    
    // Khud ka data bhi laao
    const allIdsToFetch = [userId, ...otherUserIds];

    const firestorePromises = allIdsToFetch.map(id => 
        fetch(`https://firestore.googleapis.com/v1/projects/lovz-7598d/databases/(default)/documents/users/${id}`, {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        }).then(res => res.ok ? res.json() : null) // Agar user nahi milta to null return karo
    );

    const firestoreResults = await Promise.all(firestorePromises);
    
    const usersBlockData = {};
    firestoreResults.forEach((data, index) => {
        if (!data) return; // Skip if fetch failed
        const currentId = allIdsToFetch[index];
        const blockedUsersField = data.fields?.blockedUsers?.arrayValue?.values;
        usersBlockData[currentId] = blockedUsersField ? blockedUsersField.map(v => v.stringValue) : [];
    });

    const myBlockedList = usersBlockData[userId] || [];

    // Step 3: Chats ko filter karo
    const filteredChats = allChats.filter(chat => {
        const otherUserId = chat.user1_id === userId ? chat.user2_id : chat.user1_id;
        const otherUserBlockedList = usersBlockData[otherUserId] || [];

        const iHaveBlockedThem = myBlockedList.includes(otherUserId);
        const theyHaveBlockedMe = otherUserBlockedList.includes(userId);

        // Sirf woh chat dikhao jismein dono ne ek doosre ko block nahi kiya hai
        return !iHaveBlockedThem && !theyHaveBlockedMe;
    });

    return new Response(JSON.stringify(filteredChats), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error("Error fetching chats from D1:", e);
    return new Response(`Error fetching chats: ${e.message}`, { status: 500 });
  }
}

async function handleImageUpload(request, env) {
  const fileName = request.headers.get('X-Custom-Filename');
  if (!fileName) {
    return new Response('Filename header is missing.', { status: 400 });
  }
  try {
    await env.LOVZ_IMAGES_BUCKET.put(fileName, request.body);
    const successResponse = {
      message: 'Image uploaded successfully!',
      fileName: fileName,
    };
    return new Response(JSON.stringify(successResponse), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error("Error uploading to R2:", e);
    return new Response(`Error uploading file: ${e.message}`, { status: 500 });
  }
}

async function handleHistoryRequest(request, env) {
  const url = new URL(request.url);
  const chatId = url.searchParams.get('chatId');
  if (!chatId) {
    return new Response('chatId query parameter is required.', { status: 400 });
  }
  try {
    const ps = env.DB.prepare('SELECT * FROM messages WHERE chat_id = ?');
    const { results } = await ps.bind(chatId).all();
    return new Response(JSON.stringify(results), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error("Error fetching from D1:", e);
    return new Response(`Error fetching history: ${e.message}`, { status: 500 });
  }
}

// ================== NAYA CRUSH CODE START ==================

// "Crush" action ko handle karne wala function
async function handleCrush(request, env) {
  try {
    const { senderId, receiverId } = await request.json();

    if (!senderId || !receiverId) {
      return new Response(JSON.stringify({ error: 'Sender ID and Receiver ID are required.' }), { status: 400 });
    }
    
    // ChatRoom class se authentication function udhaar lenge
    const chatRoomHelper = new ChatRoom(null, env);
    const accessToken = await chatRoomHelper.getFirebaseAccessToken();
    
    // Firestore ka path banayenge: /users/{receiverId}/crushesMe/{senderId}
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/lovz-7598d/databases/(default)/documents/users/${receiverId}/crushesMe/${senderId}`;

    // Ek khali document banayenge, iska hona hi crush ka saboot hai
    const response = await fetch(firestoreUrl, {
      method: 'PATCH', // PATCH create aur update dono karta hai
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ fields: {} }) // Khali document
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Firestore error:", errorText);
      throw new Error(`Firestore setDoc failed: ${errorText}`);
    }

    return new Response(JSON.stringify({ message: 'Crush recorded successfully!' }), { status: 200 });

  } catch (error) {
    console.error('Error handling crush:', error);
    return new Response(JSON.stringify({ error: 'Failed to record crush.', details: error.message }), { status: 500 });
  }
}

// Un users ki list laane wala function jinhone humein crush kiya hai
async function handleCrushesMe(request, env) {
  try {
    const url = new URL(request.url);
    const userId = url.searchParams.get('userId');

    if (!userId) {
      return new Response(JSON.stringify({ error: 'User ID is required.' }), { status: 400 });
    }

    const chatRoomHelper = new ChatRoom(null, env);
    const accessToken = await chatRoomHelper.getFirebaseAccessToken();
    
    // Path: /users/{userId}/crushesMe
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/lovz-7598d/databases/(default)/documents/users/${userId}/crushesMe`;
    
    const response = await fetch(firestoreUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Firestore getCollection failed: ${errorText}`);
    }
    
    const data = await response.json();
    const documents = data.documents || [];

    const crushedByUids = documents.map(doc => {
      // Document ka naam (path ka aakhri hissa) hi sender ki UID hai
      const pathParts = doc.name.split('/');
      return pathParts[pathParts.length - 1];
    });

    return new Response(JSON.stringify({ userIds: crushedByUids }), { status: 200 });

  } catch (error) {
    console.error('Error fetching crushes-me:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch crushes-me.', details: error.message }), { status: 500 });
  }
}

// =================== NAYA CRUSH CODE END ===================