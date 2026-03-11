  import 'package:flutter/material.dart';

  void main() {
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(text: "ENCRIPTAR"),
                  Tab(text: "DESENCRIPTAR"),
                ],
              ),
              title: const Text("EXERCICI09"),
            ),
            body: TabBarView( // <- removed const here
              children: [
                // TAB1
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabelExample(text: "ENCRIPTAR ARXIU"),
                      const SizedBox(height: 20),
                      const LabelExample(text: "Clau pública (RSA):"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Clau publica',
                              ),
                            ),
      
                          ),
                          



                          
                          const SizedBox(width: 10),
                          
                          OutlinedButton(
                            onPressed: () {
                              print("Button pressed");
                            },
                            child: const Text('SELECCIONA'),
                          ),
                        ],
                      ),
                      
                      
                      // ULTIMO
                      const LabelExample(text: "Arxiu a encriptar"),
                          const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'document.txt',
                              ),
                            ),
      
                          ),
                                                   
                          const SizedBox(width: 10),
                          
                          OutlinedButton(
                            onPressed: () {
                              print("Button pressed");
                            },
                            child: const Text('Navega...'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      const Divider(thickness: 0.5,color: Colors.grey,),
                      SizedBox(height: 100),

                      Center(
                        child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue, 

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6), 
                          ),),
                          onPressed: () {
                            print("Button pressed");
                          },
                          child: const Text('ENCRIPTA ARXIU'),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB2
                  Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabelExample(text: "DESENCRIPTAR ARXIU"),
                      const SizedBox(height: 20),
                      const LabelExample(text: "Clau privada (RSA):"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '~/ssh/id_rsa',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              print("Button pressed");
                            },
                            child: const Text('SELECCIONA'),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      const Divider(thickness: 0.5,color: Colors.grey,),
                      SizedBox(height: 100),

                      Center(
                        child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.green, 

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6), 
                          ),),
                          onPressed: () {
                            print("Button pressed");
                          },
                          child: const Text('DESENCRIPTA ARXIU'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  class LabelExample extends StatelessWidget {
    final String text;

    const LabelExample({super.key, required this.text});

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Divider(thickness: 0.5,color: Colors.grey,),
          ],
        ),
      );
    }
  }