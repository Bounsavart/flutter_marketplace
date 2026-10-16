import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/room_image_picker_row.dart';
import 'search_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key, this.existing, this.editRoom});
  final Property? existing;
  final Room? editRoom;

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final address = TextEditingController();
  final roomNumber = TextEditingController();
  final price = TextEditingController();
  final roomDescription = TextEditingController();
  String province = provinces.first;
  String district = districts.first;
  String roomType = 'Studio';
  List<Amenity> amenities = [];
  final selectedAmenityIds = <int>{};
  final images = <XFile>[];
  bool loading = false;
  final formKey = GlobalKey<FormState>();
  final removedImageIds = <int>{};
  String roomStatus = 'available';
  bool confirmCancelBooking = false;

  bool get addRoomOnly => widget.existing != null;
  bool get editMode => widget.editRoom != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      name.text = widget.existing!.name;
      province = widget.existing!.province;
      district = widget.existing!.district;
      address.text = widget.existing!.address;
    }
    if (widget.editRoom != null) {
      final r = widget.editRoom!;
      roomNumber.text = r.roomNumber;
      price.text = r.price.toString();
      roomDescription.text = r.description ?? '';
      roomType = r.roomType;
      roomStatus = r.status;
      selectedAmenityIds.addAll(r.amenities.map((a) => a.id));
    }
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    amenities = await context.read<AuthState>().api.amenities();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    address.dispose();
    roomNumber.dispose();
    price.dispose();
    roomDescription.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    final api = context.read<AuthState>().api;
    try {
      late Room room;
      if (editMode) {
        room = await api.updateRoom(widget.editRoom!.id, {
          'room_number': roomNumber.text.trim(),
          'room_type': roomType,
          'price': num.parse(price.text),
          'description': roomDescription.text.trim(),
          'amenityIds': selectedAmenityIds.toList(),
          'status': roomStatus,
          'confirm_cancel_booking': confirmCancelBooking,
        });
        for (final id in removedImageIds) {
          await api.deleteRoomImage(room.id, id);
        }
      } else if (addRoomOnly) {
        room = await api.addRoom(widget.existing!.id, {
          'room_number': roomNumber.text.trim(),
          'room_type': roomType,
          'price': num.parse(price.text),
          'description': roomDescription.text.trim(),
          'amenityIds': selectedAmenityIds.toList(),
        });
      } else {
        final property = await api.createProperty({
          'name': name.text.trim(),
          'description': description.text.trim(),
          'province': province,
          'district': district,
          'address': address.text.trim(),
          'room': {
            'room_number': roomNumber.text.trim(),
            'room_type': roomType,
            'price': num.parse(price.text),
            'description': roomDescription.text.trim(),
            'amenityIds': selectedAmenityIds.toList(),
          },
        });
        room = property.rooms.first;
      }
      if (images.isNotEmpty) {
        await api.uploadRoomImages(room.id, images);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (mounted) setState(() => images.addAll(picked));
  }

  // Multi-line fields use the card radius; a 30px pill looks wrong on them.
  InputDecoration _area(String label) {
    final c = Palette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.inputBorder),
    );
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: c.accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      title: editMode
          ? 'ແກ້ໄຂຫ້ອງ'
          : (addRoomOnly ? 'ເພີ່ມຫ້ອງ' : 'ເພີ່ມທີ່ພັກ'),
      subtitle: editMode
          ? widget.editRoom!.property?.name
          : (addRoomOnly ? widget.existing!.name : null),
      trailingIcon: addRoomOnly ? TablerIcons.door : TablerIcons.building,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          children: [
            if (!addRoomOnly && !editMode) ...[
              const SectionTitle('ຂໍ້ມູນທີ່ພັກ'),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'ຊື່ທີ່ພັກ',
                  prefixIcon: Icon(TablerIcons.building),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: province,
                items: provinces
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => province = v ?? province),
                decoration: const InputDecoration(
                  labelText: 'ແຂວງ',
                  prefixIcon: Icon(TablerIcons.map_pin),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: district,
                items: districts
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => district = v ?? district),
                decoration: const InputDecoration(
                  labelText: 'ເມືອງ',
                  prefixIcon: Icon(TablerIcons.map_pin),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'ທີ່ຢູ່',
                  prefixIcon: Icon(TablerIcons.home),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: _area('ລາຍລະອຽດທີ່ພັກ'),
              ),
              const SizedBox(height: 22),
              const SectionTitle('ຫ້ອງທຳອິດ'),
            ],
            TextFormField(
              controller: roomNumber,
              decoration: const InputDecoration(
                labelText: 'ເລກຫ້ອງ',
                prefixIcon: Icon(TablerIcons.door),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'ກະລຸນາປ້ອນເລກຫ້ອງ' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: roomType,
              items: const ['Studio', '1 Bedroom', '2 Bedroom']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(switch (e) {
                        'Studio' => 'ຫ້ອງສະຕູດິໂອ',
                        '1 Bedroom' => '1 ຫ້ອງນອນ',
                        _ => '2 ຫ້ອງນອນ',
                      }),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => roomType = v ?? roomType),
              decoration: const InputDecoration(
                labelText: 'ປະເພດຫ້ອງ',
                prefixIcon: Icon(TablerIcons.bed),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = num.tryParse(v?.trim() ?? '');
                return n == null || n <= 0 ? 'ກະລຸນາປ້ອນລາຄາໃຫ້ຖືກຕ້ອງ' : null;
              },
              decoration: const InputDecoration(
                labelText: 'ລາຄາຕໍ່ເດືອນ (ກີບ)',
                prefixIcon: Icon(TablerIcons.cash),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomDescription,
              maxLines: 3,
              decoration: _area('ລາຍລະອຽດຫ້ອງ'),
            ),
            if (editMode) ...[
              const SizedBox(height: 18),
              const SectionTitle('ສະຖານະຫ້ອງ'),
              if (widget.editRoom!.status == 'pending')
                const InfoBox(text: 'ກະລຸນາຢືນຢັນ ຫຼື ປະຕິເສດຄຳຂໍຈອງກ່ອນ'),
              if (widget.editRoom!.status != 'pending')
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'available', label: Text('ຫວ່າງ')),
                    ButtonSegment(value: 'rented', label: Text('ເຊົ່າແລ້ວ')),
                  ],
                  selected: {roomStatus},
                  onSelectionChanged: (v) async {
                    if (roomStatus == 'rented' && v.first == 'available') {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ຢືນຢັນປ່ຽນສະຖານະ?'),
                          content: const Text(
                            'ການຈອງທີ່ຢືນຢັນແລ້ວຈະຖືກຍົກເລີກ.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('ຍົກເລີກ'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('ຢືນຢັນ'),
                            ),
                          ],
                        ),
                      );
                      if (yes != true) return;
                      confirmCancelBooking = true;
                    }
                    setState(() => roomStatus = v.first);
                  },
                ),
            ],
            const SizedBox(height: 18),
            const SectionTitle('ສິ່ງອຳນວຍຄວາມສະດວກ'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: amenities
                  .map(
                    (a) => PillChip(
                      label: a.name,
                      selected: selectedAmenityIds.contains(a.id),
                      onTap: () => setState(() {
                        if (!selectedAmenityIds.remove(a.id)) {
                          selectedAmenityIds.add(a.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const SectionTitle('ຮູບພາບຫ້ອງ'),
            const SizedBox(height: 6),
            RoomImagePickerRow(
              existingImages: editMode
                  ? widget.editRoom!.images
                  : const <RoomImage>[],
              removedImageIds: removedImageIds,
              selectedImages: images,
              onRemoveExisting: (id) => setState(() => removedImageIds.add(id)),
              onRemoveSelected: (index) =>
                  setState(() => images.removeAt(index)),
              onAddImages: _pickImages,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      editMode
                          ? 'ບັນທຶກການແກ້ໄຂ'
                          : (addRoomOnly
                                ? 'ບັນທຶກຫ້ອງ'
                                : 'ສົ່ງປະກາດໃຫ້ແອັດມິນກວດສອບ'),
                    ),
            ),
            if (!addRoomOnly && !editMode) ...[
              const SizedBox(height: 12),
              const InfoBox(
                text:
                    'ທີ່ພັກໃໝ່ຈະຍັງບໍ່ສະແດງໃນການຄົ້ນຫາ ຈົນກວ່າຜູ້ດູແລລະບົບຈະອະນຸມັດ',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
