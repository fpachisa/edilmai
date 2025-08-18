/// Utility class for formatting mathematical expressions
class MathFormatter {
  /// Converts LaTeX mathematical notation to Unicode symbols for display
  static String formatMath(String input) {
    var out = input;
    
    // Handle LaTeX fractions: $\frac{a}{b}$ -> a/b (NOT a÷b)
    out = out.replaceAllMapped(RegExp(r'\$\\frac\{([^}]+)\}\{([^}]+)\}\$'), (match) {
      String numerator = match.group(1) ?? '';
      String denominator = match.group(2) ?? '';
      return '$numerator/$denominator';
    });
    
    // Handle simple fractions without LaTeX markers: \frac{a}{b} -> a/b (NOT a÷b)
    out = out.replaceAllMapped(RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'), (match) {
      String numerator = match.group(1) ?? '';
      String denominator = match.group(2) ?? '';
      return '$numerator/$denominator';
    });
    
    // Handle other LaTeX expressions by removing $ delimiters
    out = out.replaceAllMapped(RegExp(r'\$([^$]+)\$'), (match) {
      return match.group(1) ?? '';
    });
    
    // Handle common mathematical symbols
    out = out.replaceAll('sqrt', '√');
    out = out.replaceAll('^2', '²');
    out = out.replaceAll('^3', '³');
    out = out.replaceAll('^4', '⁴');
    out = out.replaceAll('^5', '⁵');
    out = out.replaceAll('*', '×');
    // Note: Don't replace / with ÷ because fractions should show as 3/4, not 3÷4
    
    // Handle common LaTeX symbols
    out = out.replaceAll('\\cdot', '·');
    out = out.replaceAll('\\times', '×');
    out = out.replaceAll('\\div', '÷');
    out = out.replaceAll('\\pi', 'π');
    out = out.replaceAll('\\theta', 'θ');
    out = out.replaceAll('\\alpha', 'α');
    out = out.replaceAll('\\beta', 'β');
    out = out.replaceAll('\\gamma', 'γ');
    out = out.replaceAll('\\delta', 'δ');
    out = out.replaceAll('\\lambda', 'λ');
    out = out.replaceAll('\\mu', 'μ');
    out = out.replaceAll('\\sigma', 'σ');
    
    // Handle common mathematical operators
    out = out.replaceAll('\\leq', '≤');
    out = out.replaceAll('\\geq', '≥');
    out = out.replaceAll('\\neq', '≠');
    out = out.replaceAll('\\approx', '≈');
    out = out.replaceAll('\\pm', '±');
    out = out.replaceAll('\\infty', '∞');
    
    return out;
  }
}