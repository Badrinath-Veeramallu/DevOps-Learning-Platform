import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('parses correctly when user id is "id" (Login / Verify response)', () {
      final json = {
        'id': 'usr_login_123',
        'name': 'Alex Mercer',
        'email': 'alex@example.com',
        'role': 'user',
        'avatar': 'https://example.com/avatar.png',
        'isEmailVerified': true,
        'authProvider': 'local',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr_login_123');
      expect(user.name, 'Alex Mercer');
      expect(user.email, 'alex@example.com');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.role, 'user');
      expect(user.isEmailVerified, isTrue);
      expect(user.authProvider, 'local');
    });

    test(
      'parses correctly when user id is "_id" (Mongoose /auth/me document)',
      () {
        final json = {
          '_id': 'usr_mongo_456',
          'name': 'Sarah Connor',
          'email': 'sarah@example.com',
          'isEmailVerified': true,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'usr_mongo_456');
        expect(user.name, 'Sarah Connor');
        expect(user.email, 'sarah@example.com');
        expect(user.avatar, isNull);
        expect(user.role, 'user');
        expect(user.isEmailVerified, isTrue);
      },
    );

    test('handles missing or optional fields gracefully with defaults', () {
      final json = <String, dynamic>{};

      final user = UserModel.fromJson(json);

      expect(user.id, '');
      expect(user.name, '');
      expect(user.email, '');
      expect(user.avatar, isNull);
      expect(user.role, 'user');
      expect(user.isEmailVerified, isFalse);
      expect(user.authProvider, 'local');
    });

    test('toJson serializes correctly', () {
      const user = UserModel(
        id: 'usr_789',
        name: 'DevOps Engineer',
        email: 'dev@example.com',
        avatar: 'https://example.com/pic.jpg',
        role: 'admin',
        isEmailVerified: true,
      );

      final json = user.toJson();

      expect(json['id'], 'usr_789');
      expect(json['name'], 'DevOps Engineer');
      expect(json['email'], 'dev@example.com');
      expect(json['avatar'], 'https://example.com/pic.jpg');
      expect(json['role'], 'admin');
      expect(json['isEmailVerified'], isTrue);
    });

    test('copyWith creates modified clone', () {
      const user = UserModel(
        id: 'usr_1',
        name: 'Initial Name',
        email: 'initial@example.com',
      );

      final updated = user.copyWith(name: 'Updated Name');

      expect(updated.id, 'usr_1');
      expect(updated.name, 'Updated Name');
      expect(updated.email, 'initial@example.com');
    });
  });
}
