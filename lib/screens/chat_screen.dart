import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String receptorUid;
  final String receptorNom;

  const ChatScreen({
    Key? key,
    required this.receptorUid,
    required this.receptorNom,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _missatgeController = TextEditingController();
  final String uidActual = FirebaseAuth.instance.currentUser!.uid;

  String? _meuAvatar;
  String? _receptorAvatar;

  String get conversaId {
    return uidActual.compareTo(widget.receptorUid) < 0
        ? '${uidActual}_${widget.receptorUid}'
        : '${widget.receptorUid}_$uidActual';
  }

  @override
  void initState() {
    super.initState();
    _carregarAvatars();
  }

  Future<void> _carregarAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meuAvatar = prefs.getString('avatar_$uidActual');
      _receptorAvatar = prefs.getString('avatar_${widget.receptorUid}');
    });
  }

  void enviarMissatge() async {
    final text = _missatgeController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('xats')
        .doc(conversaId)
        .collection('missatges')
        .add({
      'text': text,
      'uid': uidActual,
      'timestamp': Timestamp.now(),
    });

    _missatgeController.clear();
  }

  Future<void> _eliminarMissatge(String missatgeId) async {
    await FirebaseFirestore.instance
        .collection('xats')
        .doc(conversaId)
        .collection('missatges')
        .doc(missatgeId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (_receptorAvatar != null && _receptorAvatar!.isNotEmpty)
                  ? FileImage(File(_receptorAvatar!))
                  : null,
              backgroundColor: Colors.grey[400],
              child: (_receptorAvatar == null || _receptorAvatar!.isEmpty)
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.receptorNom),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('xats')
                  .doc(conversaId)
                  .collection('missatges')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final missatges = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: missatges.length,
                  itemBuilder: (context, index) {
                    final missatge = missatges[index];
                    final esMeu = missatge['uid'] == uidActual;
                    final text = missatge['text'] ?? '';
                    final timestamp = (missatge['timestamp'] as Timestamp).toDate();
                    final hora =
                        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onLongPress: () {
                        if (esMeu) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Eliminar missatge'),
                                content: const Text('Vols eliminar aquest missatge?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel·la'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await _eliminarMissatge(missatge.id);
                                    },
                                    child: const Text('Elimina'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Align(
                        alignment: esMeu ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: esMeu
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!esMeu)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: (_receptorAvatar != null && _receptorAvatar!.isNotEmpty)
                                      ? FileImage(File(_receptorAvatar!))
                                      : null,
                                  backgroundColor: Colors.grey[400],
                                  child: (_receptorAvatar == null || _receptorAvatar!.isEmpty)
                                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: esMeu
                                      ? Colors.blueAccent
                                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(esMeu ? 16 : 0),
                                    bottomRight: Radius.circular(esMeu ? 0 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: esMeu ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hora,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: esMeu ? Colors.white70 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (esMeu)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: (_meuAvatar != null && _meuAvatar!.isNotEmpty)
                                      ? FileImage(File(_meuAvatar!))
                                      : null,
                                  backgroundColor: Colors.grey[400],
                                  child: (_meuAvatar == null || _meuAvatar!.isEmpty)
                                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _missatgeController,
                    decoration: InputDecoration(
                      hintText: 'Escriu un missatge...',
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: enviarMissatge,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFEDA75),
                          Color(0xFFD62976),
                          Color(0xFF4F5BD5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
