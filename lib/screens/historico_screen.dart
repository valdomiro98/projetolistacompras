import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lista_compras_model.dart';
import '../services/lista_compras_service.dart';
import 'itens_lista_compras_screen.dart';

class HistoricoScreen extends StatefulWidget {
  final ListaComprasService listaComprasService;

  const HistoricoScreen({super.key, required this.listaComprasService});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListaCompras>>(
      stream: widget.listaComprasService.obterListasArquivadas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final listas = snapshot.data!;
        return ListView.builder(
          itemCount: listas.length,
          itemBuilder: (context, index) {
            final lista = listas[index];
            return _buildItemHistorico(lista, context);
          },
        );
      },
    );
  }

  Widget _buildItemHistorico(ListaCompras lista, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey.shade50,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lista.contexto.contextoNome,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              '${lista.contagemItens} itens',
              style: const TextStyle(fontSize: 12),
            ),
            if (lista.arquivadaEm != null)
              Text(
                'Data de arquivamento: ${_formatDateTime(lista.arquivadaEm!)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, lista, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'desarquivar',
              child: Row(
                children: [
                  Icon(Icons.unarchive, size: 20),
                  SizedBox(width: 8),
                  Text('Desarquivar'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Histórico vazio',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Listas arquivadas aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  Future<void> _handleMenuAction(
    String action,
    ListaCompras lista,
    BuildContext context,
  ) async {
    switch (action) {
      case 'desarquivar':
        await _desarquivarComTimeout(lista, context);
        break;
      case 'excluir':
        await _confirmarExcluir(lista, context);
        break;
    }
  }

  Future<void> _desarquivarComTimeout(
    ListaCompras lista,
    BuildContext context,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desarquivar lista?'),
        content: Text('A lista "${lista.nome}" será restaurada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desarquivar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final scaffold = ScaffoldMessenger.of(context);

    try {
      await widget.listaComprasService.desarquivarLista(lista.id!);

      scaffold.showSnackBar(
        SnackBar(
          content: Text('"${lista.nome}" desarquivada.'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {});
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarExcluir(
    ListaCompras lista,
    BuildContext context,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista de compras?'),
        content: Text(
          'A lista de compras "${lista.nome}" e todos os seus itens serão excluídos permanentemente.',
        ),
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
        await widget.listaComprasService.excluirLista(lista.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${lista.nome}" excluída.')),
          );
          setState(() {});
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }
}