import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../utils/math_formatter.dart';

/// Data model for problem content that includes both text and visual assets
class ProblemContent {
  final String text;
  final String? svgCode;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const ProblemContent({
    required this.text,
    this.svgCode,
    this.imageUrl,
    this.metadata,
  });

  /// Create from API response format
  factory ProblemContent.fromApiResponse(Map<String, dynamic> data) {
    final text = data['text'] as String? ?? data['prompt'] as String? ?? '';
    final assets = data['assets'] as Map<String, dynamic>?;
    
    return ProblemContent(
      text: text,
      svgCode: assets?['svg_code'] as String?,
      imageUrl: assets?['image_url'] as String?,
      metadata: data,
    );
  }

  /// Create from simple text (backward compatibility)
  factory ProblemContent.fromText(String text) {
    return ProblemContent(text: text);
  }

  /// Create from content parameters
  factory ProblemContent.fromContent({
    required String text,
    String? svgCode,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ProblemContent(
      text: text,
      svgCode: svgCode,
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }

  bool get hasVisualAssets => svgCode != null || imageUrl != null;
  bool get hasSvg => svgCode != null && svgCode!.trim().isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}

/// Enhanced widget that displays problem content with support for text, SVG, and images
class ProblemDisplayWidget extends StatelessWidget {
  final ProblemContent content;
  final TextStyle? textStyle;
  final bool isCompact;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const ProblemDisplayWidget({
    super.key,
    required this.content,
    this.textStyle,
    this.isCompact = false,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Convenience constructor for simple text display
  const ProblemDisplayWidget.text(
    String text, {
    super.key,
    this.textStyle,
    this.isCompact = false,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  }) : content = const ProblemContent(text: '');

  /// Factory constructor that creates the appropriate widget based on content
  factory ProblemDisplayWidget.fromContent({
    Key? key,
    required String text,
    String? svgCode,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    TextStyle? textStyle,
    bool isCompact = false,
    EdgeInsets? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    final problemContent = ProblemContent(
      text: text,
      svgCode: svgCode,
      imageUrl: imageUrl,
      metadata: metadata,
    );

    return ProblemDisplayWidget(
      key: key,
      content: problemContent,
      textStyle: textStyle,
      isCompact: isCompact,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (content.hasSvg) {
      print('ProblemDisplayWidget: Rendering content with SVG, isCompact: $isCompact');
      print('ProblemDisplayWidget: SVG length: ${content.svgCode?.length ?? 0} characters');
    }
    
    final theme = Theme.of(context);
    final defaultPadding = isCompact 
        ? const EdgeInsets.all(8.0)
        : const EdgeInsets.all(12.0);
    
    final containerPadding = padding ?? defaultPadding;
    
    // Force a rebuild by using a key based on content
    final contentKey = ValueKey('${content.text.hashCode}_${content.svgCode?.hashCode}_${content.imageUrl?.hashCode}');
    
    return Container(
      key: contentKey,
      padding: containerPadding,
      decoration: backgroundColor != null ? BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ) : null,
      child: Column(
        key: ValueKey('column_${contentKey.value}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text content
          if (content.text.isNotEmpty)
            _buildTextContent(context, theme),
          
          // SVG content
          if (content.hasSvg) ...[
            if (content.text.isNotEmpty) const SizedBox(height: 12),
            _buildSvgContent(context),
          ],
          
          // Image content (fallback if SVG not available)
          if (content.hasImage && !content.hasSvg) ...[
            if (content.text.isNotEmpty) const SizedBox(height: 12),
            _buildImageContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, ThemeData theme) {
    final effectiveTextStyle = textStyle ?? theme.textTheme.bodyMedium;
    final textKey = ValueKey('text_${content.text.hashCode}');
    
    return SelectableText(
      MathFormatter.formatMath(content.text),
      key: textKey,
      style: effectiveTextStyle?.copyWith(height: 1.4),
    );
  }

  Widget _buildSvgContent(BuildContext context) {
    if (!content.hasSvg) return const SizedBox.shrink();

    final svgKey = ValueKey('svg_${content.svgCode.hashCode}');
    
    return LayoutBuilder(
      key: ValueKey('layout_${svgKey.value}'),
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
        final svgWidth = _extractSvgWidth(content.svgCode!) ?? availableWidth;
        final svgHeight = _extractSvgHeight(content.svgCode!) ?? 200.0;
        
        // Calculate appropriate scaling
        final scale = (availableWidth / svgWidth).clamp(0.1, 2.0);
        final displayWidth = (svgWidth * scale).clamp(200.0, availableWidth);
        final displayHeight = svgHeight * scale;

        return Container(
          key: svgKey,
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: isCompact ? 150 : 300,
            minHeight: 100,
          ),
          clipBehavior: Clip.hardEdge, // Prevent overflow beyond container bounds
          child: Center(
            child: Container(
              width: displayWidth,
              height: displayHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: OverflowBox(
                  maxWidth: displayWidth,
                  maxHeight: displayHeight,
                  child: SvgPicture.string(
                    content.svgCode!,
                    width: displayWidth,
                    height: displayHeight,
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => _buildSvgPlaceholder(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (!content.hasImage) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: isCompact ? 150 : 300,
        minHeight: 100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          content.imageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImagePlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildSvgPlaceholder() {
    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Loading diagram...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image could not be loaded', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// Extract width from SVG viewBox or width attribute
  double? _extractSvgWidth(String svgCode) {
    try {
      // Try to extract from width attribute
      final widthMatch = RegExp(r'width="(\d+)"').firstMatch(svgCode);
      if (widthMatch != null) {
        final widthStr = widthMatch.group(1)!;
        final width = double.tryParse(widthStr.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (width != null) return width;
      }

      // Try to extract from viewBox
      final viewBoxMatch = RegExp(r'viewBox="([^"]+)"').firstMatch(svgCode);
      if (viewBoxMatch != null) {
        final viewBox = viewBoxMatch.group(1)!.split(' ');
        if (viewBox.length >= 3) {
          return double.tryParse(viewBox[2]);
        }
      }
    } catch (e) {
      print('Error parsing SVG width: $e');
    }
    return null;
  }

  /// Extract height from SVG viewBox or height attribute
  double? _extractSvgHeight(String svgCode) {
    try {
      // Try to extract from height attribute
      final heightMatch = RegExp(r'height="(\d+)"').firstMatch(svgCode);
      if (heightMatch != null) {
        final heightStr = heightMatch.group(1)!;
        final height = double.tryParse(heightStr.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (height != null) return height;
      }

      // Try to extract from viewBox
      final viewBoxMatch = RegExp(r'viewBox="([^"]+)"').firstMatch(svgCode);
      if (viewBoxMatch != null) {
        final viewBox = viewBoxMatch.group(1)!.split(' ');
        if (viewBox.length >= 4) {
          return double.tryParse(viewBox[3]);
        }
      }
    } catch (e) {
      print('Error parsing SVG height: $e');
    }
    return null;
  }
}

/// A more compact version for use in chat bubbles
class CompactProblemDisplay extends StatelessWidget {
  final ProblemContent content;
  final TextStyle? textStyle;

  const CompactProblemDisplay({
    super.key,
    required this.content,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ProblemDisplayWidget(
      content: content,
      textStyle: textStyle,
      isCompact: true,
      padding: const EdgeInsets.all(8.0),
    );
  }
}