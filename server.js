const WebSocket = require('ws')
const wss = new WebSocket.Server({ port: 8080 })
const Game = require('./Game')

let id = 0

const encode = JSON.stringify

wss.broadcast = (data) => {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data)
    }
  })
}

let unpairedClient

const onClose = function () {
  const ws = this
  console.log(`bye connection, ${ws.id}`)
  if (unpairedClient === ws) {
    unpairedClient = null
  } else if (ws.buddy) {
    ws.buddy.send(encode({
      type: 'lost-buddy'
    }))
    ws.buddy.buddy = null
    unpairedClient = ws.buddy
  }
}

const onMessage = function (message) {
  const ws = this
  console.log(`${ws.id} sent`, message)
}

const send = (ws, message) => {
  if (!message.type) {
    throw new Error('messages must have a type')
  }
  ws.send(encode(message))
}

const sendBuddyMessage = (ws) => {
  send(ws, {
    type: 'status',
    text: `your buddy is ${ws.buddy.id}`,
  })
}

const pairClients = (ws1, ws2) => {
  ws1.buddy = ws2
  ws2.buddy = ws1
  sendBuddyMessage(ws1)
  sendBuddyMessage(ws2)
}

const startGame = (ws1, ws2) => {
  const game = new Game(ws1, ws2)
  const board = game.getBoard()
  ;[ws1, ws2].forEach(ws => {
    send(ws, {
      type: 'start-game',
      board,
      yourTurn: game.turn === ws,
      you: game.getSymbol(ws),
    })
  })
}

const handlePairing = (ws, unpairedClient) => {
  if (unpairedClient) {
    pairClients(ws, unpairedClient)
    startGame(ws, ws.buddy)
    return null
  } else {
    send(ws, {
      type: 'status',
      text: 'waiting for a buddy',
    })
    return ws
  }
}

const onConnection = function (ws) {
  ws.id = ++id
  console.log(`new connection, ${ws.id}`)

  ws.on('message', onMessage)
  ws.on('close', onClose)

  send(ws, {
    type: 'connect',
    text: `your id is ${id}`,
    id,
  })

  unpairedClient = handlePairing(ws, unpairedClient)
}

wss.on('connection', onConnection)
