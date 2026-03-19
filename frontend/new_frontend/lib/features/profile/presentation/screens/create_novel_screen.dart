import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_novel_provider.dart';
import '../../../library/data/repositories/novel_repository.dart';

class CreateNovelScreen extends ConsumerStatefulWidget {
  final String? novelId; // For editing

  const CreateNovelScreen({super.key, this.novelId});

  @override
  ConsumerState<CreateNovelScreen> createState() => _CreateNovelScreenState();
}

class _CreateNovelScreenState extends ConsumerState<CreateNovelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  File? _coverImage;
  Uint8List? _coverImageBytes; // For web
  String _language = 'English';
  bool _isFree = true;
  bool _isLoading = false;
  List<String> _selectedGenreIds = [];
  List<Genre> _availableGenres = [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await ref.read(novelRepositoryProvider).getGenres();
      setState(() {
        _availableGenres = genres;
      });
    } catch (e) {
      print('Error loading genres: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, read as bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _coverImageBytes = bytes;
        });
      } else {
        // For mobile, use File
        setState(() {
          _coverImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveNovel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final novelId = await ref.read(userNovelsProvider.notifier).createNovel(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            coverImage: _coverImage,
            coverImageBytes: _coverImageBytes,
            genreIds: _selectedGenreIds,
            language: _language,
            isFree: _isFree,
            tags: tags.isNotEmpty ? tags : null,
          );

      if (mounted) {
        if (novelId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Novel created successfully!')),
          );
          // Navigate back to my novels list
          context.go('/library/my-novels');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create novel')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Novel'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Image
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _coverImage != null || _coverImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(_coverImageBytes!, fit: BoxFit.cover)
                              : Image.file(_coverImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text('Add Cover', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Novel Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Genres
            const Text('Genres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGenres.map((genre) {
                final isSelected = _selectedGenreIds.contains(genre.id);
                return FilterChip(
                  label: Text(genre.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenreIds.add(genre.id);
                      } else {
                        _selectedGenreIds.remove(genre.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Language
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Korean']
                  .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) => setState(() => _language = value!),
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'e.g., adventure, magic, romance',
              ),
            ),
            const SizedBox(height: 16),

            // Free/Paid
            SwitchListTile(
              title: const Text('Free to Read'),
              subtitle: const Text('Make this novel free for all readers'),
              value: _isFree,
              onChanged: (value) => setState(() => _isFree = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveNovel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Novel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
