------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: utils.adb                                               --
--  Description: Utility functions implementation                  --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3                            --
------------------------------------------------------------------

with Permutations;
use Permutations;

package body Utils is
   pragma SPARK_Mode (On);

   -- Create a permutation from a list of images
   function Create_Permutation (Input : array (Index) of Index) return Permutation is
   begin
      return Result : Permutation do
         for I in Index loop
            Result(I) := Input(I);
         end loop;
      end return;
   end Create_Permutation;

   -- Create a transposition (swap of two elements)
   function Create_Transposition (I, J : Index) return Permutation is
   begin
      return Result : Permutation := Identity do
         Result(I) := J;
         Result(J) := I;
      end return;
   end Create_Transposition;

   -- Create a cycle permutation
   function Create_Cycle (Elements : array (Positive range <>) of Index) 
                          return Permutation is
   begin
      return Result : Permutation := Identity do
         -- Create the cycle: Elements(1) -> Elements(2) -> ... -> Elements(N) -> Elements(1)
         for K in Elements'First .. Elements'Last - 1 loop
            Result(Elements(K)) := Elements(K + 1);
         end loop;
         Result(Elements(Elements'Last)) := Elements(Elements'First);
      end return;
   end Create_Cycle;

   -- Check if a permutation is a derangement (no fixed points)
   function Is_Derangement (P : Permutation) return Boolean is
   begin
      for I in Index loop
         if P(I) = I then
            return False;
         end if;
      end loop;
      return True;
   end Is_Derangement;

   -- Helper function to compute GCD
   function GCD (A, B : Positive) return Positive is
   begin
      if B = 0 then
         return A;
      else
         return GCD(B, A mod B);
      end if;
   end GCD;

   -- Helper function to compute LCM
   function LCM (A, B : Positive) return Positive is
   begin
      return (A * B) / GCD(A, B);
   end LCM;

   -- Compute the order of a permutation (least common multiple of cycle lengths)
   function Permutation_Order (P : Permutation) return Positive is
      Visited : array (Index) of Boolean := (others => False);
      Result : Positive := 1;
   begin
      for I in Index loop
         if not Visited(I) then
            -- Found a new cycle, compute its length
            declare
               Current : Index := I;
               Cycle_Length : Positive := 0;
            begin
               loop
                  if Visited(Current) then
                     exit;
                  end if;
                  Visited(Current) := True;
                  Current := P(Current);
                  Cycle_Length := Cycle_Length + 1;
               end loop;
               
               if Cycle_Length > 1 then
                  Result := LCM(Result, Cycle_Length);
               end if;
            end;
         end if;
      end loop;
      
      return Result;
   end Permutation_Order;

   -- Check if two permutations commute
   function Commute (P1, P2 : Permutation) return Boolean is
   begin
      return Multiply(P1, P2) = Multiply(P2, P1);
   end Commute;

   -- Simple deterministic "random" permutation generator
   -- Uses a linear congruential generator for SPARK compatibility
   function Random_Permutation (Seed : Positive) return Permutation is
      N : constant Positive := Index'Last;
      Result : Permutation := Identity;
      Current : Positive := Seed;
      A : constant Positive := 1664525;
      C : constant Positive := 1013904223;
      M : constant Positive := 2**32;
   begin
      -- Fisher-Yates shuffle
      for I in Index loop
         -- Generate a random index between I and N
         Current := (A * Current + C) mod M;
         declare
            J : Index := Index'First + (Current mod (Index'Last - I + 1));
            Temp : Index := Result(I);
         begin
            Result(I) := Result(J);
            Result(J) := Temp;
         end;
      end loop;
      
      return Result;
   end Random_Permutation;

   -- Print a permutation (for debugging, not SPARK verified)
   procedure Print_Permutation (P : Permutation) is
   begin
      for I in Index loop
         if P(I) = I then
            null; -- Don't print fixed points for compact output
         else
            null;
         end if;
      end loop;
   end Print_Permutation;

   -- Print the current state of Sigma and T (for debugging, not SPARK verified)
   procedure Print_State (Sigma : Sigma_Type; T : T_Type) is
   begin
      null; -- Placeholder for debugging output
   end Print_State;

end Utils;
