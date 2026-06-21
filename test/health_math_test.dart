// Unit tests for HealthMath. This file is the safety net for the
// single most important math in the app — every number on the
// dashboard, every coach suggestion, traces back through here.

import 'package:flutter_test/flutter_test.dart';
import 'package:fitevo/core/health_math.dart';
import 'package:fitevo/data/models/enums.dart';

void main() {
  group('BMR', () {
    test('Mifflin-St Jeor for adult male matches reference', () {
      final v = HealthMath.bmr(
        gender: Gender.male,
        age: 26,
        weightKg: 74.5,
        heightCm: 176,
      );
      // 10*74.5 + 6.25*176 - 5*26 + 5 = 1720
      expect(v.round(), 1720);
    });

    test('Mifflin-St Jeor for adult female matches reference', () {
      final v = HealthMath.bmr(
        gender: Gender.female,
        age: 30,
        weightKg: 62,
        heightCm: 165,
      );
      // 10*62 + 6.25*165 - 5*30 - 161 = 620 + 1031.25 - 150 - 161 = 1340.25
      expect(v.round(), 1340);
    });

    test('Katch-McArdle picks LBM-based BMR when BF% in range', () {
      // 80kg @ 15% BF → LBM = 68. BMR = 370 + 21.6*68 = 1838.8
      final v = HealthMath.bmrKatchMcArdle(80, 15);
      expect(v.round(), 1839);
    });

    test('bestBmr falls back to Mifflin when BF% missing', () {
      final v = HealthMath.bestBmr(
        gender: Gender.male,
        age: 26,
        weightKg: 74.5,
        heightCm: 176,
      );
      expect(v.round(), 1720);
    });

    test('bestBmr picks Katch-McArdle when BF% in 3..60 range', () {
      final v = HealthMath.bestBmr(
        gender: Gender.male,
        age: 26,
        weightKg: 80,
        heightCm: 180,
        bodyFatPct: 15,
      );
      expect(v.round(), 1839);
    });
  });

  group('Body-focus adjustments', () {
    test('belly fat applies -200 kcal', () {
      final r = HealthMath.bodyFocusAdjustments('belly fat');
      expect(r.$1, -200);
      expect(r.$2, 0);
    });

    test('skinny arms adds +10g protein', () {
      final r = HealthMath.bodyFocusAdjustments('skinny arms');
      expect(r.$1, 0);
      expect(r.$2, 10);
    });

    test('combined belly fat + skinny arms stacks both', () {
      final r = HealthMath.bodyFocusAdjustments('belly fat, skinny arms');
      expect(r.$1, -200);
      expect(r.$2, 10);
    });

    test('case-insensitive matching', () {
      final r = HealthMath.bodyFocusAdjustments('BELLY FAT');
      expect(r.$1, -200);
    });
  });

  group('Supplement water bumps', () {
    test('creatine adds 100 ml per gram', () {
      expect(
          HealthMath.supplementWaterBumpMl(
              creatineGramsPerDay: 5, proteinScoopsPerDay: 0),
          500);
    });

    test('protein scoop adds 250 ml', () {
      expect(
          HealthMath.supplementWaterBumpMl(
              creatineGramsPerDay: 0, proteinScoopsPerDay: 1),
          250);
    });

    test('both stack', () {
      expect(
          HealthMath.supplementWaterBumpMl(
              creatineGramsPerDay: 5, proteinScoopsPerDay: 2),
          1000);
    });

    test('creatine capped at 20g', () {
      expect(
          HealthMath.supplementWaterBumpMl(
              creatineGramsPerDay: 100, proteinScoopsPerDay: 0),
          2000);
    });
  });

  group('Newbie experience adjustments', () {
    test('< 6 months on recomp gets +100 kcal + 5g protein', () {
      final r = HealthMath.experienceAdjustments(2, FitnessGoal.recomp);
      expect(r.$1, 100);
      expect(r.$2, 5);
    });

    test('< 6 months on build-muscle gets no kcal bump (only protein)', () {
      final r =
          HealthMath.experienceAdjustments(2, FitnessGoal.buildMuscle);
      expect(r.$1, 0);
      expect(r.$2, 5);
    });

    test('intermediate (12 months) no adjustment', () {
      final r = HealthMath.experienceAdjustments(12, FitnessGoal.recomp);
      expect(r.$1, 0);
      expect(r.$2, 0);
    });

    test('null gym start date returns no adjustment', () {
      final r = HealthMath.experienceAdjustments(null, FitnessGoal.recomp);
      expect(r.$1, 0);
      expect(r.$2, 0);
    });
  });

  group('Health-flag tuning', () {
    test('hypothyroid drops TDEE multiplier by 7%', () {
      final r = HealthMath.flagAdjustments([HealthFlag.hypothyroid]);
      expect(r.tdeeMultiplier, closeTo(0.93, 1e-6));
    });

    test('PCOS drops TDEE 5% and caps carbs at 40%', () {
      final r = HealthMath.flagAdjustments([HealthFlag.pcos]);
      expect(r.tdeeMultiplier, closeTo(0.95, 1e-6));
      expect(r.carbsMaxFractionOfKcal, 0.40);
    });

    test('recovering from injury adds +100 kcal + 15g protein', () {
      final r = HealthMath.flagAdjustments([HealthFlag.recoveringFromInjury]);
      expect(r.kcalDelta, 100);
      expect(r.proteinDeltaG, 15);
    });

    test('requiresProfessionalGuidance catches the dangerous four', () {
      expect(
          HealthMath.requiresProfessionalGuidance([HealthFlag.pregnant]),
          true);
      expect(
          HealthMath.requiresProfessionalGuidance(
              [HealthFlag.breastfeeding]),
          true);
      expect(
          HealthMath.requiresProfessionalGuidance(
              [HealthFlag.eatingDisorderHistory]),
          true);
      expect(
          HealthMath.requiresProfessionalGuidance([HealthFlag.t1Diabetes]),
          true);
      expect(
          HealthMath.requiresProfessionalGuidance([HealthFlag.pcos]),
          false);
    });
  });

  group('Cycle adjustments', () {
    test('luteal phase adds 100 kcal + 300 ml water', () {
      final r = HealthMath.cycleAdjustments(CyclePhase.luteal);
      expect(r.kcalDelta, 100);
      expect(r.waterMlDelta, 300);
    });

    test('menstrual adds water only', () {
      final r = HealthMath.cycleAdjustments(CyclePhase.menstrual);
      expect(r.kcalDelta, 0);
      expect(r.waterMlDelta, 250);
    });

    test('unknown is a no-op', () {
      final r = HealthMath.cycleAdjustments(CyclePhase.unknown);
      expect(r.kcalDelta, 0);
      expect(r.waterMlDelta, 0);
    });
  });

  group('compute() end-to-end', () {
    test(
        'matches the screenshot scenario: 26y male, 74.5kg, 176cm, '
        'recomp + belly fat + skinny arms, newbie (<1mo)', () {
      final r = HealthMath.compute(
        gender: Gender.male,
        age: 26,
        weightKg: 74.5,
        heightCm: 176,
        activity: ActivityLevel.active,
        goal: FitnessGoal.recomp,
        walkingKmPerDay: 1.71,
        runningKmPerWeek: 10,
        gymMinutesPerSession: 60,
        strengthDaysPerWeek: 6,
        bodyFocusNotes: 'belly fat, skinny arms',
        creatineGramsPerDay: 6,
        proteinScoopsPerDay: 1,
        gymStartDate: DateTime.now().subtract(const Duration(days: 14)),
      );
      // Sanity envelope — within ±100 kcal of the validated screenshot.
      expect(r.calorieTarget, inInclusiveRange(2600, 2800));
      // Protein: 2.0 * 74.5 = 149, + 10 (skinny arms) + 5 (newbie) = 164
      expect(r.proteinG, 164);
      // Water: 33 * 74.5 = 2459 base + 6*100 + 1*250 = 3309
      expect(r.waterMl, 3309);
      expect(r.bmi, closeTo(24.05, 0.05));
    });

    test('high-risk health flag sets warnConsultProfessional', () {
      final r = HealthMath.compute(
        gender: Gender.female,
        age: 28,
        weightKg: 65,
        heightCm: 168,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.generalFitness,
        healthFlags: [HealthFlag.pregnant],
      );
      expect(r.warnConsultProfessional, true);
    });

    test('rest day target is below training day when rest days are set',
        () {
      final r = HealthMath.compute(
        gender: Gender.male,
        age: 30,
        weightKg: 80,
        heightCm: 180,
        activity: ActivityLevel.active,
        goal: FitnessGoal.recomp,
        walkingKmPerDay: 4,
        runningKmPerWeek: 15,
        gymMinutesPerSession: 60,
        strengthDaysPerWeek: 5,
        restDays: const [6], // Saturday
      );
      expect(r.restDayCalorieTarget, lessThan(r.calorieTarget));
    });

    test(
        'BF% provided → uses Katch-McArdle (flag exposed on '
        'ComputedTargets)', () {
      final r = HealthMath.compute(
        gender: Gender.male,
        age: 26,
        weightKg: 80,
        heightCm: 180,
        activity: ActivityLevel.moderate,
        goal: FitnessGoal.generalFitness,
        bodyFatPct: 15,
      );
      expect(r.usedKatchMcArdle, true);
    });

    test('calorie floor prevents below-1500 for males', () {
      final r = HealthMath.compute(
        gender: Gender.male,
        age: 30,
        weightKg: 45, // unusually low
        heightCm: 160,
        activity: ActivityLevel.sedentary,
        goal: FitnessGoal.loseFat,
      );
      expect(r.calorieTarget, greaterThanOrEqualTo(1500));
    });
  });

  group('BMI helpers', () {
    test('bmi computes correctly', () {
      expect(
          HealthMath.bmi(weightKg: 74.5, heightCm: 176),
          closeTo(24.05, 0.05));
    });

    test('bmiContext labels', () {
      expect(HealthMath.bmiContext(17), 'Lower range');
      expect(HealthMath.bmiContext(22), 'Typical range');
      expect(HealthMath.bmiContext(27), 'Higher range');
      expect(HealthMath.bmiContext(33), 'Significantly higher range');
    });
  });
}
