import 'dart:convert'; // Pour le traitement JSON
import 'package:flutter/material.dart'; // Flutter UI
import 'package:http/http.dart' as http; // Package HTTP pour les requêtes API

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TauxPage(),
    );
  }
}

// Classe principale pour gérer l'interface des taux
class TauxPage extends StatefulWidget {
  @override
  _TauxPageState createState() => _TauxPageState();
}

class _TauxPageState extends State<TauxPage> {
  Map<String, dynamic>? taux; // Variable pour stocker les taux récupérés
  bool isLoading = false; // Indique si une requête est en cours

  // URL de base pour accéder à l'API
  final String baseUrl = 'http://localhost:5000/taux';

  // Fonction pour récupérer les taux depuis l'API
  Future<void> fetchTaux() async {
    setState(() {
      isLoading = true; // Active le mode chargement
    });

    try {
      final response = await http.get(Uri.parse(baseUrl)); // Requête GET
      if (response.statusCode == 200) {
        taux = jsonDecode(response.body); // Décodage du JSON
      } else {
        throw Exception('Erreur lors de la récupération des taux');
      }
    } catch (e) {
      print(e); // Affiche les erreurs dans la console
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Impossible de récupérer les taux.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Désactive le mode chargement
      });
    }
  }

  // Fonction pour rafraîchir les taux via une autre requête API
  Future<void> refreshTaux() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/refresh')); // Requête GET pour rafraîchir
      if (response.statusCode == 200) {
        await fetchTaux(); // Recharge les taux après le rafraîchissement
      } else {
        throw Exception('Erreur lors du rafraîchissement des taux');
      }
    } catch (e) {
      print(e); // Affiche les erreurs dans la console
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Impossible de rafraîchir les taux.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTaux(); // Charge les taux lors de l'ouverture de la page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convertisseur de devises'),
        centerTitle: true, // Centre le titre dans l'AppBar
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Indicateur de chargement
          : taux == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: fetchTaux, // Bouton pour charger les taux
                    child: Text('Charger les taux'),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: taux!.length, // Nombre de taux
                        itemBuilder: (context, index) {
                          final key = taux!.keys.elementAt(index); // Clé (devise)
                          final value = taux![key]; // Valeur (taux)
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8), // Marge autour des cartes
                            child: ListTile(
                              leading: Icon(Icons.monetization_on), // Icône de devise
                              title: Text('$key'), // Nom de la devise
                              subtitle: Text('Taux : $value'), // Taux de la devise
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: refreshTaux, // Bouton pour rafraîchir les taux
                      child: Text('Rafraîchir les taux'),
                    ),
                  ],
                ),
    );
  }
}
