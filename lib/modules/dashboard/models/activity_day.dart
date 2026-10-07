import 'recent_activity.dart';

class ActivityDay {
  const ActivityDay({required this.date, required this.activities});

  final DateTime date;
  final List<RecentActivity> activities;
}
