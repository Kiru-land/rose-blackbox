use dep::std::hash;
use dep::std::merkle;

fn main(
    leaf: pub [Field; 62],
    note: [Field; 62],
    value: pub Field,
    nullifier: Field,
    index: Field,
    hashpath: [Field; 40],
    root: pub Field,
    newRoot: pub Field
) {
    // construct commitment from note, value, and nullifier, then assert
    // that the provided leaf (public input broadcasted on-chain) is
    // equal to the computed commitment
    let commitment = hash::pedersen_commitment([note, value, nullifier]);
    assert(leaf == commitment);

    // compute the merkle root of the commitment using the provided hashpath
    // and assert that it is equal to the provided root
    let merkle_root = merkle::compute_merkle_root(leaf, index, hashpath);
    assert(merkle_root == root);

    // compute the new merkle root using the same haspath in order to prove
    // that the provided transition is valid
    let new_merkle_root = merkle::compute_merkle_root(root, index, hashpath);
    assert(new_merkle_root == newRoot);
}

fn s_compute_merkle_root(
    mut node: Field,
    index_bits: [bool; TREE_DEPTH],
    hashpath: [Field; TREE_DEPTH]
) -> Field {
    // Iterate over each level of the tree
    for i in 0..TREE_DEPTH {
        let sibling = hashpath[i];
        // Decide the order of hashing based on the current bit of the index
        if index_bits[i] == false {
            // If the bit is 0, current node is on the left
            node = hash_pair(node, sibling);
        } else {
            // If the bit is 1, current node is on the right
            node = hash_pair(sibling, node);
        }
    }
    return node;
}

// Helper function to hash two fields together
fn hash_pair(left: Field, right: Field) -> Field {
    // Use a hash function compatible with Noir (e.g., Poseidon)
    // Combine the two fields into an array
    let inputs = [left, right];
    // Compute the hash
    let result = hash::poseidon(inputs);
    return result;
}
