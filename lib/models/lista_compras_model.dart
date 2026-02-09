import 'package:cloud_firestore/cloud_firestore.dart';

enum ListaContexto { supermercado, feira, padaria, outros }

extension ListaContextoExtension on ListaContexto {
  String get contextoNome {
    switch (this) {
      case ListaContexto.supermercado:
        return 'Supermercado';
      case ListaContexto.feira:
        return 'Feira';
      case ListaContexto.padaria:
        return 'Padaria';
      case ListaContexto.outros:
        return 'Outros';
    }
  }

  String get contextoEmoji {
    switch (this) {
      case ListaContexto.supermercado:
        return '🛒';
      case ListaContexto.feira:
        return '🥦';
      case ListaContexto.padaria:
        return '🥐';
      case ListaContexto.outros:
        return '📋';
    }
  }
}

class ListaCompras {
  final String? id;
  final String nome;
  final DateTime criadaEm;
  final bool ativa;
  final int contagemItens;
  final ListaContexto contexto;
  final String? descricao;
  final DateTime? arquivadaEm;

  ListaCompras({
    this.id,
    required this.nome,
    DateTime? criadaEm,
    this.ativa = true,
    this.contagemItens = 0,
    this.contexto = ListaContexto.supermercado,
    this.descricao,
    this.arquivadaEm,
  }) : criadaEm = criadaEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'criadaEm': Timestamp.fromDate(criadaEm),
      'ativa': ativa,
      'contagemItens': contagemItens,
      'contexto': contexto.index,
      'descricao': descricao,
      'arquivadaEm': arquivadaEm != null
          ? Timestamp.fromDate(arquivadaEm!)
          : null,
    };
  }

  factory ListaCompras.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;

      try {
        if (dateValue is Timestamp) {
          return dateValue.toDate();
        } else if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is Map) {
          if (dateValue['_seconds'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              (dateValue['_seconds'] as int) * 1000,
            );
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return ListaCompras(
      id: doc.id,
      nome: data['nome'] ?? 'Nova Lista',
      criadaEm: _parseDate(data['criadaEm']) ?? DateTime.now(),
      ativa: data['ativa'] ?? true,
      contagemItens: data['contagemItens'] ?? 0,
      contexto: ListaContexto.values[data['contexto'] ?? 0],
      descricao: data['descricao'],
      arquivadaEm: _parseDate(data['arquivadaEm']),
    );
  }

  ListaCompras copyWith({
    String? nome,
    bool? ativa,
    int? contagemItens,
    ListaContexto? contexto,
    String? descricao,
    DateTime? arquivadaEm,
  }) {
    return ListaCompras(
      id: id,
      nome: nome ?? this.nome,
      criadaEm: criadaEm,
      ativa: ativa ?? this.ativa,
      contagemItens: contagemItens ?? this.contagemItens,
      contexto: contexto ?? this.contexto,
      descricao: descricao ?? this.descricao,
      arquivadaEm: arquivadaEm ?? this.arquivadaEm,
    );
  }
}