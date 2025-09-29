import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GroupService {
  static const String baseUrl = 'http://54.82.53.11:5001/api';

  // Get all groups for the instructor
  static Future<Map<String, dynamic>> getInstructorGroups() async {
    try {
      debugPrint('Fetching instructor groups from: $baseUrl/instructor/groups');
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/groups',
      );

      debugPrint('Groups response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Groups API response keys: ${data.keys.toList()}');

        if (data['success'] == true) {
          final groups = _extractGroups(data);
          debugPrint('Extracted ${groups.length} groups');

          return {
            'success': true,
            'groups': groups,
            'message': data['message'] ?? 'Groups retrieved successfully',
          };
        } else {
          debugPrint(
            'API returned success: false with message: ${data['message']}',
          );
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve groups',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve groups. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting instructor groups: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get students in a group
  static Future<Map<String, dynamic>> getGroupStudents(String groupId) async {
    try {
      debugPrint('Fetching students for group $groupId');
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/groups/$groupId?page=1&limit=50',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          List<dynamic> students = [];

          if (data['data'] != null && data['data']['students'] is List) {
            students = data['data']['students'];
          } else if (data['students'] is List) {
            students = data['students'];
          }

          return {
            'success': true,
            'students': List<Map<String, dynamic>>.from(students),
            'message':
                data['message'] ?? 'Group students retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve group students',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve group students. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting group students: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Note: Instructors cannot create groups, only admin can.
  // This method is kept for reference but should not be used.
  // For now, making it private to avoid accidental usage.
  static Future<Map<String, dynamic>> _createGroup(
    Map<String, dynamic> groupData,
  ) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'POST',
        url: '$baseUrl/instructor/groups',
        body: jsonEncode(groupData),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      // This will likely fail for instructors since they don't have permission
      return {
        'success': false,
        'message':
            data['message'] ??
            'Instructors cannot create groups. Groups are created by admin.',
      };
    } catch (e) {
      debugPrint('Error creating group: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Add a student to a group
  static Future<Map<String, dynamic>> addStudentToGroup(
    String groupId,
    String studentId,
  ) async {
    try {
      // Validate groupId and studentId
      if (groupId.isEmpty || studentId.isEmpty) {
        debugPrint(
          'Invalid groupId or studentId: groupId=$groupId, studentId=$studentId',
        );
        return {
          'success': false,
          'message': 'Group ID and Student ID are required',
        };
      }

      debugPrint('Adding student $studentId to group $groupId');

      // Use the new API endpoint
      String url = '$baseUrl/groups/$groupId/students/$studentId';
      debugPrint('Using URL: $url');

      // Send the request
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'POST',
        url: url,
      );

      debugPrint(
        'Add student response status: ${response.statusCode}, body: ${response.body}',
      );

      // Handle potential empty response
      if (response.body.isEmpty) {
        debugPrint('Empty response body from add student API');
        // For some APIs, an empty 200/201 response might still indicate success
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Student added to group successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                'Empty response from server. Status code: ${response.statusCode}',
          };
        }
      }

      // Check if the response contains HTML (error page) instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        debugPrint(
          'Received HTML response instead of JSON. This indicates a routing error.',
        );
        return {
          'success': false,
          'message':
              'Server returned an error page. The API endpoint may be incorrect or not available. Status code: ${response.statusCode}',
        };
      }

      // Try to parse the response body
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
        debugPrint('Response data: $data');
      } catch (e) {
        debugPrint('Error parsing response JSON: $e');
        return {
          'success': false,
          'message':
              'Invalid response format from server: ${response.body.substring(0, min(100, response.body.length))}...',
        };
      }

      // Check for success
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Some APIs return success: true, others might just return 200/201 status
        final bool isSuccess =
            data['success'] == true ||
            (data['success'] == null &&
                (response.statusCode == 200 || response.statusCode == 201));

        if (isSuccess) {
          return {
            'success': true,
            'message': data['message'] ?? 'Student added to group successfully',
            'data': data['data'],
          };
        }
      }

      // Handle specific error codes
      if (response.statusCode == 403) {
        debugPrint('Permission denied (403): ${data['message']}');
        return {
          'success': false,
          'message':
              'Permission denied: ${data['message'] ?? "You don't have permission to add students to this group"}',
        };
      }

      // If we get here, it means the API call wasn't successful
      final errorMessage =
          data['message'] ??
          'Failed to add student to group. Status code: ${response.statusCode}';
      debugPrint('Add student failed: $errorMessage');

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('Exception adding student to group: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Remove a student from a group
  static Future<Map<String, dynamic>> removeStudentFromGroup(
    String groupId,
    String studentId,
  ) async {
    try {
      debugPrint('Removing student $studentId from group $groupId');

      // Use the new API endpoint
      String url = '$baseUrl/groups/$groupId/students/$studentId';
      debugPrint('Using URL: $url');

      // Send the request
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'DELETE',
        url: url,
      );

      debugPrint(
        'Remove student response status: ${response.statusCode}, body: ${response.body}',
      );

      // Handle potential empty response
      if (response.body.isEmpty) {
        debugPrint('Empty response body from remove student API');
        // For some APIs, an empty 200 response might still indicate success
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Student removed from group successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                'Empty response from server. Status code: ${response.statusCode}',
          };
        }
      }

      // Check if the response contains HTML (error page) instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        debugPrint(
          'Received HTML response instead of JSON. This indicates a routing error.',
        );
        return {
          'success': false,
          'message':
              'Server returned an error page. The API endpoint may be incorrect or not available. Status code: ${response.statusCode}',
        };
      }

      // Try to parse the response body
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
        debugPrint('Response data: $data');
      } catch (e) {
        debugPrint('Error parsing response JSON: $e');
        return {
          'success': false,
          'message':
              'Invalid response format from server: ${response.body.substring(0, min(100, response.body.length))}...',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Check for success field or assume success based on status code
        final bool isSuccess =
            data['success'] == true ||
            (data['success'] == null &&
                (response.statusCode == 200 || response.statusCode == 204));

        if (isSuccess) {
          return {
            'success': true,
            'message':
                data['message'] ?? 'Student removed from group successfully',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to remove student from group',
          };
        }
      } else if (response.statusCode == 403) {
        // Special handling for permission errors
        debugPrint('Permission denied (403): ${data['message']}');
        return {
          'success': false,
          'message':
              'Permission denied: ${data['message'] ?? "You don't have permission to remove students from this group"}',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to remove student from group. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error removing student from group: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Helper method to extract groups from different response structures
  static List<Map<String, dynamic>> _extractGroups(Map<String, dynamic> data) {
    List<dynamic> groups = [];

    if (data['groups'] is List) {
      groups = data['groups'];
      debugPrint('Found ${groups.length} groups directly in groups key');
    } else if (data['data'] != null && data['data']['groups'] is List) {
      groups = data['data']['groups'];
      debugPrint('Found ${groups.length} groups in data.groups');
    } else {
      debugPrint('No groups found in response');
    }

    return List<Map<String, dynamic>>.from(groups);
  }

  // Get group details with messages
  static Future<Map<String, dynamic>> getGroupDetailsWithMessages(
    String groupId,
  ) async {
    try {
      debugPrint('Fetching group details with messages for group $groupId');
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/groups/$groupId?page=1&limit=50',
      );

      debugPrint('Group details response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Group details API response keys: ${data.keys.toList()}');

        if (data['success'] == true) {
          // Extract group details, students, and messages from the response
          Map<String, dynamic> groupData = {};
          List<dynamic> messages = [];
          List<dynamic> students = [];
          Map<String, dynamic> memberCounts = {};

          if (data['data'] != null) {
            if (data['data']['group'] != null) {
              groupData = data['data']['group'];

              // Extract students from the group data
              if (data['data']['group']['students'] != null &&
                  data['data']['group']['students'] is List) {
                students = data['data']['group']['students'];
                debugPrint('Found ${students.length} students in group data');
              }

              // Extract member counts
              if (data['data']['group']['memberCounts'] != null) {
                memberCounts = data['data']['group']['memberCounts'];
                debugPrint('Member counts: $memberCounts');
              }
            }

            // Extract messages
            if (data['data']['messages'] != null &&
                data['data']['messages']['items'] is List) {
              messages = data['data']['messages']['items'];
              debugPrint('Found ${messages.length} messages in response');
            }
          }

          return {
            'success': true,
            'groupDetails': groupData,
            'students': List<Map<String, dynamic>>.from(students),
            'messages': List<Map<String, dynamic>>.from(messages),
            'memberCounts': memberCounts,
            'message':
                data['message'] ?? 'Group details retrieved successfully',
          };
        } else {
          debugPrint(
            'API returned success: false with message: ${data['message']}',
          );
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve group details',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve group details. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting group details with messages: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Send a message to a group
  static Future<Map<String, dynamic>> sendGroupMessage(
    String groupId,
    String message,
  ) async {
    try {
      // Use the confirmed working API endpoint for sending messages
      final String apiEndpoint = '$baseUrl/groups/$groupId/messages';

      debugPrint('Sending message to: $apiEndpoint');

      // Send message using the confirmed endpoint
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'POST',
        url: apiEndpoint,
        body: jsonEncode({'content': message, 'messageType': 'text'}),
      );

      // Check if we got HTML instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        debugPrint('Received HTML response instead of JSON from $apiEndpoint');

        // Log more details about the HTML response
        final bodyPreview = response.body.length > 100
            ? '${response.body.substring(0, 100)}...'
            : response.body;
        debugPrint('HTML response preview: $bodyPreview');

        // Try to extract error information from HTML
        String errorInfo = 'Unknown HTML error';
        if (response.body.contains('<title>') &&
            response.body.contains('</title>')) {
          final titleStart =
              response.body.indexOf('<title>') + '<title>'.length;
          final titleEnd = response.body.indexOf('</title>', titleStart);
          if (titleStart >= 0 && titleEnd > titleStart) {
            errorInfo = response.body.substring(titleStart, titleEnd).trim();
            debugPrint('Extracted error title from HTML: $errorInfo');
          }
        }

        return {
          'success': false,
          'message': 'Server returned HTML error page: $errorInfo',
        };
      }

      // Try to parse the response
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true || data['status'] == 'success') {
          debugPrint('Successfully sent message');
          return {
            'success': true,
            'message': 'Message sent successfully',
            'data': data['data'],
          };
        }
      }

      // If we got here, the API returned JSON but not success
      return {'success': false, 'message': data['message'] ?? 'Unknown error'};
    } catch (e) {
      debugPrint('Error sending group message: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get messages for a group
  static Future<Map<String, dynamic>> getGroupMessages(String groupId) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/groups/$groupId/messages',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          List<dynamic> messages = [];

          if (data['data'] != null && data['data']['messages'] is List) {
            messages = data['data']['messages'];
          } else if (data['messages'] is List) {
            messages = data['messages'];
          }

          // Convert to properly typed list
          List<Map<String, dynamic>> typedMessages =
              List<Map<String, dynamic>>.from(messages);

          // Sort messages by createdAt timestamp (oldest first)
          typedMessages.sort((a, b) {
            final String aTimeStr = a['createdAt']?.toString() ?? '';
            final String bTimeStr = b['createdAt']?.toString() ?? '';

            // Parse dates safely
            DateTime? aTime;
            DateTime? bTime;

            try {
              aTime = DateTime.parse(aTimeStr);
            } catch (e) {
              aTime = DateTime(1970); // Default date if parsing fails
            }

            try {
              bTime = DateTime.parse(bTimeStr);
            } catch (e) {
              bTime = DateTime(1970); // Default date if parsing fails
            }

            // Sort oldest first (ascending order)
            return aTime.compareTo(bTime);
          });

          return {
            'success': true,
            'messages': typedMessages,
            'message':
                data['message'] ?? 'Group messages retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve group messages',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve group messages. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting group messages: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Find student by email
  static Future<Map<String, dynamic>> findStudentByEmail(String email) async {
    try {
      debugPrint('Searching for student with email: $email');
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/students?email=${Uri.encodeComponent(email)}',
      );

      debugPrint(
        'Find student by email response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Find student API response keys: ${data.keys.toList()}');

        // Check different possible response structures
        if (data['success'] == true) {
          List<dynamic>? students;

          // Try to find students in different locations in the response
          if (data['data'] != null && data['data']['students'] != null) {
            students = data['data']['students'] as List;
          } else if (data['students'] != null) {
            students = data['students'] as List;
          } else if (data['data'] != null && data['data'] is List) {
            // Some APIs might return a direct list in the data field
            students = data['data'] as List;
          }

          if (students != null && students.isNotEmpty) {
            debugPrint('Found ${students.length} students with email $email');
            debugPrint('Student data: ${students[0]}');

            // Check different ID field names
            final studentId =
                students[0]['_id'] ??
                students[0]['id'] ??
                students[0]['userId'];
            if (studentId != null) {
              debugPrint('Student ID: $studentId');
              return {
                'success': true,
                'studentId': studentId,
                'student': students[0],
              };
            }
          }
        }

        debugPrint(
          'No student found with email $email or could not extract ID',
        );
        return {
          'success': false,
          'message': 'No student found with this email',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to find student. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error finding student by email: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
