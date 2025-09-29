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

public class ControllerInfoMobile implements Initializable {


    @FXML
    public VBox infoVbox;
    public ImageView infoImatge;
    public Label titol,info;
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





    @FXML
    public void Enrere(){


        setJsonFile("");

        arrowBack.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent e) {
                try {
                   
                    infoVbox.getChildren().clear();

                    setJsonFile("");                    
                    UtilsViews.setView("layoutMobile");
                    
                
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
        infoVbox.getChildren().clear();

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
                   case "/assets/data/consoles.json":
                        infoAdicional = game.getString("game");

                        break;
                   case "/assets/data/characters.json":
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