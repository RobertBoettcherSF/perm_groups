# Permutation Groups in Ada SPARK

**Implementation of Sims's Algorithm (1991) - Optimized Elementary Version**

This repository contains a complete Ada SPARK implementation of the **optimized elementary version of Sims's algorithm** from Donald E. Knuth's 1991 paper "Efficient Representation of Perm Groups". This implementation replaces the original TAOCP algorithms with the more efficient Filter/Sift and Enter algorithms.

## Overview

This implementation provides:

- **Sift Algorithm**: The core filtering operation that reduces permutations to their normal form
- **Enter Algorithm**: The closure operation that maintains the strong generating set
- **Membership Testing**: Efficient membership test using the Sift algorithm
- **Complete SPARK Verification**: All code is SPARK 2022 compatible with formal verification support

## Features

### Core Algorithms

1. **Sift Function** (`Sift`)
   - Finds the largest k such that π(k) ≠ k
   - If σₖⱼ is present, multiplies π by σₖⱼ⁻¹ and repeats for smaller levels
   - Returns the sifted permutation and the level it stopped at
   - Uses Subprogram_Variant to prove termination

2. **Enter Procedure** (`Enter`)
   - Passes π through Sift
   - If the sifted result is the identity, π is already in the group
   - If the sifted result is non-identity at level k, inserts it into σₖⱼ
   - Performs closure: for every existing σₓᵢ, forms products and recursively calls Enter
   - Uses Subprogram_Variant to prove termination

3. **Membership Testing** (`Is_Member`)
   - A permutation π is a member if and only if Sift(Pi, Sigma) returns the identity
   - Simple and efficient: `Is_Member(Pi, Sigma) = Is_Identity(Sift(Pi, Sigma).Perm)`

### Data Structures

- **Permutation**: Array type mapping Index to Index (bijections)
- **Optional_Permutation**: Lightweight optional type with boolean discriminant
  - Replaces the heavy vector implementation
  - Each σₖⱼ is either empty (Is_Present = False) or contains exactly one permutation
- **Sigma_Type**: 2D array of Optional_Permutation over (Index, Index)
  - For 1 ≤ j ≤ k, Sigma(K, J) holds at most one permutation
  - σₖₖ is always the identity permutation

### Utility Functions

- **Identity**: Returns the identity permutation
- **Multiply**: Computes permutation composition (Left ∘ Right)
- **Inverse**: Computes the inverse of a permutation
- **Is_Identity**: Checks if a permutation is the identity
- **Create_Transposition**: Creates a transposition (swap of two elements)
- **Create_Cycle**: Creates a cycle permutation from a list of elements
- **"=" Operator**: Checks equality of two permutations

## File Structure

```
perm_groups/
├── permutations.ads    # Package specification with all type and function declarations
├── permutations.adb    # Package body with complete implementations
├── perm_groups.gpr     # GPRbuild project file
└── README.md           # This file
```

## Requirements

- **Ada 2022** compiler (GNAT)
- **SPARK 2022** (GNATPROVE)
- **Alire** (recommended for dependency management)

## Installation

### Using Alire

```bash
# Install Alire (if not already installed)
curl -fsSL https://alire.ada.dev/install | bash

# Clone this repository
git clone https://github.com/RobertBoettcherSF/perm_groups.git
cd perm_groups

# Load Alire environment
source ~/alire/env.sh

# Install GNATPROVE
alr toolchain --select gnatprove
```

### Manual Installation

Ensure you have:
- GNAT compiler with Ada 2022 support
- GNATPROVE for SPARK verification

## Usage

### Compilation

```bash
# Compile the package
gnatmake -P perm_groups.gpr
```

### Formal Verification with GNATPROVE

```bash
# Basic verification (all levels)
gnatprove -P perm_groups.gpr --level=4

# With timeout (13 minutes = 780 seconds)
timeout 780s gnatprove -P perm_groups.gpr --level=4 --no-inlining --report=all --verbose

# Quick verification (level 2: flow analysis only)
gnatprove -P perm_groups.gpr --level=2
```

### Example Usage in Ada Code

