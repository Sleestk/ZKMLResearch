# zkVM Performance Analysis
## RISC Zero vs SP1 - Comprehensive Benchmark Study

---

## Overview

This document analyzes zkVM (zero-knowledge virtual machine) performance characteristics based on two comprehensive benchmark repositories:

- **zkvm-perf**: Automated benchmarking framework for SP1 and RISC Zero across diverse workloads
- **zkvm-compare**: Direct comparison framework for RISC Zero and SP1 on specific computational tasks

Both frameworks provide critical insights for choosing the right zkVM for production workloads, particularly for fraud detection systems that need to scale to billions of users.

---

## Repository Analysis

### zkvm-perf

**Purpose**: Large-scale automated benchmarking on cloud infrastructure (AWS EC2)

**Key Features**:
- Automated GitHub Actions workflows for consistent benchmarking
- Matrix testing across GPU (g6.16xlarge) and CPU (r7i.16xlarge) instances
- Comprehensive program suite covering diverse computational patterns
- CSV output for detailed performance analysis

**Benchmark Programs**:

| Category | Programs | Purpose |
|----------|----------|---------|
| **Loop Iterations** | loop10k → loop100m | Pure computational cycles (10K to 100M iterations) |
| **Fibonacci** | fibonacci20k → fibonacci4b | Arithmetic-heavy workload with memory updates |
| **Cryptographic Hashing** | sha256, keccak256 (100KB → 10MB) | Hash function performance under ZK constraints |
| **Blockchain Workloads** | tendermint, reth, rsp | Real-world consensus & execution verification |
| **Advanced Crypto** | ecdsa-verify, eddsa-verify, groth16, zk-email | Signature verification and recursive proofs |
| **Light Client** | helios | Ethereum light client verification |
| **SSZ** | ssz-withdrawals | Ethereum consensus layer data structures |

**Architecture**:
- `sweep.py`: Orchestrates benchmark sweeps across program/prover/parameter combinations
- `eval.sh`: Builds programs and runs individual benchmarks with GPU detection
- Programs compiled conditionally for SP1 or RISC Zero via feature flags
- Results captured with machine instance type for CPU/GPU comparison

### zkvm-compare

**Purpose**: Focused performance comparison on specific computational patterns

**Key Features**:
- Direct RISC Zero vs SP1 comparison
- Segment size configurability (critical for performance tuning)
- Multiple hardware acceleration options (Metal, CUDA, CPU)
- Parameterized workload sizes for scaling analysis

**Benchmark Workloads**:

| Workload | Sizes Tested | Purpose |
|----------|--------------|---------|
| **hello-world** | N/A | Baseline zkVM overhead |
| **sha2** | 1KB → 32KB | Hash function performance scaling |
| **fib** | 128K → 32M iterations | Arithmetic and loop performance |
| **sort** | Various sizes | Memory access patterns and algorithms |
| **big-input** | Multiple variants | Input data handling efficiency |

**Architecture**:
- `bench/`: Main benchmark runner with VM abstraction
- `common/`: Shared workload implementations
- `guest-r0/`, `guest-sp1/`: zkVM-specific guest programs
- Configurable segment sizes (20-22 typically, representing 2^20 to 2^22 cycles)

---

## zkVM Architecture Comparison

### RISC Zero

**Proof System**: zk-STARKs (Scalable Transparent Arguments of Knowledge)

**Key Characteristics**:

| Aspect | Details |
|--------|---------|
| **Programming Model** | Guest/Host architecture - Rust code compiled to RISC-V |
| **Proof System** | STARKs (FRI-based polynomial commitments) |
| **Setup Requirements** | **Transparent** - no trusted setup required |
| **Proof Size** | Larger (~100KB-1MB typical) due to STARK overhead |
| **Verification Time** | Fast (~milliseconds), logarithmic in computation size |
| **Prover Time** | Slower than SNARKs for small circuits, competitive at scale |
| **Recursion** | Native support via composition proofs |
| **Post-Quantum** | **Yes** - resistant to quantum attacks |
| **Hash Function** | Poseidon (ZK-friendly) |
| **Segment Size** | Configurable (2^20 - 2^22 cycles typical) |

