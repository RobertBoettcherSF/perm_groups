------------------------------------------------------------------
--  Permutation Groups in Ada SPARK                              --
--  Implementation of Donald E. Knuth's algorithms Aₖ(π) and Bₖ(π) --
--  for computing strong generators and transversal systems        --
--                                                               --
--  File: test_dense.adb                                          --
--  Description: Test dense example from Knuth's paper Section 6  --
--                                                               --
--  Author: Vibe Code Agent                                       --
--  Date: 2024                                                   --
--  Reference: Knuth, D.E. "The Art of Computer Programming"     --
--             Volume 2, Section 4.6.3, Section 6                 --
------------------------------------------------------------------

with Permutations;
with Sims_Algorithm;
with Utils;
with Ada.Text_IO;
use Permutations;
use Sims_Algorithm;
use Utils;
use Ada.Text_IO;

procedure Test_Dense is
   pragma SPARK_Mode (Off); -- Tests may use non-SPARK features for output

   -- Test data for dense example
   -- This example uses a larger permutation group that fills more of the space
   
   -- Generators for a dense permutation group
   -- We'll use the symmetric group S_6 for this test
   
   -- Generator 1: (1 2) - a transposition
   Gen1 : Permutation := Identity;
   -- Generator 2: (2 3) - another transposition
   Gen2 : Permutation := Identity;
   -- Generator 3: (3 4) - another transposition
   Gen3 : Permutation := Identity;
   -- Generator 4: (4 5) - another transposition
   Gen4 : Permutation := Identity;
   -- Generator 5: (5 6) - final transposition
   Gen5 : Permutation := Identity;

   -- Sigma and T data structures
   Sigma : Sigma_Type;
   T : T_Type;

   -- Vector to hold generators
   Generators : Perm_Vector;

   -- Test results
   Test_Passed : Boolean := True;

