# Security Engineering Internship Interview Gameplan
## Tools for Humanity - 2 Day Preparation Plan

---

## 🎯 **Core Focus Areas**

The internship involves building a **distributed analytics system** for detection using:
- **Zero-knowledge proofs** for privacy
- **Smart contracts** for transparency & incentives
- **zkVMs** (RISC Zero, Boundless) for verifiable compute
- **Blockchain audit trails** for public accountability

**Key Challenge:** Balance transparency (public audit logs) with privacy (protecting user data & detection algorithms)

---

## 📅 **Day 1: Worldcoin ZKML & Core Concepts**

### **Morning Session (4 hours)**

#### 1. Worldcoin Official ZKML Introduction (30 min)
**Link:** https://worldcoin.org/blog/engineering/intro-to-zkml

**Focus:**
- Worldcoin's specific approach to ZKML
- IrisCode verification workflow
- Privacy requirements for biometric data
- How ZK enables trustless Orb operations

---

#### 2. Remco Bloemen's "Zero Knowledge Machine Learning" (30 min)
**Link:** https://xn--2-umb.com/22/zk-ml/

**Why:** Remco is the author of proto-neural-zkp (Worldcoin's experimental ZKML implementation)

**Focus:**
- Fundamentals of combining ZK + ML
- Trade-offs between different proof systems
- Practical constraints

---

#### 3. Explore proto-neural-zkp Repository (1.5 hours)
**Local path:** `/Users/ble/ToolsForHumanityResearch/proto-neural-zkp`

**Key areas to examine:**
- README.md - Overview and architecture
- How Plonky2 circuits are constructed for neural networks
- IrisCode verification implementation
- Privacy guarantees and how they're achieved
- CNN (Convolutional Neural Network) integration patterns

**Questions to answer:**
- How does Plonky2 differ from zkSTARKs (RISC Zero's approach)?
- What are the proof generation costs?
- How is model upgradeability handled?

---

#### 4. vCNN Paper - Architecture for Verifiable CNNs (1 hour)
**Link:** https://eprint.iacr.org/2020/584

**Focus sections:**
- Introduction (understand the problem space)
- Architecture overview
- How convolutional layers are proven in ZK
- Performance benchmarks

**Why relevant:** Iris verification uses CNNs, this paper shows how to make them verifiable

---

### **Afternoon Session (4 hours)**

#### 5. Trustless Verification of Machine Learning (45 min)
**Author:** Daniel Kang (creator of zkml framework)
**Link:** https://medium.com/@danieldkang/trustless-verification-of-machine-learning-6f648fd8ba88

**Focus:**
- Why trustless ML verification matters
- Architecture for verifiable ML inference
- Use cases and practical applications

**Podcast deep-dive (optional):** https://zeroknowledge.fm/265-2/

---

#### 6. Boundless Framework Deep Dive (2 hours)
**Local path:** `/Users/ble/ToolsForHumanityResearch/boundless`

**Explore:**
- `README.md` - Overall architecture
- `core-contracts/` - Solidity smart contract incentive model
- `sdk/` - How to submit verifiable compute jobs
- `broker/` - Sample prover implementation
- How RISC Zero integrates with blockchain

**This is CRITICAL:** Boundless implements "smart contracts that incentivize third parties to run code" - exactly what the job description mentions!

**Questions to answer:**
- How are provers incentivized?
- How are results published to blockchain?
- What happens if a prover submits invalid proofs?
- How does the verification process work on-chain?

---

#### 7. TensorPlonk: ZKML Performance Optimization (1 hour)
**Link:** https://medium.com/@danieldkang/tensorplonk-a-gpu-for-zkml-delivering-1-000x-speedups-d1ab0ad27e1c

**Focus:**
- Proof generation bottlenecks
- Optimization strategies for ZKML at scale
- Trade-offs between proof time and verification time

**Why relevant:** You need to scale to "billions of users" - understanding performance is critical

---

## 📅 **Day 2: zkVM Frameworks & Trade-offs**

### **Morning Session (4 hours)**

#### 8. RISC Zero Fundamentals (2 hours)
**Local path:** `/Users/ble/ToolsForHumanityResearch/risc0`

**Explore:**
- Documentation and quickstart examples
- **Guest/Host architecture:** How code runs in the zkVM
- **Receipts:** Proof outputs
- **Journals:** Public outputs from the guest program
- `bonsai/` - Proof service for outsourcing computation

**Key concepts:**
- RISC-V instruction set + zk-STARKs
- How Rust code compiles to zkVM
- Proof generation vs verification costs

**Official docs (if available in repo):** Look for examples/tutorials directory

---

#### 9. Modulus Labs - "The Cost of Intelligence" (1 hour)
**Link:** https://medium.com/@ModulusLabs/chapter-5-the-cost-of-intelligence-da26dbf93307

**Focus:**
- Economic analysis of on-chain ML
- Cost breakdown: proof generation vs verification
- When ZKML makes economic sense
- Scaling considerations

**Also check:** https://drive.google.com/file/d/1tylpowpaqcOhKQtYolPlqvx6R2Gv4IzE/view (Technical paper on ML inference cost)

---

#### 10. RISC Zero vs Plonky2 Comparison (1 hour)
**Your task:** Create a comparison table

| Aspect | RISC Zero (zk-STARKs) | Plonky2 (proto-neural-zkp) |
|--------|----------------------|---------------------------|
| Proof system | | |
| Programming model | | |
| Proof size | | |
| Verification time | | |
| Setup requirements | | |
| Best use cases | | |

**Resources:**
- proto-neural-zkp README
- risc0 documentation
- Your own observations

---

### **Afternoon Session (3 hours)**

#### 11. zkVM Performance Analysis (1.5 hours)
**Local paths:**
- `/Users/ble/ToolsForHumanityResearch/zkvm-compare`
- `/Users/ble/ToolsForHumanityResearch/zkvm-perf`

**Explore:**
- Benchmark results comparing RISC Zero vs SP1
- Performance metrics: proof time, verification time, proof size
- Different workload characteristics (loop iterations, fibonacci, etc.)

**Questions to answer:**
- When would you choose RISC Zero over SP1 (Succinct)?
- What are the performance implications at scale?
- How do GPU vs CPU affect proof generation?

---

#### 12. Interview Preparation & Question Practice (1.5 hours)

Prepare answers to these likely questions:

---

### **Technical Questions**

**Q1: "Explain how you would design a fraud detection system using zkVMs for WorldID verifications."**

**Your answer should cover:**
- Smart contract publishes detection model hash/commitment
- Third-party provers download encrypted verification data
- Provers run fraud detection model inside zkVM (RISC Zero guest)
- zkVM generates proof that model ran correctly without revealing:
  - Detection algorithm details
  - User verification data
- Proof + detection result published to blockchain
- Smart contract verifies proof on-chain
- Incentive mechanism rewards correct provers

**Key insight:** "This creates transparency (anyone can audit that detection ran) while preserving privacy (no one sees the data or exact algorithm)."

---

**Q2: "How do you balance transparency (blockchain audit trail) with privacy (ZK proofs) in a detection system?"**

**Framework for answer:**

**Transparency layer (public on blockchain):**
- Proof that detection code executed correctly
- Merkle roots of datasets being analyzed
- Detection model version/commitment
- Aggregate statistics (e.g., "5% fraud rate detected today")
- Prover identities and stake
- Verification results (proof validity)

**Privacy layer (hidden via ZK):**
- Individual user data (iris scans, transaction details)
- Exact detection algorithm logic
- Specific fraud indicators/thresholds
- Model weights and parameters
- Individual verification outcomes (only aggregates published)

**Example:** "Publishing to blockchain that '1000 verifications were checked using fraud model v2.3 and 50 anomalies detected' provides transparency. ZK proofs ensure this claim is verifiable without revealing which 50 users or what specific patterns were detected."

---

**Q3: "What are the main challenges in scaling ZKML to billions of users?"**

**Answer points:**
- **Proof generation cost:** Currently expensive (CPU/GPU time)
- **Latency:** Users can't wait minutes for verification
- **Data availability:** Where is verification data stored? On-chain too expensive
- **Prover incentives:** Economic model must be sustainable at scale
- **Model upgradeability:** How to update detection models without breaking proofs?

**Solutions to mention:**
- Recursive proofs (prove batches of verifications)
- Proof aggregation (combine many proofs into one)
- Specialized hardware (ZK ASICs like Ingonyama)
- Off-chain data with on-chain commitments
- Optimistic verification (only generate proofs when challenged)

---

**Q4: "Why use RISC Zero vs other zkVM frameworks?"**

**Your comparative points:**
- **RISC Zero:** General-purpose, supports any RISC-V compiled code, larger proof sizes but more flexible
- **Plonky2:** Optimized for specific circuits (like CNNs), faster for ML workloads
- **SP1 (Succinct):** Similar to RISC Zero, different performance trade-offs

**For detection system:** "RISC Zero makes sense because detection logic might need to evolve rapidly. General-purpose zkVM allows writing detection algorithms in Rust without custom circuit design for each new model."

---

**Q5: "What security considerations are important for a decentralized detection system?"**

**Answer points:**
- **Sybil attacks:** Malicious provers submitting fake detection results
  - Solution: Stake/slashing mechanism
- **Data poisoning:** Compromised training data for fraud models
  - Solution: Transparent model training process, community review
- **Griefing:** Provers refusing to process certain users
  - Solution: Multiple redundant provers, rotation
- **Front-running:** Seeing fraud detection before on-chain publication
  - Solution: Commit-reveal schemes, time-locks
- **Model leakage:** Reverse-engineering detection algorithms from many proofs
  - Solution: Differential privacy, noise injection, model rotation

---

### **Behavioral Questions**

**Q: "Why are you interested in this internship?"**

**Frame your answer around:**
- Intersection of ZK cryptography, ML, and blockchain
- Real-world impact (protecting identity verification for millions)
- Learning from Detection & Response team's multi-disciplinary expertise
- Scaling challenges (billions of users is a unique problem)
- Privacy-preserving technology aligns with your values

---

**Q: "What's your experience with Rust and zkVMs?"**

**Be honest but show learning:**
- Describe any Rust projects you've done
- Mention which zkVM repos you've explored (RISC Zero, Boundless)
- Show specific examples: "I studied the Boundless broker implementation and understand how it submits jobs to RISC Zero"
- Acknowledge gaps: "I haven't built a production zkVM application yet, but I understand the guest/host model and proof generation workflow"

---

**Q: "How do you approach learning new complex technologies?"**

**Your preparation IS the answer:**
- "I installed 8 ZK-related repositories and systematically studied them"
- "I read both academic papers and practical implementations"
- "I compare different approaches (RISC Zero vs Plonky2) to understand trade-offs"
- "I connect concepts to real use cases (proto-neural-zkp for WorldID)"

---

## 🔑 **Key Talking Points - Memorize These**

### **Worldcoin/TFH-Specific Knowledge**

1. **Proto-neural-zkp use cases:**
   - Verifying WorldID creation locally (IrisCode model proof without revealing iris scan)
   - Making Orb trustless (proving fraud filters applied)
   - IrisCode upgradeability (updating models while maintaining privacy)

2. **Detection & Response context:**
   - Team protects 17M+ users across 160 countries
   - 350K+ weekly verifications need fraud protection
   - Multi-disciplinary: mobile, hardware, cloud, blockchain, ML, incident response

3. **The internship project:**
   - "Distributed analytics system"
   - Smart contract incentivizes third parties to run detection code
   - Publish outputs publicly, prove calculations correct privately
   - Early stage - internship timeline expectations are realistic

---

### **Technical Depth Signals**

When discussing, mention specific details to show you've done your homework:

- "Plonky2 uses recursive SNARKs which allows for faster proving of neural network layers compared to STARKs"
- "Boundless uses RISC Zero's receipt/journal model to publish proof results on-chain"
- "The trade-off between proof size (STARKs are larger) and setup requirements (STARKs don't need trusted setup) matters for decentralized systems"
- "Proto-neural-zkp's CNN approach for iris verification is based on the vCNN architecture pattern"

---

## 📊 **Transparency vs Privacy Framework**

### **The Core Problem**

Detection systems need:
- **Accountability:** Prove detection is running correctly and fairly
- **Privacy:** Don't reveal user data or detection methods (prevent adversarial evasion)

### **The ZK + Blockchain Solution**

```
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC (Blockchain)                       │
├─────────────────────────────────────────────────────────────┤
│ • Detection model commitment (hash)                          │
│ • Dataset Merkle roots                                       │
│ • Aggregate detection results                                │
│ • ZK proofs (verifiable, reveal nothing about data)         │
│ • Prover identities & economic incentives                   │
│ • Timestamp/audit trail                                      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                   PRIVATE (ZK Hidden)                        │
├─────────────────────────────────────────────────────────────┤
│ • Individual verification data (iris scans, etc.)           │
│ • Specific fraud detection algorithm logic                  │
│ • Model weights and thresholds                              │
│ • Individual detection outcomes                             │
│ • Fraud indicators/patterns                                 │
└─────────────────────────────────────────────────────────────┘
```

### **Example Workflow**

1. **TFH publishes (transparent):**
   - Smart contract with detection model commitment: `hash(fraud_model_v2.3)`
   - Dataset commitment: `merkle_root(all_verifications_2024_01_24)`

2. **Third-party prover runs (private):**
   - Downloads encrypted verification data
   - Runs fraud model inside RISC Zero zkVM guest
   - Model identifies suspicious patterns (PRIVATE)

3. **Prover publishes (transparent + private mix):**
   - ZK proof: "I ran fraud_model_v2.3 on dataset merkle_root and detected 50/1000 anomalies"
   - Smart contract verifies proof on-chain
   - Public learns: detection ran correctly, 5% fraud rate
   - Public doesn't learn: which 50 users, what patterns, exact algorithm

4. **Audit trail (transparent):**
   - Blockchain permanently records all detection runs
   - Anyone can verify proofs
   - Regulators/users can audit aggregate statistics
   - No one can see individual data

---

## 📚 **Additional Resources**

### **Background Reading (Time Permitting)**

**ZK Fundamentals:**
- zkProof Standards: https://zkproof.org/blog/
- ZK Canon (a16z): https://a16zcrypto.com/zero-knowledge-canon/
- Proofs, Args and ZK (Justin Thaler): https://people.cs.georgetown.edu/jthaler/ProofsArgsAndZK.pdf

**ZKML Ecosystem:**
- awesome-zkml README: `/Users/ble/ToolsForHumanityResearch/awesome-zkml/README.md`
- Cathie So's ZKML overview: https://hackmd.io/@cathie/zkml
- a16z on ML + ZK: https://a16zcrypto.com/content/article/checks-and-balances-machine-learning-and-zero-knowledge-proofs/

**Related Projects:**
- Raiko (multi-prover system): `/Users/ble/ToolsForHumanityResearch/raiko`
- Semaphore (privacy protocol): `/Users/ble/ToolsForHumanityResearch/semaphore-airdrop-relayer`

---

## ✅ **Pre-Interview Checklist**

**Day Before Interview:**
- [ ] Can you explain the guest/host model in RISC Zero?
- [ ] Can you describe Worldcoin's three proto-neural-zkp use cases?
- [ ] Can you articulate the transparency vs privacy trade-off clearly?
- [ ] Can you explain why Boundless is relevant to the internship project?
- [ ] Can you discuss at least 2 scaling challenges for ZKML?
- [ ] Have you prepared 2-3 questions to ask the interviewer?

**Questions to Ask Interviewer:**
1. "What's the current state of the distributed analytics system project? What would success look like by the end of the internship?"
2. "How does the Detection & Response team collaborate with other teams (e.g., Orb hardware, WorldID app developers)?"
3. "What's the biggest technical challenge you foresee in making fraud detection both transparent and privacy-preserving at scale?"
4. "How does TFH think about the trade-off between proof generation costs and verification benefits for different use cases?"

---

## 🎯 **Final Interview Strategy**

1. **Show genuine interest in the mission:** Privacy-preserving identity for billions of people is a hard, important problem

2. **Demonstrate technical depth:** Reference specific implementations (proto-neural-zkp, Boundless contracts, RISC Zero receipts)

3. **Think about trade-offs:** No solution is perfect - show you understand constraints (cost, latency, security)

4. **Connect to real-world impact:** Detection protects 17M+ users; your work could scale to billions

5. **Be honest about experience:** Internships are for learning. Show you can learn complex topics quickly (your 2-day prep proves this!)

6. **Ask thoughtful questions:** Show you've thought deeply about the problem space

---

## 🚀 **You've Got This!**

You've installed 8 major ZK repositories, you're systematically studying the exact tech stack TFH uses, and you understand both the technical challenge (verifiable compute + privacy) and the business context (WorldID fraud detection).

**The key insight to demonstrate:** ZK proofs enable a new trust model - public verifiability without public data. This unlocks decentralized detection systems that were impossible before.

Good luck! 🍀
