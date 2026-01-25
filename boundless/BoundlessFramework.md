# Boundless Framework: Prover Incentives & On-Chain Verification

## Overview

Boundless is a decentralized proof market that enables universal zero-knowledge proof generation across any blockchain. The framework incentivizes third-party provers to run computations and submit cryptographic proofs on-chain through a sophisticated economic model combining Dutch auctions, collateral staking, and slashing mechanisms.

---

## 1. How Are Provers Incentivized?

### Dutch Auction Pricing Model

**Primary File**: `contracts/src/BoundlessMarket.sol:226-227, 271`

Boundless uses a **Dutch auction** mechanism where the price for proof generation increases over time:

```solidity
struct Offer {
    uint256 minPrice;           // Starting price (low)
    uint256 maxPrice;           // Maximum price (high)
    uint64 rampUpStart;         // Auction start time
    uint32 rampUpPeriod;        // Duration of price increase
    uint32 lockTimeout;         // Deadline for locked fulfillment
    uint32 timeout;             // Overall fulfillment deadline
    uint256 lockCollateral;     // Required collateral to lock
}
```

**Pricing Mechanics** (`crates/boundless-market/src/contracts/pricing.rs`):

1. **Ramp-up Period**: Price increases linearly from `minPrice` to `maxPrice`
2. **Lock Period**: Price remains at `maxPrice` until `lockTimeout`
3. **Post-Lock Period**: Price drops to **ZERO** after lock deadline

### Payment Scenarios

**Scenario 1: Locked & Fulfilled Before Lock Deadline** (`BoundlessMarket.sol:505-538`)
- Prover receives: `locked price + collateral returned`
- Exclusive right to payment
- Maximum reward

**Scenario 2: Locked But Fulfilled After Lock Deadline** (`BoundlessMarket.sol:545-608`)
- Prover receives: `collateral only` (price = 0)
- May receive **slashed collateral** from other provers as bonus
- Client refunded the locked price

**Scenario 3: Never Locked, Fulfilled At Any Time** (`BoundlessMarket.sol:613-647`)
- Prover receives: `current auction price`
- No collateral mechanism involved
- First-come-first-served

### Collateral System

**File**: `contracts/src/types/Account.sol:14-29`

```solidity
struct Account {
    uint96 balance;              // ETH balance for payments
    uint96 collateralBalance;    // HP tokens for collateral
    uint64 requestFlagsInitial;  // Lock/fulfill status tracking
}
```

Provers deposit **HP tokens** as collateral (`BoundlessMarket.sol:830-865`):

```solidity
function depositCollateral(uint256 value) external {
    ERC20(COLLATERAL_TOKEN_CONTRACT).safeTransferFrom(msg.sender, address(this), value);
    accounts[msg.sender].collateralBalance += value;
}
```

### Economic Incentives Summary

| Timing | Payment | Collateral | Net Incentive |
|--------|---------|------------|---------------|
| Before Lock Deadline | Full Price | Returned | **Maximum** |
| After Lock Deadline | Zero | Returned + Possible Bonus | **Moderate** (collateral recovery + slashing rewards) |
| Never Lock, Quick Fulfill | Current Auction Price | N/A | **Variable** (depends on timing) |

---

## 2. How Are Results Published to Blockchain?

### Request Submission Flow

**File**: `contracts/src/BoundlessMarket.sol:170-175`

Clients submit proof requests on-chain:

```solidity
function submitRequest(ProofRequest calldata request, bytes calldata clientSignature)
    external payable {
    if (msg.value > 0) {
        deposit();  // Client deposits payment
    }
    emit RequestSubmitted(request.id, request, clientSignature);
}
```

### Request Locking

**File**: `contracts/src/BoundlessMarket.sol:226-277`

Provers lock requests to gain exclusive fulfillment rights:

```solidity
function lockRequest(ProofRequest calldata request, bytes calldata clientSignature)
    external {
    // Verifies client signature
    // Deducts payment from client + collateral from prover

    requestLocks[request.id] = RequestLock({
        prover: msg.sender,
        price: currentPrice,
        lockDeadline: block.timestamp + request.offer.lockTimeout,
        collateral: request.offer.lockCollateral,
        requestDigest: keccak256(abi.encode(request))
    });
}
```

### Proof Submission & Fulfillment

