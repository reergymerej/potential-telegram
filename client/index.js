import('./src/Main.elm')
  .then(({ Elm }) => {
    // Once mounted, Elm removes the id of the element.  Subsequent reloads
    // freak out because there _is_ not #elm-root.  This is probably an init
    // issue we can change.
    const node = document.body.firstElementChild
    const app = Elm.Main.init({ node })
    setupWebSockets(app)
  });

const setupWebSockets = (app) => {

  app.ports.portedFunction.subscribe(function(data) {
    console.log('data from elm', data)
    // localStorage.setItem('cache', JSON.stringify(data));
  });

  const webSocket = new WebSocket('ws://localhost:8080', 'optionalProtocol')

  const decode = JSON.parse

  webSocket.onopen = () => {
    console.log('WS is open')
  }

  webSocket.onmessage = (event) => {
    const message = decode(event.data)
    // All messages should be sent back through port to Elm.
    console.log(message)
    app.ports.fromJS.send(event.data)
  }

  webSocket.onclose = (event) => {
    console.log('webSocket is closed')
  }

  webSocket.onerror = (event) => {
    console.log('webSocket got an error')
  }

  /*
   *  Elm will send this to us through a port.  Then we send it through the ws.
   *  webSocket.send(JSON.stringify({
   *    type: 'move',
   *    cellIndex,
   *  }))
   */
}
