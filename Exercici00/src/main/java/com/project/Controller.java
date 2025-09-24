package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;

import javax.swing.Action;

import javafx.event.ActionEvent;

public class Controller {

    @FXML
    private Button buttonSuma, buttonResta, buttonMulti, buttonDivi, buttonIgual;

    @FXML
    private TextField container;

    private String operador = "";
    private double primer = 0;
    private double segon = 0;

    @FXML
    private void ObtenirNum(ActionEvent e) {
        Button boto = (Button) e.getSource();
        String textBoto = boto.getText();
        container.appendText(textBoto);
    }

    @FXML
    private void ObtenirBoto(ActionEvent event) {
        if (!container.getText().isEmpty()) {
            primer = Double.parseDouble(container.getText());
            Button boto = (Button) event.getSource();
            operador = boto.getText(); 
            container.clear(); 
        }
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
                    return;
                } else {
                    r = primer / segon;
                }
                break;
        
            default:
                break;
        }


        container.setText(String.valueOf(r));
        primer = r;  
        operador = ""; 
    }

    @FXML
    private void netejarContainer(ActionEvent e){
        container.clear();
        primer = 0;
        operador = "";
    }

    @FXML
    private void eliminarUltim(ActionEvent e){
        if (!container.getText().isEmpty()){ //https://stackoverflow.com/questions/27950596/how-to-build-a-delete-button-to-remove-a-character-from-the-textfield-every-time
            container.setText( container.getText().substring(0, container.getText().length()-1));

        }

    }
}
