package com.project;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.geometry.Pos;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
public class ControllerListMobile implements Initializable {


    private String info,color;
    public void setInfo(String info){
        this.info = info;

    }
    public void setColor(String color){
        this.color = color;
    }
        public String infoAdicional;

    @FXML
    public VBox infoVbox;

    @FXML
    public ImageView arrowBack;
    public Label titol;
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



        arrowBack.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent e) {
                try {
                   
                    infoVbox.getChildren().clear();

                    setJsonFile(jsonArxiu);                    
                    UtilsViews.setViewAnimating("layoutMobile");
                    infoAdicional = "";
                    
                
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
private void cargarItems() {
    infoVbox.getChildren().clear();

    try {
        for (int i = 0; i < jsonData.length(); i++) {
            JSONObject item = jsonData.getJSONObject(i);
            String name = item.getString("name");   
            String image = item.getString("image");
            // Cargar el template
            URL fxmlURL = getClass().getResource("/assets/views/infoView.fxml");
            FXMLLoader loader = new FXMLLoader(fxmlURL);
            Parent itemTemplate = loader.load();







            itemTemplate.setOnMouseClicked(new EventHandler<MouseEvent>(){
                @Override
                public void handle(MouseEvent e){
                    try {
                        UtilsViews.setViewAnimating("layoutDataMobile");
                        ControllerInfoMobile c = (ControllerInfoMobile) UtilsViews.getController("layoutDataMobile");
                        c.actualizarText(name);
                        c.actualizarImatge(new Image("/assets/data/images/" + image));
                        String infoExtra = getInfo(item,jsonArxiu);
                        String color = getColor(item,jsonArxiu);
                        c.obtenirText(infoExtra);
                        c.actualizarTitol(name);

                        c.crearRectangle(color);
                    
                    
                    } catch (Exception ex) {
                        ex.printStackTrace();;
                    }
                }
            });

            // Configurar controlador del item
            ControllerListItem itemController = loader.getController();
            String senseRuta = jsonArxiu.replace("/assets/data/", "");
            String titolClean = senseRuta.replace(".json", "");

            titol.setText(titolClean);
            itemController.setTitle(name);
            itemController.setImatge("/assets/data/images/" + image);
            if (color != null){ 
                itemController.setColor(color);
            }

            infoVbox.getChildren().add(itemTemplate);
        }
    } catch (Exception e) {
        System.err.println("Error al cargar los items.");
        e.printStackTrace();
    }
}
private String getInfo(JSONObject item, String jsonArxiu) {
    switch (jsonArxiu) {
        case "/assets/data/consoles.json":
            return "Procesador: " + item.getString("procesador")
                     + "\nFecha: " + item.getString("date")
                     + "\nColor: " + item.getString("color")
                     + "\nUnidades vendidas: " + item.getInt("units_sold");
        case "/assets/data/games.json":
            return item.getString("plot");
        case "/assets/data/characters.json":
            return item.getString("game");
        default:
            return "";
    }
}

private String getColor(JSONObject item,String jsonArxiu){
      switch (jsonArxiu) {
        case "/assets/data/consoles.json":
        case "/assets/data/characters.json":

        return item.getString("color");
        case "/assets/data/games.json":
            return null;
        default:
            return "";
    }  

}}