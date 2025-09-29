import 'package:livekit_client/livekit_client.dart';

// Helper class for participant tracks
class ParticipantTrack {
  final Participant participant; // Changed to Participant (base class) to accept both Local and Remote
  final TrackPublication? publication;
  final VideoTrack? track;
  final bool isScreenShare;
  final bool isHost;

  ParticipantTrack({
    required this.participant,
    required this.publication,
    this.track,
    this.isScreenShare = false,
    this.isHost = false,
  });
}
