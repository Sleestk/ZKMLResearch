# Proto-Neural-ZKP Interview Guide

## What This Project Does (Simple Explanation)

This is a prototype for **proving "I ran this neural network correctly" without revealing the input data**.

Think of it like proving you solved a Sudoku puzzle correctly without showing your answer sheet.

### The Workflow
```
Image Input → CNN Inference → Output Prediction
                     ↓
              (Plonky2 wraps this in a ZK proof)
                     ↓
        "I computed this correctly" + Cryptographic Proof
```

### Two Implementations
1. **Python/NumPy** (`ref_cnn/`) - Simple CNN, slow but easy to understand (~0.83s per inference)
2. **Rust** (`src/`) - Same CNN logic, **5.5x faster** (~0.15s per inference), plus ZK proof generation using Plonky2

### Architecture
- **Python reference CNN** (`ref_cnn/vanilla_cnn.py`)
- **Rust CNN** with same logic (`src/nn.rs`, `src/layers/`)
- **ZK circuit builder** (`src/lib.rs:148-220`)
- **Plonky2 proof system** (PLONK-based SNARKs)

### The CNN Model (from `src/nn.rs:12-44`)
```
Input: 120x80x3 image
├─ Conv Layer (32 filters, 5x5x3)  → 116x76x32
├─ MaxPool (2x2)                    → 58x38x32
├─ ReLU                             → 58x38x32
├─ Conv Layer (32 filters, 5x5x32) → 54x34x32
├─ MaxPool (2x2)                    → 27x17x32
├─ ReLU                             → 27x17x32
├─ Flatten                          → 14,688
├─ Fully Connected (1000 neurons)   → 1,000
├─ ReLU                             → 1,000
├─ Fully Connected (5 neurons)      → 5
└─ Normalize                        → 5 (output probabilities)
```

---

## Plonky2 vs zkSTARKs (RISC Zero) - Key Differences

| Aspect | **Plonky2** (This Project) | **zkSTARKs** (RISC Zero - on job req!) |
|--------|---------------------------|--------------------------|
| **Proof System** | PLONK (combines SNARKs + STARKs) | Pure STARKs |
| **Trusted Setup** | ❌ None needed | ❌ None needed |
| **Proof Size** | ~45KB (smaller) | ~100KB+ (larger) |
| **Verification Speed** | Faster (~10ms) | Slower (~50ms+) |
| **Approach** | **Circuit-specific**: Custom circuits per operation | **General zkVM**: Write normal Rust code |
| **Developer Experience** | Harder - manual circuit design | Easier - write normal code |
| **Performance** | Faster for specific optimized tasks | Slower but more flexible |
| **Use Case** | Best for fixed computations (fraud detection) | Best for arbitrary programs |

### Simple Analogy
- **Plonky2** = Building a custom calculator for one specific math problem (fast, but rebuild for each problem)
- **RISC Zero** = A general-purpose computer that can solve any problem (flexible, but slower)

### Code Evidence: Plonky2's Circuit Approach

From `src/lib.rs:100-120`, the `dot` function creates a **custom arithmetic circuit**:

```rust
fn dot(builder: &mut Builder, coefficients: &[i32], input: &[Target]) -> Target {
    let mut sum = builder.zero();
    for (&coefficient, &input) in coefficients.iter().zip(input) {
        let coefficient = to_field(coefficient);
        sum = builder.mul_const_add(coefficient, input, sum);  // ← Creates circuit gate
    }
    sum
}
```

**Key point:** Each operation (`mul_const_add`) creates **gates in the circuit**. This is manual work - you're designing math constraints!

With RISC Zero zkVM, you'd just write normal Rust:
```rust
fn dot(coefficients: &[i32], input: &[i32]) -> i32 {
    coefficients.iter().zip(input).map(|(c, i)| c * i).sum()  // ← Normal Rust!
}
```

---

## Proof Generation Costs (Reality Check)

### What the Code Benchmarks (`src/lib.rs:222-280`)

The main function measures:
- **Build time** - Creating the circuit structure
- **Proof time** - Generating the ZK proof
- **Proof memory** - RAM usage during proving
- **Proof size** - Size of the proof file
- **Verify time** - How long to check the proof

