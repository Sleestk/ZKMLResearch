# Range Proof zkVM

A zero-knowledge range proof built with [RISC0](https://www.risczero.com/). The program proves a secret value falls within a given range without ever revealing the value itself.

**Concrete example:** prove you are at least 18 years old without disclosing your exact age.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Core Concepts](#core-concepts)
3. [Guest Program](#guest-program--methodsguestsrcmainrs)
4. [Host Program](#host-program--hostsrcmainrs)
5. [Data Flow](#data-flow)
6. [The Zero-Knowledge Property](#the-zero-knowledge-property)
7. [How to Run](#how-to-run)
8. [Test Scenarios](#test-scenarios)
9. [Common Pitfalls](#common-pitfalls)
10. [Real-World Applications](#real-world-applications)
11. [RISC0 API Reference](#risc0-api-quick-reference)

---

## Project Structure

```
zkVM/
├── Cargo.toml                      # Workspace root (dev profile forces opt-level 3)
├── host/
│   ├── Cargo.toml
│   └── src/
│       └── main.rs                 # Host: supplies inputs, runs prover, verifies receipt
└── methods/
    ├── Cargo.toml
    ├── build.rs                    # Calls risc0_build::embed_methods() at compile time
    ├── src/
    │   └── lib.rs                  # Re-exports the generated METHOD_ELF and METHOD_ID
    └── guest/
        ├── Cargo.toml
        └── src/
            └── main.rs             # Guest: private computation inside the zkVM
```

### Build-time code generation

`methods/build.rs` calls `risc0_build::embed_methods()`. During compilation this:

1. Compiles the guest crate into a RISC-V ELF binary.
2. Generates a Rust source file that exposes two constants:
   - `METHOD_ELF` — the raw ELF bytes the prover executes.
   - `METHOD_ID` — a cryptographic image identifier used during verification.

`methods/src/lib.rs` pulls that generated file in with `include!`. The host imports both constants via `use methods::{METHOD_ELF, METHOD_ID}`.

---

## Core Concepts

RISC0 splits a zero-knowledge proof program into two distinct roles:

| Role | Runs where | Sees private data? | Responsibility |
|------|-----------|-------------------|----------------|
| **Host** | Your machine (untrusted) | Yes — it creates the inputs | Serializes inputs, invokes the prover, reads the public journal, verifies the receipt |
| **Guest** | Inside the zkVM (isolated) | Yes — but nothing outside can observe it | Reads inputs, performs computation, commits public outputs to the journal |

The verifier (anyone holding the receipt) can confirm the computation was performed correctly **without** learning any value the guest did not explicitly commit.

---

## Guest Program — `methods/guest/src/main.rs`

```rust
use risc0_zkvm::guest::env;

fn main() {
    // Read three private inputs (order must match host writes)
    let age:     u32 = env::read();
    let min_age: u32 = env::read();
    let max_age: u32 = env::read();

    // Range check — runs entirely inside the zkVM
    let is_adult: bool = age >= min_age && age <= max_age;

    // Commit only the boolean result to the public journal
    env::commit(&is_adult);
}
```

### Line-by-line

| Line(s) | What happens |
|---------|--------------|
| `env::read()` ×3 | Deserializes three `u32` values from the host in FIFO order. The guest has no other input channel. |
| `age >= min_age && age <= max_age` | The actual range check. Executes inside the zkVM — no outside observer can see intermediate values. |
| `env::commit(&is_adult)` | Writes the single `bool` result to the journal. This is the **only** value that leaves the zkVM. |

**What stays private:** `age`, `min_age`, and `max_age` are all private in this implementation. None of them are committed to the journal.

---

## Host Program — `host/src/main.rs`

```rust
use methods::{METHOD_ELF, METHOD_ID};
use risc0_zkvm::{default_prover, ExecutorEnv};

fn main() {
    // 1. Logging setup
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::filter::EnvFilter::from_default_env())
        .init();

    // 2. Define inputs
    let age:     u32 = 25;   // secret value — never leaves the zkVM
    let min_age: u32 = 18;   // lower bound
    let max_age: u32 = 123;  // upper bound

    // 3. Serialize inputs into the executor environment
    //    Write order MUST match the guest's read order
    let env = ExecutorEnv::builder()
        .write(&age)     .unwrap()   // 1st read in guest
        .write(&min_age) .unwrap()   // 2nd read in guest
        .write(&max_age) .unwrap()   // 3rd read in guest
        .build()         .unwrap();

    // 4. Generate the proof
    let prover    = default_prover();
    let prove_info = prover.prove(env, METHOD_ELF).unwrap();
    let receipt   = prove_info.receipt;

    // 5. Read the public output from the journal
    let is_valid: bool = receipt.journal.decode().unwrap();
    println!("Is valid age: {:?}", is_valid);

    // 6. Verify the proof against the guest image ID
    receipt.verify(METHOD_ID).unwrap();
}
```

### Step-by-step

| Step | API | Purpose |
|------|-----|---------|
| 1 | `tracing_subscriber` | Enables structured logging. Run with `RUST_LOG=info` to see output. |
| 2 | literals | Defines the three `u32` inputs. Only `age` is the secret; all three are private because none are committed by the guest. |
| 3 | `ExecutorEnv::builder().write()` | Serializes each input into the guest's input stream. Order is critical — must mirror `env::read()` calls in the guest. |
| 4 | `default_prover().prove()` | Executes the guest ELF inside the zkVM and produces a cryptographic proof. The receipt is verified automatically at the end of this call. |
| 5 | `receipt.journal.decode()` | Deserializes the single committed value (`is_adult: bool`) from the journal. |
| 6 | `receipt.verify(METHOD_ID)` | Explicit re-verification. Confirms the proof is valid for exactly this guest binary. |

---

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│  Host  (host/src/main.rs)                               │
│                                                         │
│   age = 25, min_age = 18, max_age = 123                 │
│        │                                                │
│        │  ExecutorEnv::builder().write() ×3             │
│        ▼                                                │
│   ┌─────────────┐    prove(env, METHOD_ELF)             │
│   │ ExecutorEnv │ ──────────────────────────┐           │
│   └─────────────┘                           │           │
│                                             ▼           │
│              ┌──────────────────────────────────────┐   │
│              │  zkVM  (isolated execution)          │   │
│              │                                      │   │
│              │   env::read() → age      (25)       │   │
│              │   env::read() → min_age  (18)       │   │
│              │   env::read() → max_age  (123)      │   │
│              │                                      │   │
│              │   is_adult = age >= min_age          │   │
│              │                && age <= max_age     │   │
│              │                                      │   │
│              │   env::commit(&is_adult)  ──────┐    │   │
│              │                                 │    │   │
│              │   age, min_age, max_age         │    │   │
│              │   never leave this box          │    │   │
│              └─────────────────────────────────┼────┘   │
│                                                │         │
│              Journal (public)                  │         │
│              ┌──────────────────┐              │         │
│              │ is_adult: true   │ ◄────────────┘         │
│              └──────────────────┘                        │
│                       │                                  │
│                       ▼                                  │
│              receipt.journal.decode() → true             │
│              receipt.verify(METHOD_ID)  → OK             │
└─────────────────────────────────────────────────────────┘
```

---

## The Zero-Knowledge Property

After execution a verifier holding the receipt can confirm:

- The guest program identified by `METHOD_ID` was executed.
- The computation completed without errors.
- The output committed to the journal is `true`.

The verifier **cannot** determine:

- What `age` was.
- What `min_age` or `max_age` were.

This is the ZK guarantee: **prove a statement about private data without revealing the data itself.** The only information that crosses the boundary is what the guest explicitly writes via `env::commit()`.

---

## How to Run

### Dev mode — fast, proof is simulated

```bash
RISC0_DEV_MODE=1 cargo run
```

Use this during development. The prover skips actual cryptographic work so iteration is fast. The receipt **cannot** be verified by a third party.

### Production mode — real cryptographic proof

```bash
cargo run --release
```

Generates a real SNARK proof. Slower, but the receipt is verifiable by anyone who trusts the `METHOD_ID`.

### Logging

```bash
RUST_LOG=info cargo run
```

Enables the tracing output configured in the host.

---

## Test Scenarios

Change the `age` value in `host/src/main.rs` and re-run to exercise different paths:

| `age` | `min_age` | `max_age` | Expected output | Why |
|-------|-----------|-----------|-----------------|-----|
| 25    | 18        | 123       | `true`          | Normal valid case |
| 15    | 18        | 123       | `false`         | Below lower bound |
| 130   | 18        | 123       | `false`         | Above upper bound |
| 18    | 18        | 123       | `true`          | Exactly the lower bound (inclusive `>=`) |
| 123   | 18        | 123       | `true`          | Exactly the upper bound (inclusive `<=`) |
| 17    | 18        | 123       | `false`         | One below lower bound |
| 124   | 18        | 123       | `false`         | One above upper bound |
| 0     | 18        | 123       | `false`         | Zero / minimum `u32` |

---

## Common Pitfalls

| Mistake | What happens |
|---------|--------------|
| `write()` and `read()` order mismatch | Guest reads the wrong values. The proof still passes because the computation itself is valid — but the semantics are wrong. |
| Committing the secret to the journal | The secret becomes public. Anyone with the receipt can read it. |
| Decoding more values than were committed | `journal.decode()` panics at runtime. |
| Assuming dev-mode receipts are real proofs | `RISC0_DEV_MODE=1` skips proving entirely. Receipts from dev mode are not verifiable by third parties. |
| Forgetting `opt-level = 3` in dev | Guest compilation and execution is significantly slower without it. The workspace `Cargo.toml` already sets this. |

---

## Real-World Applications

The pattern — *prove a value satisfies a predicate without revealing the value* — applies broadly:

- **Age / KYC gating** — prove age >= 18 for regulatory compliance.
- **Credit scoring** — prove credit score >= a lender's threshold.
- **Income verification** — prove income falls within a loan-eligibility range.
- **Auction bids** — prove a bid >= the reserve price without revealing the bid.
- **Health / insurance** — prove a health metric is within an acceptable range.
- **Wealth attestation** — prove account balance >= a minimum without revealing the balance.

---

## RISC0 API Quick Reference

| Symbol | Type | Description |
|--------|------|-------------|
| `METHOD_ELF` | `&[u8]` | Compiled guest binary (RISC-V ELF). Generated at build time by `risc0_build`. |
| `METHOD_ID` | `[u8; 32]` | Image identifier for the guest. Used to pin verification to a specific guest binary. |
| `ExecutorEnv` | struct | Represents the guest's execution environment, including serialized inputs. |
| `ExecutorEnv::builder().write(&v)` | method | Serializes a value into the guest's input stream. |
| `default_prover()` | fn | Returns the default RISC0 prover (CPU-based). |
| `prover.prove(env, elf)` | fn | Executes the guest and returns a `ProveInfo` containing the receipt. |
| `receipt.journal.decode::<T>()` | method | Deserializes the next committed value from the journal. |
| `receipt.verify(method_id)` | method | Cryptographically verifies the receipt against a method ID. |
| `env::read::<T>()` | fn (guest) | Reads the next value from the host-provided input stream. |
| `env::commit(&v)` | fn (guest) | Appends a value to the public journal. |
