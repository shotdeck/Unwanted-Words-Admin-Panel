import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/unwanted_word.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final ApiService apiService;

  const AdminPanelScreen({super.key, required this.apiService});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<UnwantedWord> _words = [];
  List<UnwantedWord> _filteredWords = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWords();
    _searchController.addListener(_filterWords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWords = _words;
      } else {
        _filteredWords = _words
            .where((word) => word.phrase.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final words = await widget.apiService.getAll();
      setState(() {
        _words = words;
        _filteredWords = words;
        _isLoading = false;
      });
      _filterWords();
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load words: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<UnwantedWord>(
      context: context,
      builder: (context) => _WordDialog(
        title: 'Add Unwanted Word',
        apiService: widget.apiService,
      ),
    );

    if (result != null) {
      _loadWords();
    }
  }

  Future<void> _showEditDialog(UnwantedWord word) async {
    final result = await showDialog<UnwantedWord>(
      context: context,
      builder: (context) => _WordDialog(
        title: 'Edit Unwanted Word',
        apiService: widget.apiService,
        existingWord: word,
      ),
    );

    if (result != null) {
      _loadWords();
    }
  }

  Future<void> _deleteWord(UnwantedWord word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unwanted Word'),
        content: Text('Are you sure you want to delete "${word.phrase}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.delete(word.id);
        _loadWords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${word.phrase}"')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<ImportResult>(
      context: context,
      builder: (context) => _ImportDialog(apiService: widget.apiService),
    );

    if (result != null && !result.dryRun) {
      _loadWords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'assets/shotdeck_website_logo_r.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            const Text(
              'Unwanted Words Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: _showImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadWords,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_filteredWords.length} of ${_words.length} words',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading words',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWords,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No unwanted words yet'
                  : 'No words match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isEmpty)
              const Text('Click the + button to add one'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) {
        final word = _filteredWords[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              word.phrase,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: word.isSuperBlacklist
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Super Blacklist',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => _showEditDialog(word),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: () => _deleteWord(word),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WordDialog extends StatefulWidget {
  final String title;
  final ApiService apiService;
  final UnwantedWord? existingWord;

  const _WordDialog({
    required this.title,
    required this.apiService,
    this.existingWord,
  });

  @override
  State<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends State<_WordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phraseController = TextEditingController();
  bool _isSuperBlacklist = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingWord != null) {
      _phraseController.text = widget.existingWord!.phrase;
      _isSuperBlacklist = widget.existingWord!.isSuperBlacklist;
    }
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UnwantedWord result;
      if (widget.existingWord != null) {
        result = await widget.apiService.update(
          widget.existingWord!.id,
          UpdateUnwantedWordRequest(
            phrase: _phraseController.text.trim(),
            isSuperBlacklist: _isSuperBlacklist,
          ),
        );
      } else {
        result = await widget.apiService.create(
          CreateUnwantedWordRequest(
            phrase: _phraseController.text.trim(),
            isSuperBlacklist: _isSuperBlacklist,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _phraseController,
                decoration: const InputDecoration(
                  labelText: 'Phrase',
                  hintText: 'Enter the unwanted word or phrase',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phrase';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Super Blacklist'),
                subtitle: const Text(
                  'If enabled, this word will be matched as a substring',
                ),
                value: _isSuperBlacklist,
                onChanged: (value) {
                  setState(() {
                    _isSuperBlacklist = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingWord != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

class _ImportDialog extends StatefulWidget {
  final ApiService apiService;

  const _ImportDialog({required this.apiService});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  PlatformFile? _selectedFile;
  bool _dryRun = true;
  bool _isLoading = false;
  ImportResult? _result;
  String? _errorMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _import() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await widget.apiService.importCsv(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        dryRun: _dryRun,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import CSV'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload a CSV file with columns: WORD (required), SUPER BLACKLIST (optional)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select File'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedFile?.name ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Dry Run'),
              subtitle: const Text(
                'Preview changes without actually importing',
              ),
              value: _dryRun,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _dryRun = value ?? true;
                      });
                    },
              contentPadding: EdgeInsets.zero,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.dryRun ? Colors.blue[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _result!.dryRun ? Colors.blue[200]! : Colors.green[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!.dryRun ? Icons.preview : Icons.check_circle,
                          color: _result!.dryRun
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _result!.dryRun
                              ? 'Dry Run Results'
                              : 'Import Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _result!.dryRun
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rows read: ${_result!.rowsRead}'),
                    Text('Rows skipped: ${_result!.rowsSkipped}'),
                    Text('Phrases seen: ${_result!.phrasesSeen}'),
                    Text('Phrases inserted: ${_result!.phrasesInserted}'),
                    Text('Super blacklist count: ${_result!.superBlacklistCount}'),
                    if (_result!.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Errors: ${_result!.errors.length}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ...(_result!.errors.take(5).map((e) => Text(
                            '  Row ${e.rowNumber}: ${e.message}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ))),
                      if (_result!.errors.length > 5)
                        Text(
                          '  ... and ${_result!.errors.length - 5} more',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(_result),
          child: Text(_result != null && !_result!.dryRun ? 'Done' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedFile == null ? null : _import,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_dryRun ? 'Preview' : 'Import'),
        ),
      ],
    );
  }
}
