import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Entrada de log con texto, color y timestamp de creación.
class LogEntry {
  final String msg;
  final Color color;
  // B-7: timestamp capturado en el momento de creación, no en el de render
  final DateTime ts;
  LogEntry(this.msg, this.color) : ts = DateTime.now();
}

/// Panel de terminal que muestra entradas de log con timestamp.
/// Último mensaje primero (reversed).
class LogPanel extends StatelessWidget {
  final List<LogEntry> entries;
  const LogPanel({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF05050F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                _dot(kRed),
                const SizedBox(width: 4),
                _dot(kYellow),
                const SizedBox(width: 4),
                _dot(kGreen),
                const SizedBox(width: 10),
                const Text(
                  'telemetria@caminside',
                  style: TextStyle(
                    fontSize: 9,
                    color: kTextMut,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Entradas
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      '> esperando eventos...',
                      style: TextStyle(
                        fontSize: 10,
                        color: kTextMut,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final ts =
                          '${e.ts.hour.toString().padLeft(2, '0')}:${e.ts.minute.toString().padLeft(2, '0')}:${e.ts.second.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '[$ts] ',
                                style: const TextStyle(color: kTextMut),
                              ),
                              TextSpan(
                                text: e.msg,
                                style: TextStyle(color: e.color),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
