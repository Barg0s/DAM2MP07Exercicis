import 'dart:io';
import 'dart:math';
import 'casella.dart';

bool cheat = false;
int comptadorTirades = 0;
void posarMinesQuadrant(
  List<List<Casella>> matrix,
  int filaInici,
  int filaFi,
  int colInici,
  int colFi,
) {
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

void generarMines(List<List<Casella>> matrix) {
  posarMinesQuadrant(matrix, 0, 2, 0, 4);

  posarMinesQuadrant(matrix, 0, 2, 5, 9);

  posarMinesQuadrant(matrix, 3, 5, 0, 4);

  posarMinesQuadrant(matrix, 3, 5, 5, 9);
}

bool destaparCasella(
  List<List<Casella>> tauler,
  int x,
  int y,
  bool esPrimeraJugada,
) {
  if (x < 0 || x >= tauler.length || y < 0 || y >= tauler[0].length)
    return false;

  Casella casella = tauler[x][y];

  if (casella.descoberta || casella.bandera) return false;

  if (casella.bomba) {
    if (esPrimeraJugada) {
      Random r = Random();

      while (true) {
        int nx = r.nextInt(tauler.length);
        int ny = r.nextInt(tauler[0].length);

        if (!tauler[nx][ny].bomba) {
          tauler[nx][ny].bomba = true;
          casella.bomba = false;
          break;
        }
      }
      return false;
    } else {
      return true;
    }
  }

  int numMines = contarMinesAdjacents(tauler, x, y);
  casella.descoberta = true;
  casella.numMinesAdjacents = numMines;

  if (numMines == 0) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx != 0 || dy != 0) {
          destaparCasella(tauler, x + dx, y + dy, false);
        }
      }
    }
  }

  return false;
}

int contarMinesAdjacents(List<List<Casella>> tauler, int x, int y) {
  int count = 0;
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      int nx = x + dx;
      int ny = y + dy;
      if (nx >= 0 &&
          nx < tauler.length &&
          ny >= 0 &&
          ny < tauler[0].length &&
          !(dx == 0 && dy == 0) &&
          tauler[nx][ny].bomba) {
        count++;
      }
    }
  }
  return count;
}

void printTauler(List<List<Casella>> matrix, bool cheat) {
  List<String> filas = ['A', 'B', 'C', 'D', 'E', 'F'];
  List<String> columnas = List.generate(10, (i) => '$i');

  String headerNormal = '   ${columnas.join(' ')}';
  String headerCheat = '   ${columnas.join(' ')}';

  if (cheat) {
    print('$headerNormal     $headerCheat');
  } else {
    print(headerNormal);
  }

  for (int i = 0; i < matrix.length; i++) {
    String filaNormal =
        '${filas[i]}  ' +
        matrix[i]
            .map((c) {
              if (c.bandera) return '#';
              if (!c.descoberta) return '·';
              if (c.bomba) return '*';
              return (c.numMinesAdjacents > 0 ? '${c.numMinesAdjacents}' : ' ');
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

bool casellesDestapades(List<List<Casella>> matrix) {
  for (var row in matrix) {
    for (var c in row) {
      if (!c.bomba && !c.descoberta) return false;
    }
  }
  return true;
}

void main() {
  List<List<Casella>> matrix = List.generate(6, (i) {
    // crea tablero
    return List.generate(10, (j) => Casella(fila: i, columna: j));
  });

  generarMines(matrix);

  bool esPrimeraJugada = true;
  bool jugant = true;
  List<String> filas = ['A', 'B', 'C', 'D', 'E', 'F'];

  while (jugant) {
    printTauler(matrix, cheat);
    print("Introdueix una opcio:");
    String? opcio = stdin.readLineSync();
    if (opcio == null || opcio.length < 2) {
      continue;
    }
    //BANDERA
    bool ponerBandera = false;
    List<String> parts = opcio.trim().split(" ");
    String coord = parts[0];
    bool esBandera =
        parts.length > 1 && (parts[1] == "flag" || parts[1] == "bandera");
    if (esBandera) {
      ponerBandera = true;
      if (parts.length < 2) {
        continue;
      }
      opcio = coord;
    }
    //AJUDA

    if (opcio.toLowerCase() == "ajuda" || opcio.toLowerCase() == "help") {
      List<String> comandes = [
        'Escollir casella (A5)',
        'flag',
        'bandera',
        'cheat',
        'trampes',
        'help',
        'ajuda',
      ];
      for (String s in comandes) {
        print(s);
      }

      continue;
    } else if (opcio.toLowerCase() == "cheat" ||
        opcio.toLowerCase() == "trampes") {
      cheat = true;
      continue;
    } else if (opcio.toLowerCase() == "deactivate cheats" ||
        opcio.toLowerCase() == "desactivar trampes") {
      cheat = false;
      continue;
    }

    // CASELLA NORMAL
    String letraFila = coord[0].toUpperCase();
    String numeroCol = coord.substring(1);

    int fila = filas.indexOf(letraFila);
    int? columna = int.tryParse(numeroCol);

    if (fila < 0 ||
        columna == null ||
        columna < 0 ||
        columna >= matrix[0].length) {
      print("Coordenada no vàlida");
      continue;
    }

    Casella casella = matrix[fila][columna];

    if (ponerBandera) {
      casella.bandera = !casella.bandera;
      continue;
    }

    bool esBomba = destaparCasella(matrix, fila, columna, esPrimeraJugada);
    comptadorTirades++;
    esPrimeraJugada = false;

    if (esBomba) {
      print("Has perdut!");
      for (var row in matrix) {
        for (var c in row) {
          if (c.bomba) c.descoberta = true;
        }
      }
      printTauler(matrix, false);
      print("Número de tirades: $comptadorTirades");
      jugant = false;
    } else if (casellesDestapades(matrix)) {
      print("Has guanyat!");
      printTauler(matrix, false);
      print("Has fet $comptadorTirades tirades.");
      jugant = false;
    }
  }
}
