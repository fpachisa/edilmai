class LearningModule {
  final String id;
  final String title;
  final String description;
  final String strand;
  final String subStrand;
  final List<String> prerequisites;
  final int estimatedMinutes;
  final String difficulty;
  final List<String> learningObjectives;
  final String aiPromptContext;
  final List<String> referenceItemIds; // IDs from algebra.json or other content files

  const LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.strand,
    required this.subStrand,
    required this.prerequisites,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.learningObjectives,
    required this.aiPromptContext,
    required this.referenceItemIds,
  });
}

// Algebra Learning Modules based on the rich content in algebra.json
const List<LearningModule> kAlgebraModules = [
  // Unknowns and Notation
  LearningModule(
    id: 'alg-unknowns-basic',
    title: 'Introduction to Variables',
    description: 'Learn what variables represent and how to form basic expressions',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: [],
    estimatedMinutes: 15,
    difficulty: 'Beginner',
    learningObjectives: [
      'Understand what a variable represents',
      'Form simple expressions with addition and subtraction',
      'Recognize variables in word problems',
    ],
    aiPromptContext: '''
You are teaching students about algebraic variables and basic expression formation. 
Focus on:
- Variables as placeholders for unknown values
- The difference between numbers and variables
- How to translate simple word problems into expressions
- Common operations: addition, subtraction, multiplication

Use Socratic questioning to guide students through understanding. Reference problems involve scenarios like:
- Adding/subtracting to unknown quantities
- Simple multiplication with unknowns
- Basic division expressed as fractions
''',
    referenceItemIds: [
      'ALG-S1-E1', // Adding to an Unknown
      'ALG-S1-E2', // Multiplying an Unknown  
      'ALG-S1-E3', // Division as a Fraction
    ],
  ),

  LearningModule(
    id: 'alg-unknowns-advanced',
    title: 'Complex Expressions',
    description: 'Build multi-step expressions and work with multiple variables',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-unknowns-basic'],
    estimatedMinutes: 20,
    difficulty: 'Intermediate',
    learningObjectives: [
      'Form two-step and multi-step expressions',
      'Work with multiple variables in one expression',
      'Handle unit conversions in algebraic contexts',
    ],
    aiPromptContext: '''
You are teaching students about complex algebraic expressions.
Focus on:
- Building expressions that require multiple operations
- Working with problems involving multiple unknown quantities
- Unit conversion within algebraic contexts
- Order of operations in expression building

Guide students through more sophisticated reasoning. Reference problems include:
- Two-step expressions
- Problems with unit conversions
- Multiple variable scenarios
''',
    referenceItemIds: [
      'ALG-S1-E4', // Two-Step Expression
      'ALG-S1-E5', // Expression with Unit Conversion
    ],
  ),

  // Simplify Linear Expressions
  LearningModule(
    id: 'alg-simplify-basic',
    title: 'Combining Like Terms',
    description: 'Learn to simplify expressions by combining similar terms',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-unknowns-basic'],
    estimatedMinutes: 18,
    difficulty: 'Intermediate',
    learningObjectives: [
      'Identify like terms in expressions',
      'Combine terms with the same variable',
      'Simplify expressions with addition and subtraction',
    ],
    aiPromptContext: '''
You are teaching students about simplifying algebraic expressions.
Focus on:
- What makes terms "like" terms (same variable, same power)
- The distributive property and combining terms
- Maintaining expression equivalence during simplification
- Common mistakes like combining unlike terms

Use guided discovery to help students see patterns. Reference problems involve:
- Combining like terms with addition
- Simplifying with constants
- Subtraction in simplification
''',
    referenceItemIds: [
      'ALG-S2-E1', // Combining Like Terms (Addition)
      'ALG-S2-E2', // Simplifying with a Constant
      'ALG-S2-E3', // Simplifying with Subtraction
    ],
  ),

  LearningModule(
    id: 'alg-simplify-advanced',
    title: 'Advanced Simplification',
    description: 'Simplify complex expressions with multiple variables and fractions',
    strand: 'Number and Algebra', 
    subStrand: 'Algebra',
    prerequisites: ['alg-simplify-basic'],
    estimatedMinutes: 25,
    difficulty: 'Advanced',
    learningObjectives: [
      'Simplify expressions with multiple different variables',
      'Work with fractional coefficients',
      'Handle more complex algebraic structures',
    ],
    aiPromptContext: '''
You are teaching students advanced expression simplification.
Focus on:
- Working with multiple variables (x, y, z, etc.)
- Fractional coefficients and how to combine them
- More complex algebraic manipulations
- Checking work by substituting test values

Guide students through sophisticated algebraic thinking. Reference problems include:
- Multiple variable expressions
- Fractional expressions and simplification
''',
    referenceItemIds: [
      'ALG-S2-E4', // Simplifying with Multiple Variables
      'ALG-S2-E5', // Simplifying Fractional Expressions
    ],
  ),

  // Evaluate by Substitution
  LearningModule(
    id: 'alg-substitution-basic',
    title: 'Basic Substitution',
    description: 'Learn to evaluate expressions by substituting values for variables',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-unknowns-basic'],
    estimatedMinutes: 20,
    difficulty: 'Intermediate',
    learningObjectives: [
      'Substitute single values into expressions',
      'Evaluate expressions after substitution',
      'Understand the relationship between variables and their values',
    ],
    aiPromptContext: '''
You are teaching students about evaluating expressions through substitution.
Focus on:
- The concept of substitution - replacing variables with actual numbers
- Order of operations when evaluating
- The importance of careful substitution (especially with negatives)
- How substitution helps verify algebraic work

Use step-by-step guidance to build confidence. Reference problems involve:
- Basic single-variable substitution
- Substitution with multiplication
- Division in substitution problems
''',
    referenceItemIds: [
      'ALG-S3-E1', // Basic Substitution
      'ALG-S3-E2', // Substitution with Multiplication
      'ALG-S3-E3', // Substitution with Division
    ],
  ),

  LearningModule(
    id: 'alg-substitution-advanced',
    title: 'Advanced Substitution',
    description: 'Master substitution with complex expressions and multiple variables',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-substitution-basic', 'alg-simplify-basic'],
    estimatedMinutes: 25,
    difficulty: 'Advanced',
    learningObjectives: [
      'Simplify expressions before substituting',
      'Work with multiple variable substitution',
      'Combine simplification and substitution strategies',
    ],
    aiPromptContext: '''
You are teaching students advanced substitution techniques.
Focus on:
- The strategic choice of when to simplify vs. when to substitute
- Working with multiple variables simultaneously
- Complex expressions requiring careful order of operations
- Real-world applications of substitution

Guide students through sophisticated problem-solving. Reference problems include:
- Simplify then substitute strategies
- Two-variable substitution problems
''',
    referenceItemIds: [
      'ALG-S3-E4', // Simplify then Substitute
      'ALG-S3-E5', // Substitution with Two Variables
    ],
  ),

  // Solve Simple Linear Equations
  LearningModule(
    id: 'alg-equations-basic',
    title: 'One-Step Equations',
    description: 'Learn to solve simple equations with one operation',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-unknowns-basic'],
    estimatedMinutes: 22,
    difficulty: 'Intermediate',
    learningObjectives: [
      'Solve equations involving addition/subtraction',
      'Solve equations involving multiplication/division',
      'Understand equation solving as "undoing" operations',
    ],
    aiPromptContext: '''
You are teaching students to solve basic linear equations.
Focus on:
- Equations as balanced scales - what you do to one side, do to the other
- Inverse operations - addition/subtraction, multiplication/division
- Checking solutions by substituting back into original equation
- Building intuition about equation solving

Use hands-on metaphors and checking strategies. Reference problems involve:
- One-step addition/subtraction equations
- One-step multiplication/division equations
''',
    referenceItemIds: [
      'ALG-S4-E1', // One-Step Equation (Addition)
      'ALG-S4-E2', // One-Step Equation (Multiplication)
    ],
  ),

  LearningModule(
    id: 'alg-equations-applications',
    title: 'Equation Word Problems',
    description: 'Apply equation solving to real-world word problems',
    strand: 'Number and Algebra',
    subStrand: 'Algebra',
    prerequisites: ['alg-equations-basic'],
    estimatedMinutes: 30,
    difficulty: 'Advanced',
    learningObjectives: [
      'Translate word problems into equations',
      'Solve multi-step word problems',
      'Interpret solutions in context',
    ],
    aiPromptContext: '''
You are teaching students to apply equation solving to word problems.
Focus on:
- Reading comprehension - identifying the unknown and relationships
- Translation skills - turning words into mathematical expressions
- Problem-solving process - define variable, write equation, solve, check in context
- Real-world relevance of algebraic problem solving

Guide students through the complete problem-solving cycle. Reference problems include:
- Two-step word problems
- Problems with combined variables
- Future state problems
''',
    referenceItemIds: [
      'ALG-S4-E3', // Two-Step Word Problem
      'ALG-S4-E4', // Word Problem with Combined Variables
      'ALG-S4-E5', // Problem Involving a Future State
    ],
  ),
];

// Helper function to get modules for a specific subtopic
List<LearningModule> getModulesForSubTopic(String subStrand, String subTopic) {
  return kAlgebraModules.where((module) {
    return module.subStrand == subStrand && 
           _isModuleForSubTopic(module.id, subTopic);
  }).toList();
}

bool _isModuleForSubTopic(String moduleId, String subTopic) {
  final topicLower = subTopic.toLowerCase();
  if (topicLower.contains('unknowns') || topicLower.contains('notation')) {
    return moduleId.startsWith('alg-unknowns');
  } else if (topicLower.contains('simplify')) {
    return moduleId.startsWith('alg-simplify');
  } else if (topicLower.contains('substitution')) {
    return moduleId.startsWith('alg-substitution');
  } else if (topicLower.contains('equations')) {
    return moduleId.startsWith('alg-equations');
  }
  return false;
}