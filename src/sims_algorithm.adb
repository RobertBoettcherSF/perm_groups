------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: sims_algorithm.adb                                      --
--  Description: Sims' algorithm implementation                    --
--  Version: 0.01                                               --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3                            --
------------------------------------------------------------------

with Permutations;
use Permutations;

package body Sims_Algorithm is
   pragma SPARK_Mode (On);

   -- Algorithm Aₖ(π): Appends a new permutation π to T(k)
   procedure Algorithm_A (K : Index; Pi : Permutation;
                         Sigma : in out Sigma_Type;
                         T : in out T_Type) is
   begin
      -- Add Pi to T(K)
      T(K).Append(new Permutation'(Pi));
      
      -- If K = 1, we're done (base case)
      if K = 1 then
         return;
      end if;
      
      -- For all σ ∈ Σ(k) and τ ∈ T(k), check if στ is not already in Γ(k)
      -- We need to call Algorithm_B for each such product
      for J in Index loop
         if Sigma(K, J).Length > 0 then
            declare
               Sigma_KJ : Permutation := Sigma(K, J).Element(1).all;
            begin
               -- For each τ in T(K)
               for Tau_Idx in 1 .. T(K).Length loop
                  declare
                     Tau : Permutation := T(K).Element(Tau_Idx).all;
                     Product : Permutation := Multiply(Sigma_KJ, Tau);
                  begin
                     -- Check if Product is not already in Γ(k)
                     if not Is_Member(Product, K, Sigma) then
                        -- Call Algorithm_B for this product
                        Algorithm_B(K, Product, Sigma, T);
                     end if;
                  end;
               end loop;
            end;
         end if;
      end loop;
      
      -- Also check products with the new Pi
      for Tau_Idx in 1 .. T(K).Length loop
         declare
            Tau : Permutation := T(K).Element(Tau_Idx).all;
            Product1 : Permutation := Multiply(Pi, Tau);
            Product2 : Permutation := Multiply(Tau, Pi);
         begin
            if not Is_Member(Product1, K, Sigma) then
               Algorithm_B(K, Product1, Sigma, T);
            end if;
            if not Is_Member(Product2, K, Sigma) then
               Algorithm_B(K, Product2, Sigma, T);
            end if;
         end;
      end loop;
   end Algorithm_A;

   -- Algorithm Bₖ(π): Ensures π is in Γ(k)
   procedure Algorithm_B (K : Index; Pi : Permutation;
                         Sigma : in out Sigma_Type;
                         T : in out T_Type) is
   begin
      -- Let π map k ↦ j
      declare
         J : Index := Pi(K);
      begin
         -- If σₖⱼ is empty, set σₖⱼ ← π and terminate
         if Sigma(K, J).Length = 0 then
            Sigma(K, J).Append(new Permutation'(Pi));
            return;
         end if;
         
         -- If k = 1, we're done (base case)
         if K = 1 then
            return;
         end if;
         
         -- Check if πσₖⱼ⁻¹ ∈ Γ(k-1)
         declare
            Sigma_KJ : Permutation := Sigma(K, J).Element(1).all;
            Sigma_KJ_Inv : Permutation := Inverse(Sigma_KJ);
            Pi_Transformed : Permutation := Multiply(Pi, Sigma_KJ_Inv);
         begin
            if Is_Member(Pi_Transformed, K-1, Sigma) then
               return; -- π is already in Γ(k), terminate
            else
               -- Otherwise, call Algorithm Aₖ₋₁(πσₖⱼ⁻¹)
               Algorithm_A(K-1, Pi_Transformed, Sigma, T);
               
               -- After adding new generators, we may need to update σₖⱼ
               -- Check if we need to update the transversal
               if not Is_Member(Pi, K, Sigma) then
                  Sigma(K, J).Clear;
                  Sigma(K, J).Append(new Permutation'(Pi));
               end if;
            end if;
         end;
      end;
   end Algorithm_B;

   -- Initialize the data structures for a given group size N
   procedure Initialize (N : Index;
                        Sigma : out Sigma_Type;
                        T : out T_Type) is
   begin
      -- Initialize all T(k) to empty vectors
      for K in Index loop
         T(K).Clear;
      end loop;
      
      -- Initialize all σₖⱼ to empty vectors
      for K in Index loop
         for J in Index loop
            Sigma(K, J).Clear;
         end loop;
      end loop;
   end Initialize;

   -- Add a new generator to the group
   procedure Add_Generator (Pi : Permutation;
                           Sigma : in out Sigma_Type;
                           T : in out T_Type) is
   begin
      -- Start with the highest level (Index'Last)
      Algorithm_B(Index'Last, Pi, Sigma, T);
   end Add_Generator;

   -- Compute the strong generating set for a given set of generators
   procedure Compute_Strong_Generators (Generators : Perm_Vector;
                                        Sigma : out Sigma_Type;
                                        T : out T_Type) is
   begin
      -- Initialize the data structures
      Initialize(Index'Last, Sigma, T);
      
      -- Add each generator to the group
      for I in 1 .. Generators.Length loop
         Add_Generator(Generators.Element(I).all, Sigma, T);
      end loop;
   end Compute_Strong_Generators;

end Sims_Algorithm;
