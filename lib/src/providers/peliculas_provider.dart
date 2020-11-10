import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:peliculas/src/models/pelicula_model.dart';
import 'package:peliculas/src/models/actores_model.dart';

class PeliculasProvider {
  String _apikey = 'a2d5fdddd7322d63b9489c70e75daef3';
  String _url = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popularesPage = 0;
  bool _cargando = false;

  // Configuranto stream
  List<Pelicula> _populares = new List();

  final _popularesStreamController =
      StreamController<List<Pelicula>>.broadcast();

  // Insertar peliculas al stream
  Function(List<Pelicula>) get popularesSink =>
      _popularesStreamController.sink.add;

  // Leer pelicula del stream
  Stream<List<Pelicula>> get popularesStream =>
      _popularesStreamController.stream;

  // Cerras stream
  void disposeStreams() {
    _popularesStreamController?.close();
  }

  // Optimizamos respuesta
  Future<List<Pelicula>> _procesarRespuesta(Uri url) async {
    // Llamamos la url con la respuesta
    final resp = await http.get(url);
    // Leemos la respuesta y lo convertimos a un mapa
    final decodedData = json.decode(resp.body);
    // Recorremos todas las peliculas
    final peliculas = new Peliculas.fromJsonList(decodedData['results']);

    return peliculas.items;
  }

  Future<List<Pelicula>> getEnCines() async {
    final url = Uri.https(_url, '3/movie/now_playing',
        {'api_key': _apikey, 'language': _language});

    return await _procesarRespuesta(url);
  }

  // Get populares
  Future<List<Pelicula>> getPopulares() async {
    if (_cargando) return [];
    _cargando = true;
    // Incrementamos el numero de la página
    _popularesPage++;

    final url = Uri.https(_url, '3/movie/popular', {
      'api_key': _apikey,
      'language': _language,
      'page': _popularesPage.toString()
    });
    final resp = await _procesarRespuesta(url);

    _populares.addAll(resp);
    popularesSink(_populares);
    _cargando = false;
    return resp;
  }

  Future<List<Actor>> getCast(String peliId) async {
    final url = Uri.https(_url, '3/movie/$peliId/credits',
        {'api_key': _apikey, 'language': _language});

    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final cast = new Cast.fromJsonList(decodedData['cast']);

    return cast.actores;
  }
}
