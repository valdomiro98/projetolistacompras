import 'package:flutter/material.dart';
import '../models/lista_compras_model.dart';
import '../services/lista_compras_service.dart';

class CriarEditarListaComprasScreen extends StatefulWidget {
  final ListaCompras? lista;

  const CriarEditarListaComprasScreen({super.key, this.lista});

  @override
  State<CriarEditarListaComprasScreen> createState() => _CriarEditarListaComprasScreenState();
}

class _CriarEditarListaComprasScreenState extends State<CriarEditarListaComprasScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListaComprasService _listaComprasService = ListaComprasService();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  ListaContexto _contextoSelecionado = ListaContexto.supermercado;

  bool get isEditing => widget.lista != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.lista?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.lista?.descricao ?? '');
    _contextoSelecionado = widget.lista?.contexto ?? ListaContexto.supermercado;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _saveList() {
    if (_formKey.currentState!.validate()) {
      final newList = ListaCompras(
        id: widget.lista?.id,
        nome: _nomeController.text,
        contexto: _contextoSelecionado,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        ativa: widget.lista?.ativa ?? true,
        contagemItens: widget.lista?.contagemItens ?? 0,
        criadaEm: widget.lista?.criadaEm,
      );

      if (isEditing) {
        _listaComprasService.editarLista(newList).then((_) {
          Navigator.of(context).pop(true);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $error')),
          );
        });
      } else {
        _listaComprasService.criarLista(newList).then((_) {
          Navigator.of(context).pop(true);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar: $error')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Lista' : 'Nova Lista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Lista*',
                  hintText: 'Ex: Compras do Mês...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite um nome para a lista.';
                  }
                  if (value.length < 3) {
                    return 'O nome deve ter pelo menos 3 caracteres.';
                  }
                  return null;
                },
                autofocus: !isEditing,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<ListaContexto>(
                value: _contextoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Contexto*',
                  border: OutlineInputBorder(),
                ),
                items: ListaContexto.values.map((contexto) {
                  return DropdownMenuItem(
                    value: contexto,
                    child: Row(
                      children: [
                        Text(contexto.contextoEmoji),
                        const SizedBox(width: 8),
                        Text(contexto.contextoNome),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _contextoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Ingredientes para bolo...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveList,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEditing ? 'Atualizar' : 'Criar Lista'),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}