// lib/presentation/widgets/status_timeline.dart
import 'package:flutter/material.dart';

import '../../data/models/service_request.dart';

/// Vertical progress of a request through its lifecycle states.
class StatusTimeline extends StatelessWidget {
  final RequestStatus current;
  const StatusTimeline({super.key, required this.current});

  static const _steps = [
    RequestStatus.requested,
    RequestStatus.accepted,
    RequestStatus.onTheWay,
    RequestStatus.arrived,
    RequestStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;
    final outlineColor = Theme.of(context).colorScheme.outline;

    if (current == RequestStatus.cancelled) {
      return Row(children: [
        Icon(Icons.cancel, color: primaryColor),
        const SizedBox(width: 8),
        Text(current.label, style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
      ]);
    }
    final currentIndex = _steps.indexOf(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length, (i) {
        final done = i <= currentIndex;
        final isLast = i == _steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 22, color: done ? primaryColor : outlineColor),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: i < currentIndex ? primaryColor : outlineColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  _steps[i].label,
                  style: TextStyle(
                    fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                    color: done ? primaryColor : tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
