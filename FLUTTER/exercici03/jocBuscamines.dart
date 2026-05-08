import 'dart:io';
import 'dart:math';
import 'casella.dart';

class JocBuscaminas {
  // Variables que abans eren globals o estaven al main
  List<List<Casella>> matrix;
  bool cheat = false;
  int comptadorTirades = 0;
  bool esPrimeraJugada = true;
  final List<String> filas = ['A', 'B', 'C', 'D', 'E', 'F'];

  JocBuscaminas()
    : matrix = List.generate(
        6,
        (i) => List.generate(10, (j) => Casella(fila: i, columna: j)),
      ) {
    generarMines();
  }

  // --- MÈTODES DE GENERACIÓ (El teu codi original) ---

  void posarMinesQuadrant(int filaInici, int filaFi, int colInici, int colFi) {
    Random r = Random();
    int collocades = 0;
    while (collocades < 2) {
      int x = filaInici + r.nextInt(filaFi - filaInici + 1);
      int y = colInici + r.nextInt(colFi - colInici + 1);

      if (!matrix[x][y].bomba) {
        matrix[x][y].bomba = true;
        collocades++;
      }
    }
  }

  void generarMines() {
    posarMinesQuadrant(0, 2, 0, 4);
    posarMinesQuadrant(0, 2, 5, 9);
    posarMinesQuadrant(3, 5, 0, 4);
    posarMinesQuadrant(3, 5, 5, 9);
  }

  // --- LÒGICA DE JOC (El teu codi original) ---

  int contarMinesAdjacents(int x, int y) {
    int count = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 &&
            nx < matrix.length &&
            ny >= 0 &&
            ny < matrix[0].length &&
            !(dx == 0 && dy == 0) &&
            matrix[nx][ny].bomba) {
          count++;
        }
      }
    }
    return count;
  }

  bool destaparCasella(int x, int y, bool primeraJugada) {
    if (x < 0 || x >= matrix.length || y < 0 || y >= matrix[0].length)
      return false;

    Casella casella = matrix[x][y];
    if (casella.descoberta || casella.bandera) return false;

    if (casella.bomba) {
      if (primeraJugada) {
        Random r = Random();
        while (true) {
          int nx = r.nextInt(matrix.length);
          int ny = r.nextInt(matrix[0].length);
          if (!matrix[nx][ny].bomba) {
            matrix[nx][ny].bomba = true;
            casella.bomba = false;
            break;
          }
        }
        return false;
      } else {
        return true;
      }
    }

    int numMines = contarMinesAdjacents(x, y);
    casella.descoberta = true;
    casella.numMinesAdjacents = numMines;

    if (numMines == 0) {
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx != 0 || dy != 0) {
            destaparCasella(x + dx, y + dy, false);
          }
        }
      }
    }
    return false;
  }

  bool casellesDestapades() {
    for (var row in matrix) {
      for (var c in row) {
        if (!c.bomba && !c.descoberta) return false;
      }
    }
    return true;
  }

  // --- INTERFAZ (El teu codi original) ---

  void printTauler() {
    List<String> columnas = List.generate(10, (i) => '$i');
    String header = '   ${columnas.join(' ')}';

    if (cheat) {
      print('$header     $header');
    } else {
      print(header);
    }

    for (int i = 0; i < matrix.length; i++) {
      String filaNormal =
          '${filas[i]}  ' +
          matrix[i]
              .map((c) {
                if (c.bandera) return '#';
                if (!c.descoberta) return '·';
                if (c.bomba) return '*';
                return (c.numMinesAdjacents > 0
                    ? '${c.numMinesAdjacents}'
                    : ' ');
              })
              .join(' ');

      if (cheat) {
        String filaCheat =
            '${filas[i]}  ' +
            matrix[i]
                .map((c) {
                  if (c.bandera) return '#';
                  if (c.bomba) return '*';
                  if (!c.descoberta) return '·';
                  return (c.numMinesAdjacents > 0
                      ? '${c.numMinesAdjacents}'
                      : ' ');
                })
                .join(' ');
        print('$filaNormal     $filaCheat');
      } else {
        print(filaNormal);
      }
    }
  }
}

// --- MAIN (Net i ordenat) ---

void main() {
  JocBuscaminas joc = JocBuscaminas();
  bool jugant = true;

  while (jugant) {
    joc.printTauler();
    print("Introdueix una opcio:");
    String? opcio = stdin.readLineSync();
    if (opcio == null || opcio.trim().isEmpty) continue;

    String input = opcio.trim();

    // AJUDA I TRAMPES
    if (input.toLowerCase() == "ajuda" || input.toLowerCase() == "help") {
      print("Comandes: A5, A5 flag, cheat, help");
      continue;
    } else if (input.toLowerCase() == "cheat" ||
        input.toLowerCase() == "trampes") {
      joc.cheat = true;
      continue;
    } else if (input.toLowerCase() == "desactivar trampes") {
      joc.cheat = false;
      continue;
    }

    // PROCESSAR JUGADA
    List<String> parts = input.split(" ");
    String coord = parts[0];
    bool esBandera =
        parts.length > 1 && (parts[1] == "flag" || parts[1] == "bandera");

    if (coord.length < 2) continue;

    String letraFila = coord[0].toUpperCase();
    String numeroCol = coord.substring(1);

    int fila = joc.filas.indexOf(letraFila);
    int? columna = int.tryParse(numeroCol);

    if (fila < 0 ||
        columna == null ||
        columna < 0 ||
        columna >= joc.matrix[0].length) {
      print("Coordenada no vàlida");
      continue;
    }

    if (esBandera) {
      joc.matrix[fila][columna].bandera = !joc.matrix[fila][columna].bandera;
    } else {
      bool mort = joc.destaparCasella(fila, columna, joc.esPrimeraJugada);
      joc.comptadorTirades++;
      joc.esPrimeraJugada = false;

      if (mort) {
        print("Has perdut!");
        for (var row in joc.matrix) {
          for (var c in row) {
            if (c.bomba) c.descoberta = true;
          }
        }
        joc.printTauler();
        print("Número de tirades: ${joc.comptadorTirades}");
        jugant = false;
      } else if (joc.casellesDestapades()) {
        print("Has guanyat!");
        joc.printTauler();
        print("Has fet ${joc.comptadorTirades} tirades.");
        jugant = false;
      }
    }
  }
}
