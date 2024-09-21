# Black Box

```
          _________                     _______                
        .'         `.                 .' _____ `.              
       / .#########. \               / .'#####`. \             
      | |###########| |             | |#######|  |             
      ; |###########| ;             ; |#######|  ;             
      \ '.___###__.' /  \            \ '.___.' /  \            
       \           / \  `-.           \       / \  `-.         
        |   ###   |  `\    \           |     |  `\    \        
       |    ###   _|    `\   \        |     _|    `\    \      
        _./'   `\._       `-._\        _./'   `\._   `-._\     
      .'/         `.`.       '_.-.   .'/         `.`.    '_.-. 
````

Black box is a privacy device pluggable on top of any token to securely buy and sell without compromising anonymity.

## Protocol

messages are stored as pedersen commitments to deposits, with a note, a value and a nullifier. These messages are then accumulated into a merkle-tree to reduce on-chain computation and permit zk-fication of the protocol, allowing to hide crucial parts of the proof in order to unlink deposits to withdrawals.  

1. User generates a pedersen commitment to their deposit
1. User deposits tokens into the Black Box, along with a commitment, a new root and a zk-proof of integrity.
4. If the verification check passes, the Black Box protocol sends the tokens to the recipient.
5. to withdraw, the user provides the amount and nullifier to the protocol, along with a proof that they have knowledge of the commitment's note.
