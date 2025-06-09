import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageBuilder extends StatelessWidget {
  final String imagePath;
  final bool? darkMode;
  final double? height;
  final double? width;
  final void Function()? onTap;

  const ImageBuilder({
    super.key,
    this.imagePath = "assets/images/care.png",
    this.darkMode,
    this.height,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    Widget imageWidget = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0.r),
        child: isNetwork
            ? CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                width: width ?? double.infinity,
                height: height ?? double.infinity,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : Image.asset(
                imagePath,
                height: height ?? double.infinity,
                fit: BoxFit.cover,
                width: width ?? double.infinity,
              ),
      ),
    );

    if (darkMode == true) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20.0.r),
          ),  
          child: imageWidget
        ),
      );
    }

    return imageWidget;
  }
}
