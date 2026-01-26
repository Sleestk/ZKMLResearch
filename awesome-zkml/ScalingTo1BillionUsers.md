# Scaling ZKML to 1 Billion Users: Bottlenecks, Optimizations, and Trade-offs

## Executive Summary

Zero-Knowledge Machine Learning (ZKML) faces significant performance challenges that must be overcome to scale to billions of users. Current systems have 100,000x to 1,000,000x overhead compared to native execution. However, recent advances like TensorPlonk demonstrate that 1,000x speedups are achievable through targeted optimizations. This document analyzes the critical bottlenecks, optimization strategies, and trade-offs necessary for production-scale ZKML deployment.

**Key Finding**: To verify 500M daily tweets (Twitter's actual volume) at 1% sampling rate would cost ~$21,000/day with TensorPlonk vs $75,000,000/day with naive approaches—a 3,500x cost reduction making ZKML economically viable at <0.5% of infrastructure costs.

---

## 1. Proof Generation Bottlenecks

### 1.1 Linear Operations (Matrix Multiplications)

**The Primary Bottleneck**

Matrix multiplication dominates computation in most ML models, exhibiting O(m × n × d) cubic complexity:

- **Scale**: A single layer in Twitter's model contains >15 million floating-point operations
- **Weight matrices**: Can exceed 8 million elements per layer
- **Accumulation**: Multiple layers compound the computational burden

**Why It's Critical for Scaling**:
- Linear layers constitute the bulk of computation in transformer models, CNNs, and recommendation systems
- Every user inference requires full matrix multiplication pipeline
- At billions of users, even small per-inference costs become prohibitive

### 1.2 Non-Linear Operations (Activations)

**The Hidden Cost**

While cheap on traditional GPUs, non-linearities (ReLU, sigmoid, etc.) are expensive in ZKML:

- **Lookup tables**: Required for efficient proving but introduce constraints
- **Constraint propagation**: Dramatically increases proving costs when done naively
- **Circuit-table coupling**: Traditional approaches (plookup) require circuit size = table size, creating 250x overhead

**Example**: A lookup table of 2^24 elements forces a circuit of 2^24 elements in plookup, even if the actual circuit logic only needs 2^16 elements.

### 1.3 Weight Commitments

**The Security-Performance Tension**

Proving the model uses fixed weights (without revealing them) is critical for verifiable ML:

- **Cryptographic hashing**: As expensive as the entire model computation
- **Verification overhead**: Each weight commitment adds to proof size and verification time
- **Scale impact**: Multiple layers × large weight matrices = substantial overhead

### 1.4 Memory and Proof Size

**Infrastructure Constraints**

- **Memory requirements**: Current systems (ezkl) exceed standard test harness capabilities
- **Proof transmission**: Large proofs create network bottlenecks
- **Verification work**: Linear increase in verifier work with model size
- **Blockchain limitations**: Large proofs infeasible for on-chain verification

**Real-World Impact**: Native cqlin implementation requires one commitment per matrix multiplication, increasing proof size and verification by nearly 10x.

### 1.5 Number Theoretic Transforms (NTT)

**The Underlying Bottleneck**

Recent research identifies NTT as the fundamental bottleneck in ZKP workloads:

- Polynomial commitment schemes rely heavily on NTT
- Batching and parallelization limited by NTT sequential dependencies
- Hardware acceleration must target NTT specifically

---

## 2. Optimization Strategies for ZKML at Scale

### 2.1 Algorithmic Optimizations

#### A. cqlin: Linear-Time Matrix Multiplication Proving

**Core Innovation**: O(n) proving time when one matrix is fixed (the typical case for ML weights)

**How It Works**:
- Leverages the fact that ML model weights are fixed during inference
- Pre-computes commitments to weight matrices
- Reduces cubic complexity to linear for the proving operation

**Impact**: Foundation for TensorPlonk's 1,000x speedup

**Limitation**: Requires fixed matrices—not suitable for dynamic weight updates

#### B. Randomized Batch Verification

**Problem**: cqlin naively applied requires one commitment per matrix multiplication

**Solution**: Use randomized checks to verify all matrix multiplications simultaneously

**Benefits**:
- Avoids 10x increase in proof size
- Reduces verifier work from O(layers) to O(1) pairing checks
- Maintains cryptographic security through challenge-response protocol

**Critical for Scale**: At billions of users, minimizing per-proof verification work is essential for decentralized verification

#### C. cq: Circuit-Independent Lookup Tables

**Problem**: plookup requires circuit size = lookup table size (250x overhead)

**Solution**: cq allows lookup tables of arbitrary size independent of circuit size

**Example Improvement**:
- Lookup table: 2^24 elements
- Circuit size: 2^16 elements
- Overhead reduction: 250x

**Additional Optimization**: Batch processing across multiple lookup tables reduces computation by 3x

**Why It Matters**: Non-linearities occur at every layer; this optimization compounds across the entire model

#### D. KZG Commitments for Weights

**Problem**: Cryptographic hashing for weight commitments adds 10x proving overhead

**Solution**: Use KZG polynomial commitments instead of hashing

**Benefits**:
- 10x faster proving time
- Integrates seamlessly with polynomial-based proving systems
- Maintains hiding property for private model weights

**Trade-off**: Requires trusted setup (though universal setups like Powers of Tau can be reused)

### 2.2 Hardware Acceleration Strategies

#### GPU Acceleration

**Current State**:
- General GPU implementations: 4.6x speedup
- Specialized systems (BatchZK): 458x faster than ZENO, 5,601x faster than baseline ZKML
- zkDL: Consistent <0.1 second per-data-point proving time (1,000-10,000x speedup)

**Key Techniques**:
- Parallelizing NTT operations
- Pipelining proof generation stages
- Memory hierarchy optimization for polynomial operations

#### ASIC Development

**Next Frontier**:
- Custom silicon targeting MSM (Multi-Scalar Multiplication) and FFT/NTT
- HyperPlonk implementations showing 700x speedups with optimized memory bandwidth
- Trade-off: Development cost vs. performance gain at scale

### 2.3 Proof System Architecture

#### Recursive Proofs

**Benefits**:
- Constant-size proofs regardless of computation complexity
- Enables verification of proofs within other proofs
- Critical for blockchain applications with gas constraints

**Example**: Halo 2 system used by EZKL

#### Aggregation and Batching

**Strategy**: Batch multiple user inferences into single proof

**BatchZK Approach**:
- Fully pipelined GPU-accelerated system
- Processes multiple proofs in parallel
- Achieves 458x speedup over single-proof systems

**Scaling Impact**: At billions of users, batching amortizes fixed costs across many proofs

### 2.4 Stochastic Verification

**Paradigm Shift**: Don't prove everything—prove a statistically significant sample

**Application to Twitter Example**:
- Total volume: 500M tweets/day
- Verification rate: 1% (5M tweets/day)
- Cost: $21,000/day
- Security guarantee: High probability of detecting manipulation

**Statistical Foundation**:
- With 1% sampling, probability of undetected fraud decreases exponentially
- Adjustable security parameter based on risk tolerance

**Critical for Billion-User Scale**: Makes verification costs linear rather than multiplicative with user growth

---

## 3. Trade-offs Between Proof Time and Verification Time

### 3.1 The Fundamental Trade-off

**Prover Work vs. Verifier Work**: Zero-knowledge proofs inherently transfer computational burden from verifier to prover

**Scaling Implications**:
- **Centralized proving**: One prover, millions of verifiers → minimize verification time
- **Decentralized proving**: Many provers → minimize proving time
- **Blockchain context**: Verification happens on-chain → critical to minimize

### 3.2 Proof Size vs. Verification Time

**The Relationship**:

| Approach | Proof Size | Verification Time | Best For |
|----------|-----------|-------------------|----------|
| Native cqlin | Large (per-layer commits) | Fast (parallel checks) | High-bandwidth networks |
| TensorPlonk | Small (batched commits) | Fast (aggregated checks) | Blockchain/low-bandwidth |
| Recursive proofs | Constant | Constant | On-chain verification |
| Non-recursive | Linear in complexity | Linear in complexity | Off-chain verification |

**Real Numbers (TensorPlonk)**:
- ezkl approach: Large proofs, high verification time
- TensorPlonk: 10x smaller proofs, same security guarantees

### 3.3 Proving Time vs. Model Privacy

**Weight Commitment Trade-off**:

1. **Cryptographic Hash**:
   - Proving time: 10x slower
   - Privacy: Strong (collision-resistant hash)
   - Verifiability: Requires pre-published hash

2. **KZG Commitment**:
   - Proving time: 10x faster
   - Privacy: Strong (polynomial hiding)
   - Verifiability: Efficient pairing checks
   - Limitation: Requires trusted setup

**Choice Depends On**:
- Threat model: Is trusted setup acceptable?
- Performance requirements: Can you afford 10x overhead?
- Integration: Does existing infrastructure use KZG or hashes?

### 3.4 Accuracy vs. Proving Time

**Quantization Trade-off**:

Reducing model precision (e.g., float32 → int8) decreases proving time but may impact accuracy

**Strategy for Scale**:
- Use quantized models for ZKML
- Accept slight accuracy degradation for massive performance gains
- Validate quantized model accuracy meets requirements

### 3.5 Generality vs. Performance

**The Specialization Spectrum**:

1. **General zkVMs**:
   - Can prove any computation
   - 100,000x - 1,000,000x overhead
   - Not suitable for ML at scale

2. **ML-Specific Systems (TensorPlonk)**:
   - Optimized for ML operations
   - 1,000x speedup
   - Limited to supported architectures

3. **Model-Specific Circuits**:
   - Maximum performance
   - No flexibility
   - High development cost per model

**Recommendation for Scale**: ML-specific systems hit the sweet spot—sufficient generality with necessary performance.

---

## 4. Scaling to Billions of Users: A Concrete Framework

### 4.1 Cost Model Analysis

**Twitter Recommendation System Case Study**:

**Problem Parameters**:
- Users: ~500M daily active
- Tweets: 500M/day (6,000/second)
- Model: Twitter recommendation algorithm
- Requirement: Verify model integrity

**Naive Approach (ezkl)**:
- Proving time: 6 hours per inference
- Cost: $88,704 per second of tweets
- Daily cost: $75,000,000
- Feasibility: **Economically impossible** (18x Twitter's entire infrastructure budget)

**TensorPlonk + Stochastic Verification**:
- Proving time: ~20 seconds per inference
- Sample rate: 1%
- Daily proofs: 5M
- Cost: $21,000/day
- Feasibility: **<0.5% of infrastructure costs** ✓

**Key Insight**: 3,500x cost reduction through algorithmic optimization + stochastic sampling

### 4.2 Infrastructure Requirements for 1B Users

**Computational Capacity**:

Assuming 1B daily active users with 10 inferences/user:
- Total inferences: 10B/day
- With 1% sampling: 100M proofs/day
- At 20 seconds/proof: 2.3M GPU-hours/day
- With 60-GPU cluster: ~1,600 GPUs required

**Cost Estimation**:
- AWS p3.2xlarge (Tesla V100): $3.06/hour
- Daily cost: ~$4.9M
- Monthly cost: ~$147M

**Optimization Strategies**:
1. **Increase batch size**: Amortize fixed costs
2. **Use spot instances**: 70% cost reduction → $44M/month
3. **Custom ASICs**: 10-100x performance improvement → $4.4M-$0.44M/month
4. **Adaptive sampling**: Higher rates for suspicious activity, lower for trusted users

### 4.3 Latency Considerations

**User Experience Requirements**:

| Application | Max Latency | Strategy |
|-------------|-------------|----------|
| Real-time inference | <100ms | Prove async, serve immediately |
| Batch verification | <1 hour | Aggregate & batch proofs |
| Audit trails | <24 hours | Stochastic sampling + batch |

**TensorPlonk Latency**:
- Proving time: ~20 seconds (Twitter model)
- Verification time: <1 second
- Solution: Asynchronous proving with immediate serving

**For Billion-User Scale**:
- Users get immediate inference results
- Proofs generated asynchronously in background
- Periodic publication of batched proofs for auditability

### 4.4 Security Model

**Stochastic Verification Security**:

For 1% sampling rate over 10B inferences:
- Proofs checked: 100M
- If adversary manipulates 0.1% of inferences (10M):
  - Expected detected: 100K
  - Probability of zero detections: ~e^(-100,000) ≈ 0

**Adaptive Adversaries**:
- Attacker may only manipulate inferences that won't be checked
- Mitigation: Unpredictable sampling (commit to seed before inference)
- Game theory: Cost of failed attack > gain from successful attack

**Trust Model**:
- Prover: Semi-honest (will try to cheat if undetected)
- Verifier: Can be anyone with proof
- Model owner: Trusted to provide correct model (or committed to via hash/KZG)

### 4.5 Decentralization Strategy

**Challenges**:
1. Proving requires significant compute (centralization pressure)
2. Verification should be lightweight (enable decentralization)
3. Coordination: Who proves what, when?

**Solutions**:

**Option A: Centralized Proving, Decentralized Verification**
- Model owner runs proving infrastructure
- Publishes proofs + commitments to blockchain/IPFS
- Anyone can verify correctness
- Suitable for: Corporate deployments (Twitter, Meta, etc.)

**Option B: Proof Markets**
- Users or model owners post proving jobs
- Specialized provers compete on price/latency
- Verified proofs submitted to blockchain
- Suitable for: Decentralized AI applications

**Option C: Rollup-Style Architecture**
- Sequencer aggregates inference requests
- Batch generates proofs for many inferences
- Submits aggregated proof on-chain
- Suitable for: Blockchain-native AI applications

### 4.6 Progressive Rollout Strategy

**Phase 1: High-Value, Low-Volume**
- Target: Critical decisions (loan approvals, medical diagnoses)
- Volume: <1M inferences/day
- Approach: Full verification (100%)
- Goal: Prove reliability and build trust

**Phase 2: Popular Applications**
- Target: Social media algorithms, content recommendations
- Volume: 100M - 1B inferences/day
- Approach: Stochastic verification (1-10%)
- Goal: Economic viability at scale

**Phase 3: Ubiquitous AI**
- Target: All ML inferences
- Volume: >10B inferences/day
- Approach: Adaptive sampling + specialized hardware
- Goal: <0.1% infrastructure overhead

---

## 5. Open Challenges and Future Directions

### 5.1 Model Architecture Evolution

**Problem**: Optimization assumes specific model architectures (matrix multiplications)

**Challenge**: New architectures (attention mechanisms, mixture-of-experts, neural ODEs) may not benefit equally

**Research Needed**:
- Efficient proving for attention mechanisms (O(n²) complexity)
- Sparse model support (activated subnetworks)
- Dynamic computation graphs

### 5.2 Continuous Learning

**Problem**: TensorPlonk assumes fixed weights; retraining breaks optimizations

**Challenge**: Billion-user systems require continuous updates

**Potential Solutions**:
- Incremental proof updates for fine-tuning
- Separate proving for base model vs. adapter layers
- Periodic re-commitment to updated weights (with transition period)

### 5.3 Privacy-Preserving Inference

**Current Gap**: TensorPlonk proves computation correctness, not input/output privacy

**Required for Scale**: Users want to:
- Keep inputs private (medical data, financial info)
- Verify outputs without revealing them
- Prove fairness without exposing sensitive attributes

**Approaches**:
- Combine ZKML with fully homomorphic encryption (FHE)
- Private information retrieval (PIR) for model weights
- Secure multi-party computation (MPC) for sensitive inferences

### 5.4 Hardware-Software Co-Design

**Observation**: Current bottlenecks (NTT, MSM) are hardware-limited

**Opportunity**: ASICs purpose-built for ZKML operations

**Research Questions**:
- What is the theoretical minimum energy per proof?
- Can we design reconfigurable hardware for multiple proof systems?
- How to balance specialization vs. generality in silicon?

### 5.5 Formal Verification of Optimizations

**Critical for Trust**: Complex optimizations (randomized batching, cq) must be formally verified

**Current State**: Most systems lack formal proofs of soundness

**Needed**:
- Machine-checked proofs (Coq, Lean) of optimization correctness
- Automated testing frameworks for ZKML systems
- Standardized security audit procedures

---

## 6. Recommendations for Practitioners

### 6.1 When to Use ZKML

**Good Fit**:
- High-value decisions where trust is critical
- Public algorithms where transparency is required
- Adversarial environments (competition, regulation)
- Auditability requirements (compliance, research)

**Poor Fit**:
- Low-value predictions where trust is implicit
- Latency-critical applications (<10ms requirements)
- Rapidly changing models (daily retraining)
- Budget-constrained applications without revenue model for verification costs

### 6.2 Choosing a ZKML System

**Decision Matrix**:

| System | Best For | Performance | Maturity |
|--------|----------|-------------|----------|
| General zkVMs | Flexibility, any model | 100,000x overhead | Production |
| EZKL | Standard models, Ethereum | 1,000x overhead | Production |
| TensorPlonk | Large models, optimization | 1x overhead (baseline) | Research |
| BatchZK | High throughput, batching | 5,000x speedup | Research |
| Custom circuits | Maximum performance | Best possible | Development |

**Recommendation**: Start with EZKL for MVP, migrate to specialized systems (TensorPlonk, BatchZK) for scale.

### 6.3 Designing for Verifiable ML

**Architecture Principles**:

1. **Quantization-First**: Design models with quantization from the start
2. **Layer Budgeting**: Track proving cost per layer during model design
3. **Modular Proving**: Split models into provable chunks
4. **Caching**: Reuse proofs for common sub-computations
5. **Graceful Degradation**: Have fallback for users who can't wait for proofs

**Development Process**:
1. Train model normally
2. Quantize and test accuracy
3. Estimate proving costs (layers × complexity)
4. Optimize architecture for proving (reduce layers, increase width)
5. Benchmark proof generation and verification
6. Deploy with stochastic verification

### 6.4 Economic Model

**Cost Components**:
1. Proving infrastructure (GPUs/ASICs)
2. Storage for proofs
3. Bandwidth for proof distribution
4. Verification costs (on-chain gas or compute)

**Revenue Models**:
1. **User pays**: Premium for verified inference
2. **Platform pays**: Cost of doing business (compliance)
3. **Third-party pays**: Advertisers, auditors, researchers
4. **Token incentives**: Crypto-economic rewards for provers/verifiers

**Break-Even Analysis**:
- Calculate cost per proof
- Estimate sampling rate needed for security
- Compare to revenue per user
- Adjust sampling rate or optimize proving as needed

---

## 7. Conclusion: The Path to Billion-User ZKML

**Current State (2023-2024)**:
- TensorPlonk demonstrates 1,000x speedups are achievable
- Cost models show economic viability at scale with stochastic verification
- Multiple systems (BatchZK, zkDL) confirm order-of-magnitude improvements

**Near-Term (2024-2026)**:
- Expect continued algorithmic optimizations (10-100x more improvements)
- GPU acceleration becoming standard (4-500x speedups)
- First production deployments at >100M daily users

**Medium-Term (2026-2028)**:
- Custom ASICs delivering 10-100x additional speedups
- Billion-user deployments economically viable
- ZKML becomes standard for high-stakes AI decisions

**Long-Term (2028+)**:
- Ubiquitous verifiable AI
- ZKML overhead < 10% of native inference
- Regulatory requirements drive adoption

**Key Insight**: Scaling to billions of users requires:
1. **Algorithmic innovation** (TensorPlonk: 1,000x) ✓
2. **Hardware acceleration** (GPUs: 10-500x, ASICs: 10-100x) [In Progress]
3. **Stochastic verification** (1-10% sampling) ✓
4. **Economic models** that align incentives ✓

**The fundamental bottleneck is no longer "if" but "when"—the path to billion-user ZKML is clear, and execution is underway.**

---

## References

1. Waiwitlikhit, S., & Kang, D. (2023). TensorPlonk: A "GPU" for ZKML, Delivering 1,000x Speedups.
2. Eagen, L., & Gabizon, A. cqlin: Efficient Linear-Time Proving for Matrix Multiplication.
3. EZKL: Privacy-Preserving Machine Learning Infrastructure.
4. BatchZK: Fully Pipelined GPU-Accelerated ZKP Generation System.
5. zkDL: CUDA-Powered Zero-Knowledge Deep Learning Toolkit.
6. Modulus Labs: Advancing ZKML Infrastructure and Tooling.
7. HyperPlonk: Hardware-Optimized Polynomial Commitment Schemes.

---

**Document Version**: 1.0
**Last Updated**: January 2026
**Authors**: Based on research by Suppakit Waiwitlikhit, Daniel Kang, and the broader ZKML research community
**License**: CC BY 4.0