### Current State (Important!)

The circuit in `src/lib.rs:148-220` currently only proves **matrix multiplication** (one layer), not the full CNN. This is a **prototype**!

### Estimated Full CNN Proof Costs

For the complete CNN model described in `src/nn.rs`:

| Metric | Value | Note |
|--------|-------|------|
| **Proof Generation Time** | ~10-60 seconds | Per inference (depends on hardware) |
| **Memory Required** | 4-16 GB RAM | During proof generation |
| **Proof Size** | ~45 KB | Very portable! Can post on blockchain |
| **Verification Time** | <100ms | Super fast! Can verify on-chain |

### Why So Expensive?

From `src/nn.rs:18-44`, the CNN has:
- 2 Convolution layers (2,400 + 25,600 parameters)
- 2 MaxPool layers
- 2 ReLU activations
- 2 Fully Connected layers (14,689,000 + 5,005 parameters)
- Normalization

Each operation must become **arithmetic constraints** in the circuit. A single convolution can require **millions of constraints**!

**Trade-off:** Slow to prove, fast to verify, perfect for blockchain use cases.

---

## Model Upgradeability - How It Works

### The Problem
Worldcoin wants to upgrade the IrisCode fraud detection model without requiring a trusted setup each time.

### Solution in This Codebase

**JSON Serialization Pipeline** (see `Readme.md:136-165`):

```
Python Model → JSON → Rust Model → Plonky2 Circuit
```

### Upgrade Process

```bash
# 1. Train new model in Python
python train_new_iris_model.py  # ← New weights

# 2. Export to JSON
python generate_cnn_json.py  # ← Serialize (src/serialize.rs)

# 3. Import in Rust and validate
cargo test serialize::tests::deserialize_model_json -- --show-output

# 4. Generate proofs with new model
cargo run --release  # ← Ready to go!
```

### Why This Matters for Worldcoin

✅ **No trusted setup** - Plonky2 is transparent (no toxic waste)
✅ **Update model weights** - Can change without changing circuit structure
✅ **Old proofs remain valid** - Previous verification logic still works
✅ **Verifiable upgrades** - Can prove model was upgraded legitimately

### The Caveat ⚠️

From the code, **only weights can change**, not architecture!

If you change the CNN structure (add layers, change dimensions), you need to:
1. Rebuild the circuit in `src/nn.rs:12-44`
2. Recompile everything
3. Update verification logic

This is a limitation of circuit-based approaches. RISC Zero would handle this more gracefully.

---

## Security Properties

1. **Privacy**: Input data (iris scans) never revealed - only the proof is public
2. **Verifiability**: Anyone can verify computation was correct without re-running it
3. **Integrity**: Cannot fake fraud detection results - cryptographically bound
4. **Transparency**: No trusted setup (anyone can verify the circuit is correct)

### Cryptographic Assumptions

From `src/lib.rs:82`:
```rust
type C = PoseidonGoldilocksConfig;  // Uses Poseidon hash
type F = <C as GenericConfig<D>>::F;  // Goldilocks field (64-bit)
```

**Assumptions:**
- Discrete log hardness in Goldilocks field
- Poseidon hash collision resistance
- PLONK soundness (well-studied since 2019)

---

## Relevance to D&R Team (Detection & Response)

### Use Cases

1. **Decentralized Fraud Detection**
   - Orb operators prove they ran legitimate fraud filters
   - No need to trust individual operators
   - Proofs can be verified on-chain

2. **Third-Party Model Verification**
   - External parties can run IrisCode model
   - Prove they executed the correct version
   - Can't substitute malicious models

3. **Privacy-Preserving Audits**
   - Blockchain verifies without seeing sensitive iris data
   - Compliance without data exposure
   - Audit trail without privacy loss

4. **Scalable Trust Infrastructure**
   - Scales detection across untrusted infrastructure
   - Don't need to trust every node
   - Cryptographic verification instead of trust

### Real-World Scenario

```
User scans iris at Orb
       ↓
IrisCode model runs (fraud detection)
       ↓
ZK proof generated: "This iris passed fraud checks"
       ↓
Proof posted to blockchain
       ↓
Smart contract verifies proof (100ms)
       ↓
User added to WorldID if valid
```

