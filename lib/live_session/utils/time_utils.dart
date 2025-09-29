// Time utilities for handling AM/PM display issues

class TimeUtils {
  // Function to fix the AM/PM inversion issue that's occurring in the app
  static String formatTimeWithCorrectAmPm(int hour, int minute) {
    // Get the correct AM/PM
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    
    // Convert to 12-hour format
    final int hour12 = (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
    
    // Format with padding for minutes
    final String formattedMinute = minute.toString().padLeft(2, '0');
    
    // Print debug info to ensure AM/PM is correct
    print('Time formatting: $hour:$minute (24h) -> $hour12:$formattedMinute $amPm (12h)');
    
    return '$hour12:$formattedMinute $amPm';
  }
  
  // Function that handles AM/PM inversion
  // This explicitly fixes the issue where times are showing with incorrect AM/PM
  static String formatTimeRangeWithCorrection(DateTime startTime, DateTime endTime) {
    // Get the intended AM/PM based on the hour
    // For example, 11:45 should be AM if hour is 11, or PM if hour is 23
    final startAmPm = startTime.hour >= 12 ? 'PM' : 'AM';
    final endAmPm = endTime.hour >= 12 ? 'PM' : 'AM';
    
    // Format 12-hour time
    final startHour12 = (startTime.hour == 0) ? 12 : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
    final endHour12 = (endTime.hour == 0) ? 12 : (endTime.hour > 12 ? endTime.hour - 12 : endTime.hour);
    
    final formattedStartMinute = startTime.minute.toString().padLeft(2, '0');
    final formattedEndMinute = endTime.minute.toString().padLeft(2, '0');
    
    return '$startHour12:$formattedStartMinute $startAmPm - '
           '$endHour12:$formattedEndMinute $endAmPm IST';
  }
  
  // Helper method to determine if a meeting time likely has AM/PM inversion
  static bool detectTimeInversion(DateTime startTime, DateTime endTime) {
    // Common AM/PM inversion patterns
    
    // Case 1: Morning hours (6-11 AM) showing in meeting data as PM
    if (startTime.hour >= 6 && startTime.hour < 12) {
      print('Possible AM/PM inversion: Morning hour ${startTime.hour} might be intended as AM');
      return true;
    }
    
    // Case 2: Afternoon hours (12-5 PM) showing as AM
    if (startTime.hour >= 12 && startTime.hour < 18) {
      print('Possible AM/PM inversion: Afternoon hour ${startTime.hour} might be intended as PM');
      return true;
    }
    
    // Case 3: Meeting spans AM to PM but shows as PM to AM
    if (startTime.hour < 12 && endTime.hour >= 12) {
      // This is a normal pattern (morning to afternoon), no inversion
      return false;
    }
    
    // Case 4: Meeting spans PM to AM but shows as AM to PM
    if (startTime.hour >= 12 && endTime.hour < 12 && 
        // Only consider same-day meetings
        startTime.day == endTime.day) {
      print('Suspicious time pattern: Meeting spans PM to AM within same day');
      return true;
    }
    
    return false;
  }
  
  // Apply the AM/PM correction if needed
  static String getTimeRangeWithFixedAmPm(DateTime startTime, DateTime endTime) {
  // Always use correct AM/PM calculation, never flip
  final startAmPm = startTime.hour >= 12 ? 'PM' : 'AM';
  final endAmPm = endTime.hour >= 12 ? 'PM' : 'AM';
  final startHour12 = (startTime.hour == 0) ? 12 : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
  final endHour12 = (endTime.hour == 0) ? 12 : (endTime.hour > 12 ? endTime.hour - 12 : endTime.hour);
  final formattedStartMinute = startTime.minute.toString().padLeft(2, '0');
  final formattedEndMinute = endTime.minute.toString().padLeft(2, '0');
  return '$startHour12:$formattedStartMinute $startAmPm - '
       '$endHour12:$formattedEndMinute $endAmPm IST';
  }
}