**Primary Prover Component**: `crates/broker/src/submitter.rs`

Provers submit proofs via the `fulfill()` function with two key components:

1. **Application Receipt**: RISC Zero proof of the actual computation
2. **Assessor Receipt**: Proof that the request was correctly fulfilled according to requirements

**File**: `contracts/src/BoundlessMarket.sol:278-342, 358-403`

```solidity
function fulfill(Fulfillment[] calldata fills, AssessorReceipt calldata assessorReceipt)
    public returns (bytes[] memory paymentError) {

    // Step 1: Verify all proofs
    verifyDelivery(fills, assessorReceipt);

    // Step 2: Process payment for each fulfillment
    for (uint256 i = 0; i < fills.length; i++) {
        (paymentError[i], expired) = _fulfillAndPay(fills[i], assessorReceipt.prover);

        // Step 3: Execute callbacks if specified
        if (fills[i].request.callback.target != address(0)) {
            _executeCallback(fills[i], assessorReceipt);
        }
    }

    emit RequestsFulfilled(fills, assessorReceipt.prover);
}
```

### Blockchain State Updates

When a proof is submitted, the following on-chain state changes occur:

1. **Request Status Updated**: Marked as fulfilled in `requestLocks` mapping
2. **Payment Transferred**: From client's account to prover's account
3. **Collateral Returned**: If locked, collateral returned to prover
4. **Callback Executed**: Optional on-chain callback to client contract
5. **Events Emitted**: `RequestsFulfilled` event for indexers

**Indexing**: `crates/indexer/src/bin/market-indexer.rs` monitors these events to maintain off-chain database of:
- Request submissions
- Request locks
- Fulfillments
- Payment amounts
- Prover statistics

---

## 3. What Happens If a Prover Submits Invalid Proofs?

### Two-Layer Defense Against Invalid Proofs

**Layer 1: Cryptographic Verification** (Prevents Invalid Proofs)
- All proofs are verified on-chain via RISC Zero verifiers
- Invalid proofs are **rejected during submission** - they never get accepted
- Transaction reverts if verification fails

**Layer 2: Slashing Mechanism** (Punishes Locked but Abandoned Requests)

### Slashing System

**File**: `contracts/src/BoundlessMarket.sol:739-786`

Slashing occurs when a prover **locks a request but fails to fulfill it before expiration**:

```solidity
function slash(RequestId requestId) external {
    RequestLock storage lock = requestLocks[requestId];

    // Can only slash AFTER request fully expires
    if (block.timestamp <= lock.deadline()) {
        revert RequestIsNotExpired();
    }

    // Mark as slashed
    requestLocks[requestId].setSlashed();

    // Calculate burn vs transfer amounts
    uint256 burnValue = lock.collateral * SLASHING_BURN_BPS / 10000;
    uint256 transferValue = lock.collateral - burnValue;

    // SLASHING_BURN_BPS = 5000 (50% burned, 50% transferred)

    // Determine collateral recipient
    address collateralRecipient;

    if (lock.isProverPaidAfterLockDeadline()) {
        // Another prover fulfilled after lock deadline
        // Reward them with slashed collateral
        collateralRecipient = /* prover who fulfilled */;
    } else {
        // Request expired unfulfilled
        // Collateral goes to market treasury
        collateralRecipient = address(this);

        // Client gets refunded the locked price
        accounts[client].balance += lock.price;
    }

    // Transfer 50% of collateral
    accounts[collateralRecipient].collateralBalance += transferValue;

    // Burn 50% of collateral permanently
    ERC20(COLLATERAL_TOKEN_CONTRACT).transfer(address(0xdEaD), burnValue);

    emit ProverSlashed(requestId, burnValue, transferValue, collateralRecipient);
}
```

### Slashing Constants

**File**: `contracts/src/BoundlessMarket.sol:92-97`

```solidity
/// Slashing burn rate: 50% burned, 50% distributed
uint256 public constant SLASHING_BURN_BPS = 5000;
```

### Slashing Scenarios

