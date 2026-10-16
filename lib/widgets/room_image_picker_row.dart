import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models.dart';
import '../theme.dart';

class RoomImagePickerRow extends StatefulWidget {
  const RoomImagePickerRow({
    super.key,
    required this.existingImages,
    required this.removedImageIds,
    required this.selectedImages,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
    required this.onAddImages,
  });

  final List<RoomImage> existingImages;
  final Set<int> removedImageIds;
  final List<XFile> selectedImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveSelected;
  final VoidCallback onAddImages;

  @override
  State<RoomImagePickerRow> createState() => _RoomImagePickerRowState();
}

class _RoomImagePickerRowState extends State<RoomImagePickerRow> {
  static const double _tileSize = 92;
  final Map<XFile, Future<Uint8List>> _imageBytes = {};

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final existing = widget.existingImages.where(
      (image) => !widget.removedImageIds.contains(image.id),
    );

    return SizedBox(
      height: _tileSize,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _cameraTile(palette),
            for (final image in existing) ...[
              const SizedBox(width: 10),
              _photoTile(
                palette: palette,
                image: Image.network(
                  AppConfig.fileUrl(image.imageUrl),
                  fit: BoxFit.cover,
                  width: _tileSize,
                  height: _tileSize,
                ),
                onRemove: () => widget.onRemoveExisting(image.id),
              ),
            ],
            for (
              var index = 0;
              index < widget.selectedImages.length;
              index++
            ) ...[
              const SizedBox(width: 10),
              _localPhotoTile(palette, widget.selectedImages[index], index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cameraTile(Palette palette) {
    return Tooltip(
      message: 'ເພີ່ມຮູບພາບຫ້ອງ',
      child: Material(
        color: palette.inputBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onAddImages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: _tileSize,
            height: _tileSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.inputBorder),
            ),
            alignment: Alignment.center,
            child: Icon(TablerIcons.camera, size: 34, color: palette.accent),
          ),
        ),
      ),
    );
  }

  Widget _localPhotoTile(Palette palette, XFile file, int index) {
    final bytes = _imageBytes.putIfAbsent(file, file.readAsBytes);
    return FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) {
        final child = snapshot.hasData
            ? Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: _tileSize,
                height: _tileSize,
              )
            : ColoredBox(color: palette.tile);
        return _photoTile(
          palette: palette,
          image: child,
          key: ValueKey(file),
          onRemove: () => widget.onRemoveSelected(index),
        );
      },
    );
  }

  Widget _photoTile({
    required Palette palette,
    required Widget image,
    required VoidCallback onRemove,
    Key? key,
  }) {
    return SizedBox(
      key: key,
      width: _tileSize,
      height: _tileSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox.expand(child: image),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.tileBorder, width: 1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'ລຶບຮູບ',
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? const Color(0xFF17131F)
                              : const Color(0xFF29252F),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
