------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Sims's Algorithm (1991)                     --
--  Optimized elementary version from "Efficient Representation of   --
--  Perm Groups" by Knuth, 1991                                  --
--                                                               --
--  File: permutations.ads                                        --
--  Description: Complete implementation with Sims Filter/Sift      --
--               and Enter algorithms                             --
--  Version: 0.11                                              --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "Efficient Representation of Perm Groups" --
--             1991 (unpublished paper)                             --
------------------------------------------------------------------

package Permutations is
   pragma SPARK_Mode (On);

   -- Maximum size for permutations
   -- Defines the upper bound for the Index type and permutation domain
   Max_Size : constant Positive := 100;

   -- Index type for permutations: maps to positions 1..Max_Size
   -- This is the domain and codomain for all permutations
   type Index is new Positive range 1 .. Max_Size;

   -- Permutation type: a bijection from Index to Index
   -- Each permutation is represented as an array where P(I) gives the image of I
   type Permutation is array (Index) of Index;

   -- Optional permutation type for the transversal system
   -- Each σₖⱼ is either empty (Is_Present = False) or contains exactly one permutation
   -- This replaces the heavy vector implementation with a lightweight optional type
   type Optional_Permutation is record
      Is_Present : Boolean := False;
      Value : Permutation;
   end record;

   -- Sigma type: Σ(k,j) - transversal system for level k, position j
   -- For 1 ≤ j ≤ k, Sigma(K, J) holds at most one permutation
   -- σₖₖ is always the identity permutation
   -- This is a 2D array of Optional_Permutation over (Index, Index)
   type Sigma_Type is array (Index, Index) of Optional_Permutation;

   -- Identity permutation
   -- Returns the identity permutation where each element maps to itself
   function Identity return Permutation
     with SPARK_Mode => On,
          Pre => True,
          Post => (for all I in Index => Identity'Result(I) = I);

   -- Permutation multiplication (composition): Left * Right
   -- Computes the composition: (Left ∘ Right)(I) = Left(Right(I))
   function Multiply (Left, Right : Permutation) return Permutation
     with SPARK_Mode => On,
          Pre => (for all I in Index => Left(I) in Index and Right(I) in Index);

   -- Permutation inverse: computes the inverse bijection
   -- For a permutation P, Inverse(P) satisfies: P(Inverse(P)(I)) = I
   function Inverse (P : Permutation) return Permutation
     with SPARK_Mode => On,
          Pre => True;

   -- Check if a permutation is the identity
   -- Returns True if P(I) = I for all I in Index
   function Is_Identity (P : Permutation) return Boolean
     with SPARK_Mode => On,
          Pre => True,
          Post => Is_Identity'Result = (for all I in Index => P(I) = I);

   -- Sift result type: contains the sifted permutation and the level it stopped at
   -- Used by the Sift algorithm to return both the result and the termination level
   type Sift_Result is record
      Perm : Permutation;
      Level : Index;
   end record;

   -- Sift function: the core of Sims's algorithm
   -- Finds the largest k such that j = π(k) ≠ k
   -- If σₖⱼ is present, multiplies π by σₖⱼ⁻¹ and repeats for smaller levels
   -- Returns the sifted permutation and the level it stopped at
   -- If π is the identity, returns identity at level 1
   -- Uses Subprogram_Variant to prove termination (decreasing level)
   function Sift (Pi : Permutation; Sigma : Sigma_Type) return Sift_Result
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size;

   -- Helper function for Sift to enable Subprogram_Variant
   -- This is needed because SPARK requires the variant to reference a state component
   -- Uses Current_Level as the variant measure
   function Sift_Helper (Pi : Permutation; Sigma : Sigma_Type; Current_Level : Index) return Sift_Result
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size and Current_Level in Index,
          Subprogram_Variant => (Decreases => Current_Level);

   -- Enter procedure: the closure step of Sims's algorithm
   -- Passes π through Sift
   -- If the sifted result is the identity, π is already in the group
   -- If the sifted result is non-identity at level k (where π'(k) = j),
   -- inserts it into the transversal: σₖⱼ ← π'
   -- Then performs closure: for every existing non-empty σₓᵢ, forms products
   -- σₖⱼ ∘ σₓᵢ and σₓᵢ ∘ σₖⱼ, and recursively calls Enter on those products
   -- Uses Subprogram_Variant to prove termination via Depth parameter
   procedure Enter (Pi : Permutation; Sigma : in out Sigma_Type)
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size;

   -- Helper procedure for Enter to enable Subprogram_Variant
   -- Uses Depth as the variant measure to prove termination
   -- Depth is bounded by Max_Size * Max_Size to prevent infinite recursion
   procedure Enter_Helper (Pi : Permutation; Sigma : in out Sigma_Type; Depth : Integer)
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size and Depth >= 0 and Depth <= Max_Size * Max_Size,
          Subprogram_Variant => (Decreases => Depth);

   -- Initialize the transversal system
   -- Sets σₖₖ to the identity for all k, and all other σₖⱼ to empty
   procedure Initialize (Sigma : out Sigma_Type)
     with SPARK_Mode => On,
          Post => (for all K in Index => Sigma(K, K).Is_Present and then Sigma(K, K).Value = Identity) and
                  (for all K in Index => (for all J in Index => (if J /= K then not Sigma(K, J).Is_Present)));

   -- Check if permutation Pi is a member of the group generated by Sigma
   -- A permutation π is a member if and only if Sift(Pi, Sigma) returns the identity
   function Is_Member (Pi : Permutation; Sigma : Sigma_Type) return Boolean
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size,
          Post => Is_Member'Result = Is_Identity(Sift(Pi, Sigma).Perm);

   -- Add a new generator to the group
   -- Calls Enter to add the generator and maintain the strong generating set
   procedure Add_Generator (Pi : Permutation; Sigma : in out Sigma_Type)
     with SPARK_Mode => On,
          Pre => Pi'Length = Max_Size;

   -- Compute the strong generating set for a given set of generators
   -- Initializes Sigma and adds each generator using Add_Generator
   type Generator_Array is array (Positive range <>) of Permutation;
   
   procedure Compute_Strong_Generators (Generators : Generator_Array;
                                        Sigma : out Sigma_Type)
     with SPARK_Mode => On,
          Pre => Generators'Length > 0 and
                (for all I in Generators'Range => Generators(I)'Length = Max_Size);

   -- Create a transposition (swap of two elements)
   -- Returns a permutation that swaps I and J, leaving all other elements fixed
   function Create_Transposition (I, J : Index) return Permutation
     with SPARK_Mode => On,
          Pre => I in Index and J in Index;

   -- Maximum number of elements for cycle creation
   Max_Cycle_Size : constant Positive := Max_Size;
   
   -- Type for cycle elements: array of indices for cycle construction
   type Cycle_Elements is array (Positive range 1 .. Max_Cycle_Size) of Index;
   
   -- Create a cycle permutation
   -- Creates a permutation that cycles through the given elements:
   -- Elements(1) -> Elements(2) -> ... -> Elements(Length) -> Elements(1)
   function Create_Cycle (Elements : Cycle_Elements; Length : Positive) return Permutation
     with SPARK_Mode => On,
          Pre => Length >= 2 and Length <= Max_Cycle_Size and
                (for all I in 1 .. Length => Elements(I) in Index);

   -- Check if two permutations are equal
   -- Returns True if Left(I) = Right(I) for all I in Index
   function "=" (Left, Right : Permutation) return Boolean
     with SPARK_Mode => On,
          Pre => True,
          Post => "="'Result = (for all I in Index => Left(I) = Right(I));

end Permutations;
