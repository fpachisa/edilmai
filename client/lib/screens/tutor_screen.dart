import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../api_client.dart';

class TutorScreen extends StatefulWidget {
  final String apiBase;
  final String sessionId;
  final String stepId;
  final String prompt;
  const TutorScreen({super.key, required this.apiBase, required this.sessionId, required this.stepId, required this.prompt});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final List<_Msg> _messages = [];
  final TextEditingController _answerCtrl = TextEditingController();
  final _confetti = ConfettiController(duration: const Duration(seconds: 1));
  bool _busy = false;
  int _xp = 0;
  String _currentStepId = 's1';

  ApiClient get _api => ApiClient(widget.apiBase);

  @override
  void initState() {
    super.initState();
    _currentStepId = widget.stepId;
    _messages.add(_Msg(agent: 'tutor', text: widget.prompt));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final text = _answerCtrl.text.trim();
    _answerCtrl.clear();
    _messages.add(_Msg(agent: 'you', text: text));
    try {
      final res = await _api.step(sessionId: widget.sessionId, stepId: _currentStepId, userResponse: text);
      final correct = res['correctness'] as bool?;
      final hint = (res['hint'] as String?) ?? '';
      final finished = res['finished'] as bool? ?? false;
      final nextPrompt = (res['next_prompt'] as String?) ?? '';
      if (correct == true) {
        _xp += 10; // local XP bump for feedback
        _confetti.play();
        if (nextPrompt.isNotEmpty && !finished) {
          _messages.add(_Msg(agent: 'tutor', text: nextPrompt));
        } else if (finished) {
          _messages.add(_Msg(agent: 'tutor', text: 'Brilliant! You’ve completed the quest.'));
        }
      } else {
        if (hint.isNotEmpty) _messages.add(_Msg(agent: 'tutor', text: 'Hint: $hint'));
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algebra Quest'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Chip(
              label: Text('XP: $_xp'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(children: [
            Expanded(child: _ChatView(messages: _messages)),
            _InputBar(
              controller: _answerCtrl,
              onSubmit: _busy ? null : _submit,
            ),
            const SizedBox(height: 8),
            const _ScratchPad(height: 160),
            const SizedBox(height: 8),
          ]),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  const _InputBar({required this.controller, this.onSubmit});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSubmit?.call(),
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type your answer…'),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.send_rounded), label: const Text('Send')),
      ]),
    );
  }
}

class _Msg {
  final String agent; // 'tutor' | 'you'
  final String text;
  _Msg({required this.agent, required this.text});
}

class _ChatView extends StatelessWidget {
  final List<_Msg> messages;
  const _ChatView({required this.messages});
  @override
  Widget build(BuildContext context) {
    final bgTutor = Theme.of(context).colorScheme.surfaceVariant;
    final bgYou = Theme.of(context).colorScheme.primaryContainer;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = messages[i];
        final isTutor = m.agent == 'tutor';
        return Align(
          alignment: isTutor ? Alignment.centerLeft : Alignment.centerRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isTutor ? bgTutor : bgYou,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(m.text),
          ),
        );
      },
    );
  }
}

class _ScratchPad extends StatefulWidget {
  final double height;
  const _ScratchPad({required this.height});
  @override
  State<_ScratchPad> createState() => _ScratchPadState();
}

class _ScratchPadState extends State<_ScratchPad> {
  final List<Offset?> _points = [];
  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        color: bg,
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
          onPanEnd: (_) => _points.add(null),
          child: CustomPaint(painter: _ScratchPainter(_points), size: Size.infinite),
        ),
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset?> pts;
  _ScratchPainter(this.pts);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i] != null && pts[i + 1] != null) canvas.drawLine(pts[i]!, pts[i + 1]!, p);
    }
  }
  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) => oldDelegate.pts != pts;
}

