# RISC Zero zkVM - Tools for Humanity Interview Guide

**Optimized for**: Detection & Response Team | Distributed Analytics System Project

---

## Table of Contents
1. [Overview & Value for TFH](#overview--value-for-tfh)
2. [Guest/Host Architecture](#guesthost-architecture)
3. [Receipts & Journals: Transparency vs Privacy](#receipts--journals-transparency-vs-privacy)
4. [RISC-V + zk-STARKs: How It Works](#risc-v--zk-starks-how-it-works)
5. [Compilation Pipeline](#compilation-pipeline)
6. [Proof Generation vs Verification: Cost Model](#proof-generation-vs-verification-cost-model)
7. [Bonsai: Distributed Proving (YOUR PROJECT!)](#bonsai-distributed-proving-your-project)
8. [Blockchain Integration](#blockchain-integration)
9. [Security Model for Detection Systems](#security-model-for-detection-systems)
10. [Detection Use Case Example](#detection-use-case-example)
11. [Interview Quick Reference](#interview-quick-reference)

---

## Overview & Value for TFH

### What is RISC Zero?
RISC Zero is a **zero-knowledge verifiable general computing platform** that:
- Runs arbitrary Rust/C/C++ code inside a zkVM
- Generates cryptographic proofs (zk-STARKs) of correct execution
- Allows verification in milliseconds without re-execution
- Enables **verifiable computation at scale**

### The TFH Connection: Distributed Analytics System

**The job description states:**
> "Execute a smart contract that incentivizes third parties to run specific code against specific datasets, publish outputs, and prove calculations were performed correctly."

**This is exactly what RISC Zero + Bonsai enables:**

```
┌─────────────────────────────────────────────────────────┐
│          TFH Distributed Analytics System               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Smart Contract (on Worldchain)                        │
│       ↓                                                 │
│  Incentivizes Third Parties                            │
│       ↓                                                 │
│  Third Party runs detection code (Guest program)       │
│       ↓                                                 │
│  RISC Zero zkVM generates proof                        │
│       ↓                                                 │
│  Proof published on-chain (Groth16, ~128 bytes)       │
│       ↓                                                 │
│  Smart contract verifies & rewards                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Core Value Propositions for Detection Engineering

1. **Verifiable Detection**: Run fraud detection algorithms off-chain, prove results on-chain
2. **Privacy-Preserving**: Inputs (user data, PII) stay private; only outputs (alerts, statistics) are public
3. **Decentralized Trust**: Third parties can't cheat - proof guarantees code executed correctly
4. **Transparency**: Audit events published to blockchain without revealing sensitive data
5. **Scalability**: Bonsai enables millions of verifications without centralized infrastructure

**Reference**: Job description lines 28-37

---

## Guest/Host Architecture

### The Fundamental Model

```
┌──────────────────────┐         ┌──────────────────────┐
│   Host (Untrusted)   │         │   Guest (Proven)     │
│                      │         │                      │
│  - Detection dataset │────────▶│  - Reads dataset     │
│  - Loads ELF binary  │         │  - Runs detection    │
│  - Runs prover       │         │  - Writes alerts     │
│  - Verifies receipt  │◀────────│  - Returns proof     │
│                      │ Receipt │                      │
└──────────────────────┘         └──────────────────────┘
```

### Guest Program (Proven Code)

**Characteristics**:
- Compiled to RISC-V ELF binary
- `#![no_std]` - minimal embedded environment
- Entry point: `risc0_zkvm::guest::entry!(main)`
- Reads inputs: `env::read()`
- Commits outputs: `env::commit()` → public journal

**Detection Example**:
```rust
#![no_main]
#![no_std]

use risc0_zkvm::guest::env;

risc0_zkvm::guest::entry!(main);

fn main() {
    // Read private transaction data
    let transactions: Vec<Transaction> = env::read();

    // Run fraud detection algorithm
    let (fraud_count, suspicious_ids) = detect_fraud(&transactions);

    // Commit PUBLIC results (no PII revealed)
    env::commit(&fraud_count);
    env::commit(&suspicious_ids);  // Only IDs, not full data
}
```

### Host Program (Untrusted Orchestrator)

**Characteristics**:
- Runs on normal hardware (could be third-party server)
- Loads guest ELF + provides dataset via `ExecutorEnv`
- Invokes prover (local or Bonsai)
- Gets Receipt with proof + journal

**TFH Use Case**:
```rust
use risc0_zkvm::{ExecutorEnv, default_prover};
use detection_methods::{FRAUD_DETECTOR_ELF, FRAUD_DETECTOR_ID};

pub fn run_detection(transactions: Vec<Transaction>) -> Receipt {
    // Build environment with private data
    let env = ExecutorEnv::builder()
        .write(&transactions).unwrap()
        .build().unwrap();

    // Generate proof (or send to Bonsai)
    let prover = default_prover();
    let receipt = prover.prove(env, FRAUD_DETECTOR_ELF).unwrap().receipt;

    // Receipt can now be posted on-chain for verification & reward
    receipt
}
```

### Critical Security Property

**The host CANNOT cheat**. Any tampering (wrong code, modified inputs, fake outputs) invalidates the proof. The cryptographic seal binds:
- **Image ID**: SHA-256 hash of detection code
- **Inputs**: Implicitly part of execution
- **Outputs**: Journal digest included in proof

This guarantees: "If the proof verifies, the specific detection code ran correctly on the claimed inputs."

---

## Receipts & Journals: Transparency vs Privacy

### Receipt Structure

```rust
pub struct Receipt {
    pub inner: InnerReceipt,     // Cryptographic proof (seal)
    pub journal: Journal,         // Public outputs
    pub metadata: ReceiptMetadata // NOT cryptographically bound!
}
```

### The Four Receipt Types

| Type | Size | Verification | Use Case |
|------|------|--------------|----------|
| **Composite** | N × 200 KB | N × 5 ms | Large programs, parallel proving |
| **Succinct** | ~100 KB | 1-2 ms | Standard off-chain verification |
| **Groth16** | **~128 bytes** | <1 ms | **Blockchain/smart contract** |
| **Fake** | ~100 bytes | 0 ms | Dev mode only (NO SECURITY) |

**For TFH**: Groth16 Receipt is ideal - tiny proof size for on-chain verification on Worldchain.

### Journal: The Transparency Layer

**What goes in the journal?**
- Detection results (fraud count, alert flags)
- Aggregated statistics (no PII)
- Audit event summaries
- Public commitments to private data

**What stays private?**
- Individual user data (PII, iris codes, etc.)
- Transaction details
- Intermediate computations
- Secret detection rules (if desired)

### Privacy vs Transparency Example

```
┌─────────────────────────────────────────────────────┐
│  Guest: Fraud Detection on 1M Transactions         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  let txs: Vec<Transaction> = env::read();          │
│    ↑ PRIVATE: Never leaves zkVM                    │
│                                                     │
│  let fraud_score = detect_fraud(&txs);             │
│    ↑ PRIVATE: Computation hidden                   │
│                                                     │
│  env::commit(&fraud_score);                        │
│  env::commit(&txs.len());                          │
│    ↑ PUBLIC: In journal, visible on-chain          │
│                                                     │
└─────────────────────────────────────────────────────┘
           │
           ▼
    Receipt posted to Worldchain
           │
           ▼
    Smart contract reads journal:
      - fraud_score: 127
      - txs_processed: 1,000,000
      - Verifies proof ✓
      - Pays third party for work
```

**This solves TFH's challenge**: Publish audit events (transparency) without revealing user data (privacy).

### Verification API

```rust
// Verify receipt proves expected detection code ran
receipt.verify(FRAUD_DETECTOR_ID).expect("Proof invalid");

// Extract public outputs
let fraud_count: u32 = receipt.journal.decode()?;
let tx_count: u64 = receipt.journal.decode()?;

// Post to smart contract for reward
worldchain.submit_proof(receipt, fraud_count, tx_count)?;
```

---

## RISC-V + zk-STARKs: How It Works

### High-Level Flow

```
RISC-V Detection Code
      ↓
┌──────────────────────────────┐
│  1. Execution Trace          │  ← Record every CPU cycle
│     (Matrix: rows = cycles)  │    as detection runs
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  2. Arithmetization          │  ← Convert trace to
│     (Finite field math)      │    polynomials
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  3. Constraint Checking      │  ← Prove RISC-V semantics
│     (RISC-V circuit)         │    were followed
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  4. zk-STARK Proof           │  ← FRI protocol generates
│     (FRI Protocol)           │    compact proof
└──────────────────────────────┘
      ↓
    Seal (200KB STARK)
      ↓
    Optional: Groth16 compression (128 bytes)
```

### Why This Matters for Detection Engineering

1. **Execution Trace** = audit log of every instruction
   - Every memory access, register update, branch decision recorded
   - ~1 million cycles = ~1 MB detection workload

2. **Arithmetization** = convert audit log to math problem
   - Baby Bear finite field: `p = 2^31 - 2^27 + 1`
   - "Code ran correctly" becomes "polynomial equation holds"

3. **zk-STARK Proof** = prove equation without showing work
   - Prover: O(n log n) - expensive, GPU-accelerated
   - Verifier: O(log n) - cheap, runs on-chain
   - **Zero-Knowledge**: Inputs never revealed, only proof

4. **Security**: 98 bits conjectured security
   - Cryptographically infeasible to forge proofs
   - Transparent (no trusted setup)

**Key Insight**: Any Rust detection code compiles to RISC-V, so you get automatic zkVM support without writing custom circuits.

---

## Compilation Pipeline

### End-to-End: Detection Code → Verifiable Proof

```
1. Write Detection Logic (Rust)
   ├── methods/guest/src/main.rs
   └── Standard Rust: no special ZK knowledge needed!
              ↓
2. Build Script Compiles to RISC-V
   ├── Target: riscv32im-risc0-zkvm-elf
   └── Output: detection.elf (RISC-V binary)
              ↓
3. Compute Image ID (Trust Anchor)
   ├── SHA-256(detection.elf) → [u32; 8]
   └── This ID is what verifiers check!
              ↓
4. Generate Method Constants
   ├── DETECTION_ELF: &[u8] = include_bytes!(...)
   └── DETECTION_ID: [u32; 8] = [...]
              ↓
5. Host Uses Constants
   ├── Load DETECTION_ELF into zkVM
   ├── Run prover → Receipt
   └── Verify: receipt.verify(DETECTION_ID)?
```

### Image ID: The Detection Code Fingerprint

**What is it?**
- Cryptographic hash (SHA-256) of the detection ELF binary
- Uniquely identifies which detection algorithm ran
- Represented as `[u32; 8]` (256 bits)

**Why it matters for TFH?**
- Smart contracts can specify: "Only reward proofs for Image ID 0x12345678..."
- Guarantees third parties ran the **exact approved detection code**
- Different code = different Image ID = verification fails
- Enables **code governance**: update detection algorithm → new Image ID → new smart contract version

**Deterministic Builds**:
- Use Docker to ensure reproducible builds
- Critical for multi-party scenarios: everyone computes same Image ID from source

---

## Proof Generation vs Verification: Cost Model

### Cost Asymmetry

| Metric | Proof Generation | Verification |
|--------|------------------|--------------|
| **Time Complexity** | O(n log n) | O(log n) segment, **O(1) succinct** |
| **Time (1M cycles)** | Minutes (GPU) to hours (CPU) | **Milliseconds** |
| **Memory** | 8-16 GB RAM | < 1 MB |
| **Hardware** | GPU: 10-100x speedup | Any device (mobile, smart contract) |
| **Cost** | **Expensive** (delegate to Bonsai) | **Cheap** (anyone can verify) |

### Why This Model Fits TFH's Architecture

**Problem**: Detection on millions of identity/financial transactions is compute-intensive.

**Traditional Approach**: Centralized detection service (single point of failure, trust issues).

**zkVM Approach**:
```
┌───────────────────────────────────────────────────┐
│  Third Party Runs Detection (Expensive Proving)  │
│  • Has GPU/Bonsai access                          │
│  • Incentivized by smart contract rewards         │
│  • Proves work was done correctly                 │
└───────────────────────────────────────────────────┘
              ↓ Submits Receipt (~128 bytes)
┌───────────────────────────────────────────────────┐
│  Smart Contract Verifies (Cheap Verification)    │
│  • Runs on Worldchain (milliseconds)              │
│  • Checks proof + Image ID                        │
│  • Pays reward if valid                           │
└───────────────────────────────────────────────────┘
              ↓
   World ID system gets detection results
   WITHOUT running centralized infrastructure!
```

### Practical Proving Times

| Program Size | GPU Proving | CPU Proving | Memory |
|--------------|-------------|-------------|--------|
| 100K cycles | ~10 seconds | ~2 minutes | 2 GB |
| 1M cycles | ~1 minute | ~20 minutes | 8 GB |
| 10M cycles | ~10 minutes | ~3 hours | 16 GB |
| 100M cycles | ~1.5 hours | ~30 hours | 32 GB |

**TFH Implication**: Detection workloads need GPU acceleration or Bonsai (next section).

---

## Bonsai: Distributed Proving (YOUR PROJECT!)

### What is Bonsai?

**Bonsai is RISC Zero's remote proving service** - essentially a **distributed compute marketplace** for zkVM proofs.

### Architecture Match with TFH Project

**Job Description**:
> "Distributed analytics system where third parties run specific code against specific datasets, publish outputs, and prove calculations were performed correctly."

**Bonsai Architecture**:
```
┌─────────────────┐          ┌─────────────────┐          ┌──────────────────┐
│  Third Party    │          │  Bonsai Cloud   │          │  Smart Contract  │
│  (Detection)    │          │  (GPU Clusters) │          │  (Worldchain)    │
│                 │          │                 │          │                  │
│  1. Upload ELF  │────────▶ │                 │          │                  │
│  2. Upload Data │────────▶ │  Proving...     │          │                  │
│  3. Create Job  │────────▶ │                 │          │                  │
│                 │          │                 │          │                  │
│  4. Get Receipt │◀────────│  Receipt Ready  │          │                  │
│                 │          │                 │          │                  │
│  5. Submit      │──────────────────────────────────────▶│  Verify & Pay   │
│     On-chain    │          │                 │          │                  │
└─────────────────┘          └─────────────────┘          └──────────────────┘
```

### Bonsai Code Flow

```rust
use bonsai_sdk::blocking::Client;

// 1. Connect to Bonsai (third party's code)
let client = Client::from_env(risc0_zkvm::VERSION)?;

// 2. Upload detection code (one-time per version)
let image_id = hex::encode(compute_image_id(FRAUD_DETECTOR_ELF)?);
client.upload_img(&image_id, FRAUD_DETECTOR_ELF.to_vec())?;

// 3. Upload transaction dataset for this run
let input_data = to_vec(&transactions).unwrap();
let input_id = client.upload_input(input_data)?;

// 4. Create proving session (Bonsai allocates GPU)
let session = client.create_session(
    image_id,
    input_id,
    vec![],      // No assumptions
    false        // Generate proof, not just execute
)?;

// 5. Poll for completion (async in production)
loop {
    let res = session.status(&client)?;
    match res.status.as_str() {
        "RUNNING" => { sleep(15); continue; }
        "SUCCEEDED" => {
            // 6. Download receipt
            let receipt: Receipt = client.download(&res.receipt_url?)?;

            // 7. Post to smart contract for reward
            worldchain.submit_detection_proof(receipt)?;
            break;
        }
        _ => panic!("Job failed")
    }
}
```

### STARK → SNARK Conversion (On-Chain Optimization)

**Problem**: STARK receipts are ~100KB (expensive on-chain storage).

**Solution**: Groth16 compression to ~128 bytes.

```rust
// After getting STARK receipt, compress to Groth16
let snark_session = client.create_snark(session.uuid)?;

loop {
    let res = snark_session.status(&client)?;
    if res.status == "SUCCEEDED" {
        let groth16_receipt: Receipt = client.download_snark(&res.output?)?;

        // Now only 128 bytes! Perfect for Worldchain
        assert!(groth16_receipt.inner.is_groth16());

        // Post to blockchain
        worldchain.verify_and_reward(groth16_receipt)?;
        break;
    }
    sleep(15);
}
```

### Bonsai vs Local Proving: TFH Decision Matrix

| Aspect | Local Proving | Bonsai | Recommendation |
|--------|---------------|--------|----------------|
| **Hardware** | GPU required | Not required | **Bonsai** - lower barrier for third parties |
| **Setup** | CUDA/Metal drivers | API key only | **Bonsai** - easier onboarding |
| **Cost** | Hardware investment | Pay-per-proof | **Bonsai** - pay-as-you-go matches incentive model |
| **Scalability** | Limited | Unlimited | **Bonsai** - scales to millions of proofs |
| **Privacy** | Full | ELF + inputs sent to Bonsai | **Depends** - if detection data is public anyway, Bonsai OK |
| **Latency** | Lower | Network + queue | **Local** if real-time detection critical |

**TFH Likely Model**: Hybrid
- **Bonsai** for batch analytics (millions of transactions, non-urgent)
- **Local** for real-time fraud detection (Orb verifications, high-value transactions)

---

## Blockchain Integration

### Smart Contract Verification Flow

```solidity
// Worldchain smart contract (simplified)
contract DetectionIncentive {
    // Groth16 verifier address (RISC Zero deployment)
    IRiscZeroVerifier public verifier;

    // Approved detection code
    bytes32 public approvedImageId;

    // Reward per proof
    uint256 public rewardAmount;

    function submitDetectionProof(
        bytes calldata seal,       // Groth16 proof (~128 bytes)
        bytes calldata journal     // Public outputs
    ) external {
        // 1. Verify proof
        Receipt memory receipt = Receipt(seal, journal);
        verifier.verify(receipt, approvedImageId);

        // 2. Decode journal to get detection results
        (uint32 fraudCount, uint64 txCount) = abi.decode(journal, (uint32, uint64));

        // 3. Validate results meet criteria
        require(txCount >= MIN_BATCH_SIZE, "Batch too small");

        // 4. Pay reward
        payable(msg.sender).transfer(rewardAmount);

        // 5. Emit audit event (transparency!)
        emit DetectionProofVerified(msg.sender, fraudCount, txCount);
    }
}
```

### Publishing Audit Events On-Chain

**TFH Goal** (from job description):
> "Publishing audit events to public blockchain for transparency"

**zkVM Solution**:
```
Private Detection Run
      ↓
Guest commits aggregated results to journal
      ↓
Receipt posted to Worldchain
      ↓
Smart contract emits audit event:
   - Timestamp
   - Third party address
   - Fraud count (no PII)
   - Transaction count
   - Proof verified ✓
      ↓
Public blockchain explorer shows audit trail
WITHOUT revealing individual user data!
```

### Groth16 On-Chain Verification Cost

**Ethereum/Worldchain Gas Costs**:
- Groth16 verification: ~280,000 gas
- At 50 gwei, 2000 ETH price: ~$28 per verification
- STARK verification: Too expensive (>10M gas)

**Conclusion**: Groth16 is mandatory for on-chain verification at TFH scale.

---

## Security Model for Detection Systems

### Threat Model for TFH Use Case

**Assumptions**:
1. **Honest Verifier**: Smart contract correctly implements verification
2. **Collision-Resistant Hash**: SHA-256 is secure (Image ID integrity)
3. **STARK Soundness**: FRI protocol is sound (98-bit security)
4. **Groth16 Soundness**: Pairing-based crypto is sound (if using)

**Adversary (Malicious Third Party) Can**:
- Control their own infrastructure
- See detection code (open source or revealed ELF)
- Choose which datasets to process
- Attempt to forge proofs

**Adversary CANNOT** (with high probability):
- Generate valid proof for incorrect results (soundness)
- Modify journal without invalidating seal (binding)
- Run different code and claim same Image ID (collision resistance)
- Extract private inputs from published receipts (zero-knowledge)

### Security Properties for Detection Engineering

1. **Correctness**: If receipt verifies, detection code ran correctly
   - No bugs, no shortcuts, no approximations
   - Cryptographically guaranteed execution trace

2. **Code Governance**: Image ID enforces exact detection algorithm
   - Third parties can't "optimize" code to game rewards
   - Updates require new Image ID → new smart contract deployment

3. **Privacy**: Private inputs stay private
   - User data never in journal
   - Only aggregated results public
   - Zero-knowledge property protects sensitive information

4. **Transparency**: Public audit trail
   - Every detection run logged on-chain
   - Verifiable by anyone (17M+ World ID users can audit)
   - Cryptographic proof of work

5. **Decentralization**: No single point of failure
   - Third parties compete to run detection
   - Smart contract is neutral arbiter
   - Bonsai provides redundant proving infrastructure

### Known Limitations

1. **Side Channels**: Execution time may leak information
   - Constant-time algorithms needed for sensitive operations
   - Example: Don't use `if fraud_detected { heavy_computation() }`

2. **Privacy Leakage via Journal**: Be careful what you commit!
   ```rust
   // BAD: Leaks individual user data
   env::commit(&flagged_user_iris_codes);

   // GOOD: Only aggregates
   env::commit(&flagged_user_count);
   ```

3. **Trusted Components**:
   - Detection code correctness (not proven by zkVM)
   - Smart contract logic (audit separately)
   - Bonsai availability (use fallback to local proving)

---

## Detection Use Case Example

### Scenario: Fraud Detection on World ID Verifications

**Problem**: Detect Sybil attacks, bot networks, fraudulent Orb scans across 350,000 weekly verifications.

**Requirements**:
- Privacy: Don't reveal individual user data
- Transparency: Publish detection results on-chain
- Decentralization: Allow third parties to run detection
- Verifiability: Prove detection ran correctly

### Guest Code: Fraud Detector

```rust
#![no_main]
#![no_std]

use risc0_zkvm::guest::env;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Verification {
    user_id: [u8; 32],      // Anonymous identifier
    orb_id: u64,
    timestamp: u64,
    iris_features: Vec<f32>, // High-dimensional biometric data
    location: (f64, f64),
}

#[derive(Serialize)]
struct DetectionOutput {
    total_verifications: u64,
    flagged_count: u32,
    flagged_orbs: Vec<u64>,  // Orb IDs, not user data!
    avg_confidence: f32,
}

risc0_zkvm::guest::entry!(main);

fn main() {
    // Read private verification batch
    let verifications: Vec<Verification> = env::read();

    // Run detection algorithms
    let mut flagged_count = 0;
    let mut flagged_orbs = Vec::new();
    let mut confidence_sum = 0.0;

    for v in &verifications {
        // Example: Detect duplicate iris features (simplified)
        let is_duplicate = check_duplicate_iris(&v.iris_features);

        // Example: Detect impossible velocity (same user, different locations)
        let impossible_travel = check_travel_speed(&verifications, &v);

        if is_duplicate || impossible_travel {
            flagged_count += 1;
            if !flagged_orbs.contains(&v.orb_id) {
                flagged_orbs.push(v.orb_id);
            }
            confidence_sum += compute_confidence(is_duplicate, impossible_travel);
        }
    }

    // Commit PUBLIC outputs (no PII!)
    let output = DetectionOutput {
        total_verifications: verifications.len() as u64,
        flagged_count,
        flagged_orbs,
        avg_confidence: confidence_sum / flagged_count as f32,
    };

    env::commit(&output);
}

fn check_duplicate_iris(features: &Vec<f32>) -> bool {
    // Cryptographic iris matching logic...
    // (This computation is PROVEN correct by zkVM!)
    false // placeholder
}

fn check_travel_speed(all: &Vec<Verification>, current: &Verification) -> bool {
    // Impossible velocity detection...
    false // placeholder
}

fn compute_confidence(dup: bool, travel: bool) -> f32 {
    // Confidence scoring...
    0.95 // placeholder
}
```

### Host Code: Third Party Runner

```rust
use risc0_zkvm::{ExecutorEnv, default_prover};
use fraud_detection_methods::{FRAUD_DETECTOR_ELF, FRAUD_DETECTOR_ID};

fn main() -> Result<()> {
    // 1. Third party fetches verification batch (via API or dataset)
    let verifications = fetch_verification_batch()?;

    // 2. Build execution environment
    let env = ExecutorEnv::builder()
        .write(&verifications)?
        .build()?;

    // 3. Generate proof (locally or via Bonsai)
    let prover = default_prover();
    let prove_info = prover.prove(env, FRAUD_DETECTOR_ELF)?;
    let receipt = prove_info.receipt;

    // 4. Extract results
    let output: DetectionOutput = receipt.journal.decode()?;
    println!("Flagged: {}/{}", output.flagged_count, output.total_verifications);
    println!("Suspicious Orbs: {:?}", output.flagged_orbs);

    // 5. Verify locally before submitting
    receipt.verify(FRAUD_DETECTOR_ID)?;

    // 6. Submit to smart contract for reward
    let worldchain = connect_worldchain()?;
    worldchain.submit_detection_proof(receipt).await?;

    println!("Proof submitted! Awaiting reward...");
    Ok(())
}
```

### Smart Contract: Verification & Rewards

```solidity
contract FraudDetectionIncentive {
    IRiscZeroVerifier public verifier;
    bytes32 public constant FRAUD_DETECTOR_ID = 0x1234...; // Image ID

    event FraudDetectionComplete(
        address indexed detector,
        uint64 totalVerifications,
        uint32 flaggedCount,
        uint64[] flaggedOrbs
    );

    function submitFraudProof(
        bytes calldata seal,
        bytes calldata journal
    ) external {
        // 1. Verify proof
        verifier.verify(seal, journal, FRAUD_DETECTOR_ID);

        // 2. Decode detection results
        DetectionOutput memory output = abi.decode(journal, (DetectionOutput));

        // 3. Validate quality
        require(output.totalVerifications >= 1000, "Batch too small");
        require(output.avgConfidence >= 0.8, "Low confidence");

        // 4. Pay reward proportional to work
        uint256 reward = output.totalVerifications * REWARD_PER_VERIFICATION;
        payable(msg.sender).transfer(reward);

        // 5. Emit audit event (TRANSPARENCY!)
        emit FraudDetectionComplete(
            msg.sender,
            output.totalVerifications,
            output.flaggedCount,
            output.flaggedOrbs
        );

        // 6. Optionally: Trigger alerts to World ID system
        if (output.flaggedCount > ALERT_THRESHOLD) {
            worldIdAlertSystem.notify(output.flaggedOrbs);
        }
    }
}
```

### What This Achieves for TFH

✅ **Decentralized**: Third parties run detection, compete for rewards
✅ **Verifiable**: Proof guarantees detection code ran correctly
✅ **Private**: Individual user data never revealed
✅ **Transparent**: Audit events published on-chain
✅ **Scalable**: Handles 350K+ weekly verifications via parallel proving
✅ **Trustless**: Smart contract enforces rules, no central authority needed

---

## Interview Quick Reference

### Key Talking Points Tailored to TFH

**1. How does RISC Zero enable TFH's distributed analytics system?**
> "RISC Zero lets third parties run detection code on sensitive data, generate proofs of correct execution, and publish only aggregated results on-chain. The zkVM guarantees they ran the exact approved algorithm - no shortcuts, no fake results. Smart contracts verify proofs and pay rewards trustlessly. This solves the core challenge: scaling detection to billions of users without centralized infrastructure or compromising privacy."

**2. Why is Bonsai critical for this architecture?**
> "Bonsai is essentially a distributed proving marketplace. It removes the GPU hardware barrier for third parties - anyone with an API key can participate. This democratizes detection work, increases redundancy, and scales elastically. For TFH, it means the detection system isn't bottlenecked by centralized proving capacity. Third parties compete for rewards, Bonsai handles compute, and the smart contract ensures quality."

**3. How do you balance privacy and transparency?**
> "The journal mechanism is the key. Detection code reads private data (transactions, biometrics) inside the zkVM, processes it, and commits only public summaries to the journal - like 'flagged 127 out of 1M transactions.' The proof guarantees this summary is correct, but the underlying data never appears in the receipt. On-chain, you get full auditability of detection results without exposing PII. Zero-knowledge property ensures even the proof itself doesn't leak sensitive information."

**4. What's the trust model for third-party detectors?**
> "Third parties are untrusted - they could be malicious, buggy, or incentivized to cheat. But they can't fake results because the proof binds the execution to a specific Image ID (detection code hash). If they modify the algorithm to game rewards, the Image ID changes and verification fails. The smart contract only accepts proofs from approved Image IDs. So trust is in the cryptography and the detection code itself, not in who runs it."

**5. How does this scale to billions of users?**
> "Two key properties: (1) Verification is O(1) with Groth16 - doesn't matter if detection ran on 1K or 1B transactions, verification takes <1ms and ~280K gas. (2) Proving is parallelizable - multiple third parties can run detection on different data subsets simultaneously, and Bonsai can spin up arbitrary GPU capacity. The bottleneck shifts from 'how much compute do we have' to 'how many third parties want to participate,' which the incentive model handles."

**6. What about real-time detection vs batch analytics?**
> "There's a tradeoff. Proving takes minutes (even with GPU), so this isn't suitable for sub-second fraud detection at the Orb. But for batch analytics - like analyzing a week's worth of verifications to identify patterns - it's perfect. TFH likely needs both: traditional real-time detection for immediate threats, and zkVM-based batch analytics for deeper insights and decentralized auditing. The job description mentions this is early-stage, so figuring out which detection workloads fit the zkVM model is part of the internship."

### Technical Deep Dives for Follow-Up Questions

**Q: How does the zkVM prevent side-channel attacks?**
> "The execution trace records every cycle deterministically, so timing attacks on the proof itself are mitigated. But the guest code still needs to be constant-time if it handles secrets - for example, biometric matching should use constant-time comparisons. The zkVM doesn't automatically make code side-channel resistant; that's the developer's responsibility."

**Q: Can detection code be updated without breaking existing proofs?**
> "Each code version has a unique Image ID. Updating the algorithm means deploying a new smart contract that accepts the new Image ID. Old proofs for the old Image ID remain valid in the historical context. For gradual rollout, the contract could accept multiple Image IDs during a transition period."

**Q: How do you handle false positives in decentralized detection?**
> "The smart contract can require multiple independent third parties to run detection on the same dataset and aggregate their results (consensus). Or, use composition - the guest code verifies multiple receipts from different detectors and only commits if they agree. This adds redundancy at the cost of more proving work."

**Q: What if Bonsai goes down?**
> "Third parties can fall back to local proving if they have GPUs. The protocol is agnostic - receipts are receipts, whether generated locally or on Bonsai. TFH could also run their own Bonsai-like infrastructure as a backup, or use multiple proving services in parallel."

### Terminology Cheat Sheet

- **zkVM**: Virtual machine that generates proofs of execution
- **Guest**: Detection code (runs inside zkVM, proven)
- **Host**: Orchestrator code (untrusted, runs on third party's server)
- **Receipt**: Proof + public outputs
- **Journal**: Public outputs from detection (aggregated results, no PII)
- **Seal**: Cryptographic proof (STARK or Groth16)
- **Image ID**: SHA-256 hash of detection code (trust anchor)
- **Groth16**: Tiny SNARK proof (~128 bytes) for on-chain verification
- **Bonsai**: Remote proving service (distributed GPU marketplace)
- **Composition**: Verifying receipts inside guest code (batching detections)

### Impressive Points to Mention

1. **World ID Scale**: 17M users, 350K weekly verifications → perfect use case for parallel proving
2. **Worldchain**: Ethereum L2 optimized for World ID → low gas costs for Groth16 verification
3. **Transparency vs Privacy**: zkVM is the only way to publish detection audits without revealing user data
4. **Incentive Alignment**: Third parties get paid for correct work, penalized for fake proofs (impossible to forge)
5. **Research Opportunity**: This is bleeding-edge - combining zkML (detection models) with blockchain incentives hasn't been done at this scale

### Questions to Ask Them

1. "What detection workloads are you prioritizing for the zkVM approach - real-time or batch analytics?"
2. "How do you envision the incentive structure - fixed rewards, or dynamic based on detection quality?"
3. "Are you planning to open-source the detection code, or keep it proprietary with only the Image ID public?"
4. "What's the privacy threat model - are you worried about third parties seeing raw data, or just about on-chain exposure?"
5. "How does this fit with the broader World ID roadmap - is the goal full decentralization of detection eventually?"

---

**Document Version**: 1.0 - TFH Interview Focus
**Based on**: RISC Zero v2.1+ | Job Description: Security Engineering Internship
**Last Updated**: 2026-01-26
**Focus**: Detection & Response Team | Distributed Analytics System
