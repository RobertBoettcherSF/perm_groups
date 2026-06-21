------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Sims's Algorithm (1991)                     --
--  Optimized elementary version from "Efficient Representation of   --
--  Perm Groups" by Knuth, 1991                                  --
--                                                               --
--  File: permutations.adb                                        --
--  Description: Complete implementation with Sims Filter/Sift      --
--               and Enter algorithms                             --
--  Version: 0.16                                              --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "Efficient Representation of Perm Groups" --
--             1991 (unpublished paper)                             --
------------------------------------------------------------------

package body Permutations is
   pragma SPARK_Mode (On);

   -- Identity permutation
   -- Returns the identity permutation where each element maps to itself
   function Identity return Permutation is
      Result : Permutation;
   begin
      for I in Index loop
         Result(I) := I;
      end loop;
      return Result;
   end Identity;

   -- Permutation multiplication (composition)
   -- Computes the composition: (Left ∘ Right)(I) = Left(Right(I))
   function Multiply (Left, Right : Permutation) return Permutation is
      Result : Permutation;
   begin
      for I in Index loop
         Result(I) := Left(Right(I));
      end loop;
      return Result;
   end Multiply;

   -- Permutation inverse: computes the inverse bijection
   -- For a permutation P, Inverse(P) satisfies: P(Inverse(P)(I)) = I
   function Inverse (P : Permutation) return Permutation is
      Result : Permutation;
   begin
      for I in Index loop
         Result(P(I)) := I;
      end loop;
      return Result;
   end Inverse;

   -- Check if a permutation is the identity
   -- Returns True if P(I) = I for all I in Index
   function Is_Identity (P : Permutation) return Boolean is
   begin
      for I in Index loop
         pragma Loop_Invariant (for all J in Index'First .. I-1 => P(J) = J);
         if P(I) /= I then
            return False;
         end if;
      end loop;
      return True;
   end Is_Identity;

   -- Helper function for Sift to enable Subprogram_Variant
   -- This implements the core Sift algorithm with a decreasing level parameter
   -- that SPARK can use to prove termination
   function Sift_Helper (Pi : Permutation; Sigma : Sigma_Type; Current_Level : Index) return Sift_Result is
      K : Index;
      J : Index;
      Next_Level : Index;
      Result : Sift_Result;
      Found : Boolean := False;
   begin
      -- Base case: if we've checked all levels down to 1
      if Current_Level = 1 then
         Result := (Perm => Pi, Level => 1);
         return Result;
      end if;

      -- Find the largest k ≤ Current_Level such that π(k) ≠ k
      K := Current_Level;
      while K > 1 and then Pi(K) = K loop
         pragma Loop_Invariant (K > 1 and K <= Current_Level);
         pragma Loop_Invariant (for all I in K+1 .. Current_Level => Pi(I) = I);
         pragma Loop_Variant (Decreases => K);
         K := K - 1;
      end loop;
      
      -- After the loop, check if K = 1 separately
      if K = 1 and then Pi(1) = 1 then
         Found := False;  -- Mark as not found
      else
         Found := True;
      end if;

      -- If no such k found (π is identity on 1..Current_Level)
      if not Found then
         Result := (Perm => Pi, Level => 1);
         return Result;
      end if;

      -- Now we have K where Pi(K) ≠ K and K >= 1
      -- Since we exited the loop with K >= 1 and Pi(K) /= K, we know K is valid
      J := Pi(K);

      -- Check if σₖⱼ is present
      if Sigma(K, J).Is_Present then
         -- Multiply π by σₖⱼ⁻¹: π ← π ∘ σₖⱼ⁻¹
         declare
            Sigma_KJ_Inv : Permutation := Inverse(Sigma(K, J).Value);
            New_Pi : Permutation := Multiply(Pi, Sigma_KJ_Inv);
         begin
            -- Recursively sift the new permutation at level K-1
            -- If K = 1, we cannot go lower, so just return the new permutation
            if K = 1 then
               Result := (Perm => New_Pi, Level => 1);
               return Result;
            else
               Next_Level := K - 1;
               Result := Sift_Helper(New_Pi, Sigma, Next_Level);
               return Result;
            end if;
         end;
      else
         -- σₖⱼ is empty, return current π and level K
         Result := (Perm => Pi, Level => K);
         return Result;
      end if;
   end Sift_Helper;

   -- Sift function: the core of Sims's algorithm
   -- Finds the largest k such that j = π(k) ≠ k
   -- If σₖⱼ is present, multiplies π by σₖⱼ⁻¹ and repeats for smaller levels
   -- Returns the sifted permutation and the level it stopped at
   function Sift (Pi : Permutation; Sigma : Sigma_Type) return Sift_Result is
   begin
      -- Start with the highest level (Index'Last)
      return Sift_Helper(Pi, Sigma, Index'Last);
   end Sift;

   -- Helper procedure for Enter to enable Subprogram_Variant
   -- This implements the closure step with a counter for the number of transversals
   -- Uses Count as the variant measure to prove termination
   procedure Enter_Helper (Pi : Permutation; Sigma : in out Sigma_Type; Count : Integer) is
      Result : Sift_Result;
      K : Index;
      J : Index;
      Next_Count : Integer;
   begin
      -- Sift the permutation
      Result := Sift(Pi, Sigma);

      -- If the sifted result is the identity, π is already in the group
      if Is_Identity(Result.Perm) then
         return;
      end if;

      -- The sifted result is non-identity at level K
      K := Result.Level;
      J := Result.Perm(K);

      -- Insert into the transversal: σₖⱼ ← π'
      Sigma(K, J).Is_Present := True;
      Sigma(K, J).Value := Result.Perm;

      -- Closure step: for every existing non-empty σₓᵢ, form products
      -- σₖⱼ ∘ σₓᵢ and σₓᵢ ∘ σₖⱼ, and recursively call Enter on those products
      -- Count + 1 is at most Max_Count because Count < Max_Count (from precondition)
      Next_Count := Count + 1;
      
      for X in Index loop
         pragma Loop_Invariant (for all I in Index'First .. X-1 => 
                                (for all Y in Index => 
                                   (if Sigma(I, Y).Is_Present then 
                                      Sigma(I, Y).Value'Length = Max_Size)));
         for Y in Index loop
            pragma Loop_Invariant (for all Y2 in Index'First .. Y-1 => 
                                   (if Sigma(X, Y2).Is_Present then 
                                      Sigma(X, Y2).Value'Length = Max_Size));
            
            if Sigma(X, Y).Is_Present then
               -- Form product: σₖⱼ ∘ σₓᵢ
               declare
                  Product1 : Permutation := Multiply(Sigma(K, J).Value, Sigma(X, Y).Value);
               begin
                  Enter_Helper(Product1, Sigma, Next_Count);
               end;

               -- Form product: σₓᵢ ∘ σₖⱼ
               declare
                  Product2 : Permutation := Multiply(Sigma(X, Y).Value, Sigma(K, J).Value);
               begin
                  Enter_Helper(Product2, Sigma, Next_Count);
               end;
            end if;
         end loop;
      end loop;
   end Enter_Helper;

   -- Enter procedure: the closure step of Sims's algorithm
   -- Passes π through Sift
   -- If the sifted result is the identity, π is already in the group
   -- If the sifted result is non-identity at level k (where π'(k) = j),
   -- inserts it into the transversal: σₖⱼ ← π'
   -- Then performs closure: for every existing non-empty σₓᵢ, forms products
   -- σₖⱼ ∘ σₓᵢ and σₓᵢ ∘ σₖⱼ, and recursively calls Enter on those products
   procedure Enter (Pi : Permutation; Sigma : in out Sigma_Type) is
   begin
      -- Start with count 0 (bounded by Max_Size * Max_Size)
      Enter_Helper(Pi, Sigma, 0);
   end Enter;

   -- Initialize the transversal system
   -- Sets σₖₖ to the identity for all k, and all other σₖⱼ to empty
   procedure Initialize (Sigma : out Sigma_Type) is
      Id : constant Permutation := Identity;
      Empty_Opt : constant Optional_Permutation := (Is_Present => False, Value => Id);
      Identity_Opt : constant Optional_Permutation := (Is_Present => True, Value => Id);
   begin
      -- Initialize all σₖⱼ to empty first
      Sigma := (others => (others => Empty_Opt));
      
      -- Set σₖₖ to the identity for all k
      for K in Index loop
         Sigma(K, K) := Identity_Opt;
      end loop;
   end Initialize;

   -- Check if permutation Pi is a member of the group generated by Sigma
   -- A permutation π is a member if and only if Sift(Pi, Sigma) returns the identity
   function Is_Member (Pi : Permutation; Sigma : Sigma_Type) return Boolean is
   begin
      return Is_Identity(Sift(Pi, Sigma).Perm);
   end Is_Member;

   -- Add a new generator to the group
   -- Calls Enter to add the generator and maintain the strong generating set
   procedure Add_Generator (Pi : Permutation; Sigma : in out Sigma_Type) is
   begin
      Enter(Pi, Sigma);
   end Add_Generator;

   -- Compute the strong generating set for a given set of generators
   -- Initializes Sigma and adds each generator using Add_Generator
   procedure Compute_Strong_Generators (Generators : Generator_Array;
                                        Sigma : out Sigma_Type) is
   begin
      -- Initialize the transversal system
      Initialize(Sigma);

      -- Add each generator to the group
      for I in Generators'Range loop
         pragma Loop_Invariant (I >= Generators'First);
         Add_Generator(Generators(I), Sigma);
      end loop;
   end Compute_Strong_Generators;

   -- Create a transposition (swap of two elements)
   -- Returns a permutation that swaps I and J, leaving all other elements fixed
   function Create_Transposition (I, J : Index) return Permutation is
      Result : Permutation := Identity;
   begin
      Result(I) := J;
      Result(J) := I;
      return Result;
   end Create_Transposition;

   -- Create a cycle permutation
   -- Creates a permutation that cycles through the given elements:
   -- Elements(1) -> Elements(2) -> ... -> Elements(Length) -> Elements(1)
   function Create_Cycle (Elements : Cycle_Elements; Length : Positive) return Permutation is
      Result : Permutation := Identity;
   begin
      -- Create the cycle: Elements(1) -> Elements(2) -> ... -> Elements(Length) -> Elements(1)
      for K in 1 .. Length - 1 loop
         pragma Loop_Invariant (K >= 1 and K < Length);
         Result(Elements(K)) := Elements(K + 1);
      end loop;
      Result(Elements(Length)) := Elements(1);
      return Result;
   end Create_Cycle;

   -- Check if two permutations are equal
   -- Returns True if Left(I) = Right(I) for all I in Index
   function "=" (Left, Right : Permutation) return Boolean is
   begin
      for I in Index loop
         pragma Loop_Invariant (for all J in Index'First .. I-1 => Left(J) = Right(J));
         if Left(I) /= Right(I) then
            return False;
         end if;
      end loop;
      return True;
   end "=";

end Permutations;