| Scenario | Locked Prover | Fulfilling Prover | Client | Protocol |
|----------|--------------|-------------------|--------|----------|
| **Locked, Fulfilled Before Deadline** | Gets price + collateral | N/A | Pays price | No slashing |
| **Locked, Fulfilled After Deadline by Another** | **50% collateral burned**, 50% to other prover | Gets 50% slashed collateral | Refunded locked price | 50% burn |
| **Locked, Never Fulfilled** | **50% collateral burned**, 50% to treasury | N/A | Refunded locked price | 50% burn + 50% treasury |
| **Never Locked, Fulfilled** | N/A | Gets auction price | Pays price | No slashing |

### Important: Invalid Proofs Cannot Be Submitted

**File**: `contracts/src/BoundlessMarket.sol:278-342`

The `verifyDelivery()` function ensures cryptographic validity:

```solidity
function verifyDelivery(Fulfillment[] calldata fills, AssessorReceipt calldata assessorReceipt)
    public view {

    // Verify each application proof
    for (uint256 i = 0; i < fills.length; i++) {
        APPLICATION_VERIFIER.verifyIntegrity(
            Receipt(fills[i].seal, fills[i].claimDigest)
        );
    }

    // Verify assessor proof
    VERIFIER.verify(assessorReceipt.seal, ASSESSOR_ID, assessorJournalDigest);
}
```

If verification fails, the transaction **reverts** - the invalid proof is never recorded on-chain.

**Slashing is NOT for invalid proofs** - it's for **locked but abandoned requests** (prover locked but didn't fulfill).

---

## 4. How Does the Verification Process Work On-Chain?

### Two-Layer Verification Architecture

Boundless uses a **dual verification system**:

1. **Application Verification**: Proves the computation itself was executed correctly
2. **Assessor Verification**: Proves the request requirements were satisfied

**File**: `contracts/src/BoundlessMarket.sol:69-123`

```solidity
/// RISC Zero verifier router for assessor seals
IRiscZeroVerifier public immutable VERIFIER;
bytes32 public immutable ASSESSOR_ID;

/// Application verifier for user computation proofs
IRiscZeroVerifier public immutable APPLICATION_VERIFIER;
```

### Verification Flow

**Step 1: Verify Application Proofs**

**File**: `contracts/src/BoundlessMarket.sol:301-317`

Each fulfillment contains:
- `seal`: ZK proof (RISC Zero receipt)
- `claimDigest`: Hash of the computation output
- `fulfillmentDataDigest`: Hash of the fulfillment data

```solidity
for (uint256 i = 0; i < fills.length; i++) {
    Fulfillment calldata fill = fills[i];

    // Verify proof integrity via RISC Zero verifier
    if (!hasSelector[i]) {
        // Default: strict gas limit ensures cheap verification
        APPLICATION_VERIFIER.verifyIntegrity{gas: DEFAULT_MAX_GAS_FOR_VERIFY}(
            Receipt(fill.seal, fill.claimDigest)
        );
    } else {
        // Custom selector: allow more gas for complex proofs
        APPLICATION_VERIFIER.verifyIntegrity(
            Receipt(fill.seal, fill.claimDigest)
        );
    }
}
```

**Gas Limits** (`BoundlessMarket.sol:80-90`):
```solidity
/// Max gas for default selector verification (ensures cheap proofs)
uint256 public constant DEFAULT_MAX_GAS_FOR_VERIFY = 50000;

/// Max gas for ERC1271 smart contract signature checks
uint256 public constant ERC1271_MAX_GAS_FOR_CHECK = 100000;
```

**Step 2: Build Merkle Tree**

**File**: `contracts/src/BoundlessMarket.sol:320` using `libraries/MerkleProofish.sol`

All fulfillment commitments are organized into a Merkle tree:

```solidity
bytes32 batchRoot = MerkleProofish.processTree(leaves);
```

This allows the assessor to prove properties of the entire batch efficiently.

**Step 3: Verify Assessor Proof**

**File**: `contracts/src/BoundlessMarket.sol:323-341`

The assessor proves:
1. All client signatures are valid
2. All request requirements are satisfied
3. Callbacks and selectors are correctly extracted

```solidity
bytes32 assessorJournalDigest = sha256(
    abi.encode(
        AssessorJournal({
            root: batchRoot,              // Merkle root of all fulfillments
            callbacks: assessorReceipt.callbacks,
            selectors: assessorReceipt.selectors,
            prover: assessorReceipt.prover
        })
    )
);

// Verify assessor proof
VERIFIER.verify(assessorReceipt.seal, ASSESSOR_ID, assessorJournalDigest);
```

