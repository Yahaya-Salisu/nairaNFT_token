// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { Script } from "forge-std/Script.sol";
import "../src/nairaNFT.sol";

contract deploynairaNFT is Script {
    nairaNFT public nft;

    function run() public {

        vm.startBroadcast();
        nft = new nairaNFT();
        vm.stopBroadcast();
    }
}