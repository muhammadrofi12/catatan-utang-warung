import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backup/backup.dart';
import '../data/book_repository.dart';
import '../domain/book.dart';

class AppScope extends InheritedNotifier<Listenable> {
  final DeviceBridge device;
  final BackupStatus backup;
  final BookRepository repository;
  AppScope({
    super.key,
    required this.repository,
    required this.device,
    required this.backup,
    required super.child,
  }) : super(notifier: Listenable.merge([repository, backup]));
  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;
}

Future<T?> visit<T>(BuildContext context, Widget child) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => child));

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String action = 'Lanjutkan',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

String safeError(Object error) {
  if (error is BookError) return error.message;
  if (error is PlatformException) {
    return error.message ?? 'Perangkat belum dapat menyelesaikan tindakan ini.';
  }
  return 'Belum berhasil. Periksa ruang penyimpanan lalu coba lagi. Catatan yang sudah tersimpan tidak dihapus.';
}

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final bool error;
  final Widget? action;
  const Notice(this.text, {super.key, this.error = false, this.action});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: error ? colors.errorContainer : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: error
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  const ActionButton(
    this.text, {
    super.key,
    this.onPressed,
    this.icon,
    this.secondary = false,
  });
  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 24)),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(text, textAlign: TextAlign.center)),
        ],
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton(onPressed: onPressed, child: child)
          : FilledButton(onPressed: onPressed, child: child),
    );
  }
}

class MoneyText extends StatelessWidget {
  final int amount;
  final bool large;
  final Color? color;
  const MoneyText(this.amount, {super.key, this.large = true, this.color});
  @override
  Widget build(BuildContext context) => Text(
    money(amount),
    softWrap: true,
    style: large
        ? Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color)
        : Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color),
  );
}

class AmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!RegExp(r'^[0-9.]*$').hasMatch(newValue.text)) return oldValue;
    var prefix = 0;
    while (prefix < oldValue.text.length &&
        prefix < newValue.text.length &&
        oldValue.text[prefix] == newValue.text[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldValue.text.length - prefix &&
        suffix < newValue.text.length - prefix &&
        oldValue.text[oldValue.text.length - suffix - 1] ==
            newValue.text[newValue.text.length - suffix - 1]) {
      suffix++;
    }
    final inserted = newValue.text.substring(
      prefix,
      newValue.text.length - suffix,
    );
    if (inserted.contains('.') &&
        !RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(newValue.text)) {
      return oldValue;
    }
    final digits = newValue.text.replaceAll('.', '');
    if (digits.length > 9) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = money(int.parse(digits)).substring(2);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DirtyGuard extends StatefulWidget {
  final bool dirty;
  final bool busy;
  final Widget child;
  const DirtyGuard({
    super.key,
    required this.dirty,
    required this.busy,
    required this.child,
  });
  @override
  State<DirtyGuard> createState() => _DirtyGuardState();
}

class _DirtyGuardState extends State<DirtyGuard> {
  bool allowed = false;
  bool asking = false;
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: allowed || (!widget.dirty && !widget.busy),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || widget.busy || asking) return;
      asking = true;
      final leave = await confirm(
        context,
        'Isian belum disimpan',
        'Kembali akan membuang isian ini. Catatan yang sudah tersimpan tetap ada.',
        action: 'Buang isian',
      );
      asking = false;
      if (!mounted || !leave) return;
      setState(() => allowed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    },
    child: widget.child,
  );
}

ThemeData warungTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2463B5),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFA8CBFF) : const Color(0xFF245FB0),
        onPrimary: dark ? const Color(0xFF10335E) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF203B5D)
            : const Color(0xFFEAF2FD),
        onPrimaryContainer: dark
            ? const Color(0xFFD8E8FF)
            : const Color(0xFF19477F),
        secondaryContainer: dark
            ? const Color(0xFF23374D)
            : const Color(0xFFF0F5FC),
        onSecondaryContainer: dark
            ? const Color(0xFFD6E4F4)
            : const Color(0xFF304B6C),
        tertiary: dark ? const Color(0xFFF1CD83) : const Color(0xFF805900),
        tertiaryContainer: dark
            ? const Color(0xFF46391F)
            : const Color(0xFFFFF4DD),
        onTertiaryContainer: dark
            ? const Color(0xFFFFE3A5)
            : const Color(0xFF664600),
        surface: dark ? const Color(0xFF111B29) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xFF172436)
            : const Color(0xFFF5F8FD),
        onSurface: dark ? const Color(0xFFEDF2F8) : const Color(0xFF17263B),
        onSurfaceVariant: dark
            ? const Color(0xFFB6C5D9)
            : const Color(0xFF53647A),
        outline: dark ? const Color(0xFF8090A7) : const Color(0xFF74859A),
        outlineVariant: dark
            ? const Color(0xFF34445B)
            : const Color(0xFFDEE6F0),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    brightness: brightness,
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    extensions: [
      WarungPalette(
        header: dark ? const Color(0xFF193D70) : const Color(0xFF2865B6),
        onHeader: Colors.white,
        payment: dark ? const Color(0xFF91DDB5) : const Color(0xFF176440),
        paymentSurface: dark
            ? const Color(0xFF1C3A30)
            : const Color(0xFFE9F6EF),
      ),
    ],
    textTheme: base.textTheme
        .copyWith(
          bodyLarge: const TextStyle(fontSize: 20, height: 1.4),
          bodyMedium: const TextStyle(fontSize: 18, height: 1.4),
          titleMedium: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: const TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: const TextStyle(
            fontSize: 30,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          labelLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(
          fontFamily: 'Roboto',
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 64,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: colors.outlineVariant),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      helperMaxLines: 3,
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primary,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    visualDensity: VisualDensity.standard,
  );
}

@immutable
class WarungPalette extends ThemeExtension<WarungPalette> {
  final Color header;
  final Color onHeader;
  final Color payment;
  final Color paymentSurface;
  const WarungPalette({
    required this.header,
    required this.onHeader,
    required this.payment,
    required this.paymentSurface,
  });
  static WarungPalette of(BuildContext context) =>
      Theme.of(context).extension<WarungPalette>()!;
  @override
  WarungPalette copyWith({
    Color? header,
    Color? onHeader,
    Color? payment,
    Color? paymentSurface,
  }) => WarungPalette(
    header: header ?? this.header,
    onHeader: onHeader ?? this.onHeader,
    payment: payment ?? this.payment,
    paymentSurface: paymentSurface ?? this.paymentSurface,
  );
  @override
  WarungPalette lerp(covariant WarungPalette? other, double t) => other == null
      ? this
      : WarungPalette(
          header: Color.lerp(header, other.header, t)!,
          onHeader: Color.lerp(onHeader, other.onHeader, t)!,
          payment: Color.lerp(payment, other.payment, t)!,
          paymentSurface: Color.lerp(paymentSurface, other.paymentSurface, t)!,
        );
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? foreground;
  final Color? background;
  const IconBadge(this.icon, {super.key, this.foreground, this.background});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: background ?? colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 25,
          color: foreground ?? colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
