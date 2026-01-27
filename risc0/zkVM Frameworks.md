# RISC Zero zkVM Framework - Technical Deep Dive

## Table of Contents
1. [Overview](#overview)
2. [Quick Start Guide](#quick-start-guide)
3. [Guest/Host Architecture](#guesthost-architecture)
4. [Receipts: Proof Outputs](#receipts-proof-outputs)
5. [Journals: Public Outputs](#journals-public-outputs)
6. [RISC-V + zk-STARKs Integration](#risc-v--zk-starks-integration)
7. [Compilation Pipeline](#compilation-pipeline)
8. [Proof Generation vs Verification](#proof-generation-vs-verification)
9. [Bonsai: Remote Proving Service](#bonsai-remote-proving-service)
10. [Advanced Concepts](#advanced-concepts)
11. [Security Model](#security-model)
12. [Performance Optimization](#performance-optimization)
13. [Code Examples](#code-examples)
14. [Interview Quick Reference](#interview-quick-reference)

---

## Overview

RISC Zero is a zero-knowledge verifiable general computing platform based on:
- **zk-STARKs** (Zero-Knowledge Scalable Transparent Arguments of Knowledge)
- **RISC-V microarchitecture** (RV32IM instruction set)

### Key Value Proposition
A prover can demonstrate correct execution of arbitrary code while revealing only:
- The output (journal)
- The code that was run (image ID)

...without revealing inputs or intermediate state.

### Core Components
```
┌─────────────────────────────────────────────┐
│           RISC Zero zkVM Stack              │
├─────────────────────────────────────────────┤
│  Application Layer (Rust/C/C++)            │
├─────────────────────────────────────────────┤
│  Guest Program → RISC-V ELF Binary         │
├─────────────────────────────────────────────┤
│  zkVM Executor → Execution Trace           │
├─────────────────────────────────────────────┤
│  Prover → RISC-V Circuit + zk-STARK        │
├─────────────────────────────────────────────┤
│  Optional: Recursion Circuit (Succinct)    │
├─────────────────────────────────────────────┤
│  Optional: Groth16 Circuit (Blockchain)    │
└─────────────────────────────────────────────┘
```

**Reference**: `README.md:20-33`

---

## Quick Start Guide

### Installation

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install RISC Zero toolchain installer
curl -L https://risczero.com/install | bash

# Install RISC Zero toolchain
rzup install

# Verify installation
cargo risczero --version
```

### Create New Project

```bash
# Generate project boilerplate
cargo risczero new my_project

# Project structure:
# my_project/
# ├── Cargo.toml
# ├── src/
# │   └── main.rs              # Host code
# └── methods/
#     ├── Cargo.toml
#     ├── build.rs             # Build script
#     └── guest/
#         └── src/
#             └── main.rs      # Guest code
```

### Build and Run

```bash
cd my_project

# Build (compiles guest to RISC-V ELF)
cargo build --release

# Run (executes guest, generates proof, verifies)
cargo run --release
```

**Reference**: `README.md:80-118`, `website/api/zkvm/quickstart.md`

---

## Guest/Host Architecture

### Architectural Overview

```
┌──────────────────────┐         ┌──────────────────────┐
│   Host (Untrusted)   │         │   Guest (Proven)     │
│                      │         │                      │
│  - Loads ELF binary  │────────▶│  - Reads inputs      │
│  - Provides inputs   │         │  - Executes code     │
│  - Runs prover       │         │  - Writes to journal │
│  - Verifies receipt  │◀────────│  - Returns output    │
│                      │ Receipt │                      │
└──────────────────────┘         └──────────────────────┘
```

### Guest Program Characteristics

**File**: `examples/hello-world/methods/guest/src/main.rs:16-35`

```rust
#![no_main]   // No standard entry point
#![no_std]    // No standard library (embedded environment)

use risc0_zkvm::guest::env;

// Special entry point macro
risc0_zkvm::guest::entry!(main);

fn main() {
    // Read inputs from host (deserialized automatically)
    let a: u64 = env::read();
    let b: u64 = env::read();

    // Business logic
    if a == 1 || b == 1 {
        panic!("Trivial factors");
    }
    let product = a.checked_mul(b).expect("Integer overflow");

    // Commit output to journal (public)
    env::commit(&product);
}
```

**Key Properties**:
- Runs in a RISC-V emulator (zkVM)
- Compiled to RISC-V ELF binary
- Entry point: `risc0_zkvm::guest::entry!(main)`
- Communication: `env::read()` for input, `env::commit()` for output
- No heap allocator by default (can enable with `alloc` feature)

### Host Program Characteristics

**File**: `examples/hello-world/src/lib.rs:27-52`

```rust
use risc0_zkvm::{ExecutorEnv, Receipt, default_prover};
use hello_world_methods::{MULTIPLY_ELF, MULTIPLY_ID};

pub fn multiply(a: u64, b: u64) -> (Receipt, u64) {
    // Build execution environment with inputs
    let env = ExecutorEnv::builder()
        .write(&a).unwrap()
        .write(&b).unwrap()
        .build().unwrap();

    // Get prover and generate proof
    let prover = default_prover();
    let receipt = prover.prove(env, MULTIPLY_ELF).unwrap().receipt;

    // Extract journal output
    let c: u64 = receipt.journal.decode().expect(
        "Journal output should deserialize into the same types (& order) that it was written"
    );

    println!("I know the factors of {c}, and I can prove it!");

    (receipt, c)
}
```

**Key Properties**:
- Runs on normal hardware
- Loads guest ELF binary (`MULTIPLY_ELF`)
- Provides inputs via `ExecutorEnv`
- Invokes prover to generate receipt
- Verifies receipt against image ID (`MULTIPLY_ID`)

### Critical Constraint

**The host CANNOT modify guest execution**. Any tampering invalidates the proof. The cryptographic seal binds:
- The code that ran (image ID)
- The inputs (implicit in execution)
- The outputs (journal)

**Reference**: `README.md:34-66`

---

## Receipts: Proof Outputs

### Receipt Structure

**File**: `risc0/zkvm/src/receipt.rs:114-150`

```rust
pub struct Receipt {
    /// The polymorphic cryptographic proof
    pub inner: InnerReceipt,

    /// The public commitment written by the guest
    /// This data is cryptographically authenticated in Receipt::verify
    pub journal: Journal,

    /// Metadata providing context (SDK versions, proving system info)
    /// NOT cryptographically bound - do not use for security decisions
    pub metadata: ReceiptMetadata,
}
```

### Four Receipt Types

```
┌─────────────────────────────────────────────────────────┐
│                  Receipt Hierarchy                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. CompositeReceipt                                   │
│     └─▶ Vec<SegmentReceipt>                           │
│         Each segment: ~200KB zk-STARK                  │
│         Use case: Large programs, parallel proving     │
│                                                         │
│  2. SuccinctReceipt                                    │
│     └─▶ Single ~100KB zk-STARK                        │
│         Via recursion circuit (compress composite)     │
│         Use case: Standard verification                │
│                                                         │
│  3. Groth16Receipt                                     │
│     └─▶ Single ~128 byte SNARK                        │
│         Via Groth16 circuit (compress succinct)        │
│         Use case: Blockchain/on-chain verification     │
│                                                         │
│  4. FakeReceipt                                        │
│     └─▶ No cryptographic proof                        │
│         Dev mode only - NEVER for production           │
│         Use case: Rapid prototyping, testing           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Receipt Verification

**File**: `risc0/zkvm/src/receipt.rs:145-150`

```rust
// Verify receipt proves successful execution of expected code
receipt.verify(image_id).expect("verification failed");

// This checks:
// 1. Seal is valid (zk-STARK or Groth16 proof)
// 2. Guest exited with success status (Halted(0))
// 3. Image ID matches expected code
// 4. Journal has not been tampered with
```

### Seal (Cryptographic Data)

The **seal** is an opaque blob containing:
- **For STARK receipts**: FRI proof data, Merkle proofs, polynomial commitments
- **For Groth16 receipts**: Three group elements (A, B, C) for pairing check
- **Size**: Segment ~200KB, Succinct ~100KB, Groth16 ~128 bytes

**Properties**:
- Cryptographically infeasible to forge
- Tamper-evident
- Verifiable in milliseconds

**Reference**: `README.md:50-60`, `website/docs/proof-system/proof-system.md:16-32`

---

## Journals: Public Outputs

### Journal Definition

**File**: `risc0/zkvm/src/receipt.rs`

```rust
pub struct Journal {
    /// Raw serialized data (RISC Zero serde format)
    pub bytes: Vec<u8>,
}

impl Journal {
    /// Decode journal into typed data
    pub fn decode<T: DeserializeOwned>(&self) -> Result<T> {
        from_slice(&self.bytes)
    }
}
```

### Writing to Journal (Guest Side)

```rust
use risc0_zkvm::guest::env;

// Commit single value
let result = 42u64;
env::commit(&result);

// Commit multiple values (in order)
env::commit(&value1);
env::commit(&value2);

// Commit slice
let data: Vec<u8> = vec![1, 2, 3, 4];
env::commit_slice(&data);
```

### Reading from Journal (Host Side)

```rust
// Single value
let output: u64 = receipt.journal.decode()?;

// Multiple values (decode in same order as committed)
let journal_bytes = &receipt.journal.bytes;
let mut cursor = std::io::Cursor::new(journal_bytes);

let value1: TypeA = risc0_zkvm::serde::from_reader(&mut cursor)?;
let value2: TypeB = risc0_zkvm::serde::from_reader(&mut cursor)?;

// Raw bytes
let raw_data: &[u8] = &receipt.journal.bytes;
```

### Journal Security Properties

1. **Append-only log**: Guest can only add data, never modify or delete
2. **Cryptographically bound**: Journal digest is part of the `ReceiptClaim`
3. **Tamper-evident**: Any modification invalidates the seal
4. **Public**: Anyone with the receipt can read the journal

### Journal vs Private Data

```
┌─────────────────────────────────────────────────┐
│  Guest Program                                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  let secret_key = env::read();    // Private   │
│  let message = env::read();       // Private   │
│                                                 │
│  let signature = sign(secret_key, message);    │
│                                                 │
│  env::commit(&signature);         // PUBLIC    │
│  env::commit(&message);           // PUBLIC    │
│                                                 │
└─────────────────────────────────────────────────┘
       │                                │
       │ Private (zero-knowledge)       │ Public (in journal)
       ▼                                ▼
   Not in receipt              Visible to verifier
```

**Reference**: `README.md:47-48`, exploration agent findings on journals

---

## RISC-V + zk-STARKs Integration

### The Big Picture

**Reference**: `website/docs/reference-docs/about-starks.md`

```
RISC-V Program
      ↓
┌──────────────────────────────┐
│  1. Execution Trace          │  ← Matrix: rows = clock cycles
│     (per instruction)        │           cols = state components
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  2. Arithmetization          │  ← Encode trace as polynomials
│     (Baby Bear field)        │    over finite field
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  3. Constraint Generation    │  ← "Computation correct" becomes
│     (RISC-V Circuit)         │    "polynomial constraints hold"
└──────────────────────────────┘
      ↓
┌──────────────────────────────┐
│  4. FRI Protocol             │  ← Prove polynomial constraints
│     (zk-STARK)               │    with zero knowledge
└──────────────────────────────┘
      ↓
    Seal (Proof)
```

### 1. Execution Trace

An execution trace is a **rectangular matrix** recording the complete state of the RISC-V machine at every clock cycle.

**Structure**:
```
Clock │  PC   │ Reg[0] │ Reg[1] │ ... │ Reg[31] │ Memory[addr] │ ...
──────┼───────┼────────┼────────┼─────┼─────────┼──────────────┼────
  0   │ 0x100 │   0    │   0    │ ... │    0    │      ...     │
  1   │ 0x104 │   0    │  17    │ ... │    0    │      ...     │
  2   │ 0x108 │   0    │  23    │ ... │    0    │      ...     │
  3   │ 0x10C │   0    │  391   │ ... │    0    │      ...     │
 ...  │  ...  │  ...   │  ...   │ ... │   ...   │      ...     │
```

- **Each row**: Full machine state at one clock cycle
- **Each column**: Temporal evolution of one state element
- **Generated by**: `ExecutorImpl` as guest code runs

**Formula**: 1 RISC-V instruction ≈ 1 clock cycle (some operations take 2 cycles)

**Reference**: `website/docs/proof-system/what-is-a-trace.md`

### 2. Arithmetization

**Finite Field**: Baby Bear prime `p = 2^31 - 2^27 + 1 = 2,013,265,921`

**Process**:
1. Each trace column becomes a polynomial `f(x)`
2. Constraint equations encode RISC-V semantics
3. Example: `ADD rd, rs1, rs2` becomes:
   ```
   constraint: reg_next[rd] = reg[rs1] + reg[rs2]  (mod p)
   ```

### 3. RISC-V Circuit

**Location**: `risc0/circuit/rv32im-sys/`

**Implements**: RV32IM instruction set
- **RV32I**: Base integer instructions (32-bit)
- **M extension**: Integer multiplication and division

**Circuit Validation**:
- Each instruction type has constraint polynomials
- Prover must show constraints are satisfied for every cycle
- Control columns identify which constraints apply per row

**Control ID**: Merkle hash of circuit control columns (identifies circuit version)

### 4. zk-STARK Protocol

**FRI (Fast Reed-Solomon Interactive Oracle Proofs)**:

```
Prover:
1. Encode trace as polynomials f(x)
2. Compute constraint polynomial C(x)
3. Show C(x) divides properly → constraints satisfied
4. Use FRI to prove low-degree of quotient polynomial
5. Generate proof: commitments + Merkle proofs + FRI data

Verifier:
1. Check polynomial commitments
2. Verify random query points (Reed-Solomon code)
3. Verify Merkle proofs (integrity)
4. Verify FRI recursion (low-degree)
5. Accept if all checks pass

Complexity:
- Prover: O(n log n) time, O(n) space
- Verifier: O(log n) time, O(1) space  ← KEY PROPERTY
```

**Security**: 98 bits conjectured security with default parameters

**Reference**: `website/docs/reference-docs/about-starks.md`, `README.md:68-76`

---

## Compilation Pipeline

### End-to-End Flow

```
┌────────────────────────────────────────────────────────┐
│  1. Write Guest Code (Rust/C/C++)                     │
│     methods/guest/src/main.rs                         │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  2. Build Script (methods/build.rs)                   │
│     risc0_build::embed_methods()                      │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  3. Rust Compiler → LLVM                              │
│     Target: riscv32im-risc0-zkvm-elf                  │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  4. RISC-V ELF Binary                                 │
│     Standard ELF format, RISC-V machine code          │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  5. Compute Image ID                                  │
│     SHA-256 hash of ELF binary                        │
│     risc0_binfmt::compute_image_id(elf_bytes)         │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  6. Generate methods.rs                               │
│     pub const METHOD_ELF: &[u8] = include_bytes!(...) │
│     pub const METHOD_ID: [u32; 8] = [...]             │
└────────────────────────────────────────────────────────┘
                      ↓
┌────────────────────────────────────────────────────────┐
│  7. Host includes methods.rs                          │
│     include!(concat!(env!("OUT_DIR"), "/methods.rs")) │
└────────────────────────────────────────────────────────┘
```

### Directory Structure

```
my_project/
├── Cargo.toml                    # Host package
├── src/
│   └── main.rs                   # Host code (uses METHOD_ELF, METHOD_ID)
│
└── methods/
    ├── Cargo.toml                # Guest package
    │   └── [package.metadata.risc0]
    │       methods = ["guest"]   # List of guest programs
    │
    ├── build.rs                  # Build script
    │   └── risc0_build::embed_methods()
    │
    └── guest/
        ├── Cargo.toml            # Guest binary package
        │   └── default-features = false
        │
        └── src/
            └── main.rs           # Guest code (RISC-V target)
```

### Build Script Details

**File**: `methods/build.rs`

```rust
fn main() {
    // Compiles all methods listed in Cargo.toml metadata
    // Generates methods.rs in OUT_DIR
    risc0_build::embed_methods();
}
```

**Generated Output**: `$OUT_DIR/methods.rs`

```rust
// Auto-generated - DO NOT EDIT

pub const MULTIPLY_ELF: &[u8] = include_bytes!("path/to/multiply.elf");

pub const MULTIPLY_ID: [u32; 8] = [
    0x12345678, 0x9abcdef0, // ... image ID digest
];

// Optionally: MULTIPLY_PATH for debugging
#[cfg(debug_assertions)]
pub const MULTIPLY_PATH: &str = "/absolute/path/to/multiply.elf";
```

### Guest Cargo.toml Configuration

```toml
[package]
name = "my-method-guest"
version = "0.1.0"
edition = "2021"

[dependencies]
risc0-zkvm = { version = "2.1", default-features = false, features = ["std"] }

# CRITICAL: Disable default features to avoid host-only APIs
[profile.release]
opt-level = 3
lto = true          # Link-time optimization
```

### Image ID: The Trust Anchor

**What is it?**
- Cryptographic hash (SHA-256) of the ELF binary
- Uniquely identifies the guest program
- 256-bit digest, represented as `[u32; 8]`

**Why it matters?**
- Verifier provides image ID during `receipt.verify(image_id)`
- Proves "this specific code" executed, not arbitrary code
- Different code → different image ID → verification fails

**Computation**:
```rust
use risc0_binfmt::compute_image_id;

let image_id = compute_image_id(elf_bytes)?;
// Deterministic: same ELF → same image ID always
```

**Deterministic Builds**:
- Use Docker containers to ensure reproducible compilation
- Important for multi-party verification scenarios

**Reference**: `README.md:36-40`, exploration agent findings on compilation

---

## Proof Generation vs Verification

### Cost Comparison Matrix

| Metric | Proof Generation | Verification |
|--------|------------------|--------------|
| **Time Complexity** | O(n log n) | O(log n) |
| **Space Complexity** | O(n) | O(1) |
| **Time (1M cycles)** | Minutes (GPU) to hours (CPU) | Milliseconds |
| **Memory (1M cycles)** | 8-16 GB RAM | < 1 MB |
| **Parallelization** | Segments proven in parallel | Single-threaded OK |
| **Hardware Acceleration** | GPU: 10-100x speedup | Not needed |
| **Scales with program size** | Linear (with recursion) | Constant (succinct/Groth16) |

### Proof Generation Deep Dive

**Location**: `risc0/zkvm/src/host/`

**Pipeline**:

```
┌──────────────────────────────────────────────┐
│  1. Executor Phase                           │
│     - Run guest code in RISC-V emulator      │
│     - Generate execution trace               │
│     - Split into segments (if large)         │
│     Cost: ~0.1-1ms per cycle                 │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  2. Proving Phase (per segment)              │
│     - Arithmetize trace                      │
│     - Compute constraint polynomials         │
│     - Run FRI protocol                       │
│     - Generate STARK proof                   │
│     Cost: Dominant phase, GPU-accelerated    │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  3. Recursion Phase (optional)               │
│     - Compress multiple segments             │
│     - Lift → Join → Succinct                 │
│     - Use recursion circuit                  │
│     Cost: ~10x cheaper than initial proving  │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  4. Groth16 Compression (optional)           │
│     - Convert STARK → SNARK                  │
│     - Trusted setup required                 │
│     - Result: ~128 byte proof                │
│     Cost: One-time, ~30 seconds              │
└──────────────────────────────────────────────┘
```

**Segment Size**: Configurable via `PO2` parameter (power of 2)
- Default: 2^20 cycles (~1M cycles) per segment
- Larger segments → fewer segments → less recursion overhead
- Smaller segments → more parallelization opportunities

**Cycle Counting**:
```rust
use risc0_zkvm::{ExecutorEnv, default_executor};

let env = ExecutorEnv::builder().build()?;
let mut exec = default_executor();
let session = exec.execute(env, METHOD_ELF)?;

println!("Total cycles: {}", session.total_cycles);
println!("User cycles: {}", session.user_cycles);
```

**GPU Acceleration**:
- **CUDA**: NVIDIA GPUs (feature flag: `cuda`)
- **Metal**: Apple Silicon (enabled by default on macOS)
- **Speedup**: 10-100x depending on program size
- **Memory**: GPU RAM requirements ~4-8 GB

**Dev Mode** (Skip Proving):
```bash
export RISC0_DEV_MODE=1
cargo run
```
- Executes guest but generates `FakeReceipt`
- No cryptographic proof
- **NEVER for production** (disable at compile time: `disable-dev-mode` feature)

**Reference**: `risc0/zkvm/src/host/server/prove/`

### Verification Deep Dive

**Location**: `risc0/zkvm/src/receipt/`

**Verification Process by Receipt Type**:

#### 1. Segment Receipt
```rust
// File: risc0/zkvm/src/receipt/segment.rs

pub fn verify(&self, image_id: Digest) -> Result<()> {
    // 1. Verify RISC-V circuit seal
    risc0_circuit_rv32im::verify(&self.seal, image_id)?;

    // 2. Check claim: output, assumptions, control ID
    // 3. Verify Merkle proofs in seal
    // 4. Check FRI polynomial commitments

    // Complexity: O(log n) due to FRI verification
    // Time: ~1-5 milliseconds per segment
}
```

#### 2. Succinct Receipt
```rust
// File: risc0/zkvm/src/receipt/succinct.rs

pub fn verify(&self, image_id: Digest) -> Result<()> {
    // 1. Verify recursion circuit seal
    risc0_circuit_recursion::verify(&self.seal)?;

    // 2. Check control ID matches expected recursion circuit
    // 3. Verify claim integrity (SHA-256 digest)

    // Complexity: O(1) - constant time
    // Time: ~1 millisecond regardless of program size
}
```

#### 3. Groth16 Receipt
```rust
// File: risc0/zkvm/src/receipt/groth16.rs

pub fn verify(&self, image_id: Digest) -> Result<()> {
    // 1. Groth16 pairing check
    //    e(A, B) = e(α, β) · e(C, δ) · e(public_inputs, γ)

    // 2. Verify claim matches public inputs

    // Complexity: O(1) - constant time
    // Time: <1 millisecond (pairing is fast)
    // Size: ~128 bytes (blockchain-friendly)
}
```

#### 4. Fake Receipt
```rust
// Dev mode only - returns Ok immediately
// NO SECURITY - testing only
```

### Receipt Size Comparison

| Receipt Type | Proof Size | Verification Time | Use Case |
|--------------|------------|-------------------|----------|
| **Composite** (N segments) | N × 200 KB | N × 5 ms | Large programs, intermediate |
| **Succinct** | ~100 KB | 1-2 ms | Standard verification |
| **Groth16** | ~128 bytes | <1 ms | Blockchain, expensive storage |
| **Fake** | ~100 bytes | 0 ms | Dev mode only |

### Verification API

```rust
use risc0_zkvm::Receipt;

// Standard verification
receipt.verify(image_id)?;

// Just check integrity (don't verify success status)
receipt.verify_integrity_with_context(&VerifierContext::default())?;

// Extract and verify claim
let claim: ReceiptClaim = receipt.get_claim()?;
assert_eq!(claim.exit_code, ExitCode::Halted(0));  // Success
```

**Reference**: Exploration agent findings on proof generation vs verification

---

## Bonsai: Remote Proving Service

### Overview

**Bonsai** is RISC Zero's remote proving service that offloads proof generation to cloud servers.

**Why use Bonsai?**
- No local GPU required
- Scales to arbitrarily large programs
- Frees host resources for other work
- Can convert STARK → Groth16 for blockchain

### Architecture

```
┌─────────────────┐          ┌─────────────────┐
│   Your Host     │          │  Bonsai Cloud   │
│                 │          │                 │
│  1. Upload ELF  │────────▶ │                 │
│  2. Upload Input│────────▶ │                 │
│  3. Create Job  │────────▶ │  GPU Clusters   │
│                 │          │                 │
│  4. Poll Status │◀────────▶│  Proving...     │
│                 │          │                 │
│  5. Download    │◀────────│  Receipt Ready  │
│     Receipt     │          │                 │
└─────────────────┘          └─────────────────┘
```

### Code Example

**File**: `bonsai/sdk/src/lib.rs:37-94`

```rust
use bonsai_sdk::blocking::Client;
use risc0_zkvm::{compute_image_id, serde::to_vec, Receipt};

fn run_bonsai(input_data: Vec<u8>) -> Result<()> {
    // 1. Create client (reads BONSAI_API_KEY and BONSAI_API_URL from env)
    let client = Client::from_env(risc0_zkvm::VERSION)?;

    // 2. Upload ELF binary
    let image_id = hex::encode(compute_image_id(METHOD_ELF)?);
    client.upload_img(&image_id, METHOD_ELF.to_vec())?;

    // 3. Upload input data (serialized)
    let input_data = to_vec(&input_data).unwrap();
    let input_data = bytemuck::cast_slice(&input_data).to_vec();
    let input_id = client.upload_input(input_data)?;

    // 4. Create proving session
    let assumptions: Vec<String> = vec![];  // For composition
    let execute_only = false;               // Generate proof, not just execute
    let session = client.create_session(
        image_id,
        input_id,
        assumptions,
        execute_only
    )?;

    // 5. Poll for completion
    loop {
        let res = session.status(&client)?;

        match res.status.as_str() {
            "RUNNING" => {
                eprintln!("Current status: {} - continue polling...", res.status);
                std::thread::sleep(Duration::from_secs(15));
                continue;
            }
            "SUCCEEDED" => {
                // 6. Download receipt
                let receipt_url = res.receipt_url.expect("Missing receipt URL");
                let receipt_buf = client.download(&receipt_url)?;
                let receipt: Receipt = bincode::deserialize(&receipt_buf)?;

                // 7. Verify locally
                receipt.verify(METHOD_ID).expect("Receipt verification failed");

                break;
            }
            _ => {
                panic!("Job failed: {} - {}",
                    res.status,
                    res.error_msg.unwrap_or_default()
                );
            }
        }
    }

    Ok(())
}
```

### STARK to SNARK Conversion

After generating a STARK proof on Bonsai, you can compress it to Groth16:

```rust
// Convert succinct receipt to Groth16
let snark_session = client.create_snark(session.uuid)?;

loop {
    let res = snark_session.status(&client)?;
    if res.status == "SUCCEEDED" {
        let snark_receipt_url = res.output.expect("Missing SNARK output");
        let snark_receipt: Receipt = client.download_snark(&snark_receipt_url)?;

        // This receipt is now a Groth16Receipt (~128 bytes)
        // Perfect for on-chain verification
        break;
    }
    std::thread::sleep(Duration::from_secs(15));
}
```

### Bonsai Configuration

```bash
# Set environment variables
export BONSAI_API_KEY="your_api_key_here"
export BONSAI_API_URL="https://api.bonsai.xyz"  # or custom endpoint

# Use in host code
let client = Client::from_env(risc0_zkvm::VERSION)?;
```

### Bonsai vs Local Proving

| Aspect | Local Proving | Bonsai |
|--------|---------------|--------|
| **Hardware** | GPU recommended | Not required |
| **Setup** | Install CUDA/Metal drivers | API key only |
| **Cost** | Hardware investment | Pay-per-proof |
| **Scalability** | Limited by local resources | Unlimited |
| **Latency** | Lower (no network) | Higher (network + queue) |
| **Privacy** | Full (everything local) | ELF + inputs sent to server |

**Reference**: `bonsai/sdk/src/lib.rs`

---

## Advanced Concepts

### 1. Segments and Continuations

**Problem**: Large programs exceed memory limits of single proof

**Solution**: Automatic segmentation

```
Program: 5 million cycles
         ↓
┌────────────────────────────────────────┐
│  Segment 0: 0 - 1M cycles             │ → SegmentReceipt 0
│  Segment 1: 1M - 2M cycles            │ → SegmentReceipt 1
│  Segment 2: 2M - 3M cycles            │ → SegmentReceipt 2
│  Segment 3: 3M - 4M cycles            │ → SegmentReceipt 3
│  Segment 4: 4M - 5M cycles            │ → SegmentReceipt 4
└────────────────────────────────────────┘
         ↓
    CompositeReceipt (5 segments)
         ↓
    SuccinctReceipt (1 proof via recursion)
```

**Segment Chaining**:
- Each segment ends with state digest: `SHA-256(registers + memory + PC)`
- Next segment starts with same state digest
- Prover must show state digests match → execution is continuous

**Session**: Collection of all segments until `env::halt()` or `env::pause()`

### 2. Composition

**Concept**: Verify receipts inside the guest program

**Use Cases**:
- Privacy-preserving workflows (verify without revealing)
- Batch verification (prove many proofs are valid)
- Multi-party computation (combine proofs from different parties)

**Code Example**:

```rust
// Inside guest program
use risc0_zkvm::guest::env;

fn main() {
    // Read a receipt from host
    let receipt_bytes: Vec<u8> = env::read();

    // Verify the receipt inside the zkVM
    let inner_journal = env::verify(INNER_IMAGE_ID, &receipt_bytes)
        .expect("Inner receipt verification failed");

    // Use the verified journal data
    let verified_data: SomeType = risc0_zkvm::serde::from_slice(&inner_journal)?;

    // Continue with computation...
    env::commit(&verified_data);
}
```

**Result**: The outer receipt now has an `Assumption`:
```rust
pub struct Assumption {
    pub claim: ReceiptClaim,    // What was assumed
    pub control_root: Digest,   // Which circuit version
}
```

**Resolving Assumptions**:
- Provide the assumed receipt during verification
- Or: Generate a new proof that includes verification of assumed receipts
- Result: Fully unconditional proof

### 3. Control IDs and Versioning

**Control ID**: Merkle hash of circuit control columns

**Purpose**:
- Identifies specific circuit version (RISC-V or recursion)
- Different circuit → different control ID
- Used to ensure verifier and prover agree on circuit

**Control Root**: Merkle hash of allowed control IDs
- Enables version upgrades without new trusted setup
- Verifier checks control ID is in allowed set

**Why it matters**:
- Circuit bugs require new control ID
- Backwards compatibility: accept multiple control IDs
- Security: reject receipts from outdated/vulnerable circuits

### 4. Memory Model

**Guest Memory**:
- 32-bit address space (4 GB virtual)
- Actually limited to ~100 MB practical limit
- Memory I/O tracked in execution trace
- Every read/write increases proof size

**Optimization Tips**:
- Minimize memory usage
- Use stack allocation over heap when possible
- Batch memory operations

### 5. Cryptographic Accelerators

RISC Zero provides optimized implementations:

**SHA-256**:
```rust
use risc0_zkvm::sha::{Digest, Sha256};

let hash = Sha256::digest(data);  // Much faster than generic implementation
```

**ECDSA (secp256k1, P-256)**:
- See `examples/ecdsa/`
- Native circuits for signature verification
- ~10x faster than pure software

**BLS12-381, BN254**:
- Pairing-friendly curves
- See `examples/bls12_381/`, `examples/bn254/`

### 6. Profiling

```rust
use risc0_zkvm::ExecutorEnv;

let env = ExecutorEnv::builder()
    .enable_profiling()
    .build()?;

let session = prover.prove(env, METHOD_ELF)?;

// Analyze cycle counts by instruction
session.profile_info();
```

**Reference**: `examples/profiling/`

---

## Security Model

### Threat Model

**Assumptions**:
1. **Honest Verifier**: Verifier correctly implements verification algorithm
2. **Collision-Resistant Hash**: SHA-256 is collision-resistant
3. **FRI Soundness**: Underlying STARK protocol is sound
4. **Groth16 Soundness** (if using): Pairing-based cryptography is sound

**Adversary Can**:
- Control all inputs to guest program
- Read all outputs (journal)
- Attempt to forge receipts
- Attempt to extract private information from receipt

**Adversary Cannot** (with high probability):
- Generate valid receipt for incorrect execution
- Modify journal without invalidating seal
- Infer private inputs from receipt (zero-knowledge property)
- Break verification with incorrect image ID

### Security Parameters

**Default Configuration**:
- **Conjectured Security**: 98 bits
- **Zero-Knowledge**: Perfect (information-theoretic)
- **Soundness Error**: 2^-98 per verification

**Soundness Calculator**:
```bash
RUST_LOG=risc0_zkp=debug cargo run
# Prints soundness analysis to console
```

**File**: `risc0/zkp/src/soundness.rs`

### Known Limitations

1. **No Post-Quantum Security**: STARKs are quantum-resistant, but underlying hash functions are not proven quantum-safe
2. **Side Channels**: Execution time may leak information (constant-time crypto needed)
3. **Memory Safety**: Rust's memory safety doesn't prevent logic bugs
4. **Trusted Components**:
   - Compiler toolchain (LLVM, rustc)
   - Host OS kernel
   - Verifier implementation

**Reference**: `README.md:67-76`, `SECURITY.md`

---

## Performance Optimization

### 1. Reduce Cycle Count

**Why**: Fewer cycles → smaller proof → faster proving

**Techniques**:
- Use efficient algorithms (O(n) vs O(n²))
- Minimize loops and recursion
- Batch operations
- Use built-in cryptographic accelerators

**Example**:
```rust
// BAD: O(n²)
for i in 0..n {
    for j in 0..m {
        compute(i, j);
    }
}

// GOOD: O(n)
for i in 0..n {
    compute_batched(i);
}
```

### 2. Optimize Memory Usage

**Why**: Every memory access is recorded in trace

**Techniques**:
- Use stack allocation (`[T; N]`) over heap (`Vec<T>`)
- Minimize allocations
- Reuse buffers
- Stream data instead of loading all at once

### 3. Use GPU Acceleration

```toml
# Cargo.toml
[dependencies]
risc0-zkvm = { version = "2.1", features = ["cuda"] }  # NVIDIA

# Or use Metal on Apple Silicon (default on macOS)
```

### 4. Segment Size Tuning

```rust
use risc0_zkvm::ExecutorEnv;

let env = ExecutorEnv::builder()
    .segment_limit_po2(20)  // 2^20 = ~1M cycles per segment (default)
    // Smaller: more parallelization, more recursion overhead
    // Larger: less parallelization, less recursion overhead
    .build()?;
```

### 5. Parallel Proving

```rust
// Segments are proven in parallel automatically
// Set thread count:
use risc0_zkvm::MemoryUsage;

let prover = default_prover();
// Or configure ProverOpts for custom parallelism
```

### 6. Dev Mode for Testing

```bash
# Skip proving during development
export RISC0_DEV_MODE=1
cargo test
```

### 7. Profile and Analyze

```rust
let env = ExecutorEnv::builder()
    .enable_profiling()
    .build()?;

let receipt = prover.prove(env, METHOD_ELF)?;

// Print cycle breakdown
receipt.session.profile_info();
```

### Performance Targets

| Program Size | Proving Time (GPU) | Proving Time (CPU) | Memory |
|--------------|--------------------|--------------------|--------|
| 100K cycles | ~10 seconds | ~2 minutes | 2 GB |
| 1M cycles | ~1 minute | ~20 minutes | 8 GB |
| 10M cycles | ~10 minutes | ~3 hours | 16 GB |
| 100M cycles | ~1.5 hours | ~30 hours | 32 GB |

*Estimates vary by hardware and program characteristics*

---

## Code Examples

### Example 1: Hello World (Factors)

**Guest** (`examples/hello-world/methods/guest/src/main.rs`):
```rust
#![no_main]
#![no_std]

use risc0_zkvm::guest::env;

risc0_zkvm::guest::entry!(main);

fn main() {
    let a: u64 = env::read();
    let b: u64 = env::read();

    if a == 1 || b == 1 {
        panic!("Trivial factors");
    }

    let product = a.checked_mul(b).expect("Integer overflow");
    env::commit(&product);
}
```

**Host** (`examples/hello-world/src/lib.rs`):
```rust
use risc0_zkvm::{ExecutorEnv, Receipt, default_prover};
use hello_world_methods::{MULTIPLY_ELF, MULTIPLY_ID};

pub fn multiply(a: u64, b: u64) -> (Receipt, u64) {
    let env = ExecutorEnv::builder()
        .write(&a).unwrap()
        .write(&b).unwrap()
        .build().unwrap();

    let prover = default_prover();
    let receipt = prover.prove(env, MULTIPLY_ELF).unwrap().receipt;

    let c: u64 = receipt.journal.decode().expect("decode failed");

    (receipt, c)
}

fn main() {
    let (receipt, result) = multiply(17, 23);
    receipt.verify(MULTIPLY_ID).expect("verification failed");
    println!("Result: {}", result);  // 391
}
```

### Example 2: Digital Signature Verification

**Guest** (`examples/digital-signature/methods/guest/src/main.rs`):
```rust
use risc0_zkvm::guest::env;
use sha2::{Sha256, Digest};
use ed25519_dalek::{PublicKey, Signature, Verifier};

risc0_zkvm::guest::entry!(main);

fn main() {
    // Read inputs (private)
    let message: Vec<u8> = env::read();
    let signature_bytes: [u8; 64] = env::read();
    let public_key_bytes: [u8; 32] = env::read();

    // Verify signature
    let public_key = PublicKey::from_bytes(&public_key_bytes).unwrap();
    let signature = Signature::from_bytes(&signature_bytes).unwrap();

    public_key.verify(&message, &signature)
        .expect("Invalid signature");

    // Commit only message hash (not full message)
    let hash = Sha256::digest(&message);
    env::commit(&hash.as_slice());
}
```

**Use Case**: Prove you have a valid signature without revealing the message or signature.

### Example 3: Password Checker

**Guest** (`examples/password-checker/methods/guest/src/main.rs`):
```rust
use risc0_zkvm::guest::env;
use sha2::{Sha256, Digest};

risc0_zkvm::guest::entry!(main);

fn main() {
    // Private input
    let password: String = env::read();

    // Public reference (hash of correct password)
    let expected_hash: [u8; 32] = env::read();

    // Check password
    let actual_hash = Sha256::digest(password.as_bytes());

    if actual_hash.as_slice() == expected_hash {
        env::commit(&true);
    } else {
        panic!("Incorrect password");
    }
}
```

**Use Case**: Prove you know the password without revealing it.

### Example 4: JSON Processing

**Guest** (`examples/json/methods/guest/src/main.rs`):
```rust
use risc0_zkvm::guest::env;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct InputData {
    values: Vec<i32>,
}

#[derive(Serialize)]
struct OutputData {
    sum: i32,
    count: usize,
}

risc0_zkvm::guest::entry!(main);

fn main() {
    let input: InputData = env::read();

    let sum: i32 = input.values.iter().sum();
    let count = input.values.len();

    let output = OutputData { sum, count };
    env::commit(&output);
}
```

**Host**:
```rust
let input = InputData { values: vec![1, 2, 3, 4, 5] };

let env = ExecutorEnv::builder()
    .write(&input)?
    .build()?;

let receipt = prover.prove(env, METHOD_ELF)?.receipt;
let output: OutputData = receipt.journal.decode()?;

assert_eq!(output.sum, 15);
assert_eq!(output.count, 5);
```

---

## Interview Quick Reference

### Key Talking Points

**1. What is RISC Zero?**
> "RISC Zero is a zero-knowledge proof system for general computation. It runs arbitrary code compiled to RISC-V inside a zkVM, generating STARKs that prove correct execution. Verifiers can check proofs in milliseconds without re-executing the program."

**2. Guest vs Host?**
> "Guest code runs inside the zkVM (proven environment) - it's compiled to RISC-V and can't access external resources. Host code runs on normal hardware (untrusted) - it loads the guest, provides inputs via ExecutorEnv, generates the proof, and verifies receipts. The host can't modify guest execution without invalidating the proof."

**3. What's in a receipt?**
> "A receipt contains three parts: (1) Journal - the public outputs committed by the guest, (2) Seal - the cryptographic proof (STARK or Groth16), and (3) Metadata - version info. Verification checks the seal is valid, the journal hasn't been tampered with, and the code matches the expected image ID."

**4. How do RISC-V and STARKs work together?**
> "As the guest executes RISC-V instructions, the zkVM generates an execution trace - a matrix where each row is the full machine state per clock cycle. This trace is arithmetized into polynomials, and constraint equations enforce RISC-V semantics. The STARK proof uses FRI to show these polynomial constraints hold, which means execution was correct."

**5. Why are proofs expensive but verification cheap?**
> "Proving is O(n log n) because the prover must generate polynomials for the entire execution trace, commit to them, and produce FRI proofs. Verification is O(log n) because the verifier only checks random query points and Merkle proofs - they don't re-execute or see the full trace. With succinct or Groth16 receipts, verification is constant time regardless of program size."

**6. What's Bonsai?**
> "Bonsai is RISC Zero's remote proving service. Instead of running proofs locally, you upload your ELF binary and inputs to Bonsai's GPU clusters. This removes the need for local hardware acceleration and scales to arbitrarily large programs. It can also compress STARKs to Groth16 SNARKs for blockchain use."

### Architecture Cheat Sheet

```
┌─────────────────────────────────────────────┐
│ Host (Untrusted)                            │
│ • Rust/C/C++ with std library               │
│ • Loads guest ELF, provides inputs          │
│ • Runs prover (GPU-accelerated)             │
│ • Verifies receipts                         │
└─────────────────────────────────────────────┘
                   ↕
           ExecutorEnv (inputs)
           Receipt (outputs)
                   ↕
┌─────────────────────────────────────────────┐
│ Guest (Proven)                              │
│ • Rust/C/C++ (no_std by default)            │
│ • Compiled to RISC-V ELF                    │
│ • Reads: env::read()                        │
│ • Writes: env::commit()                     │
│ • Runs in zkVM emulator                     │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Execution Trace (Matrix)                    │
│ • Rows: clock cycles (1 per instruction)    │
│ • Cols: registers, memory, PC, etc.         │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ RISC-V Circuit (RV32IM)                     │
│ • Constraint polynomials                    │
│ • Validates RISC-V semantics                │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ zk-STARK (FRI Protocol)                     │
│ • Prover: O(n log n)                        │
│ • Verifier: O(log n)                        │
│ • Output: Segment Receipt (~200KB)          │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Recursion Circuit (Optional)                │
│ • Compresses multiple segments              │
│ • Output: Succinct Receipt (~100KB)         │
└─────────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Groth16 Circuit (Optional)                  │
│ • Converts STARK → SNARK                    │
│ • Output: Groth16 Receipt (~128 bytes)      │
└─────────────────────────────────────────────┘
```

### Terminology Lightning Round

- **zkVM**: Zero-knowledge virtual machine (RISC-V emulator)
- **Guest**: Code running inside zkVM (proven)
- **Host**: Code running outside zkVM (untrusted)
- **Method**: RISC-V ELF binary for guest program
- **Image ID**: SHA-256 hash of ELF (identifies code)
- **Receipt**: Proof of execution (journal + seal + metadata)
- **Journal**: Public outputs (append-only log)
- **Seal**: Cryptographic proof (STARK or Groth16)
- **Segment**: Chunk of execution (~1M cycles)
- **Session**: Complete execution (all segments until halt)
- **Composite Receipt**: Vector of segment receipts
- **Succinct Receipt**: Single compressed STARK
- **Groth16 Receipt**: Single compressed SNARK
- **Execution Trace**: Matrix of machine states
- **Control ID**: Hash identifying circuit version
- **Assumption**: Unresolved inner receipt (composition)

### Complexity Quick Facts

| Metric | Value |
|--------|-------|
| **1 instruction** | ≈ 1 clock cycle |
| **1 cycle** | ≈ 1 trace row |
| **Segment size** | 2^20 cycles (default) |
| **Finite field** | Baby Bear: 2^31 - 2^27 + 1 |
| **Security** | 98 bits conjectured |
| **Prover complexity** | O(n log n) time, O(n) space |
| **Verifier complexity** | O(log n) segment, O(1) succinct |
| **GPU speedup** | 10-100x vs CPU |

### Common Interview Questions

**Q: How does RISC Zero differ from circuit-based ZK systems (e.g., Circom)?**
> "RISC Zero is general-purpose - any RISC-V code works without custom circuits. Circuit systems require hand-written constraints for each application. RISC Zero trades off proof size (larger) for flexibility and ease of development."

**Q: What's the trust model?**
> "RISC Zero uses STARKs which are transparent - no trusted setup. The verifier only trusts: (1) collision-resistant hash functions (SHA-256), (2) FRI soundness, (3) correct verifier implementation. If using Groth16 compression, there's a one-time trusted setup for the compression circuit."

**Q: Can you prove private state machines?**
> "Yes. The guest can maintain private state across multiple proofs using env::pause() to create continuations. The journal only reveals what you commit, so internal state remains private. Composition lets you verify receipts inside guests for complex protocols."

**Q: What's the performance bottleneck?**
> "Proving, specifically the FRI polynomial commitment phase. It's memory-bandwidth bound on CPUs, so GPUs provide massive speedup. Verification is never a bottleneck - it's milliseconds even for gigacycle programs."

### Impressive Examples to Mention

1. **zkML**: Train ML models, prove inference (example: `examples/xgboost/`)
2. **Ethereum Validation**: Prove Ethereum state transitions without running a full node
3. **Voting Machine**: Prove vote tally without revealing individual votes (`examples/voting-machine/`)
4. **Password Checker**: Prove password knowledge without revealing it
5. **Chess**: Prove legal move sequences (`examples/chess/`)

---

## References and Further Reading

### Official Documentation
- **Main Docs**: https://dev.risczero.com
- **API Docs**: https://docs.rs/risc0-zkvm
- **GitHub**: https://github.com/risc0/risc0
- **Examples**: `examples/` directory (27+ examples)

### Technical Papers
- **ZKP Whitepaper**: https://www.risczero.com/proof-system-in-detail.pdf
- **Original STARK Paper** (Ben-Sasson et al, 2018): https://eprint.iacr.org/2018/046.pdf

### Video Resources
- **zkSummit 10 Talk**: https://www.youtube.com/watch?v=wkIBN2CGJdc (architecture overview)
- **Study Club**: `website/docs/studyclub.md`

### External Learning Resources
- **Anatomy of a STARK**: https://aszepieniec.github.io/stark-anatomy
- **STARK 101**: https://starkware.co/stark-101
- **Vitalik's STARK Series**: https://vitalik.eth.limo/general/2017/11/09/starks_part_1.html

### Key Files in Codebase
- Core Receipt: `risc0/zkvm/src/receipt.rs`
- Guest Environment: `risc0/zkvm/src/guest/env/mod.rs`
- Host Prover: `risc0/zkvm/src/host/`
- RISC-V Circuit: `risc0/circuit/rv32im-sys/`
- Bonsai SDK: `bonsai/sdk/src/lib.rs`

---

## Appendix: Common Pitfalls

### 1. Forgetting Image ID Verification
```rust
// BAD: No image ID check
receipt.verify_integrity()?;  // Only checks seal, not code!

// GOOD: Always verify against expected code
receipt.verify(METHOD_ID)?;   // Checks seal + code + journal
```

### 2. Journal Deserialization Order
```rust
// Guest commits in order: A, B, C
env::commit(&value_a);
env::commit(&value_b);
env::commit(&value_c);

// Host MUST decode in same order
let a: TypeA = journal.decode()?;  // Gets value_a
let b: TypeB = journal.decode()?;  // Gets value_b
let c: TypeC = journal.decode()?;  // Gets value_c
```

### 3. Using Dev Mode in Production
```bash
# NEVER do this in production
export RISC0_DEV_MODE=1

# Use disable-dev-mode feature to prevent accidents
[dependencies]
risc0-zkvm = { version = "2.1", features = ["disable-dev-mode"] }
```

### 4. Trusting Receipt Metadata
```rust
// BAD: Security decision based on metadata
if receipt.metadata.version == "2.1.0" {
    // Metadata is not cryptographically bound!
}

// GOOD: Check control ID in claim (cryptographically bound)
let claim = receipt.get_claim()?;
if claim.verifier_parameters.control_id == EXPECTED_CONTROL_ID {
    // This is safe
}
```

### 5. Inefficient Guest Code
```rust
// BAD: Unnecessary allocations in tight loop
for i in 0..1_000_000 {
    let v = vec![i];  // 1M allocations!
    process(v);
}

// GOOD: Reuse buffer
let mut v = vec![0];
for i in 0..1_000_000 {
    v[0] = i;
    process(&v);
}
```

---

**Document Version**: 1.0
**Based on**: RISC Zero v2.1+
**Last Updated**: 2026-01-26
**Repository**: `/Users/ble/ToolsForHumanityResearch/risc0`
