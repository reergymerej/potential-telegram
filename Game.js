function Game(X, O) {
  this.X = X
  this.O = O
  this.turn = X
  this.board = [
    [null, null, null],
    [null, null, null],
    [null, null, null],
  ]
  this.players = [X, O]
}

Game.prototype.getBoard = function () {
  const game = this
  return this.board.map(row => {
    return row.map(cell => {
      return cell && game.getSymbol(cell)
    })
  })
}

Game.prototype.getSymbol = function (player) {
  return player === this.X
    ? 'X'
    : 'O'
}

Game.prototype.selectCell = function (player, cellIndex) {
  const rowIndex = Math.floor(cellIndex / 3)
  const cell = cellIndex % 3
  this.board[rowIndex][cell] = player

  // TODO: check for game over
  this.switchTurn()
}

Game.prototype.switchTurn = function () {
  this.turn = this.turn === this.X
    ? this.O
    : this.X
}

module.exports = Game
