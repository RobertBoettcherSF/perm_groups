------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: utils.ads                                               --
--  Description: Utility functions for permutation groups          --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3                            --
------------------------------------------------------------------

with Permutations;
use Permutations;

package Utils is
   pragma SPARK_Mode (On);

   -- Create a permutation from a list of images
   -- Input: array where Input(I) is the image of I under the permutation
   function Create_Permutation (Input : array (Index) of Index) return Permutation
     with SPARK_Mode => On,
          Pre => (for all I in Index => Input(I) in Index),
          Post => (for all I in Index => Create_Permutation'Result(I) = Input(I));

   -- Create a transposition (swap of two elements)
   function Create_Transposition (I, J : Index) return Permutation
     with SPARK_Mode => On,
          Pre => I in Index and J in Index,
          Post => Create_Transposition'Result(I) = J and
                 Create_Transposition'Result(J) = I and
                 (for all K in Index => 
                    (if K /= I and K /= J then Create_Transposition'Result(K) = K));

   -- Create a cycle permutation
   -- Example: Create_Cycle((1,2,3)) creates the permutation 1→2, 2→3, 3→1
   function Create_Cycle (Elements : array (Positive range <>) of Index) 
                          return Permutation
     with SPARK_Mode => On,
          Pre => Elements'Length >= 2 and then
                (for all I in Elements'Range => Elements(I) in Index) and then
                (for all I in Elements'Range => 
                   (for all J in I+1 .. Elements'Range => Elements(I) /= Elements(J)));

   -- Check if a permutation is a derangement (no fixed points)
   function Is_Derangement (P : Permutation) return Boolean
     with SPARK_Mode => On,
          Post => Is_Derangement'Result = (for all I in Index => P(I) /= I);

   -- Compute the order of a permutation (least common multiple of cycle lengths)
   function Permutation_Order (P : Permutation) return Positive
     with SPARK_Mode => On;

   -- Check if two permutations commute
   function Commute (P1, P2 : Permutation) return Boolean
     with SPARK_Mode => On,
          Post => Commute'Result = (Multiply(P1, P2) = Multiply(P2, P1));

   -- Generate a random permutation (for testing)
   -- Note: This uses a simple deterministic algorithm for SPARK compatibility
   function Random_Permutation (Seed : Positive) return Permutation
     with SPARK_Mode => On;

   -- Print a permutation (for debugging, not SPARK verified)
   procedure Print_Permutation (P : Permutation)
     with SPARK_Mode => Off;

   -- Print the current state of Sigma and T (for debugging, not SPARK verified)
   procedure Print_State (Sigma : Sigma_Type; T : T_Type)
     with SPARK_Mode => Off;

end Utils;
