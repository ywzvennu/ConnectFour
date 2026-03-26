// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ConnectFour {
    uint8 constant ROWS = 6;
    uint8 constant COLS = 7;

    enum Status { Waiting, Active, Draw, WonPlayer1, WonPlayer2 }

    struct Game {
        address player1;
        address player2;
        Status status;
        uint8 turn; // 1 or 2
        uint8 movesPlayed;
        uint8[6][7] board; // board[col][row], 0=empty, 1=player1, 2=player2
    }

    uint256 public gameCount;
    mapping(uint256 => Game) public games;

    event GameCreated(uint256 indexed gameId, address indexed player1);
    event GameJoined(uint256 indexed gameId, address indexed player2);
    event MovePlayed(uint256 indexed gameId, address indexed player, uint8 col, uint8 row);
    event GameWon(uint256 indexed gameId, address indexed winner);
    event GameDrawn(uint256 indexed gameId);

    function createGame() external returns (uint256 gameId) {
        gameId = gameCount++;
        Game storage g = games[gameId];
        g.player1 = msg.sender;
        g.status = Status.Waiting;
        g.turn = 1;
        emit GameCreated(gameId, msg.sender);
    }

    function joinGame(uint256 gameId) external {
        Game storage g = games[gameId];
        require(g.status == Status.Waiting, "Game not joinable");
        require(msg.sender != g.player1, "Cannot join own game");
        g.player2 = msg.sender;
        g.status = Status.Active;
        emit GameJoined(gameId, msg.sender);
    }

    function playMove(uint256 gameId, uint8 col) external {
        Game storage g = games[gameId];
        require(g.status == Status.Active, "Game not active");
        require(col < COLS, "Invalid column");

        address currentPlayer = g.turn == 1 ? g.player1 : g.player2;
        require(msg.sender == currentPlayer, "Not your turn");

        // Find lowest empty row in column
        uint8 row = type(uint8).max;
        for (uint8 r = 0; r < ROWS; r++) {
            if (g.board[col][r] == 0) {
                row = r;
                break;
            }
        }
        require(row != type(uint8).max, "Column full");

        g.board[col][row] = g.turn;
        g.movesPlayed++;

        emit MovePlayed(gameId, msg.sender, col, row);

        if (_checkWin(g, col, row, g.turn)) {
            g.status = g.turn == 1 ? Status.WonPlayer1 : Status.WonPlayer2;
            emit GameWon(gameId, msg.sender);
        } else if (g.movesPlayed == ROWS * COLS) {
            g.status = Status.Draw;
            emit GameDrawn(gameId);
        } else {
            g.turn = g.turn == 1 ? uint8(2) : uint8(1);
        }
    }

    function _checkWin(Game storage g, uint8 col, uint8 row, uint8 player) internal view returns (bool) {
        int8[4] memory dCol = [int8(1), int8(0), int8(1), int8(1)];
        int8[4] memory dRow = [int8(0), int8(1), int8(1), int8(-1)];

        for (uint8 d = 0; d < 4; d++) {
            uint8 count = 1;
            count += _countDirection(g, col, row, dCol[d], dRow[d], player);
            count += _countDirection(g, col, row, -dCol[d], -dRow[d], player);
            if (count >= 4) return true;
        }
        return false;
    }

    function _countDirection(
        Game storage g,
        uint8 col,
        uint8 row,
        int8 dCol,
        int8 dRow,
        uint8 player
    ) internal view returns (uint8 count) {
        for (uint8 i = 1; i < 4; i++) {
            int8 c = int8(col) + dCol * int8(i);
            int8 r = int8(row) + dRow * int8(i);
            if (c < 0 || c >= int8(COLS) || r < 0 || r >= int8(ROWS)) break;
            if (g.board[uint8(c)][uint8(r)] != player) break;
            count++;
        }
    }

    function getBoard(uint256 gameId) external view returns (uint8[6][7] memory) {
        return games[gameId].board;
    }

    function getGame(uint256 gameId)
        external
        view
        returns (address player1, address player2, Status status, uint8 turn, uint8 movesPlayed)
    {
        Game storage g = games[gameId];
        return (g.player1, g.player2, g.status, g.turn, g.movesPlayed);
    }
}
