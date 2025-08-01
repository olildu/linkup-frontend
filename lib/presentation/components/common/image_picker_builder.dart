import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/utils/blurhash_util.dart';
import 'package:octo_image/octo_image.dart';

class ImagePickerBuilder extends StatefulWidget {
  final int maxImages;
  final Function(List<XFile>) onImagesChanged;
  final bool allowMultipleSelection;
  final List<Map> initialImages;

  const ImagePickerBuilder({
    super.key,
    this.maxImages = 6,
    required this.onImagesChanged,
    this.allowMultipleSelection = true,
    this.initialImages = const [],
  });

  @override
  State<ImagePickerBuilder> createState() => _ImagePickerBuilderState();
}

class _ImagePickerBuilderState extends State<ImagePickerBuilder> {
  final ImagePicker _picker = ImagePicker();
  final List<dynamic> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    int initialImagesToAdd = widget.initialImages.length > widget.maxImages ? widget.maxImages : widget.initialImages.length;
    if (initialImagesToAdd > 0) {
      _displayedItems.addAll(widget.initialImages.sublist(0, initialImagesToAdd));
    }
  }

  Future<void> _pickImages() async {
    if (_displayedItems.length >= widget.maxImages) return;
    try {
      final List<XFile> pickedImages =
          widget.allowMultipleSelection
              ? await _picker.pickMultiImage()
              : [(await _picker.pickImage(source: ImageSource.gallery))].whereType<XFile>().toList();

      if (pickedImages.isNotEmpty) {
        setState(() {
          int remainingSlots = widget.maxImages - _displayedItems.length;
          if (remainingSlots > 0) {
            final newImagesToAdd =
                pickedImages.where((newlyPickedFile) {
                  return !_displayedItems.whereType<XFile>().any((existingXFile) => existingXFile.path == newlyPickedFile.path);
                }).toList();

            int imagesToAddCount = newImagesToAdd.length > remainingSlots ? remainingSlots : newImagesToAdd.length;
            if (imagesToAddCount > 0) {
              _displayedItems.addAll(newImagesToAdd.sublist(0, imagesToAddCount));
              widget.onImagesChanged(_displayedItems.whereType<XFile>().toList());
            }
          }
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to pick images';
      if (e is Exception) errorMessage = 'Failed to pick images: ${e.toString()}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _displayedItems.length) {
        _displayedItems.removeAt(index);
        widget.onImagesChanged(_displayedItems.whereType<XFile>().toList());
      }
    });
  }

  Widget _buildImageContainer(double contentSize, int index) {
    bool hasImage = index < _displayedItems.length;
    bool isAddButton = !hasImage && _displayedItems.length < widget.maxImages;
    Widget imageDisplayWidget;
    if (hasImage) {
      final item = _displayedItems[index];
      if (item is Map) {
        imageDisplayWidget = OctoImage(
          image: CachedNetworkImageProvider(item["url"]),
          placeholderBuilder: blurHash(item["blurhash"]).placeholderBuilder,
          errorBuilder: OctoError.icon(color: Colors.red),
          fit: BoxFit.cover,
          width: 30.r,
          height: 30.r,
        );
      } else if (item is XFile) {
        imageDisplayWidget = Image.file(File(item.path), fit: BoxFit.cover);
      } else {
        imageDisplayWidget = const SizedBox.shrink();
      }
    } else {
      imageDisplayWidget = Center(
        child: Container(
          padding: EdgeInsets.all((contentSize * 0.08).sp),
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Icon(Icons.add_rounded, color: Colors.white, size: (contentSize * 0.2).sp),
        ),
      );
    }

    return GestureDetector(
      onTap: isAddButton ? _pickImages : null,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(15.r),
        padding: EdgeInsets.all(1.sp),
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade400,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        child: Container(
          width: contentSize,
          height: contentSize,
          decoration: BoxDecoration(
            color: hasImage ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child:
              hasImage
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(15.r), child: imageDisplayWidget),

                      if (_displayedItems.length > 2)
                        Positioned(
                          top: 5.r,
                          right: 5.r,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(4.sp),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                            ),
                          ),
                        ),
                    ],
                  )
                  : imageDisplayWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double itemGap = 5.sp;
    final double dottedBorderInternalPaddingPerSide = 1.sp;
    const double dottedBorderStrokeWidth = 1.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double shellWidthPerItem = (2 * dottedBorderInternalPaddingPerSide) + dottedBorderStrokeWidth;
        double totalShellWidthForAllItemsInRow = 3 * shellWidthPerItem;
        double totalGapSpaceInRow = 2 * itemGap;
        double effectiveContentWidthForRow = availableWidth - totalShellWidthForAllItemsInRow - totalGapSpaceInRow;
        if (effectiveContentWidthForRow < 0) effectiveContentWidthForRow = 0;

        double smallItemContentWidth = (effectiveContentWidthForRow / 3);
        double largeItemContentWidth = ((2 * smallItemContentWidth) + itemGap);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: itemGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildImageContainer(largeItemContentWidth, 0),
                  Gap(itemGap),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildImageContainer(smallItemContentWidth, 1), Gap(itemGap), _buildImageContainer(smallItemContentWidth, 2)],
                  ),
                ],
              ),
              Gap(itemGap),
              Row(
                children: [
                  _buildImageContainer(smallItemContentWidth, 3),
                  Gap(itemGap),
                  _buildImageContainer(smallItemContentWidth, 4),
                  if (widget.maxImages > 5) ...[Gap(itemGap), _buildImageContainer(smallItemContentWidth, 5)],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
