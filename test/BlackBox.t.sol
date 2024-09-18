// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BlackBox.sol";

/// todo: implement merkle-tree manipulations in js
contract BlackBoxTest is Test {

    BlackBox public blackBox;
    
    uint256 constant TREE_DEPTH = 32;
    bytes32[TREE_DEPTH] zeroHashes;

    function setUp() public {
        // Compute empty merkle tree
        zeroHashes[0] = keccak256(abi.encodePacked(uint256(0)));
        for (uint256 i = 1; i < TREE_DEPTH; i++) {
            zeroHashes[i] = keccak256(abi.encodePacked(zeroHashes[i-1], zeroHashes[i-1]));
        }

        // Deploy BlackBox contract
        blackBox = new BlackBox(zeroHashes[TREE_DEPTH - 1], zeroHashes);
    }

    function testInitialRoot() public {
        assertEq(blackBox.root(), zeroHashes[TREE_DEPTH - 1], "Initial root should be set correctly");
    }

    function testDeposit() public {
        bytes32 commitment = keccak256("test commitment");
        uint256 initialBalance = address(blackBox).balance;

        blackBox.deposit{value: 1 ether}(commitment);

        assertEq(address(blackBox).balance, initialBalance + 1 ether, "Contract balance should increase");
        assertTrue(blackBox.root() != zeroHashes[TREE_DEPTH - 1], "Root should be updated after deposit");
    }

    // Add more test functions here for other contract functionalities
}
