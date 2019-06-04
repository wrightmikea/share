
module SigmaMod where

open import Function using (_$_; _∋_; _∘_ )
open import Data.Nat using (ℕ; zero; suc; pred; _<_; _≤_; s≤s; z≤n; _+_; _∸_)
open import Agda.Builtin.Nat using (mod-helper)
open import Data.Nat.Properties using (<⇒≢; ≤∧≢⇒<; _≟_; +-assoc; +-comm; ≤-refl; m+n∸m≡n; n∸m≤n) 
open import Data.Product using (Σ; _,_)
import Relation.Binary.PropositionalEquality as Eq
open Eq using (_≡_; _≢_; refl; cong; sym)
open Eq.≡-Reasoning using (begin_; _∎; _≡⟨⟩_; _≡⟨_⟩_)
open import Relation.Nullary using (¬_; Dec; yes; no)
open import Relation.Nullary.Negation using ()
open import UtilProperties using (≤⇒<suc; <-step; <-suc⇒≤;
  <-same-type⇒≡; <-same-sucs-type⇒≡; _$^_; $^-∘-additive)

{- Representation of modular numbers. Use "k + 1" as the modulus, since
there are no modular numbers for modulus zero.

For consistency, all functions and data structures are parameterized
by k, that is 1 less than the modulus. But for variable names we use
the modulus: mod₅1 : Mod 4 ; mod₅1 = (1, 1<5)  -}

Mod : ℕ → Set
Mod k = Σ ℕ (λ x → x < suc k)

-- the natural number corresponding to a modulo number
naturalₘ : {k : ℕ} → Mod k → ℕ
naturalₘ (x , _) = x

-- modular zero
zeroₘ : {k : ℕ} → Mod k
zeroₘ {k} = (zero , s≤s z≤n)

-- sample modular numbers as sigma
mod₂1 : Mod (pred 2); mod₂1 = (1 , s≤s (s≤s z≤n))
mod₃1 : Mod (pred 3); mod₃1 = (1 , s≤s (s≤s z≤n))

mod₅1 : Mod (pred 5) ; mod₅1 = (1 , s≤s (s≤s z≤n))
mod₅2 : Mod (pred 5) ; mod₅2 = (2 , s≤s (s≤s (s≤s z≤n)))
mod₅3 : Mod (pred 5) ; mod₅3 = (3 , s≤s (s≤s (s≤s (s≤s z≤n))))
mod₅4 : Mod (pred 5) ; mod₅4 = (4 , s≤s (s≤s (s≤s (s≤s (s≤s z≤n)))))

-- successor for modular numbers less than the maximum
incₘ : {k : ℕ} → (mod : Mod k) → (naturalₘ mod < k) → Mod k
incₘ {k} (x , _) x<k = (suc x , s≤s x<k)

-- successor with the addition of decidable x ≟ k
-- can be a with clause in sucₘ - but ran into issues with reductions
sucMInternal : {k : ℕ} → (mod : Mod k) → Dec (naturalₘ mod ≡ k) → Mod k
sucMInternal {k} (x , _) (yes x≡k) = zeroₘ
-- TODO. Ran into trouble trying to case-split on x<sk - should be s≤s x≤k.
-- Using hole for this case caused agda to loop!
sucMInternal {k} modx@(x , x<sk) (no x≢k) =
  let x≤k = <-suc⇒≤ x k x<sk
      x<k = ≤∧≢⇒< {x} {k} x≤k x≢k
  in incₘ {k} modx x<k

-- modular successor - avoiding use of with
sucₘ : {k : ℕ} → Mod k → Mod k
sucₘ {k} mod@(x , x≤k) = sucMInternal {k} mod (x ≟ k)

-- sample successors
_ : sucₘ (sucₘ mod₅1) ≡ mod₅3; _ = refl
_ : sucₘ mod₅4 ≡ zeroₘ {4} ; _ = refl
_ : sucₘ {4} zeroₘ ≡ mod₅1 ; _ = refl

-- repeated modular succession - _$^_ is repeated application
sucₘⁿ : {k : ℕ} →  (n : ℕ) → (mod : Mod k) → Mod k
sucₘⁿ {k} n = sucₘ $^ n

