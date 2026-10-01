class UserSettings {
  final int dailyGoalMinutes;
  final int pomodoroMinutes;
  final int breakMinutes;
  final bool notificationsEnabled;

  const UserSettings({
    this.dailyGoalMinutes = 120,
    this.pomodoroMinutes = 25,
    this.breakMinutes = 5,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'dailyGoalMinutes': dailyGoalMinutes,
    'pomodoroMinutes': pomodoroMinutes,
    'breakMinutes': breakMinutes,
    'notificationsEnabled': notificationsEnabled,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    dailyGoalMinutes: json['dailyGoalMinutes'] as int,
    pomodoroMinutes: json['pomodoroMinutes'] as int,
    breakMinutes: json['breakMinutes'] as int,
    notificationsEnabled: json['notificationsEnabled'] as bool,
  );

  UserSettings copyWith({
    int? dailyGoalMinutes,
    int? pomodoroMinutes,
    int? breakMinutes,
    bool? notificationsEnabled,
  }) => UserSettings(
    dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );
}
