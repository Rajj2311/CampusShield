import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chowkidar/screens/student/student_login_screen.dart';

void main() {
  testWidgets('Student Login Screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StudentLoginScreen(),
      ),
    );

    expect(find.text('Student Login'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}