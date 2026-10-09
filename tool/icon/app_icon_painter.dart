import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Uygulama ikonu seçenekleri.
enum IconDesign {
  /// Gradyan indigo zemin, beyaz domates (Pomodoro'nun simgesi), yeşil yaprak.
  domates,

  /// Koyu lacivert zemin, beyaz kum saati, camgöbeği ve yeşil kum.
  kumSaati,

  /// Açık zemin, yükselen çizgi ve yeşil uç nokta (ilerleme).
  ilerleme,

  /// Gradyan zemin, beyaz mezuniyet şapkası, yeşil püskül.
  sapka,

  /// Koyu lacivert zemin, gradyan ilerleme halkası ve yeşil tik.
  halka,

  /// Halka ve tik, altında küçük açık kitap.
  halkaAcikKitap,

  /// Halka ve tik, altında iki kitaplık yığın.
  halkaKitapYigini,

  /// Daha küçük halka ve tik, altında büyük açık kitap.
  halkaBuyukKitap,
}

/// İkonun hangi katmanı çizilecek.
enum IconLayer {
  /// Zemin + şekil, köşeleri yuvarlak kare (eski tip ikon ve önizleme).
  full,

  /// Adaptive ikonun zemini (tam kare, köşesiz).
  background,

  /// Adaptive ikonun ön planı (şeffaf zemin üstünde şekil).
  foreground,

  /// Tek renk şekil (şeffaf zemin): tema ikonu ve bildirim küçük ikonu.
  monochrome,
}

/// Marka renkleri (lib/core/theme/app_colors.dart ile aynı).
const _indigo = Color(0xFF4F46E5);
const _indigoDark = Color(0xFF3A33C2);

/// Koyu zeminde #4F46E5 laciverde karışır; halkanın başlangıcı için açık tonu.
const _indigoLight = Color(0xFF8B85FF);
const _cyan = Color(0xFF06B6D4);
const _green = Color(0xFF10B981);
const _navy = Color(0xFF0F172A);
const _navyIndigo = Color(0xFF1E1B4B);
const _focusFill = Color(0xFFEEF2FF);
const _white = Color(0xFFFFFFFF);

/// İkonu 1×1'lik bir kare olarak düşünüp çizer: tüm ölçüler kenar uzunluğunun
/// oranıdır. Adaptive ikonda sistem kenarlardan kırptığı için şekil ortadaki
/// %61'lik güvenli alanın içinde tutulur.
class AppIconPainter {
  const AppIconPainter(this.design, this.layer);

  final IconDesign design;
  final IconLayer layer;

