const WebSocket = require('ws')
const wss = new WebSocket.Server({ port: 8080 })

let id = 0

const encode = JSON.stringify

wss.broadcast = (data) => {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data)
    }
  })
}

const getPair = (newClient) => {
  if (unpairedClient) {
    return unpairedClient
  }
}

let unpairedClient

wss.on('connection', (ws) => {
  ws.id = ++id
  console.log(`new connection, ${ws.id}`)

  ws.on('message', (message) => {
    console.log('received: %s', message)
  })

  ws.on('close', () => {
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
  })

  ws.send(encode({
    type: 'connect',
    text: `your id is ${id}`,
    id: id,
  }))

  if (unpairedClient) {
    ws.buddy = unpairedClient
    unpairedClient.buddy = ws
    unpairedClient = null
    ws.send(encode({
      type: 'status',
      text: `your buddy is ${ws.buddy.id}`,
    }))

    ws.buddy.send(encode({
      type: 'status',
      text: `your buddy is ${ws.id}`,
    }))
  } else {
    ws.send(encode({
      type: 'status',
      text: 'waiting for a buddy',
    }))
    unpairedClient = ws
  }

  // wss.broadcast(encode({
  //   type: 'new-client',
  //   text: 'a new client has joined',
  // }))
})
