import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';

class CustomStickerDialog extends StatefulWidget {
  final Function(File image, String title, String message) onStickerCreated;
  final String userId;

  const CustomStickerDialog({
    super.key,
    required this.onStickerCreated,
    required this.userId,
  });

  @override
  State<CustomStickerDialog> createState() => _CustomStickerDialogState();
}

class _CustomStickerDialogState extends State<CustomStickerDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createSticker() async {
    if (_selectedImage == null ||
        _titleController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseStickers.uploadCustomSticker(
        userId: widget.userId,
        image: _selectedImage!,
        title: _titleController.text,
        message: _messageController.text,
      );

      widget.onStickerCreated(
        _selectedImage!,
        _titleController.text,
        _messageController.text,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create sticker: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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
    final theme = Theme.of(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create Custom Sticker',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Image Preview
              Container(
                height: isKeyboardVisible ? 80 : 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_rounded,
                            size: isKeyboardVisible ? 24 : 40,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No image selected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              // Image Selection Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Select Image'),
                ),
              ),
              const SizedBox(height: 20),
              // Title Input
              TextField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Sticker Title',
                  hintText: 'Enter a title for your sticker',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Message Input
              TextField(
                controller: _messageController,
                enabled: !_isLoading,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Sticker Message',
                  hintText: 'Enter a message for your sticker',
                  prefixIcon: const Icon(Icons.message_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _createSticker,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Sticker'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
