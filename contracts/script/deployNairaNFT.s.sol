// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { Script } from "forge-std/Script.sol";
import "../src/nairaNFT.sol";

contract deployNairaNFT is Script {
    nairaNFT public NFT;

    function run() public {

        vm.startBroadcast();
        NFT = new nairaNFT();
        vm.stopBroadcast();
    }
}