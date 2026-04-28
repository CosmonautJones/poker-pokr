import 'package:flutter/widgets.dart';

/// Root navigator key shared by [GoRouter] and notifier-driven UI surfaces
/// (e.g. progression toasts) that need a [BuildContext] without being
/// constructed inside a widget tree.
final rootNavigatorKey = GlobalKey<NavigatorState>();
