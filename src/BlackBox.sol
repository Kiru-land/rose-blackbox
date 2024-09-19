// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26; 

import { DepositVerifier } from "./DepositVerifier.sol";
import { WithdrawVerifier } from "./WithdrawVerifier.sol";

/**
  * @title Black Box v0.1.0
  *
  * @author 5A6E55E
  *
  *          _______
  *        .' /H|__ `.
  *       /  =[_]O|` \
  *      |   / \ |   |
  *      ;  | O |;   ;
  *       '.___.' \  /
  *        |  _  |  \  `-.
  *       |   |_|   `\    \
  *        _./'   `\_  `-._\
  *      .'/         `.`.  '_.-.
  *
  * @notice Privacy market-maker
  *
  * @dev This system makes use of pedersen commitments containing :
  *
  *      - a secret note
  *      - the value sent
  *      - a nullifier to prevent double-spends.
  *
  *      The note is used to identify the commitment during the sell phase,
  *      the value is used to prevent sells greater than the hidden balance,
  *      and the nullifier gets marked as used to prevent double-spends.
  *      
  *      Commitments are accumulated in a merkle tree, allowing for quick
  *      inclusion proofs, while being zk-friendly for lightweight on-chain
  *      integrity verification.
  *
  *      Proofs are generated over the Barretenberg curve.
  *
  *          _________                     _______                
  *        .'         `.                 .' _____ `.              
  *       / .#########. \               / .'#####`. \             
  *      | |###########| |             | |#######|  |             
  *      ; |###########| ;             ; |#######|  ;             
  *      \ '.___###__.' /  \            \ '.___.' /  \            
  *       \           / \  `-.           \       / \  `-.         
  *        |   ###   |  `\    \           |     |  `\    \        
  *       |    ###   _|    `\    \       |     _|    `\    \      
  *        _./'   `\._       `-._\        _./'   `\._   `-._\     
  *      .'/         `.`.       '_.-.   .'/         `.`.    '_.-. 
  */
contract BlackBox is DepositVerifier, WithdrawVerifier {

    bytes32 root;

    mapping(bytes32 => bool) nullifiers;

    bytes32 idx;

    address constant TOKEN = 0x0000000000000000000000000000000000000000;

    bytes32 constant BALANCE_OF_SIG = keccak256("balanceOf(address)");
    bytes32 constant TRANSFER_SIG = keccak256("transfer(address,uint256)");

    constructor(bytes32 _root) {
        root = _root;
    }

    /**
      * @notice Send ETH into the blackbox to buy TOKEN.
      *
      * @dev During a bonding-curve deposit, the user sends a valid commitment
      *      containing the note, the value sent and the nullifier, along with
      *      the new merkle-tree root after the commitment inclusion, and a zk
      *      proof of integrity, specifically:
      *
      *      - the commitment holds the correct amount
      *      - the new root is derived by a valid state transition from the
      *        current root
      *
      *      The caller must precompute the note, the amount of TOKEN received
      *      and the nullifier in order to construct a valid commitment.
      *      These must be securely kept to be able to withdraw later.
      *
      * @param commitment The merkle-tree leaf commitment to the deposit.
      *
      * @param newRoot The new root of the merkle tree after the leaf insertion.
      *
      * @param proof The proof of integrity
      */
    function deposit(
        bytes32 commitment,
        bytes32 value,
        bytes32 newRoot,
        bytes calldata proof
    ) external payable returns (bool) {
        bytes32 _BALANCE_OF_SIG = BALANCE_OF_SIG;
        bytes32 _TRANSFER_SIG = TRANSFER_SIG;
        bytes32 received;
        assembly {
            let ptr := mload(0x40)
            // query current balance of this contract
            mstore(ptr, shl(224, _BALANCE_OF_SIG))
            mstore(add(ptr, 0x04), address())
            if iszero(call(gas(), TOKEN, 0, ptr, 0x24, add(ptr, 0x24), 0x20)) { revert(0, 0) }
            let currentBalance := mload(add(ptr, 0x24))
            // send deposit call to TOKEN
            if iszero(call(gas(), TOKEN, callvalue(), 0, 0, 0, 0)) { revert(0, 0) }
            // query updated balance to compute received amount
            if iszero(call(gas(), TOKEN, 0, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
            received := sub(mload(ptr), currentBalance)
            // return excess TOKEN (if any): received - value
            if lt(received, value) {
                let excess := sub(value, received)
                mstore(ptr, shl(224, _TRANSFER_SIG))
                mstore(add(ptr, 0x04), address())
                if iszero(call(gas(), TOKEN, 0, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                received := sub(received, excess)
            }
            // update root and idx
            sstore(root.slot, newRoot)
            sstore(idx.slot, add(idx.slot, 1))
        }

        bytes32[] memory verifierInputs = new bytes32[](5);
        verifierInputs[0] = commitment;
        verifierInputs[1] = received;
        verifierInputs[2] = idx;
        verifierInputs[3] = root;
        verifierInputs[4] = newRoot;

        assert(DepositVerifier.verify(proof, verifierInputs));
        return true;
    }

    /**
      * @notice Withdraw ETH from the blackbox.
      *
      * @dev During a bonding-curve withdraw, the user sends a valid commitment
      *      containing the value to withdraw, the nullifier and the root, along
      *      with a zk proof of integrity, specifically:
      *
      *      - The withdrawer knows a (note, value, nullifier) commitment inside
      *        the merkle tree
      *      - the nullifier has not yet been used
      *
      * @param value The amount of TOKEN committed at deposit time
      *
      * @param nullifier The nullifier of the withdrawal
      *
      * @param proof The proof of integrity
      */
    function withdraw(uint256 value, bytes32 nullifier, bytes32[] memory proof) external returns (bool) {
        bytes32[] memory verifierInputs = new bytes32[](3);
        verifierInputs[0] = value;
        verifierInputs[1] = nullifier;
        verifierInputs[2] = root;

        assert(WithdrawVerifier.verify(proof, verifierInputs));

        assembly {
            let ptr := mload(0x40)
            // mark nullifier as used
            mstore(ptr, nullifier)
            mstore(add(ptr, 0x20), 1)
            let NULLIFIER_SLOT := keccak256(ptr, 0x40)
            sstore(NULLIFIER_SLOT, true)
            // send withdraw call to TOKEN
            let ptr := mload(0x40)
            mstore(ptr, shl(224, TRANSFER_SIG))
            mstore(add(ptr, 0x04), TOKEN)
            mstore(add(ptr, 0x24), value)
            if iszero(call(gas(), TOKEN, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            // send ETH to the user
            if iszero(call(gas(), msg.sender, value, 0, 0, 0, 0)) { revert(0, 0) }
        }
        return true;
    }
}
