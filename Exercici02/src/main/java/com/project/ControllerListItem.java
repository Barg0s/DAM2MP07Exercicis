package com.project;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.event.EventHandler;
import javafx.scene.layout.AnchorPane;

import java.net.URL;
import java.util.Objects;
import java.util.ResourceBundle;

public class ControllerListItem implements Initializable {
    @FXML
    private AnchorPane infoPane;
    @FXML
    private Label title;
    @FXML
    private ImageView img;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        mostrarDetalls();
    }

    public void setTitle(String text) {
        title.setText(text);
    }

    public void setImatge(String path) {
        Image imatge = new Image(Objects.requireNonNull(getClass().getResource(path)).toExternalForm());
        img.setImage(imatge);
    }

private void mostrarDetalls() {
 /*   infoPane.setOnMouseClicked(e -> {
        Controller c = (Controller) UtilsViews.getController("ViewPrincipal");
        if (c != null) {
            c.actualizarText(title.getText());
            c.actualizarImatge(img.getImage());
            System.out.println("Se actualizó info: " + title.getText());
        } else {
            System.out.println("Error: controlador principal nulo");
        }
    });
} */

}}
