//(() => {
  const webSocket = new WebSocket('ws://localhost:8080', 'optionalProtocol')

  const decode = JSON.parse

  webSocket.onopen = () => {
    console.log('ready to rock')
  }

  const onStartGame = (message) => {
    console.log('onStartGame', message)
  }

  const onWhoops = (message) => {
    console.warn(`no handler for message ${message.type}`)
    // throw new Error(`no handler for message ${message.type}`)
  }

  const messageHandlers = {
    'start-game': onStartGame,
    whoops: onWhoops,
  }

  webSocket.onmessage = (event) => {
    const message = decode(event.data)
    const handler = (messageHandlers[message.type] || messageHandlers.whoops)
    handler(message)
  }

  webSocket.onclose = (event) => {
    console.log('webSocket is closed')
  }

  webSocket.onerror = (event) => {
    console.log('webSocket got an error')
  }

//})()
