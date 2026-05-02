import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../utils/app_theme.dart';
import 'room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();

    final success = await roomProvider.joinRoom(
      _codeController.text.trim().toUpperCase(),
      auth.user!,
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
      appBar: AppBar(title: const Text('Join Room')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter invite code',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask your host for the 6-character code',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'XXXXXX',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) {
                      return 'Code must be 6 characters';
                    }
                    return null;
                  },
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
                  onPressed: roomProvider.isLoading ? null : _join,
                  child: roomProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Join Room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
