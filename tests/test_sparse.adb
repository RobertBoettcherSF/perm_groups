------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: test_sparse.adb                                         --
--  Description: Test sparse example from Knuth's paper Section 5 --
--  Version: 0.01                                               --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3, Section 5                 --
------------------------------------------------------------------

with Permutations;
with Sims_Algorithm;
with Utils;
with Ada.Text_IO;
use Permutations;
use Sims_Algorithm;
use Utils;
use Ada.Text_IO;

procedure Test_Sparse is
   pragma SPARK_Mode (Off); -- Tests may use non-SPARK features for output

   -- Test permutations from Knuth's sparse example
   -- These are the generators for a sparse permutation group
   
   -- Generator 1: (1 2 3 4 5) - a 5-cycle
   Gen1 : Permutation := Identity;
   -- Generator 2: (1 3)(2 4) - product of transpositions
   Gen2 : Permutation := Identity;
   -- Generator 3: (1 2)(3 4 5) - mixed cycle structure
   Gen3 : Permutation := Identity;

   -- Sigma and T data structures
   Sigma : Sigma_Type;
   T : T_Type;

   -- Vector to hold generators
   Generators : Perm_Vector;

   -- Test results
   Test_Passed : Boolean := True;

begin
   -- Initialize test permutations for a smaller group
   -- We'll use indices 1-5 for this test
   
   -- Create generator 1: (1 2 3 4 5)
   Gen1 := Create_Cycle((1, 2, 3, 4, 5));
   
   -- Create generator 2: (1 3)(2 4)
   Gen2 := Identity;
   Gen2(1) := 3; Gen2(3) := 1;
   Gen2(2) := 4; Gen2(4) := 2;
   
   -- Create generator 3: (1 2)(3 4 5)
   Gen3 := Identity;
   Gen3(1) := 2; Gen3(2) := 1;
   Gen3(3) := 4; Gen3(4) := 5; Gen3(5) := 3;

   -- Add generators to vector
   Generators.Append(new Permutation'(Gen1));
   Generators.Append(new Permutation'(Gen2));
   Generators.Append(new Permutation'(Gen3));

   -- Initialize data structures
   Initialize(Index'Last, Sigma, T);

   -- Test 1: Add first generator
   Add_Generator(Gen1, Sigma, T);
   
   -- Verify that Gen1 is in the group
   if not Is_Member(Gen1, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 1 FAILED: Gen1 not in group after adding");
   else
      Put_Line("Test 1 PASSED: Gen1 successfully added to group");
   end if;

   -- Test 2: Add second generator
   Add_Generator(Gen2, Sigma, T);
   
   -- Verify that Gen2 is in the group
   if not Is_Member(Gen2, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 2 FAILED: Gen2 not in group after adding");
   else
      Put_Line("Test 2 PASSED: Gen2 successfully added to group");
   end if;

   -- Test 3: Verify that Gen1 is still in the group
   if not Is_Member(Gen1, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 3 FAILED: Gen1 no longer in group");
   else
      Put_Line("Test 3 PASSED: Gen1 still in group");
   end if;

   -- Test 4: Add third generator
   Add_Generator(Gen3, Sigma, T);
   
   -- Verify that Gen3 is in the group
   if not Is_Member(Gen3, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 4 FAILED: Gen3 not in group after adding");
   else
      Put_Line("Test 4 PASSED: Gen3 successfully added to group");
   end if;

   -- Test 5: Verify that all generators are still in the group
   if not (Is_Member(Gen1, Index'Last, Sigma) and 
           Is_Member(Gen2, Index'Last, Sigma) and 
           Is_Member(Gen3, Index'Last, Sigma)) then
      Test_Passed := False;
      Put_Line("Test 5 FAILED: Not all generators in group");
   else
      Put_Line("Test 5 PASSED: All generators in group");
   end if;

   -- Test 6: Test some products of generators
   declare
      Product1 : Permutation := Multiply(Gen1, Gen2);
      Product2 : Permutation := Multiply(Gen2, Gen3);
      Product3 : Permutation := Multiply(Gen1, Multiply(Gen2, Gen3));
   begin
      if not Is_Member(Product1, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 6a FAILED: Product1 not in group");
      else
         Put_Line("Test 6a PASSED: Product1 in group");
      end if;

      if not Is_Member(Product2, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 6b FAILED: Product2 not in group");
      else
         Put_Line("Test 6b PASSED: Product2 in group");
      end if;

      if not Is_Member(Product3, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 6c FAILED: Product3 not in group");
      else
         Put_Line("Test 6c PASSED: Product3 in group");
      end if;
   end;

   -- Test 7: Test the Compute_Strong_Generators procedure
   declare
      Test_Sigma : Sigma_Type;
      Test_T : T_Type;
   begin
      Compute_Strong_Generators(Generators, Test_Sigma, Test_T);
      
      -- Verify all generators are in the computed group
      if not (Is_Member(Gen1, Index'Last, Test_Sigma) and 
              Is_Member(Gen2, Index'Last, Test_Sigma) and 
              Is_Member(Gen3, Index'Last, Test_Sigma)) then
         Test_Passed := False;
         Put_Line("Test 7 FAILED: Compute_Strong_Generators failed");
      else
         Put_Line("Test 7 PASSED: Compute_Strong_Generators successful");
      end if;
   end;

   -- Test 8: Test identity permutation
   if not Is_Member(Identity, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 8 FAILED: Identity not in group");
   else
      Put_Line("Test 8 PASSED: Identity in group");
   end if;

   -- Test 9: Test inverse of generators
   declare
      Gen1_Inv : Permutation := Inverse(Gen1);
      Gen2_Inv : Permutation := Inverse(Gen2);
      Gen3_Inv : Permutation := Inverse(Gen3);
   begin
      if not Is_Member(Gen1_Inv, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 9a FAILED: Gen1 inverse not in group");
      else
         Put_Line("Test 9a PASSED: Gen1 inverse in group");
      end if;

      if not Is_Member(Gen2_Inv, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 9b FAILED: Gen2 inverse not in group");
      else
         Put_Line("Test 9b PASSED: Gen2 inverse in group");
      end if;

      if not Is_Member(Gen3_Inv, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 9c FAILED: Gen3 inverse not in group");
      else
         Put_Line("Test 9c PASSED: Gen3 inverse in group");
      end if;
   end;

   -- Final result
   if Test_Passed then
      Put_Line("=== SPARSE EXAMPLE TESTS: ALL PASSED ===");
   else
      Put_Line("=== SPARSE EXAMPLE TESTS: SOME FAILED ===");
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
      Put_Line("Exception occurred during sparse example tests");
      Test_Passed := False;

end Test_Sparse;
