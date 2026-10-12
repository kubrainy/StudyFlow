class UserSettings {
  final String name;
  final int dailyGoalMinutes;
  final int pomodoroMinutes;
  final int breakMinutes;
  final bool notificationsEnabled;

  /// Uzun mola süresi (dk) ve kaç çalışma oturumunda bir verileceği.
  final int longBreakMinutes;
  final int longBreakEvery;

  const UserSettings({
    this.name = '',
    this.dailyGoalMinutes = 120,
    this.pomodoroMinutes = 25,
    this.breakMinutes = 5,
    this.notificationsEnabled = true,
    this.longBreakMinutes = 15,
    this.longBreakEvery = 4,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dailyGoalMinutes': dailyGoalMinutes,
    'pomodoroMinutes': pomodoroMinutes,
    'breakMinutes': breakMinutes,
    'notificationsEnabled': notificationsEnabled,
    'longBreakMinutes': longBreakMinutes,
    'longBreakEvery': longBreakEvery,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    name: json['name'] as String? ?? '',
    dailyGoalMinutes: json['dailyGoalMinutes'] as int,
    pomodoroMinutes: json['pomodoroMinutes'] as int,
    breakMinutes: json['breakMinutes'] as int,
    notificationsEnabled: json['notificationsEnabled'] as bool,
    // Eski kayıtlarda yok: varsayılan değerler.
    longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
    longBreakEvery: json['longBreakEvery'] as int? ?? 4,
  );

  UserSettings copyWith({
    String? name,
    int? dailyGoalMinutes,
    int? pomodoroMinutes,
    int? breakMinutes,
    bool? notificationsEnabled,
    int? longBreakMinutes,
    int? longBreakEvery,
  }) => UserSettings(
    name: name ?? this.name,
    dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    longBreakEvery: longBreakEvery ?? this.longBreakEvery,
  );
}
