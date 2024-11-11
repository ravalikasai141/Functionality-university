/**
 * Utilities class for Learning Difficulties
 */
public class LearningDifficultyUtilities {
    public static Map<String, LearningDifficulty> difficultiesByCode = new Map<String, LearningDifficulty>{
        '1' => new LearningDifficulty(
            'Asperger\'s syndrome',
            '15~ Asperger\'s syndrome',
            '53~ Social/communication conditions such as a speech and language impairment or an autistic spectrum condition'
        ),
        '2' => new LearningDifficulty(
            'Autism spectrum disorder',
            '14~ Autism spectrum disorder',
            '53~ Social/communication conditions such as a speech and language impairment or an autistic spectrum condition'
        ),
        '3' => new LearningDifficulty(
            'Disability affecting mobility',
            '6~ Disability affecting mobility',
            '56~ Physical impairment (a condition that substantially limits one or more basic physical activities such as walking, climbing stairs, lifting or carrying)'
        ),
        '4' => new LearningDifficulty(
            'Dyscalculia',
            '13~ Dyscalculia',
            '51~ Learning difference such as dyslexia, dyspraxia or AD(H)D'
        ),
        '5' => new LearningDifficulty(
            'Dyslexia',
            '12~ Dyslexia',
            '51~ Learning difference such as dyslexia, dyspraxia or AD(H)D'
        ),
        '6' => new LearningDifficulty(
            'Hearing impairment',
            '5~ Hearing impairment',
            '57~ D/deaf or have a hearing impairment'
        ),
        '7' => new LearningDifficulty(
            'Long-term illness or health condition',
            '95~ Other medical condition (for example epilepsy, asthma, diabetes)',
            '54~ Long-term illness or health condition such as cancer, HIV, diabetes, chronic heart disease, or epilepsy'
        ),
        '8' => new LearningDifficulty(
            'Mental health difficulty',
            '9~ Mental health difficulty',
            '55~ Mental health condition, challenge or disorder, such as depression, schizophrenia or anxiety'
        ),
        '9' => new LearningDifficulty(
            'Moderate learning difficulty',
            '10~ Moderate learning difficulty',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '10' => new LearningDifficulty(
            'Other disability',
            '97~ Other disability',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '11' => new LearningDifficulty(
            'Other learning difficulty',
            '96~ Other learning difficulty',
            '51~ Learning difference such as dyslexia, dyspraxia or AD(H)D'
        ),
        '12' => new LearningDifficulty(
            'Other medical condition',
            '96~ Other learning difficulty',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '13' => new LearningDifficulty(
            'Other physical disability',
            '93~ Other physical disability',
            '56~ Physical impairment (a condition that substantially limits one or more basic physical activities such as walking, climbing stairs, lifting or carrying)'
        ),
        '14' => new LearningDifficulty(
            'Other specific learning difficulty (e.g. Dyspraxia)',
            '94~ Other specific learning difficulty (e.g. Dyspraxia)',
            '51~ Learning difference such as dyslexia, dyspraxia or AD(H)D'
        ),
        '15' => new LearningDifficulty(
            'Profound complex disabilities',
            '7~ Profound complex disabilities',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '16' => new LearningDifficulty(
            'Severe learning difficulty',
            '11~ Severe learning difficulty',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '17' => new LearningDifficulty(
            'Social and emotional difficulties',
            '8~ Social and emotional difficulties',
            '59~ Development condition that you have had since childhood which affects motor, cognitive, social and emotional skills, and speech and language'
        ),
        '18' => new LearningDifficulty(
            'Speech, Language and Communication Needs',
            '17~ Speech, Language and Communication Needs',
            '59~ Development condition that you have had since childhood which affects motor, cognitive, social and emotional skills, and speech and language'
        ),
        '19' => new LearningDifficulty(
            'Temporary disability after illness (for example post-viral) or accident',
            '16~ Temporary disability after illness (for example post-viral) or accident',
            '96~ An impairment, health condition or learning difference not listed above'
        ),
        '20' => new LearningDifficulty(
            'Vision impairment',
            '4~ Visual impairment',
            '58~ Blind or have a visual impairment uncorrected by glasses'
        )
    };

    public class LearningDifficulty {
        public String label;
        public String ESFAValue;
        public String HESAValue;

        public LearningDifficulty(String label, String ESFAValue, String HESAValue) {
            this.label = label;
            this.ESFAValue = ESFAValue;
            this.HESAValue = HESAValue;
        }
    }
}
