import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

/// Модель заметки. Флаг [isImportant] хранит статус «важная».
class Note {
  Note({
    required this.id,
    required this.text,
    this.isImportant = false,
  });

  final int id;
  String text;
  bool isImportant;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final List<Note> _notes = [];
  int _nextId = 1;

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _saveNote() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showMessage('Введите текст заметки');
      return;
    }
    setState(() {
      _notes.add(Note(id: _nextId++, text: text));
      _controller.clear();
    });
  }

  // Одинарное нажатие — просмотр полного текста.
  void _openNote(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NoteDetailsPage(note: _notes[index]),
      ),
    );
  }

  // Двойное нажатие — отметить заметку как важную (или снять отметку).
  void _toggleImportant(int index) {
    final note = _notes[index];
    setState(() {
      note.isImportant = !note.isImportant;
    });
    _showMessage(
      note.isImportant
          ? 'Заметка отмечена как важная'
          : 'Заметка больше не важная',
    );
  }

  // Долгое нажатие — редактирование заметки.
  Future<void> _editNote(int index) async {
    _editController.text = _notes[index].text;
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать заметку'),
          content: TextField(
            controller: _editController,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Текст заметки',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _editController,
              builder: (context, value, child) {
                return FilledButton(
                  onPressed: value.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, value.text.trim()),
                  child: const Text('Сохранить'),
                );
              },
            ),
          ],
        );
      },
    );
    if (newText != null && newText.isNotEmpty) {
      setState(() {
        _notes[index].text = newText;
      });
      _showMessage('Заметка обновлена');
    }
  }

  // Свайп вправо — снять статус «важная».
  void _unmarkImportant(int index) {
    final note = _notes[index];
    if (!note.isImportant) {
      _showMessage('Заметка не отмечена как важная');
      return;
    }
    setState(() {
      note.isImportant = false;
    });
    _showMessage('Статус «важная» снят');
  }

  // Свайп влево — удаление заметки.
  void _deleteNote(Note note) {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index == -1) return;

    setState(() {
      _notes.removeAt(index);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Заметка удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () {
              setState(() {
                _notes.insert(
                  index > _notes.length ? _notes.length : index,
                  note,
                );
              });
            },
          ),
        ),
      );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Новая заметка',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveNote,
                child: const Text('Сохранить'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Нажмите — просмотр · двойное нажатие — важная · '
              'долгое нажатие — редактирование · свайп влево — удалить · '
              'свайп вправо — снять «важную»',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(child: Text('Заметок пока нет'))
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.horizontal,
                          background: _swipeBackground(
                            color: Colors.green,
                            icon: Icons.star_border,
                            label: 'Снять «важную»',
                            alignment: Alignment.centerLeft,
                          ),
                          secondaryBackground: _swipeBackground(
                            color: Colors.red,
                            icon: Icons.delete,
                            label: 'Удалить',
                            alignment: Alignment.centerRight,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Свайп вправо: не удаляем, а снимаем статус.
                              _unmarkImportant(index);
                              return false;
                            }
                            return true;
                          },
                          onDismissed: (direction) => _deleteNote(note),
                          child: GestureDetector(
                            onTap: () => _openNote(index),
                            onDoubleTap: () => _toggleImportant(index),
                            onLongPress: () => _editNote(index),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: note.isImportant
                                  ? Colors.amber.shade100
                                  : theme.colorScheme.surface,
                              child: ListTile(
                                leading: note.isImportant
                                    ? const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      )
                                    : null,
                                title: Text(
                                  note.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: note.isImportant
                                    ? const Text('Важная заметка')
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран просмотра полного текста выбранной заметки.
class NoteDetailsPage extends StatelessWidget {
  const NoteDetailsPage({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметка'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isImportant) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Важная заметка',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              note.text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
