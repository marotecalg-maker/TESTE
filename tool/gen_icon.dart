import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

// Generates Rosome's original app icon: a geometric "R" monogram on the
// violet->magenta brand gradient. No external assets, no copyright.

const int S = 1024;

final _c0 = [139, 92, 246]; // #8B5CF6
final _c1 = [168, 85, 247]; // #A855F7
final _c2 = [255, 77, 141]; // #FF4D8D

List<int> _lerp(List<int> a, List<int> b, double t) => [
      (a[0] + (b[0] - a[0]) * t).round(),
      (a[1] + (b[1] - a[1]) * t).round(),
      (a[2] + (b[2] - a[2]) * t).round(),
    ];

List<int> _grad(double t) =>
    t < 0.55 ? _lerp(_c0, _c1, t / 0.55) : _lerp(_c1, _c2, (t - 0.55) / 0.45);

double _distSeg(
    double px, double py, double ax, double ay, double bx, double by) {
  final dx = bx - ax, dy = by - ay;
  final l2 = dx * dx + dy * dy;
  double t = l2 == 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / l2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}

// "R" geometry in the 1024 model space.
const double _t = 86; // stroke width
const double _r = _t / 2; // stroke radius
const double _xs = 430; // stem centreline x
const double _yTop = 320;
const double _yBot = 706;
const double _cx = 476; // bowl centre x
const double _cy = 438; // bowl centre y
const double _ro = 120; // bowl outer radius
const double _ri = _ro - _t; // bowl inner radius (34)

bool _isInk(double x, double y) {
  // stem (rounded vertical bar)
  if (_distSeg(x, y, _xs, _yTop, _xs, _yBot) <= _r) return true;
  // bowl — right half of an annulus so it reads as an R loop
  if (x >= _xs) {
    final d = math.sqrt((x - _cx) * (x - _cx) + (y - _cy) * (y - _cy));
    if (d >= _ri && d <= _ro) return true;
  }
  // leg (rounded diagonal)
  if (_distSeg(x, y, 452, 536, 594, _yBot) <= _r) return true;
  return false;
}

void _draw(img.Image im, {required bool opaque, double scale = 1.0}) {
  const c = S / 2;
  for (int y = 0; y < S; y++) {
    for (int x = 0; x < S; x++) {
      // scale the glyph about the centre
      final mx = c + (x - c) / scale;
      final my = c + (y - c) / scale;

      List<int>? rgb;
      int a = 255;

      if (opaque) {
        rgb = _grad(((x + y) / (2 * S)).clamp(0.0, 1.0));
      }
      if (_isInk(mx, my)) {
        rgb = [255, 255, 255];
        a = 255;
      }
      if (rgb == null) continue;
      im.setPixelRgba(x, y, rgb[0], rgb[1], rgb[2], a);
    }
  }
}

Future<void> main() async {
  Directory('assets').createSync(recursive: true);

  final icon = img.Image(width: S, height: S, numChannels: 4);
  _draw(icon, opaque: true);
  File('assets/icon.png').writeAsBytesSync(img.encodePng(icon));
  stdout.writeln('wrote assets/icon.png');

  final fg = img.Image(width: S, height: S, numChannels: 4);
  _draw(fg, opaque: false, scale: 0.62); // Android adaptive safe zone
  File('assets/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));
  stdout.writeln('wrote assets/icon_foreground.png');
}