-- sample repeated successions
_ : sucₘⁿ 3 mod₅1 ≡ mod₅4; _ = refl
_ : sucₘⁿ {4} 5 zeroₘ ≡ zeroₘ ; _ = refl
_ : sucₘⁿ 0 mod₂1 ≡ mod₂1 ; _ = refl

-- sample cycling behavior
_ : sucₘⁿ {4} 12 (zeroₘ {4}) ≡ mod₅2 ; _ = refl

-- sample cycling behavior for the edge case of modulo 2 numbers
_ : sucₘⁿ 1 mod₂1 ≡ zeroₘ ; _ = refl
_ : sucₘⁿ 2 mod₂1 ≡ mod₂1 ; _ = refl
_ : sucₘⁿ 9 mod₂1 ≡ zeroₘ ; _ = refl

-- succession applied n times to modulo zero
sucₘⁿ-zeroₘ : {k : ℕ} → (n : ℕ) → Mod k
sucₘⁿ-zeroₘ {k} n = sucₘⁿ n zeroₘ

-- sample progressive succession - see below for proofs of the exemplified successions
_ : sucₘⁿ-zeroₘ {4} 0 ≡ zeroₘ ; _ = refl
_ : sucₘⁿ-zeroₘ {4} 1 ≡ mod₅1 ; _ = refl
_ : sucₘⁿ-zeroₘ {4} 2 ≡ mod₅2 ; _ = refl
_ : sucₘⁿ-zeroₘ {4} 3 ≡ mod₅3 ; _ = refl
_ : sucₘⁿ-zeroₘ {4} 4 ≡ mod₅4 ; _ = refl
_ : sucₘⁿ-zeroₘ {4} 5 ≡ zeroₘ ; _ = refl

-- modular +
infixl 6 _+ₘ_
_+ₘ_ : ∀ {k} → Mod k → Mod k → Mod k
(x , _) +ₘ mod = sucₘⁿ x mod

-- sample +ₘ calculations
_ : mod₅1 +ₘ mod₅3 ≡ mod₅4 ; _ = refl
_ : mod₅1 +ₘ zeroₘ ≡ mod₅1 ; _ = refl
_ : zeroₘ +ₘ mod₅2 ≡ mod₅2 ; _ = refl
_ : mod₅3 +ₘ mod₅2 ≡ zeroₘ ; _ = refl
_ : mod₅2 +ₘ mod₅2 +ₘ mod₅1 +ₘ mod₅4 +ₘ mod₅3 +ₘ mod₅1 ≡ mod₅3 ; _ = refl

-- modular inverse
-ₘ_ : {k : ℕ} → Mod k → Mod k
-ₘ_ {k} (zero , x≤k) = (zero , x≤k)
-ₘ_ {k} (suc x , x≤k) = (k ∸ x , ≤⇒<suc (k ∸ x) k (n∸m≤n x k)) 

-- sample inverse additions - proofs appear in SigModGroupProperties
_ : -ₘ mod₅2 ≡ mod₅3 ; _ = refl 
_ : (-ₘ zeroₘ) +ₘ (zeroₘ {3}) ≡ zeroₘ ; _ = refl
_ : mod₅3 +ₘ (-ₘ mod₅3) ≡ zeroₘ ; _ = refl
_ : (-ₘ mod₂1) +ₘ mod₂1 ≡ zeroₘ ; _ = refl

-- uniqueness : there is a unique modular number of a given modulus for a given natural number
uniqueₘ : {k : ℕ} → (mod1 : Mod k) → (mod2 : Mod k) → naturalₘ mod1 ≡ naturalₘ mod2 → mod1 ≡ mod2
uniqueₘ {k} (zero , s≤s z≤n) (.0 , s≤s z≤n) refl = refl
uniqueₘ {k} (suc x , x≤k) (.(suc x) , y≤k) refl rewrite <-same-sucs-type⇒≡ x k x≤k y≤k = refl

-- TODO - simplify or obviate the need for this proof
sucₘ≡incₘ : {k : ℕ} → (mod : Mod k) → (x<k : naturalₘ mod < k) → sucₘ mod ≡ incₘ {k} mod x<k
sucₘ≡incₘ {k} (x , _)   x<k with x ≟ k   | <⇒≢ {x} {k} x<k
sucₘ≡incₘ {k} _         _      | yes x≡k | x≢k with x≢k x≡k
...                                               | ()
sucₘ≡incₘ {k} _         _      | no _    | _ = uniqueₘ _ _ refl 

