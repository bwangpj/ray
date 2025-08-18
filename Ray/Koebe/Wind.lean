import Mathlib.Algebra.EuclideanDomain.Basic
import Mathlib.Algebra.EuclideanDomain.Field
import Mathlib.Algebra.Lie.OfAssociative
import Mathlib.Analysis.InnerProductSpace.Basic
import Ray.Koebe.Snap
import Ray.Misc.Circle
import Ray.Misc.Annuli

/-!
## If `f : Circle → ℂˣ` is continuous with injective snap, it bounds a star-shaped region

And we can extrapolate the parameterisation outwards to cover the whole plane.
-/

open Complex (arg exp I)
open Metric (ball closedBall isOpen_ball sphere)
open Set
open scoped Real Topology
noncomputable section

/-!
### Star-shaped regions
-/

variable {f : Circle → ℂˣ}
variable {z w : ℂ}
variable {x : Circle}

/-- `f` winds monotonically around the origin -/
structure Wind (f : Circle → ℂˣ) : Prop where
  fc : Continuous f
  inj : (fun x ↦ snap (f x)).Injective

namespace Wind

lemma isHomeomorph (i : Wind f) : IsHomeomorph (fun z ↦ snap (f z)) :=
  Circle.isHomeomorph_of_injective i.fc.snap_units i.inj

/-- `z ↦ snap (f z)` as a homeomorphism -/
def h (i : Wind f) : Homeomorph Circle Circle := i.isHomeomorph.homeomorph

@[simp] lemma h_apply (i : Wind f) (z : Circle) : i.h z = snap (f z) := rfl

lemma f_h_symm (i : Wind f) (z : Circle) :
    f (i.h.symm z) = ‖(f (i.h.symm z)).val‖ • z.val := by
  have h := i.h.apply_symm_apply z
  simp only [Wind.h_apply, Circle.ext_iff, Complex.real_smul, snap_unit] at h ⊢
  rwa [mul_comm, ← div_eq_iff]
  simp

@[simp] lemma h_symm_f (i : Wind f) (z : Circle) : i.h.symm (snap (f z)) = z :=
  i.h.symm_apply_apply z

/-!
### Minimum and maximum values of `‖f z‖` on the circle
-/

/-- `‖f z‖` is lower bounded on `‖z‖ = 1` -/
lemma exists_min (i : Wind f) : ∃ x, IsMinOn (fun z ↦ ‖(f z).val‖) univ x := by
  have e := (isCompact_univ (X := Circle)).exists_isMinOn (f := fun z ↦ ‖(f z).val‖) (by simp) ?_
  · simpa only [mem_univ, true_and] using e
  · exact (Units.continuous_val.comp i.fc).norm.continuousOn

/-- `‖f z‖` is upper bounded on `‖z‖ = 1` -/
lemma exists_max (i : Wind f) : ∃ x, IsMaxOn (fun z ↦ ‖(f z).val‖) univ x := by
  have e := (isCompact_univ (X := Circle)).exists_isMaxOn (f := fun z ↦ ‖(f z).val‖) (by simp) ?_
  · simpa only [mem_univ, true_and] using e
  · exact (Units.continuous_val.comp i.fc).norm.continuousOn

/-- The minimum of `‖f z‖` on `‖z‖ = 1` -/
def min (i : Wind f) : ℝ := ‖(f (Classical.choose i.exists_min)).val‖

/-- The maximum of `‖f z‖` on `‖z‖ = 1` -/
def max (i : Wind f) : ℝ := ‖(f (Classical.choose i.exists_max)).val‖

@[bound] lemma min_pos (i : Wind f) : 0 < i.min := by simp [min]
@[bound] lemma max_pos (i : Wind f) : 0 < i.max := by simp [max]
@[bound] lemma min_nonneg (i : Wind f) : 0 ≤ i.min := i.min_pos.le
@[bound] lemma max_nonneg (i : Wind f) : 0 ≤ i.max := i.max_pos.le

@[bound] lemma min_le (i : Wind f) : i.min ≤ ‖(f x).val‖ :=
  Classical.choose_spec i.exists_min trivial

@[bound] lemma le_max (i : Wind f) : ‖(f x).val‖ ≤ i.max :=
  Classical.choose_spec i.exists_max trivial

/-!
### Star-shaped parameterisation of the plane, extrapolating out from `f`
-/

/-- Forward map extending `f` to the plane -/
def fe (_ : Wind f) (z : ℂ) : ℂ := ‖z‖ • f (snap z)

/-- Inverse map -/
def fi (i : Wind f) (w : ℂ) : ℂ :=
  let z := i.h.symm (snap w)
  ‖w‖ / ‖(f z).val‖ * z

@[simp] lemma fe_zero (i : Wind f) : i.fe 0 = 0 := by simp [Wind.fe]
@[simp] lemma fi_zero (i : Wind f) : i.fi 0 = 0 := by simp [Wind.fi]

/-- `fi ∘ fe = id` -/
lemma left_inv (i : Wind f) : Function.LeftInverse i.fi i.fe := by
  intro z
  by_cases z0 : z = 0
  · simp only [z0, fe_zero, fi_zero]
  · simp [Wind.fe, Wind.fi, z0]

