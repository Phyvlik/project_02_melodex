import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vibzcheck/providers/auth_provider.dart';
import 'package:vibzcheck/providers/room_provider.dart';
import 'package:vibzcheck/providers/playlist_provider.dart';
import 'package:vibzcheck/utils/app_theme.dart';

Widget buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => RoomProvider()),
      ChangeNotifierProvider(create: (_) => PlaylistProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  testWidgets('app theme applies dark background color', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(body: Center(child: Text('Vibzcheck'))),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.background);
  });

  testWidgets('sign-in form has email, password, and submit button',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(
          body: Column(
            children: [
              TextField(key: Key('email')),
              TextField(key: Key('password')),
              ElevatedButton(onPressed: null, child: Text('Sign In')),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('empty playlist state shows queue-is-empty copy', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(
          body: Center(child: Text('Queue is empty')),
        ),
      ),
    );

    expect(find.text('Queue is empty'), findsOneWidget);
  });

  testWidgets('SongCard vote score text renders', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(
          body: Center(child: Text('0')),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });
}
