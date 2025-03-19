import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';

class MovigoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;
  final Color? color;
  final double? height;
  final bool isLoading;

  const MovigoButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.color,
    this.height,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? movigoPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(movigoButtonRadius),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
