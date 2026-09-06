import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/connectivity/connectivity_controller.dart';
import 'package:notes_app/core/theme/paper_palette.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';
import 'package:notes_app/core/theme/theme_mode_controller.dart';
import 'package:notes_app/core/utils/data_uri_cache.dart';
import 'package:notes_app/features/account/domain/note_export.dart';
import 'package:notes_app/features/account/domain/phone_alerts_controller.dart';
import 'package:notes_app/features/account/domain/profile_controller.dart';
import 'package:notes_app/features/account/domain/user_profile.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/notebooks/domain/notebooks_controller.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/plan/domain/plan_providers.dart';
import 'package:share_plus/share_plus.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/account/AccountPanel.tsx` — profile, library
/// shortcuts, and settings (feature-audit #14).
///
/// **Not ported / simplified, per the "no backend/DB for now"
/// instruction:** `pendingCount`/`usageLabel`/`persistError` depend on a
/// real mutation queue and storage-quota estimate that don't exist here;
/// "Phone alerts" requests plain OS notification permission rather than
/// scheduling the source's Calendar-Provider events (see
/// `phone_alerts_controller.dart`'s doc comment). Everything else —
/// profile editing (including a real photo picker, reusing the note
/// editor's compress-to-data-URI pattern), library counts/navigation,
/// paper skin, the day/night toggle, and Markdown/JSON export + import —
/// is real, working functionality.
class const AccountScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _editing = false;
  bool _paperOpen = false;
  String? _photoError;
  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _bioController;
  String _draftHue = profileHues.first;
  String? _draftAvatar;

  String get _email => ref.read(sessionControllerProvider)!.email;

  UserProfile get _profile =>
      ref.read(profileControllerProvider.notifier).profileFor(_email);

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _nameController = TextEditingController(text: profile.name);
    _handleController = TextEditingController(text: profile.handle);
    _bioController = TextEditingController(text: profile.bio);
    _draftHue = profile.hue;
    _draftAvatar = profile.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final profile = _profile;
    _nameController.text = profile.name;
    _handleController.text = profile.handle;
    _bioController.text = profile.bio;
    setState(() {
      _draftHue = profile.hue;
      _draftAvatar = profile.avatar;
      _photoError = null;
      _editing = true;
    });
  }

  void _saveProfile() {
    final fallback = _profile;
    final next = sanitizeProfile(
      fallback,
      name: _nameController.text,
      handle: _handleController.text,
      bio: _bioController.text,
      hue: _draftHue,
      avatar: _draftAvatar,
    );
    ref.read(profileControllerProvider.notifier).save(_email, next);
    setState(() => _editing = false);
  }

  Future<void> _pickPhoto() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    final file = files.firstOrNull;
    if (file == null) return;
    if (await file.length() > 4 * 1024 * 1024) {
      setState(() => _photoError = 'Keep photos under 4 MB.');
      return;
    }
    final bytes = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 480,
      minHeight: 480,
      quality: 72,
    );
    setState(() {
      _photoError = null;
      _draftAvatar = 'data:image/jpeg;base64,${base64Encode(compressed)}';
    });
  }

  Future<void> _exportMarkdown() async {
    final notes = _liveNotes();
    await SharePlus.instance.share(
      ShareParams(text: exportNotesMarkdown(notes), title: 'notes.md'),
    );
  }

  Future<void> _exportJson() async {
    final notes = _liveNotes();
    await SharePlus.instance.share(
      ShareParams(text: exportNotesJson(notes), title: 'notes.json'),
    );
  }

  List<Note> _liveNotes() => ref
      .read(notesControllerProvider)
      .where((n) => n.trashedAt == null && !n.archived)
      .toList();

  Future<void> _importBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final file = files.firstOrNull;
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final raw = utf8.decode(bytes);
      final existing = ref.read(notesControllerProvider);
      final merged = importNotesJson(raw, existing, _email);
      ref.read(notesControllerProvider.notifier).replaceAll(merged);
      if (mounted) {
        final imported = merged.length - existing.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imported > 0
                  ? 'Imported $imported notes'
                  : 'Nothing new to import',
            ),
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not import that file')),
        );
      }
    }
  }

  Future<void> _requestPhoneAlerts() async {
    final granted = await ref
        .read(phoneAlertsControllerProvider.notifier)
        .requestEnable();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Phone alerts are on.'
              : 'Notifications are off. Allow them in Android settings.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile =
        ref.watch(profileControllerProvider)[_email] ??
        profileFromEmail(_email);
    final notes = ref.watch(notesControllerProvider);
    final liveNotes = notes.where((n) => n.trashedAt == null && !n.archived);
    final trashCount = notes.where((n) => n.trashedAt != null).length;
    final notebooksCount = ref.watch(notebooksControllerProvider).length;
    final agenda = ref.watch(planAgendaProvider);
    final online = ref.watch(isOnlineProvider).value ?? true;
    final skin = ref.watch(skinControllerProvider);
    final dark = ref.watch(themeModeControllerProvider) == ThemeMode.dark;
    final alertsOn = ref.watch(phoneAlertsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarWithEdit(
                  profile: profile,
                  editing: _editing,
                  onToggleEditing: () => _editing
                      ? setState(() => _editing = false)
                      : _startEditing(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 27.2,
                            height: 1.05,
                            letterSpacing: -1.09,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '${liveNotes.length}',
                                label: 'Notes',
                              ),
                            ),
                            Expanded(
                              child: _Stat(
                                value: '$notebooksCount',
                                label: 'Books',
                              ),
                            ),
                            Expanded(
                              child: _Stat(
                                value: profile.handle,
                                label: 'Handle',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFC5CA8A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: _ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _ink,
                      ),
                    ),
                  ),
                  Text(
                    online ? 'On device' : 'Offline',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!_editing && profile.bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                profile.bio,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ],
            if (_editing) ...[
              const SizedBox(height: 20),
              _ProfileEditForm(
                nameController: _nameController,
                handleController: _handleController,
                bioController: _bioController,
                hue: _draftHue,
                avatar: _draftAvatar,
                photoError: _photoError,
                onHue: (hue) => setState(() => _draftHue = hue),
                onPickPhoto: _pickPhoto,
                onRemovePhoto: () => setState(() => _draftAvatar = null),
                onSave: _saveProfile,
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Library',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18.4),
            ),
            const SizedBox(height: 12),
            _RowGroup(
              children: [
                _AccountRow(
                  icon: Icons.edit_note,
                  tone: const Color(0xFFE8C44A),
                  label: 'Notes',
                  badge: liveNotes.length,
                  onTap: () {
                    ref
                        .read(noteFilterKeyProvider.notifier)
                        .set(NoteFilter.all);
                    ref.read(noteNotebookFilterProvider.notifier).set(null);
                    context.go('/notes');
                  },
                ),
                _AccountRow(
                  icon: Icons.menu_book_outlined,
                  tone: const Color(0xFFE7A3A3),
                  label: 'Notebooks',
                  badge: notebooksCount,
                  onTap: () => context.go('/notebooks'),
                ),
                _AccountRow(
                  icon: Icons.calendar_today_outlined,
                  tone: const Color(0xFFA9D4C4),
                  label: 'Plan',
                  badge: agenda.waiting,
                  onTap: () => context.go('/plan'),
                ),
                _AccountRow(
                  icon: Icons.delete_outline,
                  tone: const Color(0xFFD4C4E8),
                  label: 'Trash',
                  badge: trashCount == 0 ? null : trashCount,
                  isLast: true,
                  onTap: () {
                    ref
                        .read(noteFilterKeyProvider.notifier)
                        .set(NoteFilter.trash);
                    context.go('/notes');
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18.4),
            ),
            const SizedBox(height: 12),
            _RowGroup(
              children: [
                _AccountRow(
                  icon: Icons.palette_outlined,
                  tone: const Color(0xFFE89569),
                  label: 'Paper',
                  hint: skin.label,
                  onTap: () => setState(() => _paperOpen = !_paperOpen),
                ),
                if (_paperOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        for (final item in PaperSkin.values)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: item == PaperSkin.values.last ? 0 : 8,
                              ),
                              child: _PaperSkinChip(
                                skin: item,
                                selected: skin == item,
                                onTap: () => ref
                                    .read(skinControllerProvider.notifier)
                                    .setSkin(item),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                _AccountRow(
                  icon: dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  tone: const Color(0xFFBEC3BC),
                  label: dark ? 'Night ink' : 'Day paper',
                  onTap: () =>
                      ref.read(themeModeControllerProvider.notifier).toggle(),
                ),
                _AccountRow(
                  icon: Icons.notifications_outlined,
                  tone: const Color(0xFFC5CA8A),
                  label: 'Phone alerts',
                  hint: alertsOn ? 'On' : 'App only',
                  onTap: _requestPhoneAlerts,
                ),
                _AccountRow(
                  icon: Icons.download_outlined,
                  tone: const Color(0xFFE8C44A),
                  label: 'Export Markdown',
                  onTap: _exportMarkdown,
                ),
                _AccountRow(
                  icon: Icons.description_outlined,
                  tone: const Color(0xFFD4C4E8),
                  label: 'Export JSON',
                  onTap: _exportJson,
                ),
                _AccountRow(
                  icon: Icons.file_upload_outlined,
                  tone: const Color(0xFFE7A3A3),
                  label: 'Import backup',
                  onTap: _importBackup,
                ),
                _AccountRow(
                  icon: Icons.shield_outlined,
                  tone: const Color(0xFFA9D4C4),
                  label: 'Privacy',
                  onTap: () => context.push('/privacy'),
                ),
                _AccountRow(
                  icon: Icons.logout,
                  tone: const Color(0xFFE7A3A3),
                  label: 'Sign out',
                  danger: true,
                  isLast: true,
                  onTap: () =>
                      ref.read(sessionControllerProvider.notifier).logout(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Notes stay isolated to $_email.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _Stat({required final String value, required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16.8,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: _ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class const _AvatarWithEdit({
  required final UserProfile profile,
  required final bool editing,
  required final VoidCallback onToggleEditing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatar;
    return SizedBox(
      width: 89.6,
      height: 89.6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(27.2),
            child: avatar != null
                ? Image.memory(
                    decodeDataUriBytes(avatar),
                    width: 89.6,
                    height: 89.6,
                    fit: BoxFit.cover,
                    cacheWidth: (89.6 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  )
                : Container(
                    width: 89.6,
                    height: 89.6,
                    color: Color(
                      int.parse(profile.hue.substring(1), radix: 16) |
                          0xFF000000,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialsFromName(profile.name),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: Material(
              color: const Color(0xFFE7A3A3),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleEditing,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    editing ? Icons.close : Icons.edit_outlined,
                    size: 14,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _ProfileEditForm({
  required final TextEditingController nameController,
  required final TextEditingController handleController,
  required final TextEditingController bioController,
  required final String hue,
  required final String? avatar,
  required final String? photoError,
  required final ValueChanged<String> onHue,
  required final VoidCallback onPickPhoto,
  required final VoidCallback onRemovePhoto,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditField(controller: nameController, hint: 'Name'),
          const SizedBox(height: 8),
          _EditField(controller: handleController, hint: 'Handle'),
          const SizedBox(height: 8),
          _EditField(
            controller: bioController,
            hint: 'A line about you',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in profileHues)
                GestureDetector(
                  onTap: () => onHue(item),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(item.substring(1), radix: 16) | 0xFF000000,
                      ),
                      shape: BoxShape.circle,
                      border: hue == item
                          ? Border.all(color: _ink, width: 2)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: onPickPhoto, child: const Text('Photo')),
              const SizedBox(width: 4),
              TextButton(onPressed: onRemovePhoto, child: const Text('Remove')),
            ],
          ),
          if (photoError case final String error)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: const TextStyle(fontSize: 14, color: Color(0xFF7A2418)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1814),
                shape: const StadiumBorder(),
              ),
              child: const Text('Save profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class const _EditField({
  required final TextEditingController controller,
  required final String hint,
  final int maxLines = 1,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = maxLines > 1 ? 22.0 : 999.0;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class const _RowGroup({required final List<Widget> children})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.7),
        child: Column(children: children),
      ),
    );
  }
}

class const _AccountRow({
  required final IconData icon,
  required final Color tone,
  required final String label,
  required final VoidCallback onTap,
  final int? badge,
  final String? hint,
  final bool danger = false,
  final bool isLast = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56.8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: _ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w500,
                    color: danger ? const Color(0xFF7A2418) : _ink,
                  ),
                ),
              ),
              if (hint case final String hintText)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    hintText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1814),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _ink.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _PaperSkinChip({
  required final PaperSkin skin,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = paperPaletteFor(skin, Brightness.light);
    final radius = BorderRadius.circular(16);
    return Material(
      color: palette.paper,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected ? Border.all(color: palette.ink, width: 2) : null,
          ),
          child: Text(
            skin.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
