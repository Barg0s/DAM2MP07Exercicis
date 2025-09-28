package com.project;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.geometry.Pos;

public class Controller implements Initializable {


    String[] titols = {"characters","consoles","games"};
    @FXML
    private ImageView infoImatge;
    @FXML
    private Label titol,info;
    @FXML
    private AnchorPane container;
    @FXML
    public VBox infoVbox,detallesVbox;
    @FXML
    private  ChoiceBox<String> choiceBox;
    private JSONArray jsonData;
    private boolean creat;
    private Rectangle rectangle = null;


    @Override
    public void initialize(URL url, ResourceBundle rb) {
        try {

            choiceBox.getItems().addAll(titols);
            choiceBox.setValue(titols[0]);
            setDades(choiceBox.getValue());

            choiceBox.setOnAction((event) -> {
            String selectedTable = choiceBox.getSelectionModel().getSelectedItem();
            setDades(selectedTable);
            
        });

    cargarItems();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void actualizarText(String title){
        titol.setText(title);
    }
    public void obtenirText(String infoExtra){
            info.setText(infoExtra);
            info.setWrapText(true);
    }
public void crearRectangle(String color) {
    if (choiceBox.getValue().equals("games")) {
        if (rectangle != null) {
            detallesVbox.getChildren().remove(rectangle);
            rectangle = null;
        }
        return;
    }

    if (rectangle == null) {
        rectangle = new Rectangle(25, 25);
        detallesVbox.getChildren().add(2, rectangle); 

    }


    rectangle.setFill(Color.valueOf(color));
}


    public void actualizarImatge(Image img) {
        infoImatge.setImage(img);
    }



private void setDades(String nom) {
    try {
    String jsonArxiu = "/assets/data/" + nom + ".json";
    infoVbox.getChildren().clear();
    URL jsonURL = getClass().getResource(jsonArxiu);
    Path jsonPath = Paths.get(jsonURL.toURI());
    String content = Files.readString(jsonPath);
    jsonData = new JSONArray(content);

    cargarItems();        
    } catch (Exception e) {
        System.out.println("error al carregar el fitxer");
        e.printStackTrace();
    }

    }


 private void cargarItems() {
        try {

            infoVbox.getChildren().clear();

            for (int i = 0; i < jsonData.length(); i++) {
                JSONObject game = jsonData.getJSONObject(i);

                String name = game.getString("name"); 
                String image = game.getString("image");
                String infoAdicional = "";
                URL fxmlURL = getClass().getResource("/assets/views/infoView.fxml");
                FXMLLoader loader = new FXMLLoader(fxmlURL);
                Parent itemTemplate = loader.load();

                ControllerListItem itemController = loader.getController();
                itemController.setTitle(name);
                itemController.setImatge("/assets/data/images/" + image);

                switch (choiceBox.getValue()) {
                    case "games":
                        infoAdicional = game.getString("plot");
        
                        break;
                    case "characters":
                        itemController.setColor(game.getString("color"));



                        infoAdicional = game.getString("game");

                        
                        break;
                    case "consoles":
                                            itemController.setColor(game.getString("color"));

                        infoAdicional = "Procesador: " + game.getString("procesador")
                                    + "\nData: " + game.getString("date")
                                    + "\ncolor: " + game.getString("color")
                                    + "\nUnitats venudes: " + game.getInt("units_sold");
                        break;
                    default:
                        break;
                }
                itemController.setInfo(infoAdicional);

                infoVbox.getChildren().add(itemTemplate);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}