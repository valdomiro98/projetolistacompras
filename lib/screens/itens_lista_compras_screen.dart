import 'package:flutter/material.dart';
import '../models/lista_compras_model.dart';
import '../models/item_lista_compras_model.dart';
import '../services/lista_compras_service.dart';
import 'criar_editar_item_screen.dart';

class ItensListaComprasScreen extends StatefulWidget {
  final ListaCompras listaCompras;

  const ItensListaComprasScreen({super.key, required this.listaCompras});

  @override
  State<ItensListaComprasScreen> createState() => _ItensListaComprasScreenState();
}

class _ItensListaComprasScreenState extends State<ItensListaComprasScreen> {
  final ListaComprasService _listaComprasService = ListaComprasService();
  late bool listaArquivada;
  
  Category? _categoriaFiltro;
  final List<Category> _todasCategorias = Category.values;
  
  @override
  void initState() {
    super.initState();
    listaArquivada = !widget.listaCompras.ativa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.listaCompras.nome),
            if (listaArquivada)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Arquivada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!listaArquivada)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: () => _confirmarLimparTodosItens(context),
              tooltip: 'Limpar todos os itens',
            ),
        ],
      ),
      body: Column(
        children: [
          if (listaArquivada)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lista arquivada - Modo somente leitura',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: _categoriaFiltro == null,
                      onSelected: (selected) {
                        setState(() {
                          _categoriaFiltro = null;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green,
                    ),
                  ),
                  
                  ..._todasCategorias.map((categoria) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(categoria.categoryEmoji),
                            const SizedBox(width: 4),
                            Text(
                              categoria.categoryName,
                              style: TextStyle(
                                fontWeight: _categoriaFiltro == categoria ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        selected: _categoriaFiltro == categoria,
                        onSelected: (selected) {
                          setState(() {
                            _categoriaFiltro = selected ? categoria : null;
                          });
                        },
                        backgroundColor: categoria.categoryColor,
                        selectedColor: categoria.categoryColor.withOpacity(0.7),
                        checkmarkColor: categoria.categoryTextColor,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ItemListaCompras>>(
              stream: _listaComprasService.obterItens(widget.listaCompras.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                
                if (snapshot.hasError) {
                  return _buildErrorState('Erro ao carregar itens');
                }

                if (!snapshot.hasData) {
                  return _buildEmptyState();
                }

                final itens = snapshot.data!;
                
                if (itens.isEmpty) {
                  return _buildEmptyState();
                }
                
                final itensFiltrados = _categoriaFiltro == null
                    ? itens
                    : itens.where((item) => item.categoria == _categoriaFiltro).toList();
                
                return _buildListaItens(itensFiltrados);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !listaArquivada
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CriarEditarItemScreen(
                      idLista: widget.listaCompras.id!,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando itens...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String mensagem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final mensagem = _categoriaFiltro != null
        ? 'Nenhum item na categoria ${_categoriaFiltro!.categoryName}'
        : listaArquivada 
            ? 'Esta lista foi arquivada sem itens'
            : 'Adicione itens usando o botão +';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            listaArquivada ? Icons.archive_outlined : Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            listaArquivada ? 'Lista arquivada vazia' : 'Lista vazia',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaItens(List<ItemListaCompras> itens) {
    itens.sort((a, b) {
      if (a.comprado != b.comprado) {
        return a.comprado ? 1 : -1;
      }
      return a.criadoEm.compareTo(b.criadoEm);
    });

    return ListView.builder(
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        return _buildItemTile(item);
      },
    );
  }

  Widget _buildItemTile(ItemListaCompras item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildCheckbox(item),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  item.nome,
                  style: TextStyle(
                    decoration: item.comprado 
                        ? TextDecoration.lineThrough 
                        : TextDecoration.none,
                    color: item.comprado 
                        ? Colors.grey 
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: item.categoria.categoryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(item.categoria.categoryEmoji),
                  const SizedBox(width: 4),
                  Text(
                    item.categoria.categoryName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.categoria.categoryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantidade: ${item.quantidade}'),
            if (item.observacoes != null && item.observacoes!.isNotEmpty)
              Text(
                '${item.observacoes}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: _buildTrailingButtons(item),
      ),
    );
  }

  Widget _buildCheckbox(ItemListaCompras item) {
    if (listaArquivada) {
      return Checkbox(
        value: item.comprado,
        onChanged: null,
        fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (item.comprado) {
              return Colors.grey;
            }
            return null;
          },
        ),
      );
    } else {
      return Checkbox(
        value: item.comprado,
        onChanged: (value) {
          _listaComprasService.marcarComprado(
            item.id!, 
            value!, 
            widget.listaCompras.id!
          );
        },
      );
    }
  }

  Widget _buildTrailingButtons(ItemListaCompras item) {
    if (listaArquivada) {
      return const SizedBox(width: 40);
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CriarEditarItemScreen(
                    idLista: widget.listaCompras.id!,
                    item: item,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () {
              _confirmarExcluirItem(item);
            },
          ),
        ],
      );
    }
  }

  void _confirmarLimparTodosItens(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todos os itens?'),
        content: const Text('Todos os itens da lista serão removidos. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _listaComprasService.excluirTodosItens(widget.listaCompras.id!);
              Navigator.pop(context);
            },
            child: const Text('Limpar Tudo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmarExcluirItem(ItemListaCompras item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir item?'),
        content: Text('Deseja excluir "${item.nome}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _listaComprasService.excluirItem(
                item.id!, 
                widget.listaCompras.id!
              );
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}