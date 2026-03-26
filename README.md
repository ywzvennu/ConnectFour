# Connect Four

An on-chain Connect Four game built with Solidity and Foundry.

## Overview

Two players take turns dropping pieces into a 7-column, 6-row board. The first player to connect four pieces in a row (horizontally, vertically, or diagonally) wins. If all 42 cells are filled with no winner, the game ends in a draw.

## Contract

`ConnectFour.sol` manages multiple concurrent games with the following flow:

1. **Create** — Player 1 calls `createGame()` to start a new game
2. **Join** — Player 2 calls `joinGame(gameId)` to join
3. **Play** — Players alternate calling `playMove(gameId, col)` to drop pieces
4. **Result** — The contract detects wins and draws automatically

### Functions

| Function | Description |
|---|---|
| `createGame()` | Creates a new game, returns the game ID |
| `joinGame(uint256 gameId)` | Joins an existing game as player 2 |
| `playMove(uint256 gameId, uint8 col)` | Drops a piece in the specified column (0-6) |
| `getBoard(uint256 gameId)` | Returns the full 7x6 board state |
| `getGame(uint256 gameId)` | Returns game metadata (players, status, turn) |

### Events

- `GameCreated` / `GameJoined` — lobby lifecycle
- `MovePlayed` — emitted on each move with column and row
- `GameWon` / `GameDrawn` — game outcome

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy

```shell
forge script script/ConnectFour.s.sol:ConnectFourScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
