package com.project;

import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;
import javafx.scene.image.Image ;


import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.geometry.Pos;
public class ControllerInfoMobile implements Initializable {
    private Rectangle rectangle;
    @FXML
    public VBox infoVbox;
    public ImageView infoImatge;
    @FXML
    public Label titol,info,nom;
    @FXML
    public ImageView arrowBack;
    String jsonArxiu = "";

    public String getJsonFile() {
        return jsonArxiu;
    }
    public void setJsonFile(String jsonArxiu) {
        this.jsonArxiu = jsonArxiu;
        System.out.println(jsonArxiu);
    }
    
    public void actualizarText(String title){
        titol.setText(title);
    }
    public void actualitzarInformacio(String infoExtra){
            info.setText(infoExtra);
            info.setWrapText(true);
    }

    public void actualizarTitol(String infoExtra){
            nom.setText(infoExtra);
            nom.setWrapText(true);
    }


    public void actualizarImatge(Image img) {
        infoImatge.setImage(img);
    }

public void crearRectangle(String color) {
    infoVbox.setAlignment(Pos.CENTER);

    if (color == null || color.isEmpty()) {
        if (rectangle != null) {
            infoVbox.getChildren().remove(rectangle);
            rectangle = null;
        }
        return; 
    }

    if (rectangle == null) {
        rectangle = new Rectangle(20, 20);
        infoVbox.getChildren().add(rectangle);
    }
    rectangle.setFill(Color.web(color));
}


    @FXML
    public void Enrere(){
        arrowBack.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent e) {
                try {
                    UtilsViews.setViewAnimating("layoutListMobile");
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        });


    }
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        Enrere();
    }



}