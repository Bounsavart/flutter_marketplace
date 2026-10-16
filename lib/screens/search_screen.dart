import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/room_card.dart';
import '../widgets/ui.dart';
import 'room_detail_screen.dart';

const provinces = ['ນະຄອນຫຼວງວຽງຈັນ'];
const districts = [
  'ຈັນທະບູລີ',
  'ສີໂຄດຕະບອງ',
  'ໄຊເສດຖາ',
  'ສີສັດຕະນາກ',
  'ນາຊາຍທອງ',
  'ໄຊທານີ',
  'ຫາດຊາຍຟອງ',
];

const _priceOptions = {
  'lt2': '< 2 ລ້ານ',
  '2to4': '2–4 ລ້ານ',
  'gt4': '> 4 ລ້ານ',
};

const _sortOptions = {
  'priceAsc': 'ລາຄາ ຕ່ຳ → ສູງ',
  'priceDesc': 'ລາຄາ ສູງ → ຕ່ຳ',
};

/// Returned by [_SearchScreenState._pick] when the user picks "all".
const _all = '';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final q = TextEditingController();
  String? province;
  String? district;
  String? price;
  String? sort;
  bool availableOnly = false;
  List<Room> rooms = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      num? min;
      num? max;
      if (price == 'lt2') max = 2000000;
      if (price == '2to4') {
        min = 2000000;
        max = 4000000;
      }
      if (price == 'gt4') min = 4000000;
      rooms = await context.read<AuthState>().api.searchRooms(
        q: q.text,
        province: province,
        district: district,
        minPrice: min,
        maxPrice: max,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Room> get _shown {
    final list = availableOnly
        ? rooms.where((r) => r.status == 'available').toList()
        : [...rooms];
    if (sort == 'priceAsc') list.sort((a, b) => a.price.compareTo(b.price));
    if (sort == 'priceDesc') list.sort((a, b) => b.price.compareTo(a.price));
    return list;
  }

  /// Applies a [_pick] result: null means dismissed, [_all] clears the filter.
  void _apply(
    String? picked,
    void Function(String? value) set, {
    bool reload = true,
  }) {
    if (picked == null) return;
    setState(() => set(picked == _all ? null : picked));
    if (reload) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final name = context.watch<AuthState>().user?.name;
    final shown = _shown;
    return HeroScaffold(
      eyebrow: name == null ? 'ສະບາຍດີ' : 'ສະບາຍດີ, $name',
      title: 'ຊອກທີ່ພັກຂອງທ່ານ',
      headerBottom: TextField(
        controller: q,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintText: 'ຄົ້ນຫາຊື່ຫ້ອງ, ປະເພດ...',
          hintStyle: const TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 14,
          ),
          fillColor: Colors.white.withValues(alpha: 0.15),
          prefixIcon: const Icon(
            TablerIcons.search,
            color: AppTheme.accentLight,
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: _load,
            icon: const Icon(
              TablerIcons.arrow_right,
              color: AppTheme.accentLight,
              size: 20,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppTheme.accentLight),
          ),
        ),
        onSubmitted: (_) => _load(),
      ),
      pinned: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            _FilterPill(
              icon: TablerIcons.coin,
              label: price == null ? 'ທຸກລາຄາ' : _priceOptions[price]!,
              active: price != null,
              dropdown: true,
              onTap: () async => _apply(
                await _pick('ລາຄາ', 'ທຸກລາຄາ', _priceOptions, price),
                (v) => price = v,
              ),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              icon: TablerIcons.map_pin,
              label: province ?? 'ແຂວງ',
              active: province != null,
              dropdown: true,
              onTap: () async => _apply(
                await _pick('ແຂວງ', 'ທຸກແຂວງ', {
                  for (final p in provinces) p: p,
                }, province),
                (v) => province = v,
              ),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              icon: TablerIcons.building,
              label: district ?? 'ເມືອງ',
              active: district != null,
              dropdown: true,
              onTap: () async => _apply(
                await _pick('ເມືອງ', 'ທຸກເມືອງ', {
                  for (final d in districts) d: d,
                }, district),
                (v) => district = v,
              ),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              icon: TablerIcons.home_check,
              label: 'ຫວ່າງ',
              active: availableOnly,
              activeBg: Tone.success.bgOn(c),
              activeFg: Tone.success.fgOn(c),
              onTap: () => setState(() => availableOnly = !availableOnly),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              icon: TablerIcons.adjustments,
              label: sort == null ? 'ຕື່ມ' : _sortOptions[sort]!,
              active: sort != null,
              dashed: sort == null,
              onTap: _openMore,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Text(error!, style: TextStyle(color: Palette.of(context).danger))
            else if (shown.isEmpty)
              const EmptyState(
                icon: TablerIcons.home_search,
                text: 'ຍັງບໍ່ມີຫ້ອງທີ່ກົງກັບຕົວກອງ',
              )
            else
              ...shown.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoomCard(
                    room: room,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailScreen(roomId: room.id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "More" sheet: sort order plus a reset for every filter.
  Future<void> _openMore() async {
    final picked = await _pick(
      'ຈັດລຽງ',
      'ຄ່າເລີ່ມຕົ້ນ',
      _sortOptions,
      sort,
      footer: 'ລ້າງຕົວກອງທັງໝົດ',
    );
    if (picked == _resetAll) {
      setState(() {
        price = province = district = sort = null;
        availableOnly = false;
      });
      _load();
      return;
    }
    _apply(picked, (v) => sort = v, reload: false);
  }

  static const _resetAll = '__reset__';

  /// Bottom sheet of [options] (value → label). Returns the picked value,
  /// [_all] for [allLabel], [_resetAll] for [footer], or null if dismissed.
  Future<String?> _pick(
    String title,
    String allLabel,
    Map<String, String> options,
    String? current, {
    String? footer,
  }) {
    final c = Palette.of(context);
    Widget tile(String label, String value, bool selected) => ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: selected ? c.accent : c.text,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? Icon(TablerIcons.check, size: 18, color: c.accent)
          : null,
      onTap: () => Navigator.pop(context, value),
    );
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
            tile(allLabel, _all, current == null),
            for (final e in options.entries)
              tile(e.value, e.key, current == e.key),
            if (footer != null) ...[
              const Divider(),
              ListTile(
                dense: true,
                leading: Icon(TablerIcons.refresh, size: 18, color: c.muted),
                title: Text(
                  footer,
                  style: TextStyle(fontSize: 15, color: c.muted),
                ),
                onTap: () => Navigator.pop(context, _resetAll),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filter pill: outline by default, filled when [active]. [dashed] draws a
/// dashed outline for the "more filters" entry.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.dropdown = false,
    this.dashed = false,
    this.activeBg,
    this.activeFg,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool dropdown;
  final bool dashed;
  final Color? activeBg;
  final Color? activeFg;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final bg = active ? (activeBg ?? AppTheme.primary) : c.card;
    final fg = active ? (activeFg ?? Colors.white) : c.accent;
    final borderColor = active ? (activeBg ?? AppTheme.primary) : c.border;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (dropdown) ...[
            const SizedBox(width: 3),
            Icon(TablerIcons.chevron_down, size: 15, color: fg),
          ],
        ],
      ),
    );
    final pill = Material(
      color: bg,
      shape: StadiumBorder(
        side: dashed ? BorderSide.none : BorderSide(color: borderColor),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: content,
      ),
    );
    return TapTarget(
      onTap: onTap,
      child: dashed
          ? CustomPaint(
              foregroundPainter: _DashedStadiumPainter(borderColor),
              child: pill,
            )
          : pill,
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  _DashedStadiumPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(0.5),
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter old) => old.color != color;
}
