package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.TextField;

import javafx.event.ActionEvent;

public class Controller1 {

    @FXML
    public TextField edatField;

    @FXML
    public TextField nomField;
@FXML
private void checkEdat(ActionEvent event) {
        String nom = nomField.getText().trim();
        String edatText = edatField.getText().trim();

        if (nom.isEmpty() || edatText.isEmpty()) {
            return;
        }


        try {
            int edatInt = Integer.parseInt(edatText);
            Main.edat = edatInt;
            
        } catch (Exception e) {
            edatField.setText("Has de ficar un número com edat");
            return;
        }


        Main.nom = nom;


        Controller2 ctrl0 = (Controller2) UtilsViews.getController("ViewEdat");
        ctrl0.mostrarMissatge();
        UtilsViews.setView("ViewEdat");


}


}
