package com.project;

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
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.geometry.Pos;
public class ControllerInfoMobile implements Initializable {
    private boolean creat;
    private Rectangle rectangle = null;


    @FXML
    public VBox infoVbox;
    public ImageView infoImatge;
    @FXML
    public Label titol,info,nom;
    public String infoAdicional;
    @FXML
    public ImageView arrowBack;

    String jsonArxiu = "";
    
    JSONArray jsonData;
    public String getJsonFile() {
        return jsonArxiu;
    }
    public void setJsonFile(String jsonArxiu) {
        this.jsonArxiu = jsonArxiu;
        carregarJSON();
        System.out.println(jsonArxiu);
    }
    public void actualizarText(String title){
        titol.setText(title);
    }
    public void obtenirText(String infoExtra){
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
        return; // No crear nada
    }

    if (rectangle == null) {
        rectangle = new Rectangle(20, 20); // tamaño ejemplo
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


    private void carregarJSON(){


        try {
            URL jsonURL = getClass().getResource(jsonArxiu);
            Path jsonPath = Paths.get(jsonURL.toURI());
            String content = Files.readString(jsonPath);
            jsonData = new JSONArray(content);

            cargarItems();
        } catch (Exception e) {
            // TODO: handle exception
        }
    }
    private  void cargarItems(){

        try {
            for (int i = 0; i < jsonData.length(); i++) {
                JSONObject game = jsonData.getJSONObject(i);
                String name = game.getString("name");   
                String image = game.getString("image");


                titol.setText(name);
                Image img = new Image("/assets/data/images/" + image);
                infoImatge.setImage(img);



                switch (jsonArxiu) {
                    case "/assets/data/games.json":
                        infoAdicional = game.getString("plot");

                        break;
                   case "/assets/data/characters.json":
                        infoAdicional = game.getString("game");

                        break;
                   case "/assets/data/consoles.json":
                        infoAdicional = "Procesador: " + game.getString("procesador")
                                    + "\nData: " + game.getString("date")
                                    + "\ncolor: " + game.getString("color")
                                    + "\nUnitats venudes: " + game.getInt("units_sold");

                        break;
                    default:
                        throw new AssertionError();
                }

                
            }

        } catch (Exception e) {
        System.out.println("error al carregar el fitxer");
        e.printStackTrace();        }
    }

}