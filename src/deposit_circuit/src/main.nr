use dep::std::hash;
use dep::std::merkle;

fn main(
    leaf: pub hash::EmbeddedCurvePoint,
    note: [Field; 62],
    value: pub Field,
    nullifier: Field,
    index: pub Field,
    hashpath: [Field; 40],
    root: pub Field,
    newRoot: pub Field
) {
    // construct commitment from note, value, and nullifier, then assert
    // that the provided leaf (public input broadcasted on-chain) is
    // equal to the computed commitment
    let note_hash = std::hash::hash_to_field(note.as_slice());
    let commitment = hash::pedersen_commitment([note_hash, value, nullifier]);
    assert(leaf == commitment);

    // compute the merkle root of the commitment using the provided hashpath
    // and assert that it is equal to the provided root
    let merkle_root = merkle::compute_merkle_root(0, index, hashpath);
    assert(merkle_root == root);

    // compute the new merkle root using the same haspath in order to prove
    // that the provided transition is valid
    let new_merkle_root = merkle::compute_merkle_root(leaf.to_field(), index, hashpath);
    assert(new_merkle_root == newRoot);
}

// fn compute_merkle_root(
    // mut node: Field,
    // index_bits: [bool; TREE_DEPTH],
    // hashpath: [Field; TREE_DEPTH]
// ) -> Field {
    // for i in 0..TREE_DEPTH {
        // let sibling = hashpath[i];
        // if index_bits[i] == false {
            // node = hash_pair(node, sibling);
        // } else {
            // node = hash_pair(sibling, node);
        // }
    // }
    // return node;
// }