**Docker Integration**: RISC Zero requires Docker for proving operations, which:
- Ensures reproducible proof generation across environments
- Adds startup overhead (image download/container initialization)
- Enables consistent toolchain management

**Implementation Details**:
```rust
// Guest program entry point
risc0_zkvm::guest::entry!(main);

// Reading inputs from host
let n: u32 = risc0_zkvm::guest::env::read();

// Generating receipts (proofs)
// Host calls prove() which returns Receipt containing:
// - Journal (public outputs)
// - Seal (cryptographic proof)
```

### SP1 (Succinct Proof 1)

**Proof System**: Optimized STARK-to-SNARK pipeline

**Key Characteristics**:

| Aspect | Details |
|--------|---------|
| **Programming Model** | Similar guest/host, custom RISC-V target (riscv32im-succinct-zkvm-elf) |
| **Proof System** | Hybrid STARK→SNARK (uses native-gnark for final compression) |
| **Setup Requirements** | Universal setup (reusable across programs) |
| **Proof Size** | Smaller than pure STARKs due to SNARK compression |
| **Verification Time** | Very fast (constant time, ~milliseconds) |
| **Prover Time** | Optimized with GPU acceleration support |
| **Recursion** | Efficient via SNARK composition |
| **Shard Size** | Configurable (influences parallelization) |
| **Optimizations** | Target-specific optimizations, native-gnark integration |

**Shard Size Configuration**: SP1 uniquely supports different shard sizes (not available in RISC Zero for this benchmark suite):
- Shard size = 2^N (e.g., 22 = ~4M cycles per shard)
- Larger shards: fewer shards, less overhead, but higher memory requirements
- Smaller shards: better parallelization, more overhead per shard

**Implementation Details**:
```rust
// Guest program entry point
sp1_zkvm::entrypoint!(main);

// Reading inputs from host
let n: u32 = sp1_zkvm::io::read();

// SP1 specific optimizations:
// - Program cache disabled in benchmarks (SP1_DISABLE_PROGRAM_CACHE=true)
// - CUDA acceleration when available
// - Native GNARK proving backend
```

---

## Performance Metrics Explained

### Key Performance Indicators

**1. Proof Generation Time**
- Time to generate a cryptographic proof of correct execution
- **Critical for scalability**: Determines throughput of provable computation
- **Hardware dependent**: GPU acceleration can provide 10-100x speedup
- **Workload dependent**: Complex operations (hashing, signatures) are slower to prove

**2. Verification Time**
- Time to verify a proof on-chain or off-chain
- **Critical for blockchain integration**: Must fit in block gas limits
- **Generally fast**: Both zkVMs optimize for quick verification (~ms)
- **SNARK advantage**: Constant-time verification vs logarithmic for pure STARKs

**3. Proof Size**
- Size of the generated proof in bytes
- **Critical for on-chain publishing**: Ethereum calldata costs ~16 gas/byte
- **Trade-off**: Smaller proofs cost less to publish but may take longer to generate
- **STARK disadvantage**: Larger proofs (100KB-1MB) vs SNARKs (few KB)

**4. Memory Usage**
- Peak RAM during proof generation
- **Critical for hardware requirements**: Determines prover machine specs
- **Segment/shard size impact**: Larger segments = more memory but fewer segments

**5. Cycles Executed**
- Number of RISC-V instructions executed in the guest program
- **Determines proof cost**: More cycles = longer proof time
- **Optimization target**: Efficient guest code reduces proving costs

---

## Workload Characteristics

### 1. Loop Iterations (Computational Overhead)

**What it tests**: Pure zkVM execution overhead with minimal memory operations

**Programs**: `loop10k` → `loop100m` (10,000 to 100 million iterations)

**Implementation**:
```rust
for i in 0..iterations {
    memory_barrier(&i);  // Prevents optimization
}
```

