import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStickerDialog extends StatefulWidget {
  final Sticker sticker;
  final String userId;
  final Function(Sticker updatedSticker) onStickerUpdated;

  const EditStickerDialog({
    super.key,
    required this.sticker,
    required this.userId,
    required this.onStickerUpdated,
  });

  @override
  State<EditStickerDialog> createState() => _EditStickerDialogState();
}

class _EditStickerDialogState extends State<EditStickerDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.sticker.title;
    _messageController.text = widget.sticker.body;
  }

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

  Future<void> _updateSticker() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
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
      String imageUrl = widget.sticker.url;
      if (_selectedImage != null) {
        // Upload new image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('custom_stickers')
            .child(widget.userId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putFile(_selectedImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Update sticker in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('customStickers')
          .doc(widget.sticker.id)
          .update({
        'sticker_url': imageUrl,
        'sticker_title': _titleController.text,
        'sticker_body': _messageController.text,
        'timeStamp': Timestamp.now(),
      });

      // Create updated sticker object
      final updatedSticker = Sticker(
        id: widget.sticker.id,
        url: imageUrl,
        title: _titleController.text,
        body: _messageController.text,
        isFavorite: widget.sticker.isFavorite,
      );

      widget.onStickerUpdated(updatedSticker);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sticker: $e'),
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
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Custom Sticker',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Image Preview
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : NetworkImage(widget.sticker.url) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_selectedImage == null)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to change image',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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
                    onPressed: _isLoading ? null : _updateSticker,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Sticker'),
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