import 'package:flutter_test/flutter_test.dart';
import 'package:melodex/utils/constants.dart';
import 'package:melodex/models/recommendation_model.dart';

void main() {
  group('Scoring weights', () {
    test('weights sum to exactly 1.0', () {
      final total = AppConstants.weightVotes +
          AppConstants.weightMood +
          AppConstants.weightListenHistory;
      expect(total, closeTo(1.0, 0.0001));
    });

    test('vote weight is highest at 50%', () {
      expect(AppConstants.weightVotes, greaterThan(AppConstants.weightMood));
      expect(AppConstants.weightVotes,
          greaterThan(AppConstants.weightListenHistory));
    });
  });

  group('Scoring formula', () {
    double computeScore({
      required double normalizedVote,
      required double moodMatch,
      required double historyBoost,
    }) {
      final voteContrib = normalizedVote * AppConstants.weightVotes;
      final moodContrib = moodMatch * AppConstants.weightMood;
      final historyContrib = historyBoost * AppConstants.weightListenHistory;
      return (voteContrib + moodContrib + historyContrib).clamp(0.0, 1.0);
    }

    test('perfect song scores 1.0 (top votes + mood match + genre fit)', () {
      final score = computeScore(
        normalizedVote: 1.0,
        moodMatch: 1.0,
        historyBoost: 1.0,
      );
      expect(score, closeTo(1.0, 0.0001));
    });

    test('mood match alone contributes 30% to score', () {
      final score = computeScore(
        normalizedVote: 0.0,
        moodMatch: 1.0,
        historyBoost: 0.0,
      );
      expect(score, closeTo(AppConstants.weightMood, 0.0001));
    });

    test('recently played song gets penalised below neutral', () {
      // historyBoost = -0.5 for recently played
      final score = computeScore(
        normalizedVote: 0.5,
        moodMatch: 0.5,
        historyBoost: -0.5,
      );
      final neutral = computeScore(
        normalizedVote: 0.5,
        moodMatch: 0.5,
        historyBoost: 0.0,
      );
      expect(score, lessThan(neutral));
    });

    test('score is always clamped between 0 and 1', () {
      final high = computeScore(
          normalizedVote: 2.0, moodMatch: 2.0, historyBoost: 2.0);
      final low = computeScore(
          normalizedVote: -5.0, moodMatch: -5.0, historyBoost: -5.0);
      expect(high, lessThanOrEqualTo(1.0));
      expect(low, greaterThanOrEqualTo(0.0));
    });

    test('mood mismatch scores lower than mood match', () {
      final match = computeScore(
          normalizedVote: 0.5, moodMatch: 1.0, historyBoost: 0.0);
      final mismatch = computeScore(
          normalizedVote: 0.5, moodMatch: 0.0, historyBoost: 0.0);
      expect(match, greaterThan(mismatch));
    });
  });

  group('RecommendationModel', () {
    test('constructs with required fields', () {
      final rec = RecommendationModel(
        songId: 'id1',
        spotifyId: 'spotify1',
        title: 'Test Song',
        artist: 'Test Artist',
        albumArtUrl: 'https://example.com/art.jpg',
        totalScore: 0.8,
        voteScore: 0.4,
        moodScore: 0.3,
        historyScore: 0.1,
        reasoning: 'votes +2 | mood matches (chill) | genre fits taste',
      );

      expect(rec.title, equals('Test Song'));
      expect(rec.totalScore, equals(0.8));
      expect(rec.reasoning, contains('mood matches'));
    });

    test('isManualOverride defaults to false', () {
      final rec = RecommendationModel(
        songId: 'id1',
        spotifyId: 'spotify1',
        title: 'Test',
        artist: 'Artist',
        albumArtUrl: '',
        totalScore: 0.5,
        voteScore: 0.25,
        moodScore: 0.15,
        historyScore: 0.1,
        reasoning: '',
      );
      expect(rec.isManualOverride, isFalse);
    });
  });

  group('App constants', () {
    test('invite code length is 6', () {
      expect(AppConstants.inviteCodeLength, equals(6));
    });

    test('mood options contains core moods', () {
      expect(AppConstants.moodOptions, containsAll(['chill', 'hype', 'sad', 'party']));
    });

    test('max room members is reasonable', () {
      expect(AppConstants.maxRoomMembers, greaterThanOrEqualTo(2));
      expect(AppConstants.maxRoomMembers, lessThanOrEqualTo(100));
    });
  });
}
