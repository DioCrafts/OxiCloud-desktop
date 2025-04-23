import 'package:flutter/material.dart';

/// An optimized input field that minimizes repaints
/// and efficiently manages focus and resources
class OptimizedInputField extends StatefulWidget {
  /// Text editing controller
  final TextEditingController controller;
  
  /// Label text for the field
  final String labelText;
  
  /// Hint text for the field
  final String? hintText;
  
  /// Prefix icon
  final Widget? prefixIcon;
  
  /// Suffix icon
  final Widget? suffixIcon;
  
  /// Whether to obscure the text (for passwords)
  final bool obscureText;
  
  /// Validator function
  final String? Function(String?)? validator;
  
  /// Callback when the field is submitted
  final void Function(String)? onFieldSubmitted;
  
  /// Text input action
  final TextInputAction? textInputAction;
  
  /// Create an OptimizedInputField
  const OptimizedInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  State<OptimizedInputField> createState() => _OptimizedInputFieldState();
}

class _OptimizedInputFieldState extends State<OptimizedInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Cache theme data to avoid property accesses in build
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Optimize border rendering
    final defaultBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: _isFocused ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
        width: _isFocused ? 2.0 : 1.0,
      ),
      borderRadius: BorderRadius.circular(8),
    );
    
    final errorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(8),
    );
    
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      textInputAction: widget.textInputAction,
      style: textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: defaultBorder,
        enabledBorder: defaultBorder,
        focusedBorder: defaultBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        // Optimize for fewer repaints by using consistent paddings
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // Align label with input text to prevent jumps during focus
        alignLabelWithHint: true,
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}