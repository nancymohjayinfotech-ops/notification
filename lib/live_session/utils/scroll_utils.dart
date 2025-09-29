// This file contains utility functions for managing the ScrollController
// and scrolling to the bottom of a ListView when new messages are added.

import 'package:flutter/material.dart';

class ScrollUtils {
  // Scroll to the bottom of a ListView when new messages are added
  static void scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent, // For reverse: false, maxScrollExtent is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Check if scroll position is at or near bottom
  static bool isAtBottom(ScrollController controller) {
    if (!controller.hasClients) return false;

    // For reverse: false ListView, check if near bottom
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    return maxScroll - currentScroll <= 50; // Within 50 pixels of bottom
  }
}
