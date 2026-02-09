import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lista_compras_model.dart';
import '../models/item_lista_compras_model.dart';

class ListaComprasService {
  final CollectionReference _listasComprasCollection =
      FirebaseFirestore.instance.collection('listas_compras');
  final CollectionReference _itensListaComprasCollection =
      FirebaseFirestore.instance.collection('itens_lista_compras');

  Future<void> criarLista(ListaCompras lista) {
    return _listasComprasCollection.add(lista.toMap());
  }

  Stream<List<ListaCompras>> obterListasAtivas() {
    return _listasComprasCollection
        .orderBy('criadaEm', descending: true)
        .snapshots()
        .handleError((error) {
          return Stream.value([]);
        })
        .map((snapshot) {
          try {
            final todasListas = snapshot.docs.map((doc) {
              return ListaCompras.fromFirestore(doc);
            }).toList();

            return todasListas.where((lista) => lista.ativa).toList();
          } catch (e) {
            return [];
          }
        });
  }

  Stream<List<ListaCompras>> obterListasArquivadas() {
    return _listasComprasCollection
        .where('ativa', isEqualTo: false)
        .orderBy('arquivadaEm', descending: true)
        .snapshots()
        .handleError((error) {
          return Stream.value([]);
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              return ListaCompras.fromFirestore(doc);
            }).toList();
          } catch (e) {
            return [];
          }
        });
  }

  Future<void> editarLista(ListaCompras lista) {
    return _listasComprasCollection.doc(lista.id).update(lista.toMap());
  }

  Future<void> arquivarLista(String listaId) async {
    try {
      await _listasComprasCollection.doc(listaId).update({
        'ativa': false,
        'arquivadaEm': Timestamp.now(),
      });
    } catch (e) {
      try {
        await _listasComprasCollection.doc(listaId).update({
          'ativa': false,
          'arquivadaEm': FieldValue.serverTimestamp(),
        });
      } catch (e2) {
        rethrow;
      }
    }
  }

  Future<void> desarquivarLista(String listaId) async {
    try {
      await _listasComprasCollection.doc(listaId).update({
        'ativa': true,
        'arquivadaEm': null,
      });
    } catch (e) {
      try {
        await _listasComprasCollection.doc(listaId).update({
          'ativa': true,
        });
      } catch (e2) {
        rethrow;
      }
    }
  }

  Future<void> excluirLista(String listaId) async {
    try {
      await _excluirTodosItensDaLista(listaId);
      await _listasComprasCollection.doc(listaId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> adicionarItem(ItemListaCompras item) async {
    try {
      await _itensListaComprasCollection.add(item.toMap());
      await _atualizarContagemItens(item.idLista, 1);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ItemListaCompras>> obterItens(String idLista) {
    try {
      return _itensListaComprasCollection
          .where('idLista', isEqualTo: idLista)
          .snapshots()
          .handleError((error) {
            return Stream.value([]);
          })
          .map((snapshot) {
            try {
              if (snapshot.docs.isEmpty) {
                return <ItemListaCompras>[];
              }

              final itens = snapshot.docs
                  .map((doc) {
                    try {
                      return ItemListaCompras.fromFirestore(doc);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((item) => item != null)
                  .cast<ItemListaCompras>()
                  .toList();

              itens.sort((a, b) {
                if (a.comprado != b.comprado) {
                  return a.comprado ? 1 : -1;
                }
                return a.criadoEm.compareTo(b.criadoEm);
              });

              return itens;
            } catch (e) {
              return [];
            }
          });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> editarItem(ItemListaCompras item) async {
    try {
      await _itensListaComprasCollection.doc(item.id).update(item.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> marcarComprado(
    String idItem,
    bool comprado,
    String idLista,
  ) async {
    try {
      await _itensListaComprasCollection.doc(idItem).update({
        'comprado': comprado,
        'compradoEm': comprado ? Timestamp.now() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> excluirItem(String idItem, String idLista) async {
    try {
      await _itensListaComprasCollection.doc(idItem).delete();
      await _atualizarContagemItens(idLista, -1);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> excluirTodosItens(String idLista) async {
    try {
      await _excluirTodosItensDaLista(idLista);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _excluirTodosItensDaLista(String idLista) async {
    try {
      final querySnapshot = await _itensListaComprasCollection
          .where('idLista', isEqualTo: idLista)
          .get();

      int contagem = 0;
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
        contagem++;
      }

      if (contagem > 0) {
        await _atualizarContagemItens(idLista, -contagem);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _atualizarContagemItens(String idLista, int alterar) async {
    try {
      final doc = await _listasComprasCollection.doc(idLista).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        int contagemAtual = (data['contagemItens'] as int?) ?? 0;

        contagemAtual = contagemAtual + alterar;
        if (contagemAtual < 0) contagemAtual = 0;

        await _listasComprasCollection.doc(idLista).update({
          'contagemItens': contagemAtual,
        });
      }
    } catch (e) {
    }
  }
}