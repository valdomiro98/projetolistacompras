import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Category { alimento, bebida, higiene, limpeza, outros }

extension CategoryExtension on Category {
  String get categoryName {
    switch (this) {
      case Category.alimento:
        return 'Alimentos';
      case Category.bebida:
        return 'Bebidas';
      case Category.higiene:
        return 'Higiene';
      case Category.limpeza:
        return 'Limpeza';
      case Category.outros:
        return 'Outros';
    }
  }

  String get categoryEmoji {
    switch (this) {
      case Category.alimento:
        return '🍎';
      case Category.bebida:
        return '🥤';
      case Category.higiene:
        return '🧼';
      case Category.limpeza:
        return '🧹';
      case Category.outros:
        return '📦';
    }
  }

  Color get categoryColor {
    switch (this) {
      case Category.alimento:
        return Colors.orange.shade50;
      case Category.bebida:
        return Colors.blue.shade50;
      case Category.higiene:
        return Colors.purple.shade50;
      case Category.limpeza:
        return Colors.green.shade50;
      case Category.outros:
        return Colors.grey.shade50;
    }
  }

  Color get categoryTextColor {
    switch (this) {
      case Category.alimento:
        return Colors.orange.shade800;
      case Category.bebida:
        return Colors.blue.shade800;
      case Category.higiene:
        return Colors.purple.shade800;
      case Category.limpeza:
        return Colors.green.shade800;
      case Category.outros:
        return Colors.grey.shade800;
    }
  }
}

class ItemListaCompras {
  final String? id;
  final String idLista;
  final String nome;
  final double quantidade;
  final Category categoria;
  final String? observacoes;
  final bool comprado;
  final DateTime criadoEm;
  final DateTime? compradoEm;

  ItemListaCompras({
    this.id,
    required this.idLista,
    required this.nome,
    required this.quantidade,
    required this.categoria,
    this.observacoes,
    this.comprado = false,
    DateTime? criadoEm,
    this.compradoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'idLista': idLista,
      'nome': nome,
      'quantidade': quantidade,
      'categoria': categoria.index,
      'observacoes': observacoes,
      'comprado': comprado,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'compradoEm': compradoEm != null ? Timestamp.fromDate(compradoEm!) : null,
    };
  }

  factory ItemListaCompras.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;

      try {
        if (dateValue is Timestamp) {
          return dateValue.toDate();
        } else if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is Map && dateValue['_seconds'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            (dateValue['_seconds'] as int) * 1000,
          );
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return ItemListaCompras(
      id: doc.id,
      idLista: data['idLista'] ?? '',
      nome: data['nome'] ?? '',
      quantidade: (data['quantidade'] ?? 1).toDouble(),
      categoria: Category.values[data['categoria'] ?? 0],
      observacoes: data['observacoes'],
      comprado: data['comprado'] ?? false,
      criadoEm: _parseDate(data['criadoEm']) ?? DateTime.now(),
      compradoEm: _parseDate(data['compradoEm']),
    );
  }
}