# Trustless Verification of Machine Learning

**Author**: Daniel Kang
**Source**: https://medium.com/@danieldkang/trustless-verification-of-machine-learning-6f648fd8ba88
**Also available**: https://ddkang.github.io/_posts/2022-10-18-trustless/
**Preprint**: https://arxiv.org/abs/2210.08674

---

## Why Trustless ML Verification Matters

**TL;DR**: As ML-as-a-Service (MLaaS) deployments become increasingly complex and opaque, consumers cannot verify whether providers (Amazon, Google, Microsoft) execute models correctly or are malicious/lazy/buggy. Expert-annotated datasets for verification cost up to $85,000, while legal discovery and FOIA requests require trustless document retrieval. Trustless verification enables post-hoc proof of correct execution without revealing model weights or inputs, costing only ~$100 to verify accuracy within 5% (0.1% overhead).

**The Trust Problem**:
- ML deployments are becoming increasingly complex as models scale in scope and accuracy
- Organizations rely on MLaaS providers to execute complex, proprietary models
- Services are becoming difficult to understand and audit
- Critical question: How can consumers trust that predictions were served correctly?

**Current Limitations**:
- No way to verify model execution without re-running (requires access to proprietary weights)
- Verification through expert annotation is prohibitively expensive ($85,000+)
- Model providers could be:
  - **Malicious**: Intentionally providing wrong outputs
  - **Lazy**: Using cheaper/faster models than promised
  - **Erroneous**: Having bugs in serving code

**Why This Matters**:
1. **Accountability**: Enables verification without trusting the provider
2. **Cost Efficiency**: Verification protocol adds only $99.93 cost vs $85,000 for expert datasets
3. **Legal Requirements**: Supports trustless document retrieval for legal discovery/FOIA
4. **Third-Party Verification**: Proofs can resolve disputes without revealing sensitive data
5. **Privacy Preservation**: Verification doesn't require exposing model weights or inputs

---

## Architecture for Verifiable ML Inference

**TL;DR**: The system uses ZK-SNARKs (zero-knowledge proofs) with the halo2 proving library to create verifiable ML inference. Key innovation is efficient arithmetization of quantized DNNs with lookup arguments for non-linearities. MobileNet v2 on ImageNet achieves 79% accuracy with 10-second verification on commodity hardware and 6KB proofs. This is 17,280x faster than prior work requiring two days per prediction.

**Core Technology - ZK-SNARKs Properties**:
1. **Succinct Proofs**: As small as 6KB for ML models (100 bytes for non-ML)
2. **Non-Interactive**: Proof can be verified by anyone at any time
3. **Knowledge Soundness**: Prover cannot generate invalid proofs
4. **Completeness**: Correct proofs will always verify
5. **Zero-Knowledge**: Proof reveals nothing about inputs/weights beyond outputs

**Technical Architecture**:

**Step 1: Arithmetization**
- Turn computation into arithmetic circuit (system of polynomial equations over large prime field)
- Challenge: Neural networks require efficient representation of non-linearities
- Prior approaches: Groth16 (poor for DNNs due to non-linearities) or DNN-specific sum-check systems (worse performance)

