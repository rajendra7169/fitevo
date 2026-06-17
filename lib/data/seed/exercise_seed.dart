import '../models/enums.dart';
import '../models/exercise.dart';

/// Beginner-friendly exercises seeded on first run.
/// Covers the major muscle groups + cardio.
List<Exercise> buildSeedExercises() {
  Exercise mk(
    String name, {
    required List<MuscleGroup> muscles,
    required Equipment equipment,
    required List<String> cues,
    required List<String> mistakes,
    int rest = 90,
    bool beginner = true,
  }) {
    return Exercise()
      ..name = name
      ..muscleGroups = muscles
      ..equipment = equipment
      ..isBeginnerFriendly = beginner
      ..formCues = cues
      ..commonMistakes = mistakes
      ..defaultRestSeconds = rest
      ..isSeeded = true;
  }

  return [
    // PUSH
    mk('Push-up',
        muscles: [MuscleGroup.chest, MuscleGroup.triceps, MuscleGroup.shoulders],
        equipment: Equipment.bodyweight,
        cues: [
          'Hands shoulder-width, body in a straight line',
          'Lower chest to just above the floor',
          'Elbows ~45° from torso, not flared'
        ],
        mistakes: [
          'Sagging hips or piked butt',
          'Flaring elbows out 90°',
          'Half reps — touch chest down'
        ],
        rest: 60),
    mk('Dumbbell Bench Press',
        muscles: [MuscleGroup.chest, MuscleGroup.triceps, MuscleGroup.shoulders],
        equipment: Equipment.dumbbell,
        cues: [
          'Feet planted, slight arch',
          'Lower dumbbells to mid-chest with control',
          'Press up and slightly together at the top'
        ],
        mistakes: [
          'Bouncing dumbbells off chest',
          'Wrists bent backwards',
          'Going too heavy too soon — start light'
        ]),
    mk('Overhead Dumbbell Press',
        muscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
        equipment: Equipment.dumbbell,
        cues: [
          'Sit or stand tall, core braced',
          'Press straight up, not forward',
          'Lower under control to ear height'
        ],
        mistakes: [
          'Arching lower back',
          'Pressing dumbbells forward instead of up',
          'Locking out aggressively'
        ]),
    mk('Lateral Raise',
        muscles: [MuscleGroup.shoulders],
        equipment: Equipment.dumbbell,
        cues: [
          'Slight bend at elbow, lift to shoulder height',
          'Lead with elbows, not hands',
          'Slow on the way down'
        ],
        mistakes: [
          'Using too much weight and swinging',
          'Lifting above shoulder height',
          'Shrugging shoulders into the lift'
        ],
        rest: 60),
    mk('Tricep Pushdown',
        muscles: [MuscleGroup.triceps],
        equipment: Equipment.cable,
        cues: [
          'Elbows pinned to ribs',
          'Push handles down until arms straight',
          'Control the negative'
        ],
        mistakes: [
          'Elbows drifting forward',
          'Using body weight to push down',
          'Half range of motion'
        ],
        rest: 60),

    // PULL
    mk('Lat Pulldown',
        muscles: [MuscleGroup.back, MuscleGroup.biceps],
        equipment: Equipment.cable,
        cues: [
          'Lean back slightly, chest up',
          'Pull bar to upper chest',
          'Lead with elbows pulling down and back'
        ],
        mistakes: [
          'Excessive leaning to pull weight',
          'Pulling behind the neck',
          'Letting bar slam back up'
        ]),
    mk('Seated Cable Row',
        muscles: [MuscleGroup.back, MuscleGroup.biceps],
        equipment: Equipment.cable,
        cues: [
          'Chest tall, slight forward lean to start',
          'Pull handle to lower ribs',
          'Squeeze shoulder blades together'
        ],
        mistakes: [
          'Rounding the lower back',
          'Yanking with the arms',
          'Big body swing'
        ]),
    mk('Dumbbell Row',
        muscles: [MuscleGroup.back, MuscleGroup.biceps],
        equipment: Equipment.dumbbell,
        cues: [
          'Flat back, hand and knee on bench',
          'Pull dumbbell to hip with elbow close',
          'Lower under control'
        ],
        mistakes: [
          'Rounding the upper back',
          'Twisting torso to pull heavier',
          'Pulling to chest instead of hip'
        ]),
    mk('Dumbbell Bicep Curl',
        muscles: [MuscleGroup.biceps],
        equipment: Equipment.dumbbell,
        cues: [
          'Elbows tight to ribs',
          'Squeeze biceps at top',
          'Lower slowly, full extension at bottom'
        ],
        mistakes: [
          'Swinging at the hips',
          'Elbows drifting forward',
          'Cutting reps short'
        ],
        rest: 60),
    mk('Hammer Curl',
        muscles: [MuscleGroup.biceps, MuscleGroup.forearms],
        equipment: Equipment.dumbbell,
        cues: [
          'Neutral grip (thumbs up)',
          'Curl up keeping wrists straight',
          'Control the lowering phase'
        ],
        mistakes: [
          'Body english to lift the weight',
          'Rotating wrists at top',
          'Partial reps'
        ],
        rest: 60),

    // LEGS
    mk('Goblet Squat',
        muscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.core],
        equipment: Equipment.dumbbell,
        cues: [
          'Hold dumbbell at chest, elbows tucked',
          'Feet shoulder-width, toes slightly out',
          'Sit down between heels, keep chest up'
        ],
        mistakes: [
          'Knees caving inward',
          'Heels lifting off the floor',
          'Squatting too shallow'
        ]),
    mk('Barbell Back Squat',
        muscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.hamstrings],
        equipment: Equipment.barbell,
        cues: [
          'Bar on traps, elbows under',
          'Brace core, descend with control',
          'Drive through mid-foot to stand'
        ],
        mistakes: [
          'Knees collapsing in',
          'Rounding the lower back at the bottom',
          'Going too heavy without spotter/pins'
        ],
        rest: 150,
        beginner: false),
    mk('Romanian Deadlift',
        muscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.back],
        equipment: Equipment.barbell,
        cues: [
          'Bar close to legs, soft knee bend',
          'Hinge at hips, push hips back',
          'Feel stretch in hamstrings, then stand'
        ],
        mistakes: [
          'Rounding the back',
          'Squatting down instead of hinging',
          'Bar drifting away from body'
        ],
        rest: 120,
        beginner: false),
    mk('Walking Lunges',
        muscles: [MuscleGroup.quads, MuscleGroup.glutes, MuscleGroup.hamstrings],
        equipment: Equipment.dumbbell,
        cues: [
          'Take a long step forward',
          'Drop back knee toward floor',
          'Push through front heel to step through'
        ],
        mistakes: [
          'Front knee caving inward',
          'Short choppy steps',
          'Bouncing knee on the floor'
        ]),
    mk('Leg Press',
        muscles: [MuscleGroup.quads, MuscleGroup.glutes],
        equipment: Equipment.machine,
        cues: [
          'Back firmly against pad',
          'Lower until knees ~90°',
          'Push through whole foot, do not lock out'
        ],
        mistakes: [
          'Going so deep your lower back lifts',
          'Locking knees aggressively',
          'Only using toes'
        ]),

    // CORE
    mk('Plank',
        muscles: [MuscleGroup.core],
        equipment: Equipment.bodyweight,
        cues: [
          'Forearms under shoulders',
          'Body in a straight line',
          'Squeeze glutes and brace abs'
        ],
        mistakes: [
          'Sagging hips',
          'Piked butt up',
          'Holding breath'
        ],
        rest: 45),
    mk('Hanging Knee Raise',
        muscles: [MuscleGroup.core],
        equipment: Equipment.bodyweight,
        cues: [
          'Hang from bar, shoulders engaged',
          'Curl knees up toward chest',
          'Lower with control — no swinging'
        ],
        mistakes: [
          'Swinging legs',
          'Just lifting legs without rolling hips',
          'Dropping straight to start position'
        ],
        rest: 60),

    // CARDIO
    mk('Treadmill Walk/Jog',
        muscles: [MuscleGroup.cardio, MuscleGroup.fullBody],
        equipment: Equipment.machine,
        cues: [
          'Upright posture, eyes forward',
          'Land mid-foot, arms relaxed',
          'Start with a 5-min warm-up walk'
        ],
        mistakes: [
          'Holding onto rails the whole time',
          'Going too fast too soon',
          'No cooldown'
        ],
        rest: 0),
    mk('Stationary Bike',
        muscles: [MuscleGroup.cardio, MuscleGroup.quads],
        equipment: Equipment.machine,
        cues: [
          'Seat height: slight knee bend at bottom',
          'Steady cadence, breathe steadily',
          'Mix in 20s harder pushes for intensity'
        ],
        mistakes: [
          'Seat too low (knee pain)',
          'Hunched shoulders gripping bars',
          'Resistance set to zero'
        ],
        rest: 0),
  ];
}