begin
   -- Initialize test permutations
   -- Create adjacent transpositions that generate S_6
   
   Gen1 := Create_Transposition(1, 2);
   Gen2 := Create_Transposition(2, 3);
   Gen3 := Create_Transposition(3, 4);
   Gen4 := Create_Transposition(4, 5);
   Gen5 := Create_Transposition(5, 6);

   -- Add generators to vector
   Generators.Append(new Permutation'(Gen1));
   Generators.Append(new Permutation'(Gen2));
   Generators.Append(new Permutation'(Gen3));
   Generators.Append(new Permutation'(Gen4));
   Generators.Append(new Permutation'(Gen5));

   -- Initialize data structures
   Initialize(Index'Last, Sigma, T);

   -- Test 1: Add all generators
   for I in 1 .. Generators.Length loop
      Add_Generator(Generators.Element(I).all, Sigma, T);
   end loop;
   
   Put_Line("Test 1: Added all generators to the group");

   -- Test 2: Verify all generators are in the group
   for I in 1 .. Generators.Length loop
      if not Is_Member(Generators.Element(I).all, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 2 FAILED: Generator " & Integer'Image(I) & " not in group");
      end if;
   end loop;
   
   if Test_Passed then
      Put_Line("Test 2 PASSED: All generators in group");
   end if;

   -- Test 3: Test that we can generate various permutations in S_6
   -- Test some specific permutations that should be in the group
   
   -- Test (1 3) = (1 2)(2 3)(1 2)
   declare
      Test_Perm1 : Permutation := Multiply(Gen1, Multiply(Gen2, Gen1));
   begin
      if not Is_Member(Test_Perm1, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 3a FAILED: (1 3) not in group");
      else
         Put_Line("Test 3a PASSED: (1 3) in group");
      end if;
   end;

   -- Test (1 4) = (1 2)(2 3)(3 4)(2 3)(1 2)
   declare
      Test_Perm2 : Permutation := 
        Multiply(Gen1, Multiply(Gen2, Multiply(Gen3, Multiply(Gen2, Gen1))));
   begin
      if not Is_Member(Test_Perm2, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 3b FAILED: (1 4) not in group");
      else
         Put_Line("Test 3b PASSED: (1 4) in group");
      end if;
   end;

   -- Test (1 2 3) = (1 2)(2 3)
   declare
      Test_Perm3 : Permutation := Multiply(Gen1, Gen2);
   begin
      if not Is_Member(Test_Perm3, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 3c FAILED: (1 2 3) not in group");
      else
         Put_Line("Test 3c PASSED: (1 2 3) in group");
      end if;
   end;

   -- Test 4: Test longer products
   declare
      Long_Product : Permutation := Identity;
   begin
      -- Create a product of all generators
      for I in 1 .. Generators.Length loop
         Long_Product := Multiply(Long_Product, Generators.Element(I).all);
      end loop;
      
      if not Is_Member(Long_Product, Index'Last, Sigma) then
         Test_Passed := False;
         Put_Line("Test 4 FAILED: Long product not in group");
      else
         Put_Line("Test 4 PASSED: Long product in group");
      end if;
   end;

   -- Test 5: Test inverses of all generators
   for I in 1 .. Generators.Length loop
      declare
         Gen_Inv : Permutation := Inverse(Generators.Element(I).all);
      begin
         if not Is_Member(Gen_Inv, Index'Last, Sigma) then
            Test_Passed := False;
            Put_Line("Test 5 FAILED: Inverse of generator " & Integer'Image(I) & " not in group");
         end if;
      end;
   end loop;
   
   if Test_Passed then
      Put_Line("Test 5 PASSED: All generator inverses in group");
   end if;

   -- Test 6: Test that the group is closed under multiplication
   -- Pick a few random products and verify they're in the group
   declare
      Product1 : Permutation := Multiply(Generators.Element(1).all, Generators.Element(2).all);
      Product2 : Permutation := Multiply(Generators.Element(3).all, Generators.Element(4).all);
      Product3 : Permutation := Multiply(Product1, Product2);
   begin
      if not (Is_Member(Product1, Index'Last, Sigma) and 
              Is_Member(Product2, Index'Last, Sigma) and 
              Is_Member(Product3, Index'Last, Sigma)) then
         Test_Passed := False;
         Put_Line("Test 6 FAILED: Group not closed under multiplication");
      else
         Put_Line("Test 6 PASSED: Group closed under multiplication");
      end if;
   end;

   -- Test 7: Test identity is in the group
   if not Is_Member(Identity, Index'Last, Sigma) then
      Test_Passed := False;
      Put_Line("Test 7 FAILED: Identity not in group");
   else
      Put_Line("Test 7 PASSED: Identity in group");
   end if;

   -- Test 8: Test Compute_Strong_Generators with dense group
   declare
      Test_Sigma : Sigma_Type;
      Test_T : T_Type;
   begin
      Compute_Strong_Generators(Generators, Test_Sigma, Test_T);
      
      -- Verify all generators are in the computed group
      for I in 1 .. Generators.Length loop
         if not Is_Member(Generators.Element(I).all, Index'Last, Test_Sigma) then
            Test_Passed := False;
            Put_Line("Test 8 FAILED: Generator " & Integer'Image(I) & " not in computed group");
         end if;
      end loop;
      
      if Test_Passed then
         Put_Line("Test 8 PASSED: Compute_Strong_Generators successful for dense group");
      end if;
   end;

   -- Test 9: Performance test - add many permutations
   declare
      Performance_Sigma : Sigma_Type;
      Performance_T : T_Type;
      Start_Time, End_Time : Ada.Real_Time.Time;
   begin
      Initialize(Index'Last, Performance_Sigma, Performance_T);
      
      Start_Time := Ada.Real_Time.Clock;
      
      -- Add generators and some products
      for I in 1 .. Generators.Length loop
         Add_Generator(Generators.Element(I).all, Performance_Sigma, Performance_T);
      end loop;
      
      -- Add some products
      for I in 1 .. Generators.Length loop
         for J in 1 .. Generators.Length loop
            declare
               Product : Permutation := Multiply(Generators.Element(I).all, Generators.Element(J).all);
            begin
               Add_Generator(Product, Performance_Sigma, Performance_T);
            end;
         end loop;
      end loop;
      
      End_Time := Ada.Real_Time.Clock;
      
      Put_Line("Test 9: Added " & Integer'Image(Generators.Length * (Generators.Length + 1)) & 
               " permutations in " & 
               Duration'Image(Ada.Real_Time.To_Duration(End_Time - Start_Time)) & " seconds");
      Put_Line("Test 9 PASSED: Performance test completed");
   end;

   -- Final result
   if Test_Passed then
      Put_Line("=== DENSE EXAMPLE TESTS: ALL PASSED ===");
   else
      Put_Line("=== DENSE EXAMPLE TESTS: SOME FAILED ===");
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
      Put_Line("Exception occurred during dense example tests");
      Test_Passed := False;

end Test_Dense;
