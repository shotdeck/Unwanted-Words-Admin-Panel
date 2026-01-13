class UnwantedWord {
  final int id;
  final String phrase;
  final bool isSuperBlacklist;

  UnwantedWord({
    required this.id,
    required this.phrase,
    required this.isSuperBlacklist,
  });

  factory UnwantedWord.fromJson(Map<String, dynamic> json) {
    return UnwantedWord(
      id: json['id'] as int,
      phrase: json['phrase'] as String,
      isSuperBlacklist: json['isSuperBlacklist'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': phrase,
      'isSuperBlacklist': isSuperBlacklist,
    };
  }

  UnwantedWord copyWith({
    int? id,
    String? phrase,
    bool? isSuperBlacklist,
  }) {
    return UnwantedWord(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      isSuperBlacklist: isSuperBlacklist ?? this.isSuperBlacklist,
    );
  }
}

class CreateUnwantedWordRequest {
  final String phrase;
  final bool isSuperBlacklist;

  CreateUnwantedWordRequest({
    required this.phrase,
    this.isSuperBlacklist = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'phrase': phrase,
      'isSuperBlacklist': isSuperBlacklist,
    };
  }
}

class UpdateUnwantedWordRequest {
  final String phrase;
  final bool isSuperBlacklist;

  UpdateUnwantedWordRequest({
    required this.phrase,
    this.isSuperBlacklist = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'phrase': phrase,
      'isSuperBlacklist': isSuperBlacklist,
    };
  }
}

class ImportResult {
  final bool dryRun;
  final int rowsRead;
  final int rowsSkipped;
  final int phrasesSeen;
  final int phrasesInserted;
  final int superBlacklistCount;
  final List<ImportRowError> errors;

  ImportResult({
    required this.dryRun,
    required this.rowsRead,
    required this.rowsSkipped,
    required this.phrasesSeen,
    required this.phrasesInserted,
    required this.superBlacklistCount,
    required this.errors,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      dryRun: json['dryRun'] as bool? ?? false,
      rowsRead: json['rowsRead'] as int? ?? 0,
      rowsSkipped: json['rowsSkipped'] as int? ?? 0,
      phrasesSeen: json['phrasesSeen'] as int? ?? 0,
      phrasesInserted: json['phrasesInserted'] as int? ?? 0,
      superBlacklistCount: json['superBlacklistCount'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => ImportRowError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ImportRowError {
  final int rowNumber;
  final String? phrase;
  final String message;

  ImportRowError({
    required this.rowNumber,
    this.phrase,
    required this.message,
  });

  factory ImportRowError.fromJson(Map<String, dynamic> json) {
    return ImportRowError(
      rowNumber: json['rowNumber'] as int? ?? 0,
      phrase: json['phrase'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}
