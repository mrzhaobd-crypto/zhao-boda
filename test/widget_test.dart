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
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
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
  for (final entry in {
    '401 권한 오류': '키/권한을 확인해 주세요',
    '500 서버 오류': '응답을 받지 못했습니다',
    '시간 초과': '응답 시간이 초과되었습니다',
  }.entries) {
    testWidgets('${entry.key}: 오류 뒤 입력과 재시도', (tester) async {
      await tester.pumpWidget(const ChatLabApp());
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'retry question');
      await tester.tap(find.byTooltip('전송'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'next draft');
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('성공').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 시도'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('retry question'), findsOneWidget);
      expect(find.text('모의 응답: retry question'), findsOneWidget);
      expect(find.text(entry.value), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'next draft',
      );
    });
  }

  testWidgets('429 재시도는 1초 다음 2초 대기', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('429 요청 제한').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'limited');
    await tester.tap(find.byTooltip('전송'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    for (final seconds in [1, 2]) {
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.text('$seconds초 후 다시 시도합니다…'), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      await tester.pump(Duration(seconds: seconds));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('잠시 후 다시 시도해 주세요'), findsOneWidget);
      expect(find.text('limited'), findsOneWidget);
    }
  });
}