**Without ZK:** Must trust the Orb operator
**With ZK:** Cryptographic proof, no trust needed

---

## Trade-offs & Challenges

### Strengths ✅
- No trusted setup (transparent)
- Fast verification (milliseconds)
- Small proofs (45 KB)
- Model weights can be updated easily
- Strong cryptographic guarantees

### Challenges ⚠️
- Slow proof generation (seconds to minutes)
- Manual circuit design required
- Architecture changes require circuit rebuilding
- High memory requirements (4-16 GB)
- Limited to fixed computation structures

### When to Use Plonky2 vs Alternatives

**Use Plonky2 when:**
- Computation is fixed (like fraud detection)
- Verification must be on-chain
- Proof size matters (blockchain gas costs)
- Performance is critical (willing to optimize circuits)

**Use RISC Zero when:**
- Computation changes frequently
- Developer velocity matters more
- General-purpose programs (not just ML)
- Willing to accept larger proofs

---

## Alternative Approaches

### 1. RISC Zero (zkVM - mentioned in job requirements!)
- **Pros:** General-purpose, write normal Rust, easier to upgrade
- **Cons:** Slower proving, larger proofs (~100KB+)
- **Best for:** Arbitrary programs, frequent changes

### 2. Trusted Execution Environments (TEEs)
- **Pros:** Fast, no proof generation overhead
- **Cons:** Hardware trust assumptions, side-channel attacks
- **Best for:** Real-time requirements, trusted hardware available

### 3. Multi-Party Computation (MPC)
- **Pros:** No single point of failure, distributed trust
- **Cons:** Complex protocols, network overhead, coordination required
- **Best for:** Multiple parties with conflicting interests

### 4. Homomorphic Encryption
- **Pros:** Compute on encrypted data
- **Cons:** Extremely slow, limited operations
- **Best for:** Cloud computation on private data

---

## Running the Benchmarks (Hands-On Demo)

### Python CNN Benchmark
```bash
cd ref_cnn
python benchmark_cnn.py  # Takes ~13 min for 100 runs on M1 Max
```

**Expected output:** `~0.83s average per inference`

### Rust CNN Benchmark
```bash
# First generate the test data
cd ref_cnn
python generate_cnn_json.py
cd ..

# Run Rust benchmark
cargo bench bench_neural_net
```

**Expected output:** `~151ms per inference` (5.5x faster!)

### ZK Circuit Test (Currently: Matrix Multiplication Only)
```bash
cargo +nightly-2023-08-01 run --release -- -vvv --input-size 1000 --output-size 1000
```

This builds a circuit, generates a proof, and verifies it.

---

## Interview Talking Points

### Technical Understanding
- "I understand Plonky2 uses PLONK-based SNARKs without trusted setup"
- "The circuit approach requires manual optimization but enables fast verification"
- "RISC Zero's zkVM approach trades proof size for developer velocity"

### Business Context
- "For Worldcoin's use case, fixed fraud detection models are perfect for circuit-based approaches"
- "The model upgradeability feature enables continuous improvement without re-setup"
- "Fast verification (<100ms) makes on-chain verification economically viable"

### Trade-offs Awareness
- "Proof generation is expensive (~10-60s), but verification is cheap - good for blockchain"
- "Architecture changes require rebuilding circuits - RISC Zero would be more flexible here"
- "For D&R team, the proof-of-correctness model enables trustless fraud detection at scale"

### Code-Specific Insights
- "The circuit builder in `src/lib.rs` manually constructs arithmetic gates - very different from normal programming"
- "The benchmark shows 5.5x speedup from Rust vs Python, but ZK overhead would be ~100x on top"
- "Serialization pipeline enables Python ML engineers to export models for Rust ZK engineers"

---

## Questions to Ask Interviewer

1. "Is the D&R team currently using RISC Zero (mentioned in job requirements)? How does it compare to Plonky2 in your experience?"

2. "For the IrisCode fraud detection model, how frequently do you expect model updates vs architecture changes?"

3. "What's the acceptable latency for proof generation in your production use cases?"

4. "Are you exploring hybrid approaches - TEEs for speed, ZK for verifiability?"

5. "How do you handle the trade-off between proof generation cost and decentralization benefits?"
