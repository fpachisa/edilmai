import 'dart:math';
import 'dart:ui' show FontFeature;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../ui/app_theme.dart';
import '../state/game_state.dart';
import '../data/learning_modules.dart';

class TutorScreen extends StatefulWidget {
  final String apiBase;
  final String sessionId;
  final String stepId;
  final String prompt;
  final LearningModule? moduleContext;
  const TutorScreen({super.key, required this.apiBase, required this.sessionId, required this.stepId, required this.prompt, this.moduleContext});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final List<_Msg> _messages = [];
  final TextEditingController _answerCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final _confetti = ConfettiController(duration: const Duration(seconds: 1));
  bool _busy = false;
  bool _aiTyping = false;
  String _currentStepId = 's1';
  int _attempts = 0; // for hint-ladder visualization

  ApiClient get _api => ApiClient(widget.apiBase);

  @override
  void initState() {
    super.initState();
    _currentStepId = widget.stepId;
    _messages.add(_Msg(agent: 'tutor', text: widget.prompt));
    WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocus.requestFocus());
    GameStateController.instance.onPromptShown();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _answerCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() { _busy = true; _aiTyping = true; });
    final text = _answerCtrl.text.trim();
    _answerCtrl.clear();
    _messages.add(_Msg(agent: 'you', text: text));
    try {
      final res = await _api.step(sessionId: widget.sessionId, stepId: _currentStepId, userResponse: text);
      final correct = res['correctness'] as bool?;
      final hint = (res['hint'] as String?) ?? '';
      final tutorMessage = (res['tutor_message'] as String?) ?? '';
      final finished = res['finished'] as bool? ?? false;
      final nextPrompt = (res['next_prompt'] as String?) ?? '';
      final updates = res['updates'] as Map<String, dynamic>? ?? {};
      // Record attempt for stats
      GameStateController.instance.recordAttempt(correct: correct == true, skill: 'Algebraic Expressions');

      if (correct == true) {
        final baseXp = (updates['xp_earned'] as int?) ?? 10;
        GameStateController.instance.applyXpForCorrect(baseXp: baseXp);
        _confetti.play();
        
        if (finished) {
          final itemCompleted = updates['item_completed'] as bool? ?? false;
          final nextItemAvailable = updates['next_item_available'] as bool? ?? false;
          final nextItemTitle = updates['next_item_title'] as String? ?? '';
          
          if (itemCompleted && nextItemAvailable) {
            GameStateController.instance.onItemCompleted(topic: 'Algebra');
            // Show completion message with next item info
            _messages.add(_Msg(agent: 'tutor', text: nextPrompt.isNotEmpty ? nextPrompt : 'Great job! Ready for the next challenge?'));
            // Add a button or automatic continuation
            _showNextItemDialog(nextItemTitle);
          } else if (updates['progression_completed'] == true) {
            _messages.add(_Msg(agent: 'tutor', text: nextPrompt.isNotEmpty ? nextPrompt : 'Congratulations! You\'ve mastered algebra! 🌟'));
          } else {
            _messages.add(_Msg(agent: 'tutor', text: 'Brilliant! You\'ve completed the quest.'));
          }
        } else if (nextPrompt.isNotEmpty) {
          _messages.add(_Msg(agent: 'tutor', text: nextPrompt));
          GameStateController.instance.onPromptShown();
        }
        _attempts = 0; // reset ladder when moving to a new prompt
      } else {
        // Show AI tutor response for incorrect answers
        if (tutorMessage.isNotEmpty) {
          _messages.add(_Msg(agent: 'tutor', text: tutorMessage));
          _attempts += 1;
        } else if (hint.isNotEmpty) {
          _messages.add(_Msg(agent: 'tutor', text: 'Hint: $hint'));
          _attempts += 1;
        }
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() { _busy = false; _aiTyping = false; });
        // Keep focus in the input for fast continued answers
        _inputFocus.requestFocus();
      }
    }
  }

  Future<void> _requestHint() async {
    if (_busy) return;
    setState(() { _busy = true; _aiTyping = true; });
    try {
      final res = await _api.step(sessionId: widget.sessionId, stepId: _currentStepId, userResponse: '');
      final hint = (res['hint'] as String?) ?? '';
      if (hint.isNotEmpty) {
        _messages.add(_Msg(agent: 'tutor', text: 'Hint: $hint'));
        _attempts += 1;
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting hint: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _busy = false; _aiTyping = false; });
        _inputFocus.requestFocus();
      }
    }
  }

  void _showNextItemDialog(String nextItemTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Quest Complete!'),
        content: Text('Ready for the next challenge?\n\n"$nextItemTitle"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _continueToNextItem();
            },
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }

  Future<void> _continueToNextItem() async {
    try {
      setState(() => _busy = true);
      final res = await _api.continueProgression(sessionId: widget.sessionId);
      final newSessionId = res['session_id'] as String;
      final newStepId = res['step_id'] as String;
      final newPrompt = res['prompt'] as String;
      
      // Navigate to new tutor screen with new session
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TutorScreen(
              apiBase: widget.apiBase,
              sessionId: newSessionId,
              stepId: newStepId,
              prompt: newPrompt,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting next item: $e')),
        );
      }
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
          AnimatedBuilder(
            animation: GameStateController.instance,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Chip(label: Text('XP: ${GameStateController.instance.xp}')),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: Stack(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                        child: Glass(
                          child: Column(children: [
                            Expanded(child: _ChatView(messages: _messages, typing: _aiTyping)),
                            _InputBar(
                              controller: _answerCtrl,
                              focusNode: _inputFocus,
                              onSubmit: _busy ? null : _submit,
                              onHint: _busy ? null : _requestHint,
                              attempts: _attempts,
                            ),
                          ]),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                        child: Column(
                          children: const [
                            Glass(child: _ScratchPad(height: 260)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(children: [
                  Expanded(child: Glass(child: _ChatView(messages: _messages, typing: _aiTyping))),
                  const SizedBox(height: 8),
                  Glass(
                    child: _InputBar(
                      controller: _answerCtrl,
                      focusNode: _inputFocus,
                      onSubmit: _busy ? null : _submit,
                      onHint: _busy ? null : _requestHint,
                      attempts: _attempts,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Glass(child: _ScratchPad(height: 160)),
                ]),
              );
            }),
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
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSubmit;
  final VoidCallback? onHint;
  final int attempts;
  const _InputBar({required this.controller, this.focusNode, this.onSubmit, this.onHint, this.attempts = 0});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MathPreview(controller: controller),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _HintLadder(attempts: attempts, onHint: onHint),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit?.call(),
                decoration: const InputDecoration(hintText: 'Type your answer…'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.send_rounded), label: const Text('Send')),
          ]),
          const SizedBox(height: 8),
          _QuickReplies(attempts: attempts, onInsert: (txt) {
            final selection = controller.selection;
            final value = controller.text;
            final start = selection.start >= 0 ? selection.start : value.length;
            final end = selection.end >= 0 ? selection.end : value.length;
            final newText = value.replaceRange(start, end, txt);
            controller.text = newText;
            final newPos = start + txt.length;
            controller.selection = TextSelection.collapsed(offset: newPos);
            focusNode?.requestFocus();
          }, onHint: onHint),
          const SizedBox(height: 8),
          _MathKeypad(onInsert: (txt, {int? cursorOffset}) {
            final selection = controller.selection;
            final value = controller.text;
            final start = selection.start >= 0 ? selection.start : value.length;
            final end = selection.end >= 0 ? selection.end : value.length;
            final newText = value.replaceRange(start, end, txt);
            controller.text = newText;
            final newPos = start + (cursorOffset ?? txt.length);
            controller.selection = TextSelection.collapsed(offset: newPos);
            focusNode?.requestFocus();
          }),
        ],
      ),
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
  final bool typing;
  const _ChatView({required this.messages, this.typing = false});
  @override
  Widget build(BuildContext context) {
    final bgTutor = Colors.white.withOpacity(0.08);
    final bgYou = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (typing ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= messages.length) {
          return const _TypingIndicator();
        }
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [if (!isTutor) BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Text(
              m.text,
              style: const TextStyle(height: 1.3),
            ),
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

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke({required this.points, required this.color, required this.width});
}

class _ScratchPadState extends State<_ScratchPad> {
  final List<_Stroke> _strokes = [];
  Color _color = Colors.black87;
  double _width = 3.0;
  bool _grid = true;

  void _onPanStart(DragStartDetails d) {
    setState(() => _strokes.add(_Stroke(points: [d.localPosition], color: _color, width: _width)));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _strokes.last.points.add(d.localPosition));
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        color: bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo_rounded),
                    onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.clear()),
                  ),
                  const SizedBox(width: 6),
                  _ColorDot(color: Colors.black87, selected: _color.value == Colors.black87.value, onTap: () => setState(() => _color = Colors.black87)),
                  _ColorDot(color: Colors.indigoAccent, selected: _color.value == Colors.indigoAccent.value, onTap: () => setState(() => _color = Colors.indigoAccent)),
                  _ColorDot(color: Colors.redAccent, selected: _color.value == Colors.redAccent.value, onTap: () => setState(() => _color = Colors.redAccent)),
                  _ColorDot(color: Colors.greenAccent.shade400, selected: _color.value == Colors.greenAccent.shade400.value, onTap: () => setState(() => _color = Colors.greenAccent.shade400)),
                  const SizedBox(width: 6),
                  _WidthChip(label: 'S', width: 3.0, selected: _width == 3.0, onTap: () => setState(() => _width = 3.0)),
                  _WidthChip(label: 'M', width: 5.0, selected: _width == 5.0, onTap: () => setState(() => _width = 5.0)),
                  _WidthChip(label: 'L', width: 8.0, selected: _width == 8.0, onTap: () => setState(() => _width = 8.0)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Grid',
                    icon: Icon(_grid ? Icons.grid_on_rounded : Icons.grid_off_rounded),
                    onPressed: () => setState(() => _grid = !_grid),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: CustomPaint(painter: _ScratchPainter(_strokes, grid: _grid), size: Size.infinite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 2 : 1),
          ),
        ),
      ),
    );
  }
}

