import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/unwanted_word.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String get _unwantedWordsEndpoint => '$baseUrl/api/admin/unwanted-words';

  Future<List<UnwantedWord>> getAll() async {
    final response = await http.get(
      Uri.parse(_unwantedWordsEndpoint),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => UnwantedWord.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<UnwantedWord> getById(int id) async {
    final response = await http.get(
      Uri.parse('$_unwantedWordsEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return UnwantedWord.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<UnwantedWord> create(CreateUnwantedWordRequest request) async {
    final response = await http.post(
      Uri.parse(_unwantedWordsEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return UnwantedWord.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<UnwantedWord> update(int id, UpdateUnwantedWordRequest request) async {
    final response = await http.put(
      Uri.parse('$_unwantedWordsEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return UnwantedWord.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('$_unwantedWordsEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<ImportResult> importCsv({
    required Uint8List fileBytes,
    required String fileName,
    bool dryRun = false,
  }) async {
    final uri = Uri.parse('$_unwantedWordsEndpoint/import-csv');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    request.fields['dryRun'] = dryRun.toString();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return ImportResult.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final jsonBody = json.decode(body);
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ?? jsonBody['Message'] ?? body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