  void paint(Canvas canvas, double s) {
    final rect = Offset.zero & Size.square(s);

    if (layer == IconLayer.full || layer == IconLayer.background) {
      canvas.save();
      if (layer == IconLayer.full) {
        canvas.clipRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(s * 0.225)),
        );
      }
      canvas.drawRect(rect, _backgroundPaint(rect));
      canvas.restore();
    }
    if (layer == IconLayer.background) return;

    final mono = layer == IconLayer.monochrome;
    switch (design) {
      case IconDesign.domates:
        _tomato(canvas, s, mono: mono);
      case IconDesign.kumSaati:
        _hourglass(canvas, s, mono: mono);
      case IconDesign.ilerleme:
        _progress(canvas, s, mono: mono);
      case IconDesign.sapka:
        _cap(canvas, s, mono: mono);
      case IconDesign.halka:
        _ring(canvas, s, mono: mono);
      case IconDesign.halkaAcikKitap:
        _ring(canvas, s, mono: mono, scale: 0.66, centerY: 0.405);
        _openBook(canvas, s, mono: mono, top: 0.635, width: 0.46);
      case IconDesign.halkaKitapYigini:
        _ring(canvas, s, mono: mono, scale: 0.66, centerY: 0.405);
        _bookStack(canvas, s, mono: mono);
      case IconDesign.halkaBuyukKitap:
        _ring(canvas, s, mono: mono, scale: 0.58, centerY: 0.395);
        _openBook(canvas, s, mono: mono, top: 0.605, width: 0.56);
    }
  }

  Paint _backgroundPaint(Rect rect) {
    final colors = switch (design) {
      IconDesign.domates => const [_indigo, _indigoDark],
      IconDesign.kumSaati => const [_navyIndigo, _navy],
      IconDesign.ilerleme => const [_focusFill, Color(0xFFE0E7FF)],
      IconDesign.sapka => const [_indigo, _cyan],
      IconDesign.halka ||
      IconDesign.halkaAcikKitap ||
      IconDesign.halkaKitapYigini ||
      IconDesign.halkaBuyukKitap => const [_navyIndigo, _navy],
    };
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
  }

  Paint _stroke(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  Paint _fill(Color color) => Paint()..color = color;

  /// Tek renkli katmanda renk yerine yalnızca saydamlık (alfa) kullanılır.
  Color _c(bool mono, Color color) =>
      mono ? Color.fromARGB((color.a * 255).round(), 0, 0, 0) : color;

  // ------------------------------------------------------------------ halka

  /// [scale] halkayı küçültür, [centerY] merkezini kare yüksekliğinin oranı
  /// olarak aşağı ya da yukarı taşır (altına kitap sığsın diye).
  void _ring(
    Canvas c,
    double s, {
    required bool mono,
    double scale = 1,
    double centerY = 0.5,
  }) {
    c.save();
    c.translate(s * 0.5, s * centerY);
    c.scale(scale);
    c.translate(-s * 0.5, -s * 0.5);

    final center = Offset(s / 2, s / 2);
    final radius = s * 0.26;
    final width = s * 0.075;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const sweep = 2 * math.pi * 0.75;

    // Tek renkte iz belirgin kalsın diye daha koyu (opak) çizilir.
    final track = mono
        ? const Color(0x4D000000)
        : _white.withValues(alpha: 0.14);
    c.drawCircle(center, radius, _stroke(width, track));

    final arc = _stroke(width, _c(mono, _white));
    if (!mono) {
      // Sweep gradyanı 3 hizasından başlar; yayın başladığı tepeye (-90°)
      // döndürülmezse 3 hizasında sert bir renk dikişi oluşur. Aralık, yuvarlak
      // uç kapaklarını da kapsasın diye iki yandan biraz geniştir.
      arc.shader = const SweepGradient(
        endAngle: sweep + 0.4,
        colors: [_indigoLight, _cyan],
        transform: GradientRotation(-math.pi / 2 - 0.2),
      ).createShader(arcRect);
    }
    c.drawArc(arcRect, -math.pi / 2, sweep, false, arc);

    final check = Path()
      ..moveTo(s * 0.405, s * 0.505)
      ..lineTo(s * 0.470, s * 0.572)
      ..lineTo(s * 0.600, s * 0.430);
    c.drawPath(check, _stroke(s * 0.07, _c(mono, _green)));
    c.restore();
  }

  /// Halkanın altındaki açık kitap: iki sayfa ortada birleşir.
  void _openBook(
    Canvas c,
    double s, {
    required bool mono,
    required double top,
    required double width,
  }) {
    final half = width / 2;
    Path page({required bool left}) {
      double x(double dx) => 0.5 + (left ? -dx : dx);
      return Path()
        ..moveTo(s * 0.5, s * (top + 0.025))
        ..quadraticBezierTo(
          s * x(half * 0.45),
          s * (top - 0.012),
          s * x(half),
          s * top,
        )
        ..lineTo(s * x(half), s * (top + 0.105))
        ..quadraticBezierTo(
          s * x(half * 0.45),
          s * (top + 0.093),
          s * 0.5,
          s * (top + 0.135),
        )
        ..close();
    }

    c.drawPath(page(left: true), _fill(_c(mono, _white)));
    c.drawPath(
      page(left: false),
      _fill(_c(mono, _white.withValues(alpha: 0.82))),
    );
  }

  /// Halkanın altındaki iki kitaplık yığın: alttaki geniş ve beyaz, üstteki
  /// biraz dar ve camgöbeği; her birinin solunda cilt çizgisi.
  void _bookStack(Canvas c, double s, {required bool mono}) {
    void book(Rect rect, Color color) {
      c.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.022)),
        _fill(_c(mono, color)),
      );
      // Cilt: sol uçtan biraz içeride ince koyu çizgi (tek renkte oyuk).
      final x = rect.left + rect.width * 0.14;
      final spine = _stroke(s * 0.012, const Color(0x40000000));
      if (mono) {
        spine.blendMode = BlendMode.clear;
      }
      c.drawLine(
        Offset(x, rect.top + s * 0.012),
        Offset(x, rect.bottom - s * 0.012),
        spine,
      );
    }

    final bottom = Rect.fromLTRB(s * 0.27, s * 0.715, s * 0.73, s * 0.78);
    final upper = Rect.fromLTRB(s * 0.31, s * 0.645, s * 0.69, s * 0.705);
    if (mono) {
      c.saveLayer(Offset.zero & Size.square(s), Paint());
      book(bottom, _white);
      book(upper, _white);
      c.restore();
    } else {
      book(bottom, _white);
      book(upper, _cyan);
    }
  }

  // ---------------------------------------------------------------- domates

  void _tomato(Canvas c, double s, {required bool mono}) {
    final body = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.585),
      width: s * 0.54,
      height: s * 0.46,
    );
    c.drawOval(body, _fill(_c(mono, _white)));

    // Yapraklar: gövdenin üst ortasından yıldız gibi açılır.
    final crown = Offset(s * 0.5, s * 0.375);
    void leaf(double degrees, double length) {
      c.save();
      c.translate(crown.dx, crown.dy);
      c.rotate(degrees * math.pi / 180);
      final path = Path()
        ..quadraticBezierTo(length * 0.5, -s * 0.05, length, 0)
        ..quadraticBezierTo(length * 0.5, s * 0.05, 0, 0);
      c.drawPath(path, _fill(_c(mono, _green)));
      c.restore();
    }

    leaf(-158, s * 0.17);
    leaf(-22, s * 0.17);
    leaf(-122, s * 0.13);
    leaf(-58, s * 0.13);
    // Sap.
    c.drawLine(
      crown,
      Offset(s * 0.5, s * 0.30),
      _stroke(s * 0.04, _c(mono, _green)),
    );

    // Saat ibreleri: domates aynı zamanda bir zamanlayıcı.
    final center = body.center;
    final hands = Path()
      ..moveTo(center.dx, center.dy - s * 0.115)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx + s * 0.085, center.dy + s * 0.04);
    if (mono) {
      c.saveLayer(Offset.zero & Size.square(s), Paint());
      c.drawOval(body, _fill(_c(mono, _white)));
      c.drawPath(
        hands,
        _stroke(s * 0.05, const Color(0xFF000000))..blendMode = BlendMode.clear,
      );
      c.restore();
    } else {
      c.drawPath(hands, _stroke(s * 0.05, _indigo));
    }
  }

  // --------------------------------------------------------------- kum saati

  void _hourglass(Canvas c, double s, {required bool mono}) {
    Offset p(double x, double y) => Offset(s * x, s * y);

    final topGlass = Path()
      ..moveTo(s * 0.335, s * 0.295)
      ..lineTo(s * 0.665, s * 0.295)
      ..lineTo(s * 0.525, s * 0.5)
      ..lineTo(s * 0.475, s * 0.5)
      ..close();
    final bottomGlass = Path()
      ..moveTo(s * 0.475, s * 0.5)
      ..lineTo(s * 0.525, s * 0.5)
      ..lineTo(s * 0.665, s * 0.705)
      ..lineTo(s * 0.335, s * 0.705)
      ..close();

    // Kum (camın içinde).
    final topSand = Path()
      ..moveTo(s * 0.395, s * 0.335)
      ..lineTo(s * 0.605, s * 0.335)
      ..lineTo(s * 0.508, s * 0.472)
      ..lineTo(s * 0.492, s * 0.472)
      ..close();
    final bottomSand = Path()
      ..moveTo(s * 0.385, s * 0.672)
      ..lineTo(s * 0.615, s * 0.672)
      ..lineTo(s * 0.55, s * 0.575)
      ..quadraticBezierTo(s * 0.5, s * 0.545, s * 0.45, s * 0.575)
      ..close();
    c.drawPath(topSand, _fill(_c(mono, _cyan)));
    c.drawPath(bottomSand, _fill(_c(mono, _green)));
    c.drawLine(
      p(0.5, 0.47),
      p(0.5, 0.575),
      _stroke(s * 0.014, _c(mono, _green)),
    );

    // Cam çerçevesi ve alt/üst plakalar.
    final glass = _stroke(s * 0.034, _c(mono, _white));
    c.drawPath(topGlass, glass);
    c.drawPath(bottomGlass, glass);
    final plate = _fill(_c(mono, _white));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(s * 0.29, s * 0.245, s * 0.71, s * 0.29),
        Radius.circular(s * 0.022),
      ),
      plate,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(s * 0.29, s * 0.71, s * 0.71, s * 0.755),
        Radius.circular(s * 0.022),
      ),
      plate,
    );
  }

  // ----------------------------------------------------------------- ilerleme

  void _progress(Canvas c, double s, {required bool mono}) {
    final points = [
      Offset(s * 0.25, s * 0.655),
      Offset(s * 0.42, s * 0.52),
      Offset(s * 0.56, s * 0.585),
      Offset(s * 0.745, s * 0.345),
    ];
    final baseline = s * 0.745;

    // Zemin çizgisi.
    c.drawLine(
      Offset(s * 0.25, baseline),
      Offset(s * 0.75, baseline),
      _stroke(s * 0.03, _c(mono, _indigo.withValues(alpha: 0.30))),
    );

    // İlerleme çizgisi.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    c.drawPath(line, _stroke(s * 0.07, _c(mono, _indigo)));

    // Uç nokta.
    c.drawCircle(points.last, s * 0.078, _fill(_c(mono, _green)));
  }

  // -------------------------------------------------------------------- şapka

  void _cap(Canvas c, double s, {required bool mono}) {
    // Şapkanın alt kısmı (başı saran bant).
    final base = Path()
      ..moveTo(s * 0.315, s * 0.50)
      ..lineTo(s * 0.315, s * 0.625)
      ..quadraticBezierTo(s * 0.5, s * 0.735, s * 0.685, s * 0.625)
      ..lineTo(s * 0.685, s * 0.50)
      ..lineTo(s * 0.5, s * 0.575)
      ..close();
    c.drawPath(base, _fill(_c(mono, _white.withValues(alpha: 0.82))));

    // Üst yüzey: baklava dilimi.
    final top = Path()
      ..moveTo(s * 0.5, s * 0.305)
      ..lineTo(s * 0.785, s * 0.425)
      ..lineTo(s * 0.5, s * 0.545)
      ..lineTo(s * 0.215, s * 0.425)
      ..close();
    c.drawPath(top, _fill(_c(mono, _white)));

    // Püskül.
    c.drawLine(
      Offset(s * 0.745, s * 0.445),
      Offset(s * 0.745, s * 0.60),
      _stroke(s * 0.028, _c(mono, _green)),
    );
    c.drawCircle(
      Offset(s * 0.745, s * 0.62),
      s * 0.036,
      _fill(_c(mono, _green)),
    );
  }
}
