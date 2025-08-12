class SyllabusSection {
  final String strand; // e.g., Number and Algebra
  final List<SubStrand> subStrands;
  const SyllabusSection({required this.strand, required this.subStrands});
}

class SubStrand {
  final String title; // e.g., Fractions
  final List<String> subTopics; // e.g., Four operations; Percentage increase/decrease
  const SubStrand({required this.title, required this.subTopics});
}

// Minimal placeholder content lifted from the P6 syllabus PDF (subset)
const List<SyllabusSection> kP6Syllabus = [
  SyllabusSection(
    strand: 'Number and Algebra',
    subStrands: [
      SubStrand(
        title: 'Fractions',
        subTopics: [
          'Four operations',
          'Divide proper fraction by whole number',
          'Divide whole/proper by proper fraction',
          'Word problems (fractions)',
        ],
      ),
      SubStrand(
        title: 'Percentage',
        subTopics: [
          'Find whole from part and %',
          'Percentage increase/decrease',
          'Word problems (percentage)',
        ],
      ),
      SubStrand(
        title: 'Ratio',
        subTopics: [
          'Fraction–ratio relationship',
          'Changing ratios',
          'Word problems (ratio)',
        ],
      ),
      SubStrand(
        title: 'Rate and Speed',
        subTopics: [
          'Distance–Time–Speed',
          'Average speed',
          'Unit conversions (display only)',
          'Word problems (speed)',
        ],
      ),
      SubStrand(
        title: 'Algebra',
        subTopics: [
          'Unknowns and notation',
          'Simplify linear expressions',
          'Evaluate by substitution',
          'Solve simple linear equations',
        ],
      ),
    ],
  ),
  SyllabusSection(
    strand: 'Measurement and Geometry',
    subStrands: [
      SubStrand(
        title: 'Area and Volume',
        subTopics: [
          'Area and circumference of circle',
          'Semi/quarter-circle perimeter & area',
          'Composite figures',
        ],
      ),
      // Add more from PDF later
    ],
  ),
  SyllabusSection(
    strand: 'Statistics',
    subStrands: [
      SubStrand(
        title: 'Pie Charts',
        subTopics: [
          'Interpret pie charts',
          'Draw pie charts (angles ↔ %)',
          'Word problems (pie charts)',
        ],
      ),
    ],
  ),
];
