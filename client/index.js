import('./src/Main.elm')
  .then(({ Elm }) => {
    var node = document.getElementById('elm-root')
    Elm.Main.init({ node: node })
  });

(() => {
  const webSocket = new WebSocket('ws://localhost:8080', 'optionalProtocol')

  const decode = JSON.parse

  webSocket.onopen = () => {
    console.log('ready to rock')
  }

  const updateBoardState = (board) => {
    board.forEach((row, rowIndex) => {
      row.forEach((owner, colIndex) => {
        const i = rowIndex * 3 + colIndex
        const el = document.getElementById(i)
        if (owner) {
          el.setAttribute('data-owner', owner)
          el.innerText = owner
        } else {
          el.removeAttribute('data-owner')
          el.innerText = ''
        }
      })
    })
  }

  let myTurn

  const onStartGame = (message) => {
    updateBoardState(message.board)
    myTurn = message.yourTurn
  }

  const onUpdateGame = (message) => {
    updateBoardState(message.board)
    myTurn = message.yourTurn
  }

  const onWhoops = (message) => {
    console.warn(`no handler for message ${message.type}`)
    // throw new Error(`no handler for message ${message.type}`)
  }

  const messageHandlers = {
    'update-game': onUpdateGame,
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

  const onCellClick = (event) => {
    const target = event.target
    const owner = target.getAttribute('data-owner')
    const cellIndex = target.id
    if (!owner) {
      if (myTurn) {
        webSocket.send(JSON.stringify({
          type: 'move',
          cellIndex,
        }))
      }
    }
  }

  document.querySelectorAll('.cell').forEach(x => {
    x.addEventListener('click', onCellClick)
  })
})()
