function Game(X, O) {
  this.X = X
  this.O = O
  this.turn = X
  this.board = [
    [null, null, null],
    [null, X, null],
    [null, null, null],
  ]
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

module.exports = Game
