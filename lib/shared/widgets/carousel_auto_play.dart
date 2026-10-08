import 'dart:async';

import 'package:flutter/material.dart';

/// Auto-advance only while visible, idle, foregrounded, and motion is enabled.
class CarouselAutoPlay extends StatefulWidget {
  const CarouselAutoPlay({
    required this.controller,
    required this.page,
    required this.itemCount,
    required this.child,
    this.enabled = true,
    this.interval = const Duration(seconds: 5),
    super.key,
  });
  final PageController controller;
  final int page;
  final int itemCount;
  final Widget child;
  final bool enabled;
  final Duration interval;

  @override
  State<CarouselAutoPlay> createState() => _CarouselAutoPlayState();
}

class _CarouselAutoPlayState extends State<CarouselAutoPlay>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _touching = false;
  bool _scrolling = false;
  bool _advancing = false;
  bool _active = true;

  bool get _canAdvance {
    if (!mounted ||
        !_active ||
        !widget.enabled ||
        !_foreground ||
        _touching ||
        _scrolling ||
        _advancing ||
        widget.itemCount < 2) {
      return false;
    }
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations != true &&
        media?.accessibleNavigation != true &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
  }

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(CarouselAutoPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.interval != widget.interval ||
        oldWidget.controller != widget.controller ||
        oldWidget.itemCount != widget.itemCount) {
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_canAdvance) _timer = Timer(widget.interval, _advance);
  }

  Future<void> _advance() async {
    if (!_canAdvance || !widget.controller.hasClients) {
      _schedule();
      return;
    }
    _advancing = true;
    try {
      await widget.controller.animateToPage(
        (widget.page + 1) % widget.itemCount,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _advancing = false;
      if (mounted && _active) _schedule();
    }
  }

  @override
  void deactivate() {
    _active = false;
    _timer?.cancel();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      _touching = true;
      _timer?.cancel();
    },
    onPointerUp: (_) {
      _touching = false;
      _schedule();
    },
    onPointerCancel: (_) {
      _touching = false;
      _schedule();
    },
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          if (notification is ScrollStartNotification) {
            _scrolling = true;
            _timer?.cancel();
          } else if (notification is ScrollEndNotification) {
            _scrolling = false;
            _schedule();
          }
        }
        return false;
      },
      child: widget.child,
    ),
  );
}
