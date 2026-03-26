// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ConnectFour} from "../src/ConnectFour.sol";

contract ConnectFourScript is Script {
    function run() public returns (ConnectFour) {
        vm.startBroadcast();
        ConnectFour connectFour = new ConnectFour();
        vm.stopBroadcast();
        return connectFour;
    }
}
