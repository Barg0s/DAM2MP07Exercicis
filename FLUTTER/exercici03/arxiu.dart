import 'dart:math';

void generarMines(List<List<String>> matrix) {
  Random r = Random();
  List<String> posicions = [];
  int minaColocada = 0;
  while (minaColocada < 8) {
    int x = r.nextInt(6);
    int y = r.nextInt(10);
    if (!posicions.contains("$x,$y")){
      matrix[x][y] = "*"; 
      minaColocada++; 
      posicions.add('$x,$y');
      print("mina colocada a:[$x][$y]");
      }
  }
}



bool destaparCaselles(List<List<String>> matrix,int x,int y,bool esPrimeraJugada, bool esJugadaUsuari){

  if (x > 10 || y > 6){
      return false;
  }
  if (matrix[x][y] == "*" && esPrimeraJugada){
    matrix[x][y] == " ";
    return false;
    }else{
      return true;
    }


}



void comptaMinesAdjacents(List<List<String>> matrix,x,y){}
void main() {
  List<List<String>> matrix = List.generate(6, (i) {
    return List.generate(10, (j) => "·");
  });
  generarMines(matrix);
  for (var row in matrix) {
    print(row.join(" "));
  }
}

