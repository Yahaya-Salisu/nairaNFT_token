// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import "../src/nairaNFT.sol";

contract nairaNFT is nairaNFT, Test {
    nairaNFT public NFT;
    address public owner;
    address public User1;
    address public User2;

    function setUp() public {
        NFT = new nairaNFT();
        owner = address(this);
        User1 = makeAddr("User1");
        User2 = makeAddr("User2");
    }
}