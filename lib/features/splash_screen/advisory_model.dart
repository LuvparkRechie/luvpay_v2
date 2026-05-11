class SplashAdvisory {
  final String? id;
  final int order;
  final String iconName;
  final String iconColor;
  final String title;
  final String subtitle;
  final SplashAdvisoryButton primaryButton;
  final SplashAdvisoryButton? secondaryButton;

  const SplashAdvisory({
    required this.id,
    required this.order,
    this.iconName = "",
    this.iconColor = "",
    required this.title,
    required this.subtitle,
    required this.primaryButton,
    required this.secondaryButton,
  });

  bool get hasVisibleContent =>
      title.trim().isNotEmpty || subtitle.trim().isNotEmpty;

  static List<SplashAdvisory> listFromResponse(dynamic response) {
    final rows = _extractRows(response);
    final advisories = <SplashAdvisory>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (!_isActive(row)) continue;

      final advisory = SplashAdvisory.fromMap(row, fallbackOrder: i);
      if (advisory.hasVisibleContent) {
        advisories.add(advisory);
      }
    }

    advisories.sort((a, b) => a.order.compareTo(b.order));
    return advisories;
  }

  factory SplashAdvisory.fromMap(
    Map<String, dynamic> raw, {
    required int fallbackOrder,
  }) {
    final map = _NormalizedMap(raw);
    final primaryText = map.readString(const [
      "primary_button_text",
      "primary_btn_text",
      "right_button_text",
      "right_btn_text",
      "accept_button_text",
      "confirm_button_text",
      "ok_button_text",
      "okay_button_text",
      "button_text",
      "button1_text",
      "button_1_text",
    ]);
    final secondaryText = map.readString(const [
      "secondary_button_text",
      "secondary_btn_text",
      "left_button_text",
      "left_btn_text",
      "cancel_button_text",
      "decline_button_text",
      "button2_text",
      "button_2_text",
    ]);

    return SplashAdvisory(
      id: map.readOptionalString(const [
        "id",
        "notice_id",
        "advisory_id",
        "splash_advisory_id",
        "splash_notice_id",
        "parking_notice_id",
      ]),
      order: map.readInt(const [
        "order",
        "sort_order",
        "display_order",
        "sequence",
        "seq",
        "slide_no",
        "slide_number",
      ], fallback: fallbackOrder),
      iconName: map.readString(const [
        "icon",
        "icon_name",
        "icon_key",
        "icon_code",
        "leading_icon",
        "advisory_icon",
        "advisory_type",
        "notice_type",
      ]),
      iconColor: map.readString(const [
        "icon_color",
        "icon_hex",
        "accent_color",
        "accent_hex",
        "color",
      ]),
      title: map.readString(const [
        "title",
        "title_text",
        "header",
        "heading",
        "subject",
        "notice_title",
        "advisory_title",
      ]),
      subtitle: map.readString(const [
        "subtitle",
        "sub_title",
        "subtitle_text",
        "description",
        "body",
        "message",
        "notice",
        "notice_message",
        "advisory_message",
        "content",
        "details",
      ]),
      primaryButton: SplashAdvisoryButton(
        text: primaryText,
        action: _buttonActionFromRaw(map.readString(const [
          "primary_button_action",
          "primary_action",
          "right_button_action",
          "button_action",
          "button1_action",
          "button_1_action",
        ])),
      ),
      secondaryButton: secondaryText.trim().isEmpty
          ? null
          : SplashAdvisoryButton(
              text: secondaryText,
              action: _buttonActionFromRaw(map.readString(const [
                "secondary_button_action",
                "secondary_action",
                "left_button_action",
                "button2_action",
                "button_2_action",
              ], fallback: "dismiss")),
            ),
    );
  }

  static List<Map<String, dynamic>> _extractRows(dynamic response) {
    if (response == null || response == "No Internet") return const [];

    if (response is List) {
      return response.whereType<Map>().map(_castMap).toList();
    }

    if (response is Map) {
      final map = _castMap(response);
      const listKeys = [
        "items",
        "data",
        "records",
        "rows",
        "results",
        "advisories",
        "notices",
        "slides",
      ];

      for (final key in listKeys) {
        final value = map[key];
        if (value is List) {
          return value.whereType<Map>().map(_castMap).toList();
        }
      }

      return [map];
    }

    return const [];
  }

  static Map<String, dynamic> _castMap(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static bool _isActive(Map<String, dynamic> raw) {
    final map = _NormalizedMap(raw);
    final value = map.readOptionalString(const [
      "is_active",
      "active",
      "enabled",
      "is_enabled",
      "show",
      "is_show",
      "visible",
      "status",
    ]);

    if (value == null || value.trim().isEmpty) return true;

    final normalized = value.trim().toLowerCase();
    return normalized == "y" ||
        normalized == "yes" ||
        normalized == "true" ||
        normalized == "1" ||
        normalized == "active" ||
        normalized == "enabled" ||
        normalized == "published";
  }
}

class SplashAdvisoryButton {
  final String text;
  final SplashAdvisoryButtonAction action;

  const SplashAdvisoryButton({
    required this.text,
    required this.action,
  });
}

enum SplashAdvisoryButtonAction {
  next,
  dismiss,
}

SplashAdvisoryButtonAction _buttonActionFromRaw(String raw) {
  switch (raw.trim().toLowerCase()) {
    case "dismiss":
    case "close":
    case "cancel":
    case "skip":
    case "done":
      return SplashAdvisoryButtonAction.dismiss;
    default:
      return SplashAdvisoryButtonAction.next;
  }
}

class _NormalizedMap {
  final Map<String, dynamic> _values;

  _NormalizedMap(Map<String, dynamic> raw)
      : _values = raw.map((key, value) => MapEntry(_normalizeKey(key), value));

  String readString(
    List<String> keys, {
    String fallback = "",
  }) {
    return readOptionalString(keys) ?? fallback;
  }

  String? readOptionalString(List<String> keys) {
    for (final key in keys) {
      final value = _values[_normalizeKey(key)];
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != "null") {
        return text;
      }
    }

    return null;
  }

  int readInt(List<String> keys, {required int fallback}) {
    for (final key in keys) {
      final value = _values[_normalizeKey(key)];
      if (value is int) return value;
      if (value is num) return value.toInt();

      final parsed = int.tryParse(value?.toString().trim() ?? "");
      if (parsed != null) return parsed;
    }

    return fallback;
  }

  static String _normalizeKey(String key) {
    return key
        .trim()
        .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1_$2')
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .toLowerCase();
  }
}
