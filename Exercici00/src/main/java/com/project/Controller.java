package com.project;

import java.util.Locale;


import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import java.util.Locale;

public class Controller {

    @FXML
    private Button buttonSuma, buttonResta, buttonMulti, buttonDivi, buttonIgual,buttonDecimal;

    @FXML
    private Label container;

    private String operador = "";
    private double primer = 0;
    private double segon = 0;

private boolean comprobarOperador(String textBoto){
        if ((textBoto.equals("+") || textBoto.equals("-") || 
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
}


@FXML
private void ObtenirNum(ActionEvent e) { //https://stackoverflow.com/questions/56299102/how-to-know-which-button-is-bieng-clicked-in-javafx

    Button boto = (Button) e.getSource();
    String textBoto = boto.getText();

    if ((container.getText().equals("0") || container.getText().equals("No es pot dividir entre 0")) && !comprobarOperador(textBoto)) { //limpia pantalla si ha petado o nada mas iniciar la calc
        container.setText("");
        bloquejarBotons(false);
    }

    if (comprobarOperador(textBoto) && !container.getText().isEmpty() && !container.getText().equals("No es pot dividir entre 0")) {//guarda numeros hasta que pulses un operador
        primer = Double.parseDouble(container.getText());
        operador = textBoto;
        container.setText("");
    } else {
        container.setText(container.getText() + textBoto);
    }
}
    @FXML
    private void afegirPunt(ActionEvent event){
        
        if (container.getText().contains(".")){
            return;
        }
        container.setText(container.getText() + ".");
        
    }

    @FXML
    private void Operar(ActionEvent event) {
        if (container.getText().isEmpty() || operador.isEmpty()) return;

        segon = Double.parseDouble(container.getText());
        double r = 0;

        switch (operador) {
            case "+":
                r = primer + segon;
                break;
            case "-":
                r = primer - segon;
                break;
            case "*":
                r = primer * segon;
                break;
            case "/":
                if (segon == 0) {
                    container.setText("No es pot dividir entre 0");
                    bloquejarBotons(true);
                    return;
                } else {
                    r = primer / segon;
                }
                break;
        
            default:
                break;
        }


        container.setText(String.format(Locale.US, "%.2f", r));
        primer = r;  
        operador = ""; 
    }

    @FXML
    private void netejarContainer(ActionEvent e){
        container.setText("0");
        primer = 0;
        segon = 0;
        operador = "";
        bloquejarBotons(false);
        
    }

    @FXML
    private void eliminarUltim(ActionEvent e){
        if (!container.getText().isEmpty()){ //https://stackoverflow.com/questions/27950596/how-to-build-a-delete-button-to-remove-a-character-from-the-textfield-every-time
            container.setText( container.getText().substring(0, container.getText().length()-1));

            bloquejarBotons(false);
        }

    }
}
