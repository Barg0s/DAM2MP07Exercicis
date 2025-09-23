package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;
import javafx.scene.text.Text;
import javafx.event.ActionEvent;
public class Controller {

    @FXML
    private Button buttonSuma,buttonResta,buttonMulti,buttonDivi,buttonIgual;


    @FXML
    private TextField container;

    private String operador = "";
    private int primer = 0;
    private int segon = 0;
    


    @FXML
    private void ObtenirBoto(ActionEvent event) {
        Button boto = (Button) event.getSource();
        String textBoto = boto.getText();

        if (!"+-*/=".contains(textBoto)) {
            container.appendText(textBoto);
            primer = Integer.parseInt(container.getText());
        } else {
            operador = textBoto;
            container.clear();
        }
    }

        @FXML
private void Operar(ActionEvent event) {
    Button boto = (Button) event.getSource(); //https://www.quora.com/How-do-I-check-if-a-button-in-JavaFX-is-pressed
        if (!boto.getText().equals("+") && !boto.getText().equals("-") 
            && !boto.getText().equals("*") && !boto.getText().equals("/") && !boto.getText().equals("=")) {
            segon = Integer.parseInt(boto.getText());
            }
            double r = 0;

    switch (operador) {
        case "+": r = primer + segon; 
        break;
        case "-": r = primer - segon;
         break;
        case "*": r = primer * segon; 
        break;
        case "/": 
                if (segon == 0){
                    container.setText("no es pot dividir entre 0");
                    return;
                }else{
                r = primer / segon; 
}
            break;
    }

    operador = ""; 
    container.clear();
    container.setText(String.valueOf(r));
}
    }
