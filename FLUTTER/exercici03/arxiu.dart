import 'dart:io';
import 'dart:math';
import 'casella.dart';

void generarMines(List<List<Casella>> matrix, int totalMines) {
  Random r = Random();
  int minasColocadas = 0;
  while (minasColocadas < totalMines) {
    int x = r.nextInt(matrix.length);
    int y = r.nextInt(matrix[0].length);
    if (!matrix[x][y].bomba) {
      matrix[x][y].bomba = true;
      minasColocadas++;
    }
  }
}

bool destaparCasella(List<List<Casella>> tauler, int x, int y, bool esPrimeraJugada, bool esJugadaUsuari) {
  if (x < 0 || x >= tauler.length || y < 0 || y >= tauler[0].length) return false;

  Casella casella = tauler[x][y];
  if (casella.descoberta || casella.bandera) return false;

  if (casella.bomba) {
    if (esPrimeraJugada) {
      Random r = Random();
      while (true) {
        int nx = r.nextInt(tauler.length);
        int ny = r.nextInt(tauler[0].length);
        Casella nueva = tauler[nx][ny];
        if (!nueva.bomba && !nueva.descoberta) {
          nueva.bomba = true;
          casella.bomba = false;
          break;
        }
      }
    } else if (esJugadaUsuari) {
      return true; 
    } else {
      return false;
    }
  }

  int numMines = contarMinesAdjacents(tauler, x, y);
  casella.descoberta = true;
  casella.numMinesAdjacents = numMines;

  if (numMines == 0) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx != 0 || dy != 0) {
          destaparCasella(tauler, x + dx, y + dy, false, false);
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
      if (nx >= 0 && nx < tauler.length && ny >= 0 && ny < tauler[0].length &&
          !(dx == 0 && dy == 0) && tauler[nx][ny].bomba) {
        count++;
      }
    }
  }
  return count;
}

void printTauler(List<List<Casella>> matrix) {
  List<String> filas = ['A','B','C','D','E','F'];
  List<String> columnas = List.generate(10, (i) => '${i+1}');
  print('   ${columnas.join(' ')}');

  for (int i = 0; i < matrix.length; i++) {
    String fila = '${filas[i]}  ';
    fila += matrix[i].map((c) {
      if (c.bandera) return 'F';
      if (!c.descoberta) return '.';
      return c.bomba ? '*' : (c.numMinesAdjacents > 0 ? '${c.numMinesAdjacents}' : ' ');
    }).join(' ');
    print(fila);
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
    return List.generate(10, (j) => Casella(fila: i, columna: j));
  });

  generarMines(matrix, 8);

  bool esPrimeraJugada = true;
  bool jugant = true;
  List<String> filas = ['A','B','C','D','E','F'];

  while (jugant) {
    printTauler(matrix);
    print("Introdueix una opcio:");
    String? opcio = stdin.readLineSync();
    if (opcio == null || opcio.length < 2) {
      continue;
    }
    //BANDERA
    bool ponerBandera = false;
    List<String> parts = opcio.trim().split(" ");
    if (parts[0].toLowerCase() == "flag" || parts[0].toLowerCase() == "bandera") {
      ponerBandera = true;
      if (parts.length < 2) {
        continue;
      }
      opcio = parts[1];
    }
    //AJUDA

    if (opcio.toLowerCase() == "ajuda" || opcio.toLowerCase() == "help"){
        List<String> comandes = ['Escollir casella (A5)','flag','bandera','cheat','trampes','help','ajuda'];
      for (String s in comandes){
          print(s);
      
      }
    continue;
    }



    // CASELLA NORMAL  
    String letraFila = opcio[0].toUpperCase();
    String numeroCol = opcio.substring(1);

    int fila = filas.indexOf(letraFila);
    int columna = int.tryParse(numeroCol)! - 1;

    if (fila < 0 || fila >= matrix.length || columna < 0 || columna >= matrix[0].length) {
      continue;
    }

    Casella casella = matrix[fila][columna];

    if (ponerBandera) {
      casella.bandera = !casella.bandera;
      continue;
    }

    bool esBomba = destaparCasella(matrix, fila, columna, esPrimeraJugada, true);
    esPrimeraJugada = false;

    if (esBomba) {
      print("Has perdut");
      for (var row in matrix) {
        for (var c in row) {
          if (c.bomba) c.descoberta = true;
        }
      }
      printTauler(matrix);
      jugant = false;
    } else if (casellesDestapades(matrix)) {
      print("Has guanyat");
      printTauler(matrix);
      jugant = false;
    }
  }
}
