import 'package:flutter/material.dart';
import '../api_client.dart';
import '../config.dart';
import '../state/active_learner.dart';
import '../state/app_mode.dart';
import '../ui/app_theme.dart';

class CreateLearnerScreen extends StatefulWidget {
  const CreateLearnerScreen({super.key});

  @override
  State<CreateLearnerScreen> createState() => _CreateLearnerScreenState();
}

class _CreateLearnerScreenState extends State<CreateLearnerScreen> with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _ctaName => _nameCtrl.text.trim().isEmpty ? 'your child' : _nameCtrl.text.trim();

  Future<void> _createAndStart() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your child\'s name to personalise their learning.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient(kDefaultApiBase);
      final res = await api.createLearner(name: name);
      final id = res['learner_id'] as String;
      final disp = res['name'] as String? ?? name;
      ActiveLearner.instance.setActive(id: id, name: disp);
      AppModeController.instance.switchTo(AppMode.learner);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'We couldn\'t save that just now. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Hero icon with glow
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primary,
                            boxShadow: [
                              BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.45), blurRadius: 28, spreadRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 46),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Headline
                      Text(
                        "Add Your Child's Account",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Personalised PSLE Maths coaching — start in under a minute.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      // Card with form + benefits
                      Glass(
                        radius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: "Child's first name",
                                hintText: 'e.g., Aisha, Ryan',
                              ),
                              enabled: !_busy,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: const [
                              _Chip(label: 'Grade: Primary 6', icon: Icons.grade_rounded),
                              _Chip(label: 'Subject: Maths', icon: Icons.calculate_rounded),
                            ]),
                            const SizedBox(height: 14),
                            const _BenefitRow(icon: Icons.psychology_rounded, text: 'Socratic AI coaching that builds understanding'),
                            const SizedBox(height: 8),
                            const _BenefitRow(icon: Icons.emoji_events_rounded, text: 'Confetti moments, streaks, XP — stay motivated'),
                            const SizedBox(height: 8),
                            const _BenefitRow(icon: Icons.insights_rounded, text: 'Parent insights you can trust'),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy || _nameCtrl.text.trim().isEmpty ? null : _createAndStart,
                              child: _busy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text('Continue as $_ctaName'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You can switch between Parent and Learner anytime from the menu.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white70),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ]);
  }
}