class _WidthChip extends StatelessWidget {
  final String label;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  const _WidthChip({required this.label, required this.width, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final bool grid;
  _ScratchPainter(this.strokes, {required this.grid});
  @override
  void paint(Canvas canvas, Size size) {
    if (grid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(0.06)
        ..strokeWidth = 1;
      const step = 20.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    for (final s in strokes) {
      final p = Paint()
        ..color = s.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], p);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _ScratchPainter old) => old.strokes != strokes || old.grid != grid;
}

class _QuickReplies extends StatelessWidget {
  final void Function(String text) onInsert;
  final VoidCallback? onHint;
  final int attempts;
  const _QuickReplies({required this.onInsert, this.onHint, this.attempts = 0});
  @override
  Widget build(BuildContext context) {
    final nextLevel = (attempts + 1).clamp(1, 3);
    final chips = <Widget>[
      _chip(context, label: 'Hint L$nextLevel', icon: Icons.lightbulb_rounded, onTap: onHint),
      _chip(context, label: '+', onTap: () => onInsert(' + ')),
      _chip(context, label: '×', onTap: () => onInsert(' * ')),
      _chip(context, label: '/', onTap: () => onInsert(' / ')),
      _chip(context, label: '(', onTap: () => onInsert('(')),
      _chip(context, label: ')', onTap: () => onInsert(')')),
      _chip(context, label: 'b', onTap: () => onInsert('b')),
      _chip(context, label: 'n', onTap: () => onInsert('n')),
      _chip(context, label: 'k', onTap: () => onInsert('k')),
      _chip(context, label: 'Clear', icon: Icons.backspace_rounded, onTap: () => onInsert('')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        const SizedBox(width: 4),
        for (final w in chips) ...[w, const SizedBox(width: 8)],
      ]),
    );
  }

  Widget _chip(BuildContext context, {required String label, IconData? icon, VoidCallback? onTap}) {
    return ActionChip(
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _MathPreview extends StatelessWidget {
  final TextEditingController controller;
  const _MathPreview({required this.controller});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final raw = value.text.trim();
        if (raw.isEmpty) return const SizedBox.shrink();
        final pretty = _prettyPrint(raw);
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.preview_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Flexible(child: Text(pretty, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], height: 1.2))),
            ],
          ),
        );
      },
    );
  }

  static String _prettyPrint(String s) {
    var out = s;
    out = out.replaceAll('sqrt', '√');
    out = out.replaceAll('^2', '²');
    out = out.replaceAll('^3', '³');
    out = out.replaceAll('*', '×');
    out = out.replaceAll('/', '÷');
    return out;
  }
}

