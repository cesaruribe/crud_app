import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- MODELO ---
part 'main.g.dart';

@collection
class Persona {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late int cedula;

  late String nombre;
  late String telefono;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de almacenamiento según plataforma
  String dir = "";
  if (!kIsWeb) {
    final directory = await getApplicationDocumentsDirectory();
    dir = directory.path;
  }

  final isar = await Isar.open(
    [PersonaSchema],
    directory: dir,
  );

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: CrudPage(isar: isar),
    );
  }
}

class CrudPage extends StatefulWidget {
  final Isar isar;
  const CrudPage({super.key, required this.isar});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  List<Persona> personas = [];
  final _cedulaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refrescarLista();
  }

  Future<void> _refrescarLista() async {
    final lista = await widget.isar.personas.where().findAll();
    setState(() => personas = lista);
  }

  Future<void> _guardar(Persona? personaExistente) async {
    final nuevaPersona = personaExistente ?? Persona();
    nuevaPersona.cedula = int.parse(_cedulaCtrl.text);
    nuevaPersona.nombre = _nombreCtrl.text;
    nuevaPersona.telefono = _telCtrl.text;

    await widget.isar.writeTxn(() async {
      await widget.isar.personas.put(nuevaPersona);
    });

    _cedulaCtrl.clear();
    _nombreCtrl.clear();
    _telCtrl.clear();
    if (mounted) Navigator.pop(context);
    _refrescarLista();
  }

  void _mostrarFormulario(Persona? persona) {
    if (persona != null) {
      _cedulaCtrl.text = persona.cedula.toString();
      _nombreCtrl.text = persona.nombre;
      _telCtrl.text = persona.telefono;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _cedulaCtrl,
                decoration: const InputDecoration(labelText: 'Cédula'),
                keyboardType: TextInputType.number),
            TextField(
                controller: _nombreCtrl,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: _telCtrl,
                maxLength: 20,
                decoration: const InputDecoration(labelText: 'Teléfono')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => _guardar(persona),
                child: const Text("Guardar")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CRUD Isar Multiplataforma")),
      body: ListView.builder(
        itemCount: personas.length,
        itemBuilder: (context, index) {
          final p = personas[index];
          return ListTile(
            title: Text(p.nombre),
            subtitle: Text("C.I: ${p.cedula} - Tel: ${p.telefono}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _mostrarFormulario(p)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await widget.isar
                          .writeTxn(() => widget.isar.personas.delete(p.id));
                      _refrescarLista();
                    }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
