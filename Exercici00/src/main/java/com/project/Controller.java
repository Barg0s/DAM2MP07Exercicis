package com.project;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;

public class Controller {

    @FXML
    private Button buttonSuma, buttonResta, buttonMulti, buttonDivi, buttonIgual,buttonDecimal,buttonEliminar;

    @FXML
    private TextField container;


private boolean comprobarOperador(String textBoto){
        if ((textBoto.equals("+") || 
         textBoto.equals("*") || textBoto.equals("/")) 
        && !container.getText().isEmpty()) {
        
            return true;
    } 
    return false;

}

private void bloquejarBotons(boolean bloquejar) {
    buttonSuma.setDisable(bloquejar);
    buttonResta.setDisable(bloquejar);
    buttonMulti.setDisable(bloquejar);
    buttonDivi.setDisable(bloquejar);
    buttonIgual.setDisable(bloquejar);
    buttonDecimal.setDisable(bloquejar);
    buttonEliminar.setDisable(bloquejar);
}



    @FXML
    private void ObtenirNum(ActionEvent e) { //https://stackoverflow.com/questions/56299102/how-to-know-which-button-is-bieng-clicked-in-javafx

        Button boto = (Button) e.getSource();
        String textBoto = boto.getText();

        if ((container.getText().equals("0") || container.getText().equals("No es pot dividir entre 0")) && !comprobarOperador(textBoto)) {
            container.setText("");
            bloquejarBotons(false);
        }

        container.setText(container.getText() + textBoto);
    }

    @FXML
    private void afegirPunt(ActionEvent event){
        
        if (container.getText().contains(".")){
            return;
        }
        container.setText(container.getText() + ".");
        
    }



private boolean esNegatiu(String operacio, int i) {
    char[] operadors = {'+','-','*','/'};
    if (operacio.charAt(i) != '-') {
        return false;
    }
    if (i == 0) {
        return true;
    }

    char anterior = operacio.charAt(i - 1);
    for (char c : operadors){
        if (anterior == c){
            return true;
        }
    }
    return false;
}
private List<String> separarOperacio(String operacio) {
    List<String> op = new ArrayList<>();
    String num = "";

    for (int i = 0; i < operacio.length(); i++) {
        char c = operacio.charAt(i);

        if (Character.isDigit(c) || c == '.') {
            num += c; //afegeix el simbol amb el numero
        } else if (c == '+' || c == '-' || c == '*' || c == '/') {
            if (esNegatiu(operacio, i)) {
                num += c; //afegeix el simbol amb el numero
            } else {
                if (!num.isEmpty()) {
                    op.add(num); //afegeix el numero
                    num = ""; //ho reseteja
                }
                op.add(String.valueOf(c)); //afegeix el simbol com un item mes del array
            }
        }
    }

    if (!num.isEmpty()) {
        op.add(num);
    }

    return op;
}


private List<String> MultiplicacioDivisio(List<String> operacio) {
    for (int i = 0; i < operacio.size(); i++) {
        String operador = operacio.get(i);

        if (operador.equals("*") || operador.equals("/")) {
            double primer = 0;
            double segon = 0;

            try {
                primer = Double.parseDouble(operacio.get(i - 1));
                segon = Double.parseDouble(operacio.get(i + 1));
            } catch (NumberFormatException e) {
                container.setText("Numero invalid");
                return operacio;
            }

            double resultat = 0.0;

            if (operador.equals("*")) {
                resultat = primer * segon;
            } else {
                if (segon == 0) {
                    throw new ArithmeticException();
                }
                resultat = primer / segon;
            }

            operacio.set(i - 1, String.valueOf(resultat)); //reemplaça el primer nom amb el resultat
            operacio.remove(i); //eliminaoperador
            operacio.remove(i); //elimina el segon numero
            i--; //va cap enrere per comprobar
        }
    }
    return operacio;
}


private double SumaResta(List<String> operacio) {
    double total = 0;

    for (int i = 0; i < operacio.size(); i++) {
        String num = operacio.get(i);
        if (i == 0) {
            total = Double.parseDouble(num);
        } else {
            if (num.equals("+") || num.equals("-")) {
                String operador = num;
                double numero = Double.parseDouble(operacio.get(i + 1));

                if (operador.equals("+")) {
                    total += numero;
                } else if (operador.equals("-")) {
                    total -= numero;
                }

                i++; 
            }
        }
    }

    return total;
}





    private double calcular(String op) throws Exception {
        List<String> operacio = separarOperacio(op);

        operacio = MultiplicacioDivisio(operacio);
        double resultat = SumaResta(operacio);
        return resultat;
    }


    @FXML
    private void Operar(ActionEvent event) {
        if (container.getText().isEmpty()) 
        return;

        String expressio = container.getText();
        if (container.getText().length() == 1){
            container.setText("0");
        }
        try {
            double r = calcular(expressio);
            container.setText(String.format(Locale.US, "%.2f", r));
            bloquejarBotons(false);
        } catch (ArithmeticException ex) {
            container.setText("No es pot dividir entre 0");
            bloquejarBotons(true);
        } catch (Exception ex) {
            container.setText("Error");
            bloquejarBotons(true);
        }
    }

    @FXML
    private void netejarContainer(ActionEvent e){
        container.setText("0");
        bloquejarBotons(false);
        
    }

@FXML
private void eliminarUltim(ActionEvent e){
    String TextActual = container.getText();

    if (!TextActual.isEmpty()) {
        TextActual = TextActual.substring(0, TextActual.length() - 1);
        
        container.setText(TextActual);
        
        bloquejarBotons(false);
        
        if (TextActual.length() == 0) {
            container.setText("0");
        }
    }
}




}