### Assessor Guest Program

**File**: `crates/guest/assessor/assessor-guest/src/main.rs`

The assessor runs inside the RISC Zero zkVM and performs:

```rust
// For each fulfillment:
for fill in fulfillments {
    // 1. Verify ECDSA signature on request
    let request_digest = fill.verify_signature(&eip_domain_separator)?;

    // 2. Evaluate fulfillment requirements (predicates)
    let claim_digest = fill.evaluate_requirements()?;

    // 3. Extract callbacks for on-chain execution
    if let Some(callback) = fill.request.callback {
        callbacks.push(callback);
    }

    // 4. Build Merkle tree leaf
    leaves.push(commitment.eip712_hash_struct());
}

// Output journal with Merkle root and metadata
env::commit(&AssessorJournal {
    root: merkle_root(&leaves),
    callbacks,
    selectors,
    prover,
});
```

**File**: `crates/assessor/src/lib.rs:88-117`

Signature verification logic:

```rust
impl Fulfillment {
    pub fn verify_signature(&self, domain: &Eip712Domain) -> Result<[u8; 32], Error> {
        let hash = self.request.eip712_signing_hash(domain);
        let signature = Signature::try_from(self.signature.as_slice())?;

        // Ensure canonical signature (prevent malleability)
        if signature.normalize_s().is_some() {
            return Err(Error::SignatureNonCanonicalError);
        }

        // Recover signer address
        let recovered = signature.recover_address_from_prehash(&hash)?;
        let client_addr = self.request.client_address();

        if recovered != client_addr {
            return Err(Error::SignatureVerificationError);
        }

        Ok(hash.into())
    }

    pub fn evaluate_requirements(&self) -> Result<Digest, Error> {
        let predicate = Predicate::try_from(
            self.request.requirements.predicate.clone()
        )?;

        predicate.eval(&self.fulfillment_data)
            .ok_or(Error::RequirementsEvaluationError)
    }
}
```

### Verification Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     BoundlessMarket.sol                     │
│                                                             │
│  fulfill(Fulfillment[], AssessorReceipt)                   │
│    │                                                        │
│    ├─► verifyDelivery()                                    │
│    │     │                                                  │
│    │     ├─► For each fill:                                │
│    │     │     APPLICATION_VERIFIER.verifyIntegrity()      │
│    │     │       └─► RiscZeroVerifierRouter                │
│    │     │             └─► Blake3Groth16Verifier           │
│    │     │                   └─► Verifies seal ✓           │
│    │     │                                                  │
│    │     └─► Build Merkle root                             │
│    │           └─► VERIFIER.verify(assessor seal)          │
│    │                 └─► RiscZeroVerifierRouter            │
│    │                       └─► Verifies assessor proof ✓   │
│    │                                                        │
│    └─► _fulfillAndPay()                                    │
│          └─► Transfer payment to prover                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Verifier Router System

**File**: `contracts/src/verifier/RiscZeroVerifierRouter.sol`

Routes verification to appropriate verifier based on seal type:

```solidity
contract RiscZeroVerifierRouter is IRiscZeroVerifier {
    mapping(bytes4 => IRiscZeroVerifier) public verifiers;

    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest)
        external view virtual {
        getVerifier(seal).verify(seal, imageId, journalDigest);
    }

    function getVerifier(bytes calldata seal) internal view returns (IRiscZeroVerifier) {
        bytes4 selector = bytes4(seal[0:4]);
        IRiscZeroVerifier verifier = verifiers[selector];
        if (address(verifier) == address(0)) {
            revert MissingVerifierSelector(selector);
        }
        return verifier;
    }
}
```

Supports multiple proof systems:
- **Groth16**: Fast verification, ~300k gas
- **STARK**: Larger proofs, different security assumptions
- **Blake3-Groth16**: Optimized for specific applications

### Selector Constraints

**File**: `contracts/src/BoundlessMarket.sol:289-299`

Ensures proofs use expected verification methods:

```solidity
uint256 selectorsLength = assessorReceipt.selectors.length;
for (uint256 i = 0; i < selectorsLength; i++) {
    bytes4 expected = assessorReceipt.selectors[i].value;
    bytes4 received = bytes4(fills[assessorReceipt.selectors[i].index].seal[0:4]);

    hasSelector[assessorReceipt.selectors[i].index] = true;

    if (expected != received) {
        revert SelectorMismatch(expected, received);
    }
}
```