-- TODO - simplify or obviate the need for this proof
sucₘ≡zeroₘ : {k : ℕ} → (mod : Mod k) → (naturalₘ mod ≡ k) → sucₘ mod ≡ zeroₘ
sucₘ≡zeroₘ {k} (x , lx) x≡k with x ≟ k
sucₘ≡zeroₘ {k} (x , lx) x≡k | yes p = refl
sucₘ≡zeroₘ {k} (x , lx) x≡k | no x≢k with x≢k x≡k
...                                     | ()

-- basic theorem 1
-- modular values can be obtained by repeated succession from modular zero - as in naturals
sucₘⁿ-identity : {k : ℕ} → (x : ℕ) → (x≤k : x < suc k) → sucₘⁿ-zeroₘ x ≡ (x , x≤k)
sucₘⁿ-identity {k} zero (s≤s z≤n) = refl
sucₘⁿ-identity {k} (suc x) (s≤s x<k) =
  let x<sk = <-step x k x<k
  in 
  begin
    sucₘⁿ-zeroₘ (suc x) ≡⟨⟩
    sucₘ (sucₘⁿ-zeroₘ x) ≡⟨ cong sucₘ (sucₘⁿ-identity {k} x x<sk) ⟩
    sucₘ (x , x<sk) ≡⟨ sucₘ≡incₘ {k} (x , x<sk) x<k ⟩
    (suc x , s≤s x<k)
  ∎

-- basic theorem 2
-- repeated application of sucₘ to zeroₘ cycles at the modulus [suc k]
cycle-zeroₘ : {k : ℕ} → sucₘⁿ-zeroₘ (suc k) ≡ zeroₘ
cycle-zeroₘ {k} =
  begin
    sucₘⁿ {k} (suc k) zeroₘ ≡⟨⟩
    sucₘ (sucₘⁿ k zeroₘ) ≡⟨ cong sucₘ (sucₘⁿ-identity {k} k ≤-refl) ⟩
    sucₘ (k , ≤-refl) ≡⟨ sucₘ≡zeroₘ {k} (k , ≤-refl) refl ⟩
    zeroₘ
  ∎

-- composition of iterated applications of modulo succession is additive in the number of iterations
sucₘ-additivity : {k : ℕ} → (x y : ℕ) → (mod : Mod k) → ((sucₘⁿ x) ∘ (sucₘⁿ y)) mod ≡ sucₘⁿ (x + y) mod
sucₘ-additivity {k} x y mod = $^-∘-additive sucₘ x y mod

-- basic theorem 3
-- the sum of 2 modular numbers can be reduced to a function of the sum of their natural counterparts
+ₘ-by-+ : {k : ℕ} → (mod1 mod2 : Mod k) → mod1 +ₘ mod2 ≡ sucₘⁿ-zeroₘ {k} (naturalₘ mod1 + naturalₘ mod2)
+ₘ-by-+ {k} (x , x≤k) (y , y≤k) =
  begin
    (x , x≤k) +ₘ (y , y≤k) ≡⟨⟩
    sucₘⁿ x (y , y≤k) ≡⟨ cong (sucₘⁿ x) (sym (sucₘⁿ-identity y y≤k)) ⟩
    sucₘⁿ x (sucₘⁿ {k} y (zeroₘ {k}) ) ≡⟨ sucₘ-additivity {k} x y zeroₘ ⟩
    sucₘⁿ-zeroₘ {k} (x + y)
  ∎

-- commutativity of modular addition
+ₘ-comm : {k : ℕ} → (mod1 mod2 : Mod k) → mod1 +ₘ mod2 ≡ mod2 +ₘ mod1
+ₘ-comm mx@(x , lx) my@(y , ly) =
   begin
     mx +ₘ my ≡⟨ +ₘ-by-+ mx my ⟩
     sucₘⁿ-zeroₘ (x + y) ≡⟨ cong sucₘⁿ-zeroₘ (+-comm x y) ⟩
     sucₘⁿ (y + x) zeroₘ ≡⟨ sym (+ₘ-by-+ my mx) ⟩
     my +ₘ mx
   ∎
