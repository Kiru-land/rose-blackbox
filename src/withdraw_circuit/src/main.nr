use dep::std::hash;
use dep::std::merkle;

fn main(
    message: Field,
    value: pub Field,
    nullifier: pub Field,
    index: Field,
    hashpath: [Field; 40],
    root: pub Field,
) {
    // reconstruct the commitment from the message, value, and nullifier
    let commitment = hash::pedersen_commitment([message, value, nullifier]);
    // verify commitment inclusion in the merkle tree
    let merkle_root = merkle::compute_merkle_root(commitment.to_field(), index, hashpath);
    assert(merkle_root == root);
}
