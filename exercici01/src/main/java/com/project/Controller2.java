package com.project;

import javafx.fxml.FXML;
import javafx.scene.text.Text;
import javafx.scene.control.Button;

public class Controller2 {

    @FXML
    private Button enrereButton;
    @FXML
    private Text container;

    public void mostrarMissatge() {
        container.setText("Hola " + Main.nom + ", tens " + Main.edat + " anys!");
    }

    @FXML
    public void enrere(){
        Controller1 ctrl1 = (Controller1) UtilsViews.getController("ViewPrincipal");
        ctrl1.nomField.setText("");
        ctrl1.edatField.setText("");
        UtilsViews.setView("ViewPrincipal");
    }
}