/-- `fe ∘ fi = id` -/
lemma right_inv (i : Wind f) : Function.RightInverse i.fi i.fe := by
  intro w
  by_cases w0 : w = 0
  · simp only [w0, fe_zero, fi_zero]
  · simp only [fe, fi, norm_mul, norm_div, Complex.norm_real, Real.norm_eq_abs,
      abs_norm, norm_eq_of_mem_sphere, mul_one, Complex.real_smul, Complex.ofReal_div]
    rw [← Complex.ofReal_div, snap_mul, snap_of_pos, one_mul, i.f_h_symm]
    all_goals simp [Complex.real_smul, Complex.norm_real, ne_eq, w0, not_false_eq_true, mul_one,
      Complex.ofReal_div]
    nth_rw 2 [i.f_h_symm]
    rw [Complex.real_smul, ← mul_assoc, div_mul_cancel₀ _ (by simp)]
    exact norm_mul_snap w0

lemma continuous_fe (i : Wind f) : Continuous i.fe := by
  rw [continuous_iff_continuousAt]
  intro z
  by_cases z0 : z = 0
  · refine Metric.continuousAt_iff.mpr fun ε ε0 ↦ ⟨ε / i.max, by bound, fun w wz ↦ ?_⟩
    simp only [z0, dist_zero_right, fe, Complex.real_smul, norm_zero, snap_zero, zero_smul,
      Complex.norm_mul, Complex.norm_real, norm_norm, lt_div_iff₀ i.max_pos] at wz ⊢
    exact lt_of_le_of_lt (by bound) wz
  · apply ContinuousAt.smul
    · exact continuous_norm.continuousAt
    · exact Units.continuous_val.continuousAt.comp (i.fc.continuousAt.comp (continuousAt_snap z0))

lemma continuous_fi (i : Wind f) : Continuous i.fi := by
  rw [continuous_iff_continuousAt]
  intro w
  by_cases w0 : w = 0
  · refine Metric.continuousAt_iff.mpr fun ε ε0 ↦ ⟨ε * i.min, by bound, fun z zw ↦ ?_⟩
    simp only [w0, dist_zero_right, ← div_lt_iff₀ i.min_pos, fi, norm_zero, Complex.ofReal_zero,
      snap_zero, zero_div, zero_mul, Complex.norm_mul, Complex.norm_div, Complex.norm_real,
      norm_norm, norm_eq_of_mem_sphere, mul_one] at zw ⊢
    exact lt_of_le_of_lt (by bound) zw
  · apply ContinuousAt.mul (ContinuousAt.div ?_ ?_ ?_) ?_
    · fun_prop
    · refine Complex.continuous_ofReal.continuousAt.comp ?_
      refine (Units.continuous_val.comp (i.fc.comp i.h.continuous_symm)).norm.continuousAt.comp ?_
      exact continuousAt_snap (by simpa using w0)
    · simp
    · apply continuousAt_subtype_val.comp
      exact i.h.continuous_symm.continuousAt.comp (continuousAt_snap (by simpa using w0))

/-- Star-shaped parameterisation of the plane, extrapolating out from `f` -/
def g (i : Wind f) : Homeomorph ℂ ℂ where
  toFun := i.fe
  invFun := i.fi
  left_inv := i.left_inv
  right_inv := i.right_inv
  continuous_toFun := i.continuous_fe
  continuous_invFun := i.continuous_fi

lemma g_apply (i : Wind f) : i.g z = ‖z‖ • f (snap z) := rfl
lemma g_symm_apply (i : Wind f) : i.g.symm w =
    let z := i.h.symm (snap w)
    ‖w‖ / ‖(f z).val‖ * z.val := rfl
@[simp] lemma g_zero (i : Wind f) : i.g 0 = 0 := by simp [i.g_apply]
@[simp] lemma g_symm_zero (i : Wind f) : i.g.symm 0 = 0 := by simp [i.g_symm_apply]

/-!
### Regions inside and outside the wind
-/

def disk (i : Wind f) : Set ℂ := i.g '' closedBall 0 1
def inner (i : Wind f) : Set ℂ := i.g '' ball 0 1
def outer (i : Wind f) : Set ℂ := i.g '' norm_Ioi 1

lemma isCompact_disk (i : Wind f) : IsCompact i.disk :=
  (isCompact_closedBall _ _).image_of_continuousOn i.g.continuous.continuousOn

lemma isOpen_inner (i : Wind f) : IsOpen i.inner := by
  simp only [inner, Homeomorph.isOpen_image, isOpen_ball]

@[simp] lemma zero_mem_inner (i : Wind f) : 0 ∈ i.inner := by use 0; simp
@[simp] lemma zero_mem_disk (i : Wind f) : 0 ∈ i.disk := by use 0; simp

lemma frontier_disk (i : Wind f) : frontier i.disk = i.g '' sphere 0 1 := by
  simp only [disk, ← Homeomorph.image_frontier]
  rw [frontier_closedBall _ (by norm_num)]

lemma frontier_outer (i : Wind f) : frontier i.outer = i.g '' sphere 0 1 := by
  simp only [outer, ← Homeomorph.image_frontier]
  apply congr_arg₂ _ rfl
  simp only [frontier_norm_Ioi]

lemma compl_outer (i : Wind f) : i.outerᶜ = i.disk := by
  simp only [outer, disk, norm_Ioi, ← Equiv.image_compl, ← Homeomorph.coe_toEquiv,
    Equiv.image_eq_iff_eq, compl_setOf, not_lt]
  ext z
  simp

lemma compl_disk (i : Wind f) : i.diskᶜ = i.outer := by
  rw [← compl_outer, compl_compl]

lemma isOpen_outer (i : Wind f) : IsOpen i.outer := by
  rw [← compl_disk]
  exact i.isCompact_disk.isClosed.isOpen_compl

lemma isPreconnected_outer (i : Wind f) : IsPreconnected i.outer := by
  apply isPreconnected_norm_Ioi.image
  exact i.g.continuous.continuousOn
