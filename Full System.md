# The Full System: Distributed Security Detection for World ID

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    The Full System                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. zkML (proto-neural-zkp/)                               │
│     → Neural networks for fraud/Sybil detection            │
│     → Runs in zkVM (risc0/, boundless/)                    │
│     → Generates cryptographic proofs                       │
│                                                             │
│  2. zkVM (risc0/, boundless/)                              │
│     → Executes ML inference provably                       │
│     → Keeps data private                                   │
│     → Outputs: detection results + proof                   │
│                                                             │
│  3. Blockchain (boundless/core-contracts/)                 │
│     → Smart contract verifies proofs                       │
│     → Pays bounties to third parties                       │
│     → Publishes transparent audit trail                    │
│     → Coordinates distributed detection                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. zkML Layer (`proto-neural-zkp/`) - **CRITICAL**

**Purpose**: The intelligence of the detection system

**What it does**:
- Implements neural networks for sophisticated fraud detection
- Detects Sybil attacks (coordinated fake accounts)
- Identifies anomalous behavior patterns
- Recognizes bot activity and fraud signals

**Why zkML specifically**:
- Traditional ML requires sending sensitive data to whoever runs the model
- zkML allows running ML inference **without revealing the input data**
- Proves the model actually ran (can't fake results)
- Only outputs detection results, not raw biometric/behavioral data

**Example**:
```rust
// Guest code running in zkVM
fn detect_fraud_zkml() {
    let model = load_neural_network();      // Pre-trained fraud detector
    let user_data = load_dataset();         // Private biometric/behavioral data

    let mut suspicious = vec![];
    for user in user_data {
        let fraud_score = model.infer(user.features);
        if fraud_score > 0.95 {
            suspicious.push(user.id);       // Only IDs published, not raw data
        }
    }

    env::commit(&suspicious);               // Public output of the proof
}
```

### 2. zkVM Layer (`risc0/`, `boundless/`)

**Purpose**: Verifiable computation engine

**What it does**:
- Executes the zkML detection code in a provable environment
- Generates cryptographic proofs of correct execution
- Ensures privacy (zero-knowledge property)
- Produces verifiable outputs

**The Magic**:
```
Input: Detection Code + Private Dataset
         ↓
    [zkVM Execution]
         ↓
Output: Results + Proof
```

The proof cryptographically guarantees:
- ✅ This exact code ran (verified by code hash)
- ✅ On this dataset (verified by data commitment)
- ✅ Produced these results (bound to the proof)
- ✅ **Without revealing the private data**

**Why it matters**:
- Third parties can't cheat (proof prevents fake results)
- Third parties can't steal data (zero-knowledge property)
- Results are verifiable on-chain (anyone can check the proof)

### 3. Blockchain Layer (`boundless/core-contracts/`)

**Purpose**: Coordination, incentives, and transparency

**What it does**:
- **Smart Contract as Bounty System**: Pays third parties for running detection
- **Proof Verification**: Validates zkVM proofs on-chain
- **Public Audit Trail**: Immutable record of all security detections
- **Decentralization**: Multiple parties can participate, no single point of trust

**Smart Contract Flow**:
```solidity
contract DetectionBounty {
    struct AuditRecord {
        bytes32 detectionCodeHash;    // Which algorithm ran
        uint256 timestamp;             // When it ran
        bytes32 datasetHash;           // Which dataset (hashed)
        bytes publicOutputs;           // Detection results
        bytes zkProof;                 // Cryptographic proof
        address submitter;             // Who ran it
    }

    AuditRecord[] public auditTrail;  // Public transparency

    function submitDetection(bytes calldata proof, bytes calldata outputs) {
        // Verify the zkVM proof
        require(verifyProof(proof, outputs), "Invalid proof");

        // Record to public audit trail
        auditTrail.push(AuditRecord({...}));

        // Pay bounty to submitter
        payable(msg.sender).transfer(BOUNTY_AMOUNT);
    }
}
```

**Why blockchain**:
- **Transparency**: Anyone can verify World ID is running security checks
- **Decentralization**: Don't rely on single entity to run all detection
- **Immutability**: Audit trail can't be tampered with
- **Automation**: Smart contracts handle payments/verification trustlessly

## Complete Flow Example

### Scenario: Detecting Sybil Attacks

```
1. World ID prepares detection job:
   ├─ Trained neural network (Sybil detector)
   ├─ Encrypted dataset (user behavior patterns)
   └─ zkVM guest code (runs inference)

2. Smart contract published on Worldchain:
   ├─ Bounty: 100 USDC for valid detection
   ├─ Code hash: 0xabc123... (exact algorithm to run)
   └─ Dataset hash: 0xdef456... (which data to analyze)

3. Third Party downloads and runs:
   ├─ Executes detection in RiscZero zkVM
   ├─ Neural network analyzes user patterns
   ├─ Finds 47 suspicious account clusters
   └─ Generates proof of correct execution

4. Third Party submits to smart contract:
   ├─ Proof: [cryptographic proof]
   ├─ Results: "47 suspicious accounts: [IDs]"
   └─ Smart contract verifies proof

5. Smart contract actions:
   ├─ ✅ Proof valid → Pay 100 USDC bounty
   ├─ 📝 Publish to audit trail on-chain
   └─ 🚨 World ID receives alert about suspicious accounts

6. Public transparency:
   ├─ Anyone can see: "Sybil detection ran at 2026-02-12"
   ├─ Anyone can verify: The proof is valid
   └─ Privacy maintained: Raw biometric data never exposed
```

## Why This System Solves the Problem

### The Challenge
World ID processes millions of identity verifications daily and needs:
- Sophisticated fraud detection (ML required)
- Privacy protection (can't expose biometric data)
- Trustless execution (third parties might cheat)
- Transparency (users need to trust the system)
- Scalability (billions of future users)

### How Each Component Helps

| Component | Problem It Solves |
|-----------|------------------|
| **zkML** | Enables sophisticated ML-based detection while preserving privacy |
| **zkVM** | Proves detection ran correctly without revealing sensitive data |
| **Blockchain** | Provides transparency, coordination, and trustless incentives |

### The Privacy + Verifiability Paradox

**Traditional systems force a choice**:
- Trust third parties → Privacy risk (they see raw data)
- Don't trust third parties → Can't scale (must run everything yourself)

**This system enables both**:
- ✅ Third parties run detection (scalability)
- ✅ Data stays private (zero-knowledge proofs)
- ✅ Results are verifiable (cryptographic proofs)
- ✅ Public transparency (blockchain audit trail)

## Repository Mapping

| Repository | Role | Priority |
|------------|------|----------|
| `proto-neural-zkp/` | zkML detection algorithms | **CRITICAL** |
| `risc0/` | zkVM framework for proof generation | HIGH |
| `boundless/` | zkVM framework + smart contracts | HIGH |
| `boundless/core-contracts/` | On-chain verification & incentives | HIGH |
| `zkvm-compare/`, `zkvm-perf/` | Performance benchmarking | MEDIUM |

## Key Innovations

1. **Verifiable Crowdsourced Security**: Anyone can contribute compute power to run detection, with cryptographic guarantees of correctness

2. **Privacy-Preserving ML at Scale**: Run neural networks on sensitive data without exposing the data

3. **Transparent Security**: All detection activities published on-chain for public audit while maintaining user privacy

4. **Decentralized Trust**: No single point of failure or trust - system secured by cryptography, not corporate promises