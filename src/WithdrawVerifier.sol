// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26; 

contract WithdrawVerifier {
    // function verify(
        // uint value,
        // bytes32 nullifier,
        // bytes32 root,
        // bytes32[] memory proof
    // ) public view returns (bool)
    function verify(bytes calldata _proof, bytes32[] memory _publicInputs) public view returns (bool) {}
}
