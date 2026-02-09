import 'package:flutter/material.dart';
import '../models/lista_compras_model.dart';
import '../services/lista_compras_service.dart';
import 'criar_editar_lista_compras_screen.dart';
import 'itens_lista_compras_screen.dart';
import 'historico_screen.dart';

class ListasComprasScreen extends StatefulWidget {
  const ListasComprasScreen({super.key});

  @override
  State<ListasComprasScreen> createState() => _ListasComprasScreenState();
}

class _ListasComprasScreenState extends State<ListasComprasScreen> {
  final ListaComprasService _listaComprasService = ListaComprasService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Compras'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: _TabTextStyle(text: 'LISTAS', tabIndex: 0),
              ),
              Tab(
                child: _TabTextStyle(text: 'HISTÓRICO', tabIndex: 1),
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        body: TabBarView(
          children: [
            _ListasAtivasTab(),
            HistoricoScreen(listaComprasService: _listaComprasService),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CriarEditarListaComprasScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class _TabTextStyle extends StatefulWidget {
  final String text;
  final int tabIndex;

  const _TabTextStyle({required this.text, required this.tabIndex});

  @override
  State<_TabTextStyle> createState() => _TabTextStyleState();
}

class _TabTextStyleState extends State<_TabTextStyle> {
  @override
  Widget build(BuildContext context) {
    final isSelected = DefaultTabController.of(context)?.index == widget.tabIndex;
    
    return Text(
      widget.text,
      style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ListasAtivasTab extends StatefulWidget {
  const _ListasAtivasTab();

  @override
  State<_ListasAtivasTab> createState() => __ListasAtivasTabState();
}

class __ListasAtivasTabState extends State<_ListasAtivasTab> {
  final ListaComprasService _listaComprasService = ListaComprasService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListaCompras>>(
      stream: _listaComprasService.obterListasAtivas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'Nenhuma lista disponível',
            'Crie uma nova lista usando o botão +'
          );
        }

        final listas = snapshot.data!;
        return ListView.builder(
          itemCount: listas.length,
          itemBuilder: (context, index) {
            final lista = listas[index];
            return _buildItemLista(lista);
          },
        );
      },
    );
  }

  Widget _buildItemLista(ListaCompras lista) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContextoColor(lista.contexto),
          child: Text(
            lista.contexto.contextoEmoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          lista.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lista.contexto.contextoNome,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${lista.contagemItens} itens',
              style: const TextStyle(fontSize: 12),
            ),
            if (lista.descricao != null && lista.descricao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  lista.descricao!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Data de criação: ${_formatDateTime(lista.criadaEm)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, lista),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'arquivar',
              child: Row(
                children: [
                  Icon(Icons.archive, size: 20),
                  SizedBox(width: 8),
                  Text('Arquivar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'excluir',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItensListaComprasScreen(listaCompras: lista),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String titulo, String subtitulo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            titulo,
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
              subtitulo,
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

  Color _getContextoColor(ListaContexto contexto) {
    switch (contexto) {
      case ListaContexto.supermercado:
        return Colors.green.shade50;
      case ListaContexto.feira:
        return Colors.lightGreen.shade50;
      case ListaContexto.padaria:
        return Colors.orange.shade50;
      case ListaContexto.outros:
        return Colors.grey.shade50;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateDay = DateTime(date.year, date.month, date.day);
    
    String datePart;
    
    if (dateDay == today) {
      datePart = 'Hoje';
    } else if (dateDay == yesterday) {
      datePart = 'Ontem';
    } else if (now.difference(date).inDays < 7) {
      final days = now.difference(date).inDays;
      datePart = 'há $days dias';
    } else {
      datePart = 'em ${date.day}/${date.month}/${date.year}';
    }
    
    final timePart = 'às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return '$datePart $timePart';
  }

  Future<void> _handleMenuAction(String action, ListaCompras lista) async {
    switch (action) {
      case 'editar':
        await _editarLista(context, lista);
        break;
      case 'arquivar':
        await _confirmarArquivar(context, lista);
        break;
      case 'excluir':
        await _confirmarExcluir(context, lista);
        break;
    }
  }

  Future<void> _editarLista(BuildContext context, ListaCompras lista) async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CriarEditarListaComprasScreen(lista: lista),
      ),
    );

    if (resultado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${lista.nome}" atualizada')),
      );
    }
  }

  Future<void> _confirmarArquivar(BuildContext context, ListaCompras lista) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar lista?'),
        content: Text('A lista "${lista.nome}" será armazenada no histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _listaComprasService.arquivarLista(lista.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${lista.nome}" arquivada.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao arquivar: $e.')),
        );
      }
    }
  }

  Future<void> _confirmarExcluir(BuildContext context, ListaCompras lista) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista?'),
        content: Text('A lista "${lista.nome}" e todos os seus itens serão excluídos permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _listaComprasService.excluirLista(lista.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A "${lista.nome}" foi excluída.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e.')),
        );
      }
    }
  }
}