**Why it matters**:
- Measures base cost of zkVM instruction execution
- Indicates how efficiently the zkVM handles RISC-V instructions
- Pure arithmetic workloads (ML inference, numerical computation) scale similarly

**Expected behavior**:
- Near-linear scaling with iteration count
- GPU acceleration shows biggest impact at high iteration counts
- SP1's optimized RISC-V target may show advantages

### 2. Fibonacci Sequence (Arithmetic + Memory)

**What it tests**: Arithmetic operations with register state updates

**Programs**: `fibonacci20k` → `fibonacci4b` (20K to 4 billion iterations)

**Implementation**:
```rust
fn fibonacci(n: u32) -> u32 {
    let mut a = 0;
    let mut b = 1;
    for _ in 0..n {
        let sum = (a + b) % 7919;  // Modulo prevents overflow
        a = b;
        b = sum;
    }
    b
}
```

**Why it matters**:
- Models ML inference patterns (accumulation, state updates)
- Tests how zkVM handles register allocation and memory
- Representative of CNN layer computations

**Expected behavior**:
- Similar to loop iteration but slightly higher overhead
- Modulo operation adds arithmetic complexity
- Good indicator for neural network layer proving costs

### 3. Cryptographic Hashing (SHA-256, Keccak-256)

**What it tests**: ZK-unfriendly hash functions under zkVM constraints

**Programs**: `sha256100kb` → `sha25610mb`, `keccak256100kb` → `keccak25610mb`

**Why it matters**:
- Essential for blockchain state verification (Ethereum uses Keccak-256)
- Tests zkVM performance on non-ZK-friendly operations
- Iris verification likely involves cryptographic operations

**Expected behavior**:
- **Significantly slower** than native execution
- Each hash operation requires proving many RISC-V instructions
- RISC Zero uses Poseidon internally, but guest code can use SHA-256/Keccak
- Critical bottleneck for blockchain verification workloads

### 4. Blockchain Workloads

**Tendermint**: Consensus layer verification (validator signature checks)

**Reth**: Ethereum execution layer block processing

**RSP**: Ethereum block processing with different block numbers

**Why it matters**:
- Real-world ZK applications (light clients, rollups)
- Combines signature verification, hashing, and state transitions
- Models fraud detection verification complexity

**Expected behavior**:
- Most complex benchmarks (thousands to millions of cycles)
- Signature verification (ECDSA/EdDSA) is particularly expensive
- GPU acceleration critical for practical performance

### 5. Advanced Cryptographic Operations

**ECDSA/EdDSA Verify**: Elliptic curve signature verification

**Groth16 Verify**: Recursive proof verification (proof of a proof)

**ZK-Email**: Email DKIM signature verification in ZK

**Helios**: Ethereum consensus light client

**Why it matters**:
- Recursive proofs enable proof aggregation (critical for scaling)
- Signature verification common in fraud detection
- Tests zkVM capability for complex cryptographic primitives

**Expected behavior**:
- Extremely expensive (millions of cycles)
- GPU acceleration essential
- May benefit from precompiles/accelerators in future zkVM versions

---

## Hardware Acceleration: GPU vs CPU

### GPU Acceleration (NVIDIA CUDA)

**Benchmark Setup**:
- **zkvm-perf**: g6.16xlarge (NVIDIA L4 Tensor Core GPU)
- **zkvm-compare**: g4dn.xlarge, g6.xlarge, g6.16xlarge

**When GPU helps**:
- **Large proof generation**: Highly parallel cryptographic operations (FFTs, multi-scalar multiplication)
- **High iteration counts**: loop100m, fibonacci4b scale well
- **Complex workloads**: Blockchain verification, signature checking

**GPU Speedup Expectations**:
- **10-50x** for large programs (fibonacci4b, reth blocks)
- **5-20x** for medium programs (fibonacci20m, tendermint)
- **<5x** for small programs (overhead dominates)

**GPU Trade-offs**:
- Higher cloud costs (~$4-8/hour for g6.16xlarge vs ~$1-2/hour for CPU)
- Warmup overhead (CUDA initialization, memory transfers)
- Not cost-effective for small proofs

