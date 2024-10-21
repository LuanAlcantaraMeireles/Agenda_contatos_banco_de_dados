import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Agenda(),
    );
  }
}

class Contato {
  final int id;
  final String nome;
  final String telefone;
  final String email;

  Contato({required this.id, required this.nome, required this.telefone, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'email': email,
    };
  }
}

class Agenda extends StatefulWidget {
  @override
  State<Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  late Database _database;
  final List<Contato> contatos = [];
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    _abrirBancoDeDados().then((value) {
      _database = value;
      _recuperarContatos();
    });
    super.initState();
  }

  Future<Database> _abrirBancoDeDados() async {
    return openDatabase(
      join(await getDatabasesPath(), 'agenda_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE contatos(id INTEGER PRIMARY KEY, nome TEXT, telefone TEXT, email TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> _recuperarContatos() async {
    final List<Map<String, dynamic>> maps = await _database.query('contatos');

    setState(() {
      contatos.clear();
      for (Map<String, dynamic> map in maps) {
        contatos.add(Contato(id: map['id'], nome: map['nome'], telefone: map['telefone'], email: map['email']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda'),
      ),
      body: ListView.builder(
        itemCount: contatos.length,
        itemBuilder: (context, index) {
          Contato contato = contatos[index];
          return GestureDetector(
            onTap: () {
              _criarEditarContato(context, contato: contato);
            },
            child: ListTile(
              title: Text(contato.nome),
              subtitle: Text('${contato.telefone} | ${contato.email}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _criarEditarContato(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _criarEditarContato(BuildContext context, {Contato? contato}) {
    nomeController.text = contato?.nome ?? '';
    telefoneController.text = contato?.telefone ?? '';
    emailController.text = contato?.email ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${contato != null ? 'Editar' : 'Criar'} Contato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: telefoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                String nome = nomeController.text;
                String telefone = telefoneController.text;
                String email = emailController.text;

                if (nome.isNotEmpty && telefone.isNotEmpty && email.isNotEmpty) {
                  if (contato != null) {
                    _atualizarContato(contato.id, nome, telefone, email);
                  } else {
                    _inserirContato(nome, telefone, email);
                  }
                  Navigator.pop(context);
                } else {
                  // Mostrar mensagem de erro
                }
              },
              child: Text('${contato != null ? 'Salvar' : 'Criar'}'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _inserirContato(String nome, String telefone, String email) async {
    await _database.insert(
      'contatos',
      Contato(id: contatos.length + 1, nome: nome, telefone: telefone, email: email).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _