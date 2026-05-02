import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _selectedGenres = [];
  String _selectedMood = 'chill';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();

    final success = await roomProvider.createRoom(
      hostUid: auth.user!.uid,
      hostName: auth.user!.displayName,
      name: _nameController.text.trim(),
      preferredGenres: _selectedGenres,
      currentMood: _selectedMood,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(room: roomProvider.currentRoom!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    prefixIcon: Icon(Icons.headphones),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Room name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Starting Mood',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.moodOptions.map((mood) {
                    final selected = _selectedMood == mood;
                    return ChoiceChip(
                      label: Text(mood),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedMood = mood),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : AppColors.onSurface,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preferred Genres (optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.genreOptions.map((genre) {
                    final selected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(genre),
                      selected: selected,
                      onSelected: (on) => setState(() {
                        if (on) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      }),
                      selectedColor: AppColors.primary.withAlpha(50),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.onSurface,
                      ),
                      backgroundColor: AppColors.surfaceVariant,
                    );
                  }).toList(),
                ),
                if (roomProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    roomProvider.errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: roomProvider.isLoading ? null : _create,
                  child: roomProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Create Room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
