package com.project;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;

import org.json.JSONArray;
import org.json.JSONObject;

public class Controller implements Initializable {

    @FXML
    private ImageView infoImatge;
    @FXML
    private Label info;
    @FXML
    private AnchorPane container;
    @FXML
    private VBox infoVbox;

    private JSONArray jsonData;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        try {
            URL jsonURL = getClass().getResource("/assets/data/games.json");
            Path jsonPath = Paths.get(jsonURL.toURI());
            String content = new String(Files.readAllBytes(jsonPath));
            jsonData = new JSONArray(content);

            cargarItems();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void actualizarText(String title){
        info.setText(title);
    }

    public void actualizarImatge(Image img) {
        infoImatge.setImage(img);
    }

    private void cargarItems() {
        try {
            infoVbox.getChildren().clear();

            for (int i = 0; i < jsonData.length(); i++) {
                JSONObject game = jsonData.getJSONObject(i);
                String name = game.getString("name");
                String image = game.getString("image");

                URL fxmlURL = getClass().getResource("/assets/views/infoView.fxml");
                FXMLLoader loader = new FXMLLoader(fxmlURL);
                Parent itemTemplate = loader.load();

                ControllerListItem itemController = loader.getController();
                itemController.setTitle(name);
                itemController.setImatge("/assets/data/images/" + image);

                infoVbox.getChildren().add(itemTemplate);
                System.out.println("Añadido item: " + name);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