```ada
with Permutations;

procedure Test_Permutation_Groups is
   use Permutations;
   
   -- Define some permutations
   Gen1 : Permutation := Create_Transposition(1, 2);
   Gen2 : Permutation := Create_Transposition(2, 3);
   
   -- Array of generators
   Generators : Generator_Array(1 .. 2) := (Gen1, Gen2);
   
   -- Compute strong generating set
   Sigma : Sigma_Type;
   
begin
   Compute_Strong_Generators(Generators, Sigma);
   
   -- Test membership
   Test_Perm : Permutation := Multiply(Gen1, Gen2);
   if Is_Member(Test_Perm, Sigma) then
      -- Test_Perm is in the group
      null;
   end if;
end Test_Permutation_Groups;
```

## Implementation Details

### Key Differences from TAOCP Implementation

This implementation uses **Sims's optimized algorithm** instead of Knuth's original TAOCP algorithms:

1. **Data Structure**: Uses `Optional_Permutation` instead of `Permutation_Vector`
   - Each σₖⱼ holds at most one permutation (or is empty)
   - More memory efficient
   - Simpler to reason about in SPARK

2. **Sift Algorithm**: Replaces the complex recursive membership test
   - Iteratively reduces permutations using existing transversals
   - Returns both the reduced permutation and the level it stopped at

3. **Enter Algorithm**: Replaces Algorithm_A and Algorithm_B
   - Single unified procedure for adding generators
   - Includes closure step to maintain strong generating set
   - Uses depth counter for termination proof

### SPARK Compatibility

This implementation addresses several SPARK-specific challenges:

1. **No Dynamic Allocation**: Uses only static arrays and records
2. **Recursion Termination**: Uses Subprogram_Variant with decreasing measures
3. **Loop Invariants**: All loops include pragma Loop_Invariant
4. **Explicit Initialization**: All functions explicitly initialize their results
5. **Type Safety**: Proper type conversions and bounds checking

### Algorithm Complexity

Sims's algorithms have the following characteristics:

- **Sift**: O(n) where n is the permutation size (Max_Size)
- **Enter**: O(|Σ|²) in the worst case for closure step
- **Is_Member**: O(n) via Sift

The implementation uses:
- Maximum permutation size: 100 (Max_Size)
- No dynamic memory allocation

### Mathematical Background

From Knuth's 1991 paper "Efficient Representation of Perm Groups":

- **σₖⱼ**: The transversal for level k, position j (either empty or a single permutation)
- **Sift(π)**: Reduces π using existing transversals, returns (π', k) where π' fixes k+1..n
- **Enter(π)**: Adds π to the transversal system and performs closure

The key invariant:
```
For all k, j: if σₖⱼ is present, then σₖⱼ ∈ Γ(k) and σₖⱼ(k) = j
```

## Version History

| Version | Date       | Description |
|---------|------------|-------------|
| 0.01-0.08 | 2024    | Initial TAOCP implementation with various fixes |
| 0.09    | 2024      | Comprehensive SPARK fixes and documentation |
| 0.10    | 2024      | Final version with comprehensive comments |
| 0.11    | 2024      | **Refactored to Sims's Algorithm (1991)** - Replaced TAOCP algorithms with Sift/Enter, Optional_Permutation data structure |

## References

1. Knuth, Donald E. *The Art of Computer Programming*, Volume 2: Seminumerical Algorithms. Addison-Wesley, 1969. Section 4.6.3: Semi-invariants of a Group.

2. Knuth, Donald E. "Efficient Representation of Perm Groups". Unpublished paper, 1991.

3. Sims, Charles C. "Computing with Permutation Groups". In *Computational Group Theory*, Academic Press, 1970.

4. SPARK 2022 Language Reference Manual

5. Ada 2022 Language Reference Manual

## License

This implementation is provided as-is for educational and research purposes. It implements the algorithms described in Donald E. Knuth's work on permutation groups and is intended for use in formal verification and group theory applications.

## Contributing

Contributions are welcome! Please ensure:
- All code maintains SPARK 2022 compatibility
- All functions include proper SPARK contracts (Pre/Post)
- All loops include Loop_Invariant pragmas
- All recursive functions include Subprogram_Variant aspects
- Version numbers are incremented in file headers

## Support

For questions or issues, please refer to:
- The GitHub repository issues page
- Knuth's "Efficient Representation of Perm Groups" (1991)
- SPARK documentation for formal verification guidance
