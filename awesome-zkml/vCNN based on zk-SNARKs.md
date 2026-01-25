# vCNN: Verifiable Convolutional Neural Network based on zk-SNARKs

**Paper**: https://eprint.iacr.org/2020/584
**Authors**: Seunghwa Lee, Hankyung Ko, Jihye Kim, Hyunok Oh

---

## Introduction (Understanding the Problem Space)

**TL;DR**: AI inference services need verification without revealing proprietary weights or private input data. Traditional zk-SNARKs enable this but are prohibitively slow for real applications. vCNN solves this by reducing convolution proving complexity from O(ln) to O(l+n), where l=kernel size and n=data size, achieving 20-18000x speedup over existing approaches.

**Key Problem**:
- CNNs are deployed in safety-critical applications (healthcare, insurance) where incorrect results can cause severe damage
- Service providers need to protect CNN weights (intellectual property)
- Users need privacy for input data, especially when results are verified by third parties
- Re-execution for verification is impossible without access to weights and input data

**Solution Approach**:
- Zero-knowledge SNARKs allow verification without revealing private information (weights or inputs)
- However, existing zk-SNARK approaches have O(ln) proving complexity for convolutions, making them too slow
- vCNN proposes efficient relation representation reducing complexity to O(l+n)
- Experimental results show 20x improvement for MNIST and 18000x for VGG16

---

## Architecture Overview

**TL;DR**: vCNN uses a hybrid approach combining Quadratic Polynomial Programs (QPP) for convolutions and Quadratic Arithmetic Programs (QAP) for other CNN operations (ReLU, pooling). These are connected via Commit and Prove SNARKs (CP-SNARKs) to avoid performance degradation from treating all operations uniformly.

**Key Design Decisions**:
- **QPP for Convolutions**: Optimizes the dominant computational cost (90%+ of proving time)
- **QAP for Non-Convolutions**: Handles ReLU and pooling operations efficiently
- **CP-SNARK Connection**: Bridges QPP and QAP circuits without mutual performance degradation
  - Prevents degree amplification that would occur if everything used QPP (would blow up to O((|x|+|a|)²) for ReLU/pooling)
  - Allows independent treatment of convolution and non-convolution intermediates

**System Components**:
1. Commitment scheme for hiding AI weights and input data
2. QPP-based proof generation for convolutions
3. QAP-based proof generation for activation and pooling layers
4. CP-SNARK for connecting proofs across different representations

---

## How Convolutional Layers are Proven in ZK

**TL;DR**: Standard QAP encoding of convolution requires O(ln) multiplication gates (one per output×kernel element). vCNN transforms the "sum of products" representation into "product of sums" using polynomial circuits (QPP), requiring only a single multiplication gate. This reduces proving complexity from O(ln) to O(l+n) by expressing convolution as x(Z)·a(Z)=y(Z) where coefficients are encoded in polynomial form.

**Standard Approach (Inefficient)**:
- Convolution: `yi = Σ(aj · xi-j+l-1)` for i∈[n]
- Encoded as QAP with n×l multiplication gates
- Example: 5 inputs, 3 kernel = 9 multiplication gates
- Complexity: O(|x|·|a|) = O(ln)

**vCNN Optimization**:
1. **Transform to Product of Sums**:
   - Change from `Σ(aj·xi)` to `(Σxi)·(Σai)`
   - Naive transformation is unsound (different outputs can have same sum)

2. **Add Indeterminate Variable Z**:
   - Express as: `(Σ xiZ^i)·(Σ aiZ^i) = Σ yiZ^i`
   - This identity must hold for all choices of Z
   - Creates unique polynomial representation

3. **Use QPP Instead of QAP**:
   - Quadratic Polynomial Program allows wires to carry polynomial values
   - Single multiplication of polynomials: x(Z)·a(Z)=y(Z)
   - Complexity: O(|x|+|a|) = O(l+n)

**Technical Details**:
- Product of sums representation requires "dummy" equations (head/tail parts)
- Uses Number Theoretic Transform (NTT) for fast polynomial division
- Converts bivariate to univariate polynomial by degree elevation for efficiency

---

## Performance Benchmarks

**TL;DR**: vCNN achieves 20x speedup for simple models (MNIST) and up to 18000x for complex models (VGG16) compared to Groth16. For VGG16, vCNN generates proofs in 8 hours vs 10 years for Groth16, with CRS size reduced from 1400TB to 83GB. Verification time remains constant (~75ms to 19.4s depending on model complexity).

### Small CNN Models
**MNIST (single conv+pool layer, kernel size 10)**:
- Kernel depth 3: 2.6x faster setup, 3.3x faster proving, 3.3x smaller CRS
- Kernel depth 15: 9x faster setup, 7.5x faster proving, 12.3x smaller CRS
- 32-bit quantization: 20x faster proving, 30x smaller CRS

**Multi-layer MNIST (3×3 kernel, 10-bit quantization)**:
- 2 layers: 10.6x faster setup, 12x faster proving, 14.5x smaller CRS
- Groth16 fails beyond 2 layers due to memory requirements
- vCNN generates proof in <11 seconds with 55MB CRS

### Real CNN Models

| Model | Setup | Prove | Verify | CRS Size | Speedup vs Groth16 |
|-------|-------|-------|--------|----------|-------------------|
| **LeNet-5** | 19.47s | 9.34s | 75ms | 40.07MB | 291x |
| **AlexNet** | 20min | 18min | 130ms | 2.1GB | 1200x |
| **VGG16** | 10hrs | 8hrs | 19.4s | 83GB | 18000x |
| **VGG16+FC** | 2days | 2days | 19.4s | 420GB | 3400x |

**Groth16 Comparison**:
- LeNet-5: 1.5hrs setup, 0.75hrs prove, 11GB CRS
- AlexNet: 16 days setup, 14 days prove, 2.5TB CRS
- VGG16: 13 years setup, 10 years prove, 1400TB CRS (impractical)

**Key Insights**:
- Proof size: 2803 bits (vCNN) vs 1019 bits (Groth16)
- Verification time equivalent across approaches
- Performance gain increases with model complexity
- vCNN makes previously impractical verifications feasible

---

## References
Lee, S., Ko, H., Kim, J., & Oh, H. (2020). vCNN: Verifiable Convolutional Neural Network based on zk-SNARKs. *IACR Cryptology ePrint Archive*, 2020/584.
