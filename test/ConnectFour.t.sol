// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ConnectFour} from "../src/ConnectFour.sol";

contract ConnectFourTest is Test {
    ConnectFour public game;
    address player1 = address(0x1);
    address player2 = address(0x2);

    function setUp() public {
        game = new ConnectFour();
    }

    function _createAndJoin() internal returns (uint256) {
        vm.prank(player1);
        uint256 id = game.createGame();
        vm.prank(player2);
        game.joinGame(id);
        return id;
    }

    function test_createGame() public {
        vm.prank(player1);
        uint256 id = game.createGame();
        (address p1,, ConnectFour.Status status, uint8 turn,) = game.getGame(id);
        assertEq(p1, player1);
        assertEq(uint8(status), uint8(ConnectFour.Status.Waiting));
        assertEq(turn, 1);
    }

    function test_joinGame() public {
        vm.prank(player1);
        uint256 id = game.createGame();
        vm.prank(player2);
        game.joinGame(id);
        (, address p2, ConnectFour.Status status,,) = game.getGame(id);
        assertEq(p2, player2);
        assertEq(uint8(status), uint8(ConnectFour.Status.Active));
    }

    function test_revert_joinOwnGame() public {
        vm.prank(player1);
        uint256 id = game.createGame();
        vm.prank(player1);
        vm.expectRevert("Cannot join own game");
        game.joinGame(id);
    }

    function test_revert_joinActiveGame() public {
        uint256 id = _createAndJoin();
        vm.prank(address(0x3));
        vm.expectRevert("Game not joinable");
        game.joinGame(id);
    }

    function test_playMove() public {
        uint256 id = _createAndJoin();
        vm.prank(player1);
        game.playMove(id, 3);
        uint8[6][7] memory board = game.getBoard(id);
        assertEq(board[3][0], 1);
    }

    function test_revert_notYourTurn() public {
        uint256 id = _createAndJoin();
        vm.prank(player2);
        vm.expectRevert("Not your turn");
        game.playMove(id, 0);
    }

    function test_revert_invalidColumn() public {
        uint256 id = _createAndJoin();
        vm.prank(player1);
        vm.expectRevert("Invalid column");
        game.playMove(id, 7);
    }

    function test_revert_columnFull() public {
        uint256 id = _createAndJoin();
        // Fill column 0 (6 rows)
        for (uint8 i = 0; i < 6; i++) {
            address p = i % 2 == 0 ? player1 : player2;
            vm.prank(p);
            game.playMove(id, 0);
        }
        // Column 0 is now full, player1's turn
        vm.prank(player1);
        vm.expectRevert("Column full");
        game.playMove(id, 0);
    }

    function test_verticalWin() public {
        uint256 id = _createAndJoin();
        // Player1 drops in col 0, player2 drops in col 1
        for (uint8 i = 0; i < 3; i++) {
            vm.prank(player1);
            game.playMove(id, 0);
            vm.prank(player2);
            game.playMove(id, 1);
        }
        // Player1 drops 4th in col 0 -> vertical win
        vm.prank(player1);
        game.playMove(id, 0);
        (,, ConnectFour.Status status,,) = game.getGame(id);
        assertEq(uint8(status), uint8(ConnectFour.Status.WonPlayer1));
    }

    function test_horizontalWin() public {
        uint256 id = _createAndJoin();
        // Player1: cols 0,1,2,3  Player2: cols 0,1,2 (stacking on top)
        // Row 0: P1 at cols 0,1,2,3
        // Row 0 for P2: cols 4,5,6 won't interfere
        // Alternate: P1 col0, P2 col4, P1 col1, P2 col5, P1 col2, P2 col6, P1 col3 -> win
        vm.prank(player1);
        game.playMove(id, 0);
        vm.prank(player2);
        game.playMove(id, 4);
        vm.prank(player1);
        game.playMove(id, 1);
        vm.prank(player2);
        game.playMove(id, 5);
        vm.prank(player1);
        game.playMove(id, 2);
        vm.prank(player2);
        game.playMove(id, 6);
        vm.prank(player1);
        game.playMove(id, 3);
        (,, ConnectFour.Status status,,) = game.getGame(id);
        assertEq(uint8(status), uint8(ConnectFour.Status.WonPlayer1));
    }

    function test_diagonalWinAscending() public {
        uint256 id = _createAndJoin();
        // Build a diagonal for player1: (0,0), (1,1), (2,2), (3,3)
        // Col 0: P1
        vm.prank(player1);
        game.playMove(id, 0); // (0,0)=P1
        // Col 1: P2 then P1
        vm.prank(player2);
        game.playMove(id, 1); // (1,0)=P2
        vm.prank(player1);
        game.playMove(id, 1); // (1,1)=P1
        // Col 2: P2, P2, P1
        vm.prank(player2);
        game.playMove(id, 2); // (2,0)=P2
        vm.prank(player1);
        game.playMove(id, 6); // filler
        vm.prank(player2);
        game.playMove(id, 2); // (2,1)=P2
        vm.prank(player1);
        game.playMove(id, 2); // (2,2)=P1
        // Col 3: P2, P2, P2, P1
        vm.prank(player2);
        game.playMove(id, 3); // (3,0)=P2
        vm.prank(player1);
        game.playMove(id, 6); // filler
        vm.prank(player2);
        game.playMove(id, 3); // (3,1)=P2
        vm.prank(player1);
        game.playMove(id, 6); // filler
        vm.prank(player2);
        game.playMove(id, 3); // (3,2)=P2
        vm.prank(player1);
        game.playMove(id, 3); // (3,3)=P1 -> diagonal win
        (,, ConnectFour.Status status,,) = game.getGame(id);
        assertEq(uint8(status), uint8(ConnectFour.Status.WonPlayer1));
    }

    function test_revert_moveAfterWin() public {
        uint256 id = _createAndJoin();
        for (uint8 i = 0; i < 3; i++) {
            vm.prank(player1);
            game.playMove(id, 0);
            vm.prank(player2);
            game.playMove(id, 1);
        }
        vm.prank(player1);
        game.playMove(id, 0); // win
        vm.prank(player2);
        vm.expectRevert("Game not active");
        game.playMove(id, 1);
    }

    function test_multipleGames() public {
        vm.prank(player1);
        uint256 id1 = game.createGame();
        vm.prank(player1);
        uint256 id2 = game.createGame();
        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(game.gameCount(), 2);
    }
}
