------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: test_random.adb                                         --
--  Description: Test with random permutations                    --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3                            --
------------------------------------------------------------------

with Permutations;
with Sims_Algorithm;
with Utils;
with Ada.Text_IO;
with Ada.Real_Time;
use Permutations;
use Sims_Algorithm;
use Utils;
use Ada.Text_IO;
use Ada.Real_Time;

procedure Test_Random is
   pragma SPARK_Mode (Off); -- Tests may use non-SPARK features for output

   -- Number of random tests to run
   Num_Tests : constant Positive := 10;
   Num_Generators : constant Positive := 5;

   -- Sigma and T data structures
   Sigma : Sigma_Type;
   T : T_Type;

   -- Vector to hold generators
   Generators : Perm_Vector;

   -- Test results
   Test_Passed : Boolean := True;
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;

begin
   Put_Line("=== RANDOM PERMUTATION GROUP TESTS ===");
   Put_Line("Running " & Integer'Image(Num_Tests) & " tests with " & 
            Integer'Image(Num_Generators) & " random generators each");

   -- Seed for random permutation generation
   Seed : Positive := 42; -- Fixed seed for reproducibility

   for Test_Num in 1 .. Num_Tests loop
      Put_Line("--- Test " & Integer'Image(Test_Num) & " ---");
      
      -- Clear previous data
      Generators.Clear;
      Initialize(Index'Last, Sigma, T);
      
      -- Generate random generators
      for I in 1 .. Num_Generators loop
         declare
            Random_Perm : Permutation := Random_Permutation(Seed + I + (Test_Num-1)*Num_Generators);
         begin
            Generators.Append(new Permutation'(Random_Perm));
            Put_Line("  Generated random permutation " & Integer'Image(I));
         end;
      end loop;
      
      -- Test 1: Add all generators to the group
      declare
         Start_Time, End_Time : Time;
      begin
         Start_Time := Clock;
         
         for I in 1 .. Generators.Length loop
            Add_Generator(Generators.Element(I).all, Sigma, T);
         end loop;
         
         End_Time := Clock;
         Put_Line("  Added " & Integer'Image(Generators.Length) & " generators in " & 
                  Duration'Image(To_Duration(End_Time - Start_Time)) & " seconds");
      end;
      
      -- Test 2: Verify all generators are in the group
      Total_Tests := Total_Tests + 1;
      for I in 1 .. Generators.Length loop
         if not Is_Member(Generators.Element(I).all, Index'Last, Sigma) then
            Test_Passed := False;
            Put_Line("  FAILED: Generator " & Integer'Image(I) & " not in group");
            goto Cleanup_Test;
         end if;
      end loop;
      Put_Line("  PASSED: All generators in group");
      Passed_Tests := Passed_Tests + 1;
      
      -- Test 3: Verify inverses are in the group
      Total_Tests := Total_Tests + 1;
      for I in 1 .. Generators.Length loop
         declare
            Gen_Inv : Permutation := Inverse(Generators.Element(I).all);
         begin
            if not Is_Member(Gen_Inv, Index'Last, Sigma) then
               Test_Passed := False;
               Put_Line("  FAILED: Inverse of generator " & Integer'Image(I) & " not in group");
               goto Cleanup_Test;
            end if;
         end;
      end loop;
      Put_Line("  PASSED: All generator inverses in group");
      Passed_Tests := Passed_Tests + 1;
      
      -- Test 4: Verify some products are in the group
      Total_Tests := Total_Tests + 1;
      for I in 1 .. Generators.Length loop
         for J in 1 .. Generators.Length loop
            declare
               Product : Permutation := Multiply(Generators.Element(I).all, Generators.Element(J).all);
            begin
               if not Is_Member(Product, Index'Last, Sigma) then
                  Test_Passed := False;
                  Put_Line("  FAILED: Product of generators " & Integer'Image(I) & " and " & 
                           Integer'Image(J) & " not in group");
                  goto Cleanup_Test;
               end if;
            end;
         end loop;
      end loop;
      Put_Line("  PASSED: All tested products in group");
      Passed_Tests := Passed_Tests + 1;
      
      -- Test 5: Verify identity is in the group
      Total_Tests := Total_Tests + 1;
      if not Is_Member(Identity, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("  FAILED: Identity not in group");
         goto Cleanup_Test;
      end if;
      Put_Line("  PASSED: Identity in group");
      Passed_Tests := Passed_Tests + 1;
      
      -- Test 6: Test Compute_Strong_Generators
      Total_Tests := Total_Tests + 1;
      declare
         Test_Sigma : Sigma_Type;
         Test_T : T_Type;
      begin
         Compute_Strong_Generators(Generators, Test_Sigma, Test_T);
         
         -- Verify all generators are in the computed group
         for I in 1 .. Generators.Length loop
            if not Is_Member(Generators.Element(I).all, Index'Last, Test_Sigma) then
               Test_Passed := False;
               Put_Line("  FAILED: Generator " & Integer'Image(I) & " not in computed group");
               goto Cleanup_Test;
            end if;
         end loop;
         Put_Line("  PASSED: Compute_Strong_Generators successful");
         Passed_Tests := Passed_Tests + 1;
      end;
      
      <<Cleanup_Test>>
      -- Clean up for next test
      for K in Index loop
         T(K).Clear;
         for J in Index loop
            Sigma(K, J).Clear;
         end loop;
      end loop;
      
      New_Line;
   end loop;

   -- Final results
   Put_Line("=== RANDOM TESTS SUMMARY ===");
   Put_Line("Total tests: " & Integer'Image(Total_Tests));
   Put_Line("Passed: " & Integer'Image(Passed_Tests));
   Put_Line("Failed: " & Integer'Image(Total_Tests - Passed_Tests));
   
   if Passed_Tests = Total_Tests then
      Put_Line("=== RANDOM TESTS: ALL PASSED ===");
   else
      Put_Line("=== RANDOM TESTS: SOME FAILED ===");
   end if;

   -- Clean up
   Generators.Clear;
   for K in Index loop
      T(K).Clear;
      for J in Index loop
         Sigma(K, J).Clear;
      end loop;
   end loop;

exception
   when others =>
      Put_Line("Exception occurred during random tests");
      Test_Passed := False;

end Test_Random;
