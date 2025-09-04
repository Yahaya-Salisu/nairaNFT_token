// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import { nairaNFT } from "../src/nairaNFT.sol";

contract nairaNFT is nairaNFT, Test {
    nairaNFT public nft;
    address public owner;
    address public User;

    function setUp() public {
        nft = new nairaNFT();
        owner = address(this);
        User = makeAddr("User");
    }

    function setBaseURI() external {
        string memory newBase = "";
        vm.prank(owner);
        nft.setBaseURI(newBase);
    }

    function setBaseURI_revert_if_notOwner() external {
        string memory newBase = "";
        vm.prank(User);
        VM.expectRevert();
        nft.setBaseURI(newBase);
    }

    function setMintPrice() external {
        uint256 mintPrice = 1e16 ether;
        vm.prank(owner);
        nft.setMintPrice(mintPrice);
    }

    function setMintPrice_revert_if_notOwner() external {
        uint256 mintPrice = 1e16 ether;
        vm.prank(User);
        VM.expectRevert();
        nft.setMintPrice(mintPrice);
    }

    function setMaxPerWallet() external {
        uint256 maxPerWallet = 5;
        vm.prank(owner);
        nft.setMaxPerWallet(maxPerWallet);
    }

    function setMaxPerWallet_revert_if_notOwner() external {
        uint256 maxPerWallet = 5;
        vm.prank(User);
        vm.expectRevert();
        nft.setMaxPerWallet(maxPerWallet);
    }

    function pause() external {
        vm.prank(owner);
        nft.pause();
    }

    function pause_revert_if_notOwner() external {
        vm.prank(User);
        vm.expectRevert();
        nft.pause();
    }

    function unpause() external {
        vm.prank(owner);
        nft.unpause();
    }

    function unpause_revert_if_notOwner() external {
        vm.prank(User);
        vm.expectRevert();
        nft.unpause();
    }

    function ownerMint() external {
        uint256 quantity = 3;
        vm.prank(owner);
        nft.ownerMint(to, quantity);
    }

    function ownerMint_revert_if_notOwner() external {
        uint256 quantity = 3;
        vm.prank(User);
        vm.expectRevert();
        nft.ownerMint(to, quantity);
    }

    function ownerMint_revert_if_exceeds_maxPerWallet() external {
        uint256 quantity = 3 * 2;
        vm.prank(owner);
        vm.expectRevert();
        nft.ownerMint(to, quantity);
    }

    function ownerMint_revert_if_exceeds_maxSupply() external {
        uint256 quantity = 1_001;
        vm.prank(owner);
        vm.expectRevert();
        nft.ownerMint(to, quantity);
    }

    function publicMint() external {
        uint256 quantity = 3;
        vm.deal(User, 0.03 ether)
        vm.prank(User);
        nft.publicMint(to, quantity);
    }

    function publicMint_revert_if_exceeds_maxSupply() external {
        uint256 quantity = 1_001;
        vm.deal(User, 10.01 ether)
        vm.prank(User);
        nft.publicMint(to, quantity);
    }

    function publicMint_revert_if_exceeds_maxPerWallet() external {
        uint256 quantity = 3 * 2;
        vm.deal(User, 0.06 1e16 ether)
        vm.prank(User);
        nft.publicMint(to, quantity);
    }

    function publicMint_revert_if_quantity_isZero() external {
        uint256 quantity = 0;
        vm.deal(User, 0.01 ether)
        vm.prank(User);
        nft.publicMint(to, quantity);
    }

    function publicMint_revert_if_mintPrice_isZero() external {
        uint256 quantity = 3;
        vm.deal(User, 0 ether)
        vm.prank(User);
        nft.publicMint(to, quantity);
    }

    function withdraw() external {
        uint256 quantity = 3;
        vm.startPrank(owner);
        nft.ownerMint(to, quantity);
        nft.withdraw(to);
        vm.stopPrank();
    }
}