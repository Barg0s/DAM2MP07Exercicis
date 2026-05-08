class Casella {
  int fila;
  int columna;
  bool bomba;
  bool descoberta;
  bool bandera;
  int numMinesAdjacents;

  Casella({
    this.fila = 0,
    this.columna = 0,
    this.bomba = false,
    this.descoberta = false,
    this.bandera = false,
    this.numMinesAdjacents = 0,
  });

}