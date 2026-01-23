import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appdata.dart'; 

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Consumer<AppData>(
            builder: (context, appData, _) {
              if (appData.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }   
              if (appData.error.isNotEmpty) {
                return Center(child: Text(appData.error));
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    color: Colors.blue,
                    child: const Text(
                      'DB',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: appData.personatges.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final p = appData.personatges[index];
                        return personatgeCard(
                        p["nom"]!,
                        p["alias"]!,
                        p["imatge"]!,
                        context
                      );

                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
Widget personatgeCard(
  String nom,
  String alias,
  String image,
  BuildContext context,
) {
  return Card(
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      splashColor: Colors.blue.withAlpha(30),
      onTap: () {
      debugPrint("Has pulsado $alias");
      },
      child: SizedBox(
        width: 100,
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "http://localhost:3000/images/$image",
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 10),
            Text(nom),
            Text(alias),
          ],
        ),
      ),
    ),
  );
}
}