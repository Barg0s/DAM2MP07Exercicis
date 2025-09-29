package com.project;

import java.io.IOException;
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
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Node;
import javafx.scene.layout.VBox;
import javafx.event.ActionEvent;

public class ControllerMobile implements Initializable {


    String[] titols = {"characters","consoles","games"};
    @FXML
    private ImageView infoImatge;
    @FXML
    private Label titol,info;
    @FXML
    private AnchorPane container;
    @FXML
    public VBox infoVbox;
    private String actual;

    public String getActual() {
        return this.actual;
    }

    public void setActual(String actual) {
        this.actual = actual;
    }




    @Override
    public void initialize(URL url, ResourceBundle rb) {
        crearLabels();
    }

    public void actualizarText(String title){
        titol.setText(title);
    }
    public void obtenirText(String infoExtra){
            info.setText(infoExtra);
            info.setWrapText(true);
    }





    public void actualizarImatge(Image img) {
        infoImatge.setImage(img);
    }

public void crearLabels() {
    infoVbox.getChildren().clear();
    for (String t : titols) {
        Label l = new Label();
        l.setText(t);
        l.setId(t);
        infoVbox.getChildren().add(l);

        l.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent e) {
                try {
                   
                    System.out.println(l.getText());
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        });

    }
}


}