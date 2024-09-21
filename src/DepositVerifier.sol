// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26; 

contract DepositVerifier {
    // function verify(
    //     bytes32 leaf,
    //     uint value,
    //     uint index,
    //     bytes32 root,
    //     bytes32 newRoot,
    //     bytes[] memory proof
    // ) public view returns (bool)
    function verify(bytes calldata _proof, bytes32[] memory _publicInputs) public view returns (bool) {
        return true;
    }
}