**Step 2: Proving System**
- Uses **halo2 library** (leverages recent ZK proving ecosystem advances)
- Benefits from broader ZK ecosystem improvements vs. neural network-specific systems
- Groth16 not amenable for DNN inference (quadratic constraints can't easily represent non-linearities)

**Novel Contributions**:
1. **Efficient Quantized DNN Arithmetization**: New methods for representing quantized neural networks in circuits
2. **Lookup Arguments for Non-Linearities**: Efficient handling of ReLU and other activation functions
3. **Circuit Packing**: Optimized circuit representation to reduce computational overhead

**Workflow**:
1. Model Provider (MP) commits to model by hashing weights
2. MP executes inference on inputs
3. MP generates ZK-SNARK proof of correct execution
4. Model Consumer (MC) verifies proof without accessing weights/inputs
5. Verification takes ~10 seconds on commodity hardware

**Performance Breakthrough**:
- **Prior Work**: Up to 2 days computation to verify single prediction
- **This Work**: 10 seconds verification for 79% accuracy ImageNet model
- **Proof Size**: 6KB
- **Speedup**: ~17,280x faster than prior work

---

## Use Cases and Practical Applications

**TL;DR**: Two primary protocols demonstrated: (1) ML Model Accuracy Verification - verify model meets accuracy requirements before purchase/deployment, costing $99.93 vs $85,000 for expert datasets with 0.1% overhead; (2) Trustless Document Retrieval - legal subpoenas/FOIA requests where respondent proves they returned all matching documents without exposing non-matching ones. Both protocols support third-party dispute resolution.

### Use Case 1: ML Model Accuracy Verification

**Scenario**: Model Consumer (MC) wants to verify Model Provider's (MP) claimed accuracy before purchasing or using MLaaS service.

**Protocol Steps**:
1. **Model Commitment**: MP commits to model by hashing its weights
2. **Test Set Distribution**: MC sends test set to MP
3. **Proof Generation**: MP provides outputs + ZK-SNARK proofs of correct execution for test set
4. **Verification**: MC verifies ZK-SNARKs to confirm correct model execution
5. **Decision**: MC purchases model or engages MP as MLaaS provider

**Economic Incentives**:
- Protocol includes game-theoretic incentives to ensure both parties act honestly
- Details in full preprint

**Cost-Benefit Analysis**:
- **Traditional Approach**: Expert-annotated dataset costs up to $85,000
- **Trustless Verification**: $99.93 to verify accuracy within 5%
- **Overhead**: As little as 0.1% additional cost
- **Savings**: ~850x cheaper than traditional verification

**Benefits**:
- No need to trust MP's claimed accuracy
- Prevents bait-and-switch (MP serving cheaper model than advertised)
- Detects bugs in serving code
- Enables pay-for-performance contracts

### Use Case 2: Trustless Document Retrieval

**Scenario**: Legal discovery or FOIA request where judge orders subpoena for documents matching specific criteria (specified by ML model classifier).

**Protocol Steps**:
1. **Dataset Commitment**: Responder commits to dataset by producing hashes of all documents
2. **Model Specification**: Requester sends ML model classifier defining matching criteria
3. **Selective Execution**: Responder runs model on all documents
4. **Proof + Disclosure**: Responder provides:
   - Documents that match the classifier
   - ZK-SNARK proofs of valid inference on ALL documents
5. **Verification**: Requester verifies proofs to ensure no matching documents were withheld

**Privacy Guarantees**:
- Non-matching documents remain completely private
- Requester cannot learn about documents that don't match
- Responder cannot hide matching documents
- Third-party (judge) can verify compliance

**Applications**:
- **Legal Discovery**: Plaintiff requests documents for litigation
- **FOIA Requests**: Journalists request government documents
- **Regulatory Compliance**: Auditors verify data handling
- **Data Breaches**: Verify which records were affected

**Advantages Over Traditional Discovery**:
- No over-disclosure of irrelevant sensitive documents
- Mathematically guaranteed completeness (all matching docs provided)
- Third-party verifiable without re-executing
- Reduces litigation costs and privacy risks

### Performance Trade-offs

**Accuracy vs Verification Time**:
The system enables flexible trade-offs by varying model complexity:
- Lower complexity models: Faster verification, lower accuracy
- Higher complexity models: Slower verification, higher accuracy
- **Sweet spot**: MobileNet v2 at 79% accuracy with 10-second verification

**Scalability Considerations**:
- Verification time is independent of dataset size for accuracy verification
- Document retrieval scales with number of documents (each needs proof)
- Commodity hardware sufficient (no specialized equipment needed)
- Proofs are only 6KB (easily transmissible)

---

## Technical Innovations Summary

1. **First ImageNet-Scale ZK-SNARK**: MobileNet v2 achieving 79% accuracy
2. **17,280x Speedup**: 10 seconds vs 2 days for prior work
3. **Practical Deployment**: Commodity hardware, 6KB proofs, 0.1% overhead
4. **Economic Viability**: $100 verification vs $85,000 expert annotation
5. **Novel Arithmetization**: Efficient quantized DNN representation with lookup arguments

---

## Future Directions

- Open-source release announced (see [zkml release post](https://medium.com/@danieldkang/open-sourcing-zkml-trustless-machine-learning-for-all-f5ee1dbf2499))
- Further optimizations for larger models (VGG, ResNet)
- Integration with smart contracts for automated verification
- Expansion to other ML domains (NLP, time-series, RL)

---

## References

Kang, D., et al. (2022). "Scaling up Trustless DNN Inference with Zero-Knowledge Proofs." *arXiv preprint arXiv:2210.08674*.

**Related Work**:
- [Open-sourcing zkml](https://ddkang.github.io/blog/2023/04/03/open-source/) - April 2023 update with 13% accuracy improvement, 6x proving cost reduction, 500x verification speedup
- [ZKAudit](https://medium.com/@danieldkang/introducing-zkaudit-trustless-audits-of-ml-with-zkml-f23025e203c1) - Trustless ML audits