This prevents provers from using cheaper (less secure) verification methods than required.

---

## Key Files Reference

| Component | Primary Files | Purpose |
|-----------|--------------|---------|
| **Core Market Contract** | `contracts/src/BoundlessMarket.sol` | Request submission, locking, fulfillment, payment, slashing |
| **Account Management** | `contracts/src/types/Account.sol` | Balance tracking, collateral management |
| **Request Types** | `contracts/src/types/ProofRequest.sol`<br>`contracts/src/types/Offer.sol`<br>`contracts/src/types/RequestLock.sol` | Data structures for requests, offers, locks |
| **Verification** | `contracts/src/verifier/RiscZeroVerifierRouter.sol`<br>`contracts/src/verifier/VerifierLayeredRouter.sol` | Proof verification routing |
| **Assessor Logic** | `crates/assessor/src/lib.rs`<br>`crates/guest/assessor/assessor-guest/src/main.rs` | Signature verification, requirement evaluation |
| **Prover Implementation** | `crates/broker/src/submitter.rs` | Proof submission logic |
| **Pricing Logic** | `crates/boundless-market/src/contracts/pricing.rs` | Dutch auction calculations |
| **Indexer** | `crates/indexer/src/bin/market-indexer.rs` | Event monitoring and database population |

---

## Economic Model Summary

### Incentive Structure

1. **Competitive Pricing**: Dutch auction balances urgency vs cost
2. **Collateral Staking**: HP tokens ensure prover commitment
3. **Timing Incentives**:
   - Fulfill before lock deadline → full payment
   - Fulfill after lock deadline → collateral only
   - Lock but abandon → 50% slashed, 50% redistributed
4. **Slashing Rewards**: Late fulfillers can earn slashed collateral
5. **Zero Late Payment**: Price = 0 after lock deadline encourages early fulfillment

### Security Properties

1. **Cryptographic Soundness**: All proofs verified via RISC Zero
2. **Economic Security**: Collateral creates skin-in-the-game
3. **Liveness Guarantee**: Slashing punishes abandoned requests
4. **Fair Pricing**: Dutch auction discovers market price
5. **Anti-Spam**: Collateral requirements prevent frivolous locks

### Trust Assumptions

- **Prover Trust**: Minimized via ZK proofs (computational integrity guaranteed)
- **Client Trust**: Signatures ensure request authenticity
- **Verifier Trust**: RISC Zero provides cryptographic security
- **Economic Rationality**: Provers act to maximize profit (locked provers fulfill to avoid slashing)

---

## Interview Preparation Tips

### Key Concepts to Emphasize

1. **Two-Layer Verification**:
   - Application proofs verify computation
   - Assessor proofs verify request satisfaction
   - Separation of concerns improves modularity

2. **Economic Incentives**:
   - Dutch auction aligns prover/client interests
   - Collateral ensures commitment
   - Slashing punishes abandonment, rewards completion

3. **Invalid Proofs**:
   - Cannot be submitted (cryptographic verification)
   - Slashing is for locked-but-abandoned requests
   - Not a penalty for incorrect computation

4. **Blockchain Efficiency**:
   - Batch verification reduces gas costs
   - Merkle trees enable efficient multi-proof verification
   - Verifier router supports multiple proof systems

### Potential Interview Questions

**Q: How does Boundless prevent provers from submitting fake proofs?**
A: Two-layer cryptographic verification - all proofs verified on-chain via RISC Zero verifiers. Invalid proofs cause transaction revert.

**Q: What happens if a prover locks a request but doesn't fulfill it?**
A: They get slashed - 50% of collateral burned, 50% goes to either the prover who eventually fulfills it or the market treasury.

**Q: Why use a Dutch auction instead of fixed pricing?**
A: Price discovery - urgent requests pay more, routine requests pay less. Balances client costs with prover profitability.

**Q: How does the assessor improve security?**
A: Verifies signatures and requirements inside zkVM, preventing provers from bypassing client requirements or forging requests.

**Q: What prevents provers from front-running each other?**
A: Lock mechanism - first locker gets exclusive rights during lock period. After lock deadline, price = 0 (only collateral recovery incentive).