class _MathKeypad extends StatelessWidget {
  final void Function(String text, {int? cursorOffset}) onInsert;
  const _MathKeypad({required this.onInsert});
  @override
  Widget build(BuildContext context) {
    final keys = <_KeyDef>[
      _KeyDef('x'), _KeyDef('y'), _KeyDef('b'), _KeyDef('n'), _KeyDef('k'),
      _KeyDef('+'), _KeyDef('-'), _KeyDef('×', insert: '*'), _KeyDef('÷', insert: '/'), _KeyDef('='),
      _KeyDef('('), _KeyDef(')'), _KeyDef('^', insert: '^'), _KeyDef('^2'), _KeyDef('^3'),
      _KeyDef('√()', insert: 'sqrt() ', cursorOffset: 5),
      _KeyDef('frac', insert: r'\frac{ }{ }', cursorOffset: 7),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final k = keys[i];
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => onInsert(k.insert ?? k.label, cursorOffset: k.cursorOffset ?? (k.insert ?? k.label).length),
            child: Text(k.label),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: keys.length,
      ),
    );
  }
}

class _KeyDef {
  final String label;
  final String? insert;
  final int? cursorOffset;
  _KeyDef(this.label, {this.insert, this.cursorOffset});
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    final bgTutor = Colors.white.withOpacity(0.08);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgTutor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(), SizedBox(width: 4), _Dot(delayMs: 150), SizedBox(width: 4), _Dot(delayMs: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot({this.delayMs = 0});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _a = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: const CircleAvatar(radius: 4, backgroundColor: Colors.white70),
    );
  }
}

class _HintLadder extends StatelessWidget {
  final int attempts; // 0-based attempts so far
  final VoidCallback? onHint;
  const _HintLadder({required this.attempts, this.onHint});
  @override
  Widget build(BuildContext context) {
    final current = (attempts).clamp(0, 2); // show 0..2 filled
    List<Widget> steps = [];
    for (var i = 0; i < 3; i++) {
      final active = i <= current;
      steps.add(Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: active ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.15),
        ),
      ));
      if (i < 2) steps.add(const SizedBox(width: 6));
    }
    return Row(
      children: [
        const Icon(Icons.emoji_objects_rounded, size: 16, color: Colors.amberAccent),
        const SizedBox(width: 6),
        ...steps,
        const SizedBox(width: 10),
        Text('Hints', style: TextStyle(color: Colors.white.withOpacity(0.8))),
        const SizedBox(width: 6),
        TextButton.icon(onPressed: onHint, icon: const Icon(Icons.lightbulb_outline), label: const Text('Get hint')),
      ],
    );
  }
}
