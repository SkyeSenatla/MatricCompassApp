import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/layout/window_size.dart';

void main() {
  test("Material 3's breakpoints: 600 and 840", () {
    expect(WindowSize.forWidth(360), WindowSize.compact);
    expect(WindowSize.forWidth(599), WindowSize.compact);
    expect(WindowSize.forWidth(600), WindowSize.medium);
    expect(WindowSize.forWidth(839), WindowSize.medium);
    expect(WindowSize.forWidth(840), WindowSize.expanded);
    expect(WindowSize.forWidth(1280), WindowSize.expanded);
  });
}