### CPU Optimization

**Benchmark Setup**:
- **zkvm-perf**: r7i.16xlarge (64 vCPU, AVX-512 support)
- **zkvm-compare**: r7i.16xlarge

**CPU Optimizations Applied**:
```bash
# AVX-512 acceleration
export RUSTFLAGS="-C target-cpu=native -C target-feature=+avx512ifma,+avx512vl"
```

**When CPU is sufficient**:
- Small to medium proofs (fibonacci20k-200k, loop10k-1m)
- Development/testing (faster iteration, lower cost)
- Batch processing (queue multiple proofs across CPU cores)

**CPU Trade-offs**:
- Lower hourly cost but longer proof times
- Better for sustained throughput (queue many proofs)
- Adequate for non-latency-sensitive workloads

---

## Decision Framework: When to Choose Each zkVM

### Choose RISC Zero When:

✅ **Transparency is critical**
- No trusted setup required (fully transparent STARKs)
- Easier regulatory compliance
- Public auditability of the proof system

✅ **Post-quantum security matters**
- STARKs are quantum-resistant
- Important for long-term security guarantees

✅ **General-purpose computation flexibility**
- Any Rust code compiles to RISC-V → works in zkVM
- Rapid iteration on detection algorithms
- No need for custom circuit design

✅ **You prioritize verification speed**
- Fast verification critical for on-chain scenarios
- Logarithmic verification time scaling

