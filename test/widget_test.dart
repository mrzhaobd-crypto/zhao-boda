import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('앱이 뜨고 가짜 대화가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatLabApp());

    // 제목
    expect(find.text('AI Chat — 실습 1'), findsOneWidget);

    // 할 일 1이 끝났다면 목록이 그려진다
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('오늘 뭐 배워?'), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
  testWidgets('공백은 보내지 않고 키보드 전송을 지원한다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      4,
    );
    await tester.enterText(find.byType(TextField), '  keyboard message  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(find.text('keyboard message'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('키보드가 올라와도 입력창이 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final keyboardTop =
        (tester.view.physicalSize.height - 300) / tester.view.devicePixelRatio;
    expect(
      tester.getBottomRight(find.byType(TextField)).dy,
      lessThanOrEqualTo(keyboardTop),
    );
    expect(tester.takeException(), isNull);
  });
}
