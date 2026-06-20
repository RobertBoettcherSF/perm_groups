# Permutation Groups in Ada SPARK

## Overview

This repository contains a simplified Ada SPARK implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) for computing strong generators and transversal systems of permutation groups.

**Version: 0.01**

## Reference

Knuth, D.E. *The Art of Computer Programming*, Volume 2: Seminumerical Algorithms, Section 4.6.3

## Simplified Repository Structure

```
perm_groups/
├── permutations.ads    # Complete implementation (specification)
├── permutations.adb    # Complete implementation (body)
├── perm_groups.gpr    # GPRbuild project file
└── README.md          # This file
```

## Features

- **Formal Verification**: All code with SPARK 2022 contracts
- **Knuth's Algorithms**: Complete implementation of Aₖ(π) and Bₖ(π)
- **Data Structures**: Σ(k) and T(k) using Ada.Containers.Vectors
- **Simplified Structure**: Easy to copy and verify individual files

## Usage

### Compilation
```bash
gprbuild -P perm_groups.gpr
```

### Verification
```bash
gnatprove -P perm_groups.gpr --level=4 --timeout=0 --no-inlining --report=all --verbose
```

## API

The `Permutations` package provides:

```ada
-- Types
type Index is new Positive range 1 .. 100;
type Permutation is array (Index) of Index;
type Perm_Vector is new Ada.Containers.Vectors.Vector;
type Sigma_Type is array (Index, Index) of Perm_Vector;
type T_Type is array (Index) of Perm_Vector;

-- Basic operations
function Identity return Permutation;
function Multiply (Left, Right : Permutation) return Permutation;
function Inverse (P : Permutation) return Permutation;
function Is_Identity (P : Permutation) return Boolean;
function Is_Member (Pi : Permutation; K : Index; Sigma : Sigma_Type) return Boolean;

-- Knuth's algorithms
procedure Algorithm_A (K : Index; Pi : Permutation; Sigma : in out Sigma_Type; T : in out T_Type);
procedure Algorithm_B (K : Index; Pi : Permutation; Sigma : in out Sigma_Type; T : in out T_Type);
procedure Initialize (N : Index; Sigma : out Sigma_Type; T : out T_Type);
procedure Add_Generator (Pi : Permutation; Sigma : in out Sigma_Type; T : in out T_Type);
procedure Compute_Strong_Generators (Generators : Perm_Vector; Sigma : out Sigma_Type; T : out T_Type);

-- Utility functions
function Create_Transposition (I, J : Index) return Permutation;
function Create_Cycle (Elements : array (Positive range <>) of Index) return Permutation;
function "=" (Left, Right : Permutation) return Boolean;
```

## Version History

- **Version 0.01**: Simplified implementation with all algorithms in single files

## License

Open source for academic and research use.

---
*Implementation by Vibe Code Agent, 2024*