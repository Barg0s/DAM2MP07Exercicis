package com.project;

import java.net.URL;
import java.util.Objects;
import java.util.ResourceBundle;

import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;

public class ControllerListItem implements Initializable {
    @FXML
    private AnchorPane infoPane;
    @FXML
    private Label title;
    @FXML
    private ImageView img;


    private String info,color;
    public void setInfo(String info){
        this.info = info;

    }
    public void setColor(String color){
        this.color = color;
    }
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

        infoPane.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent e){
                Controller c = (Controller) UtilsViews.getController("layout");
                c.actualizarText(title.getText());
                c.actualizarImatge(img.getImage());
                c.obtenirText(info);
                c.crearRectangle(color);
            }
        });

}}