✅ **Proof size is not the bottleneck**
- Off-chain verification (don't pay for calldata)
- Storage/bandwidth costs are manageable

### Choose SP1 When:

✅ **Proof size minimization is critical**
- On-chain verification on Ethereum (calldata costs matter)
- SNARK compression reduces proof size significantly

✅ **Prover performance is the priority**
- Optimized RISC-V target and STARK→SNARK pipeline
- Better GPU utilization in many workloads

✅ **You need advanced shard size tuning**
- Configurable shard sizes for optimal parallelization
- Fine-tune memory/parallelism trade-offs

✅ **You want fast constant-time verification**
- SNARK verification is O(1) regardless of computation size

✅ **Ecosystem momentum matters**
- SP1 has active development and growing adoption
- Strong Succinct Labs support and tooling

### Hybrid Approach (Most Production Systems)

🔄 **Combine both based on workload**:

**RISC Zero for**:
- Exploratory/development phase (rapid iteration)
- Transparent audit requirements
- Complex, evolving fraud detection logic

**SP1 for**:
- Production on-chain verification (minimize gas costs)
- High-throughput proving infrastructure (optimize GPU usage)
- Proof aggregation and recursion

---

## Scaling Implications for Fraud Detection

### The Challenge: Scaling to 1 Billion Users

**Current Worldcoin Scale**:
- 17M+ verified users
- 350K+ weekly verifications
- Growing rapidly toward 1B+ target

**Proof Generation Requirements** (hypothetical):

| Scenario | Daily Verifications | Proofs/Second | Hardware Requirement |
|----------|-------------------|---------------|---------------------|
| Current (350K/week) | 50,000 | 0.58 | 1-2 GPU instances |
| 10x Growth | 500,000 | 5.8 | 10-20 GPU instances |
| 100x Growth | 5,000,000 | 57.9 | 100-200 GPU instances |
| 1B users (1% daily active) | 10,000,000 | 115.7 | 200-400 GPU instances |

**Assumptions**:
- Average proof time: ~2 seconds on GPU (varies by workload)
- Batch processing possible (prove multiple verifications together)
- Proof aggregation reduces total proof count

### Cost Analysis

**RISC Zero Proof Publishing Costs** (Ethereum mainnet):

| Proof Size | Calldata Cost | At $3000 ETH | Per Million Proofs |
|------------|--------------|--------------|-------------------|
| 100 KB | ~1.6M gas | ~$6-10 | $6-10M |
| 500 KB | ~8M gas | ~$30-50 | $30-50M |
| 1 MB | ~16M gas | ~$60-100 | $60-100M |

**SP1 Proof Publishing Costs** (with SNARK compression):

| Proof Size | Calldata Cost | At $3000 ETH | Per Million Proofs |
|------------|--------------|--------------|-------------------|
| 5 KB | ~80K gas | ~$0.30-0.50 | $300K-500K |
| 10 KB | ~160K gas | ~$0.60-1.00 | $600K-1M |

**This is why SP1's SNARK compression matters for production at scale.**

### Optimization Strategies

**1. Proof Aggregation (Recursive Proofs)**
- Prove N verifications individually (parallel)
- Generate single proof that "I verified N proofs correctly"
- Reduces on-chain verification to 1 proof per batch

**Example**: Instead of publishing 1000 proofs, publish 1 aggregated proof:
- RISC Zero: 1000 × 500KB = 500MB → 1 × 500KB proof
- SP1: 1000 × 10KB = 10MB → 1 × 10KB proof
- **1000x reduction in on-chain costs**

**2. Merkle Batch Commitments**
- Commit to batch of verification results (Merkle root)
- Only publish root on-chain (32 bytes)
- Publish full proofs to IPFS/data availability layer
- Challenge period allows fraud proof if incorrect

**Example**: 1M verifications/day:
- On-chain: 1 Merkle root per day (32 bytes × 365 = 11.6 KB/year)
- Off-chain: Full proofs on Arweave/Celestia

**3. Optimistic Verification**
- Assume verifications are correct by default
- Only generate proofs when challenged
- Slashing mechanism for incorrect claims

**Trade-off**: Reduces proving costs by 99%+ but adds fraud proof latency

**4. Specialized Hardware**
- ZK ASICs (e.g., Ingonyama's FPGA chips)
- Custom silicon for FFTs and MSMs
- **Expected**: 10-100x improvement over GPU

---

## Performance Bottlenecks by Workload

### 1. Loop Iterations
- **Bottleneck**: Basic zkVM instruction overhead
- **Optimization**: Minimal (already efficient)
- **Scaling**: Linear with iteration count

### 2. Fibonacci / Arithmetic
- **Bottleneck**: Register allocation and modular arithmetic
- **Optimization**: Compiler optimizations, efficient RISC-V target
- **Scaling**: Linear with iteration count

### 3. Cryptographic Hashing
- **Bottleneck**: Many RISC-V instructions per hash operation
- **Optimization**: ZK-friendly hash precompiles (Poseidon, BLAKE3)
- **Scaling**: Linear with data size

### 4. Signature Verification (ECDSA/EdDSA)
- **Bottleneck**: Elliptic curve operations (millions of cycles)
- **Optimization**: Precompiles or dedicated accelerators
- **Scaling**: Linear with number of signatures

### 5. Blockchain Verification
- **Bottleneck**: Combination of all above (hashing + signatures + state)
- **Optimization**: Recursive proofs, batching, optimized guest code
- **Scaling**: Depends on block complexity

---

## Practical Recommendations

### For Fraud Detection System Development

**Phase 1: Prototype (Current)**
- **Use RISC Zero** for rapid iteration
- Focus on detection algorithm logic, not proof optimization
- Transparent proofs easier to audit and debug
- No trusted setup complexity

**Phase 2: Optimization (6-12 months)**
- Benchmark specific fraud detection workloads on both zkVMs
- Measure proof generation time for realistic detection models
- Profile where cycles are spent (signature verification, hashing, ML inference)
- Consider hybrid approach (RISC Zero for complex logic, SP1 for on-chain verification)

**Phase 3: Production Scale (12-24 months)**
- **Switch to SP1** for on-chain proof publishing
- Implement proof aggregation (batch 1000+ verifications per proof)
- Use GPU infrastructure for proving (g6.16xlarge or equivalent)
- Optimize guest code to minimize cycles

### Key Performance Tuning Parameters

**Segment/Shard Size** (for SP1):
- Start with 2^22 (4M cycles/shard)
- Increase for high-memory workloads
- Decrease for better GPU parallelization

**Batch Size**:
- Prove multiple verifications in single guest program
- Trade-off: memory usage vs proof efficiency
- Sweet spot: 100-1000 verifications per proof

**Hardware Selection**:
- Development: CPU instances (r7i.16xlarge)
- Production: GPU instances (g6.16xlarge or multi-GPU)
- Consider spot instances for cost optimization (proving is interruptible)

---

## Key Questions Answered

### Q1: When would you choose RISC Zero over SP1?

**Choose RISC Zero when**:
1. **Transparency matters**: No trusted setup, easier regulatory compliance
2. **Post-quantum security required**: STARKs are quantum-resistant
3. **Rapid development**: General-purpose zkVM, any Rust code works
4. **Off-chain verification**: Proof size doesn't matter
5. **Long-term security**: Transparent cryptography reduces attack surface

**Choose SP1 when**:
1. **On-chain verification**: SNARK compression minimizes gas costs
2. **Proof size critical**: 10-100x smaller proofs than pure STARKs
3. **Performance optimized**: Better prover performance in many workloads
4. **Verification speed**: Constant-time SNARK verification
5. **Ecosystem momentum**: Active development, growing adoption

### Q2: What are the performance implications at scale?

**For 1B users**:

**Proof Generation**:
- **Without optimization**: 10M proofs/day = 200-400 GPU instances = $1-2M/month
- **With aggregation (1000x)**: 10K proofs/day = 1-2 GPU instances = $5-10K/month
- **Critical**: Proof aggregation is essential for economic viability

**On-Chain Publishing**:
- **RISC Zero** (500KB proofs): ~$50M/month for 10M proofs (prohibitive)
- **SP1** (10KB proofs): ~$1M/month for 10M proofs (expensive but viable)
- **With aggregation**: ~$50K/month (10K proofs) - economically sustainable

**Latency**:
- Proof generation: 1-10 seconds (GPU) to 10-60 seconds (CPU)
- Verification: <100ms for both zkVMs
- Aggregation adds: +10-30 seconds per batch
- **Total latency**: 30-60 seconds for aggregated verification (acceptable for fraud detection)

### Q3: How do GPU vs CPU affect proof generation?

**GPU Advantages**:
- **10-50x faster** for large programs (millions of cycles)
- Parallel cryptographic operations (FFT, MSM)
- Essential for production throughput

**GPU Disadvantages**:
- Higher cost ($4-8/hour vs $1-2/hour)
- Warmup overhead (CUDA initialization)
- Not efficient for small proofs

**When to use GPU**:
- Production proving infrastructure
- High iteration workloads (fibonacci2b+, loop10m+)
- Blockchain verification (reth, tendermint)
- Signature verification (ecdsa, eddsa)
- **Throughput > cost** (latency-sensitive applications)

**When CPU is sufficient**:
- Development and testing
- Small proofs (fibonacci20k-200k, loop10k-1m)
- Batch processing (queue proofs, process overnight)
- **Cost > throughput** (non-urgent workloads)

**Hybrid Strategy**:
- CPU for development, testing, small proofs
- GPU for production, large proofs, time-sensitive verification
- Auto-scaling: CPU baseline + GPU spot instances for spikes

---

## Benchmarking Best Practices

### Running zkvm-perf

**Local benchmarking**:
```bash
# Install toolchains
curl -L https://sp1.succinct.xyz | bash && sp1up
curl -L https://risczero.com/install | bash && rzup install

# Run single benchmark
./eval.sh fibonacci sp1 poseidon 22 benchmark

# Run sweep
python3 sweep.py --programs fibonacci loop10k --provers sp1 risc0 --trials 3
```

**Automated cloud benchmarking**:
1. Fork repository and set up AWS credentials
2. Configure GitHub Actions secrets
3. Trigger "Execute ZKVM-Perf (Matrix)" workflow
4. Download CSV artifacts from completed runs

### Running zkvm-compare

**Setup**:
```bash
# Build SP1 guest program
cd guest-sp1 && cargo prove build

# Run all benchmarks
bash -x run-all.sh cuda g6.16xlarge sp1 21 >> run.log 2>&1
```

**Interpreting results**:
- Compare segment sizes (20, 21, 22) for same workload
- Measure scaling: how does proof time grow with input size?
- Profile cycle counts: where is guest program spending time?

---

## Future Optimizations

### zkVM Roadmap (Industry-wide)

**1. Hardware Acceleration**
- Specialized ZK ASICs (Ingonyama, Cysic)
- Custom FPGA acceleration for FFT/MSM
- **Expected impact**: 10-100x improvement

**2. Precompiles/Accelerators**
- Native support for SHA-256, Keccak, ECDSA
- Reduce cycles for common operations by 100-1000x
- Critical for blockchain verification workloads

**3. Proof Compression**
- Recursive SNARK composition
- Folding schemes (Nova, SuperNova)
- **Expected impact**: 1000x proof aggregation efficiency

**4. Compiler Optimizations**
- RISC-V instruction scheduling for zkVM constraints
- Loop unrolling, vectorization for ZK
- **Expected impact**: 2-5x reduction in cycles

### Worldcoin-Specific Optimizations

**1. Fraud Model Optimization**
- Profile detection algorithm cycles
- Replace expensive operations with ZK-friendly alternatives
- Minimize cryptographic operations in guest code

**2. Batch Verification**
- Process 1000+ verifications per proof
- Merkle tree aggregation of results
- Parallel proof generation across GPU cluster

**3. Optimistic Detection**
- Publish Merkle commitments by default
- Generate proofs only when challenged
- Slashing for false fraud claims

**4. Tiered Verification**
- Quick heuristic checks (no ZK)
- Medium confidence (cheap proofs)
- High confidence (expensive but thorough proofs)
- Adaptive based on fraud risk score

---

## Conclusion

Both RISC Zero and SP1 are production-ready zkVMs with different trade-offs:

**RISC Zero excels at**:
- Transparent, post-quantum secure proofs
- General-purpose computation flexibility
- Rapid development iteration

**SP1 excels at**:
- On-chain verification (minimized proof size and gas costs)
- Optimized prover performance
- SNARK-based proof compression

**For Worldcoin fraud detection**:

**Development Phase** → RISC Zero
- Rapid iteration on detection algorithms
- Transparent proofs easier to audit
- No trusted setup complexity

**Production Phase** → SP1 (with RISC Zero for complex logic)
- On-chain verification requires SNARK compression
- Proof aggregation essential for economic scalability
- GPU infrastructure for throughput

**Key Insight**: The choice isn't binary. Production systems should use **both**:
- RISC Zero for transparent computation and complex detection logic
- SP1 for on-chain proof publishing and verification

**Critical Success Factors**:
1. **Proof aggregation**: 1000x cost reduction is non-negotiable at scale
2. **GPU infrastructure**: Essential for production throughput
3. **Optimized guest code**: Profile and minimize cycles in detection algorithms
4. **Hybrid architecture**: Use right zkVM for each component

The path to 1 billion users requires not just choosing the right zkVM, but architecting a system that leverages the strengths of both while optimizing for the specific constraints of fraud detection at scale.

---

## Additional Resources

**zkvm-perf Repository**: `/Users/ble/ToolsForHumanityResearch/zkvm-perf`
- Comprehensive benchmark suite
- Automated cloud infrastructure
- Real-world workload testing

**zkvm-compare Repository**: `/Users/ble/ToolsForHumanityResearch/zkvm-compare`
- Direct RISC Zero vs SP1 comparison
- Configurable segment sizes
- Scaling analysis across workload sizes

**Key Papers**:
- RISC Zero whitepaper: STARKs and RISC-V architecture
- SP1 documentation: STARK→SNARK pipeline and optimizations
- Recursive proof composition for aggregation

**Community Resources**:
- RISC Zero Discord: Active developer community
- Succinct (SP1) Discord: SP1-specific optimization tips
- ZK Canon (a16z): General ZK proof system education
