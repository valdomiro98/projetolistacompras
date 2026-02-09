import 'package:flutter/material.dart';
import '../models/item_lista_compras_model.dart';
import '../services/lista_compras_service.dart';

class CriarEditarItemScreen extends StatefulWidget {
  final String idLista;
  final ItemListaCompras? item;

  const CriarEditarItemScreen({super.key, required this.idLista, this.item});

  @override
  State<CriarEditarItemScreen> createState() => _CriarEditarItemScreenState();
}

class _CriarEditarItemScreenState extends State<CriarEditarItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListaComprasService _listaComprasService = ListaComprasService();

  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _observacoesController;

  Category _categoriaSelecionada = Category.alimento;

  bool get estaSendoEditado => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item?.nome ?? '');
    _quantidadeController = TextEditingController(
      text: widget.item?.quantidade.toString() ?? '1',
    );
    _observacoesController = TextEditingController(
      text: widget.item?.observacoes ?? '',
    );
    _categoriaSelecionada = widget.item?.categoria ?? Category.alimento;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _salvarItem() {
    if (_formKey.currentState!.validate()) {
      final novoItem = ItemListaCompras(
        id: widget.item?.id,
        idLista: widget.idLista,
        nome: _nomeController.text,
        quantidade: double.parse(_quantidadeController.text),
        categoria: _categoriaSelecionada,
        observacoes: _observacoesController.text.isEmpty
            ? null
            : _observacoesController.text,
      );

      if (estaSendoEditado) {
        _listaComprasService.editarItem(novoItem).then((_) {
          Navigator.of(context).pop();
        });
      } else {
        _listaComprasService.adicionarItem(novoItem).then((_) {
          Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(estaSendoEditado ? 'Editar Item' : 'Novo Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                  labelText: 'Nome do item*',
                  hintText: 'Ex: Pão de forma, ovo, manteiga...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o nome do item.';
                  }
                  return null;
                },
                autofocus: !estaSendoEditado,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite a quantidade.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Quantidade inválida.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Category>(
                      value: _categoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria*',
                        border: OutlineInputBorder(),
                      ),
                      items: Category.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Text(category.categoryEmoji),
                              const SizedBox(width: 8),
                              Text(category.categoryName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSelecionada = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma categoria.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Ex: Marca, peso, sabor...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvarItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    estaSendoEditado ? 'Atualizar' : 'Adicionar à Lista',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}