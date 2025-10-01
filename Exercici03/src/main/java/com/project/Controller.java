package com.project;

import java.io.BufferedReader;  // Correct JavaFX import
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.URL;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Base64;
import java.util.ResourceBundle;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.application.Platform;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;
import javafx.scene.text.Text;
import javafx.stage.FileChooser;

public class Controller implements Initializable {

    // Models
    private static final String TEXT_MODEL   = "gemma3:1b";
    private static final String VISION_MODEL = "llava-phi3";

    @FXML private Button buttonCallStream, buttonCallComplete, buttonBreak, buttonPicture;
    @FXML private Text textInfo;
    @FXML private VBox chatVBox;


    @FXML
    private TextField text;
    private final HttpClient httpClient = HttpClient.newHttpClient();
    private CompletableFuture<HttpResponse<InputStream>> streamRequest;
    private CompletableFuture<HttpResponse<String>> completeRequest;
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);
    private InputStream currentInputStream;
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();
    private Future<?> streamReadingTask;
    private volatile boolean isFirst = false;


    @Override
    public void initialize(URL url, ResourceBundle rb) {
        setButtonsIdle();
    }

    // --- UI actions ---






    
    @FXML
    private void callStream(ActionEvent event) {
        Text textoPrueba = new Text();
        textInfo.setText("");
        setButtonsRunning();
        isCancelled.set(false);
            String textUser = text.getText();
            Label l = new Label(textUser);
            chatVBox.getChildren().add(l);
            chatVBox.getChildren().add(textoPrueba);
            textoPrueba.setWrappingWidth(400);

        
        ensureModelLoaded(TEXT_MODEL).whenComplete((v, err) -> {
            if (err != null) {
                Platform.runLater(() -> { textoPrueba.setText("Error loading model."); setButtonsIdle(); });
                return;
            }

            executeTextRequest(TEXT_MODEL, textUser, true);
            textInfo = textoPrueba;

        });
    }

    @FXML
    private void callComplete(ActionEvent event) {
        textInfo.setText("");
        setButtonsRunning();
        isCancelled.set(false);

        ensureModelLoaded(TEXT_MODEL).whenComplete((v, err) -> {
            if (err != null) {
                Platform.runLater(() -> { textInfo.setText("Error loading model."); setButtonsIdle(); });
                return;
            }
            executeTextRequest(TEXT_MODEL, "Tell me a haiku.", false);
        });
    }


    //https://stackoverflow.com/questions/48832841/jruby-javafx-how-to-add-icon-to-button




    @FXML
    private void callPicture(ActionEvent event) {
        textInfo.setText("");
        setButtonsRunning();
        isCancelled.set(false);

        // Choose image file
        FileChooser fc = new FileChooser();
        fc.setTitle("Choose an image");
        fc.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Images", "*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif")
        );

        // set default dir to current working directory
        File initialDir = new File(System.getProperty("user.dir"));
        if (initialDir.exists() && initialDir.isDirectory()) {
            fc.setInitialDirectory(initialDir);
        }

        File file = fc.showOpenDialog(buttonPicture.getScene().getWindow());
        ImageView imageView = new ImageView(file.toURI().toString());
        int index = chatVBox.getChildren().size();
        chatVBox.getChildren().add(index -1,imageView);
        if (file == null) {
            Platform.runLater(() -> { textInfo.setText("No file selected."); setButtonsIdle(); });
            return;
        }


        // Read file -> base64
        final String base64Image;
        try {
            byte[] bytes = Files.readAllBytes(file.toPath());
            base64Image = Base64.getEncoder().encodeToString(bytes);
        } catch (Exception e) {
            e.printStackTrace();
            Platform.runLater(() -> { textInfo.setText("Error reading image."); setButtonsIdle(); });
            return;
        }

        ensureModelLoaded(VISION_MODEL).whenComplete((v, err) -> {
            if (err != null) {
                Platform.runLater(() -> { textInfo.setText("Error loading model."); setButtonsIdle(); });
                return;
            }
            executeImageRequest(VISION_MODEL, "Describe what's in this picture", base64Image);
        });
    }

    @FXML
    private void callBreak(ActionEvent event) {
        isCancelled.set(true);
        cancelStreamRequest();
        cancelCompleteRequest();
        Platform.runLater(() -> {
            textInfo.setText("Request cancelled.");
            setButtonsIdle();
        });
    }

    // --- Request helpers ---

    // Text-only (stream or not)
    private void executeTextRequest(String model, String prompt, boolean stream) {
        JSONObject body = new JSONObject()
            .put("model", model)
            .put("prompt", prompt)
            .put("stream", stream)
            .put("keep_alive", "10m");

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString(body.toString()))
            .build();

        if (stream) {
            isFirst = true;

            streamRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                .thenApply(response -> {
                    currentInputStream = response.body();
                    streamReadingTask = executorService.submit(this::handleStreamResponse);
                    return response;
                })
                .exceptionally(e -> {
                    if (!isCancelled.get()) e.printStackTrace();
                    Platform.runLater(this::setButtonsIdle);
                    return null;
                });

        } else {
            Platform.runLater(() -> textInfo.setText("Wait complete ..."));

            completeRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenApply(response -> {
                    String responseText = safeExtractTextResponse(response.body());
                    Platform.runLater(() -> { textInfo.setText(responseText); setButtonsIdle(); });
                    return response;
                })
                .exceptionally(e -> {
                    if (!isCancelled.get()) e.printStackTrace();
                    Platform.runLater(this::setButtonsIdle);
                    return null;
                });
        }
    }

    // Image + prompt (non-stream) using vision model
    private void executeImageRequest(String model, String prompt, String base64Image) {
        Platform.runLater(() -> textInfo.setText("Analyzing picture ..."));

        JSONObject body = new JSONObject()
            .put("model", model)
            .put("prompt", prompt)
            .put("images", new JSONArray().put(base64Image))
            .put("stream", false)
            .put("keep_alive", "10m")
            .put("options", new JSONObject()
                .put("num_ctx", 2048)     // lower context to reduce memory
                .put("num_predict", 256)  // shorter output to avoid OOM
            );

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString(body.toString()))
            .build();

        completeRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
            .thenApply(resp -> {
                int code = resp.statusCode();
                String bodyStr = resp.body();

                String msg = tryParseAnyMessage(bodyStr);
                if (msg == null || msg.isBlank()) {
                    msg = (code >= 200 && code < 300) ? "(empty response)" : "HTTP " + code + ": " + bodyStr;
                }

                final String toShow = msg;
                Platform.runLater(() -> { textInfo.setText(toShow); setButtonsIdle(); });
                return resp;
            })
            .exceptionally(e -> {
                if (!isCancelled.get()) e.printStackTrace();
                Platform.runLater(() -> { textInfo.setText("Request failed."); setButtonsIdle(); });
                return null;
            });
    }

    // Stream reader for text responses
    private void handleStreamResponse() {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(currentInputStream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (isCancelled.get()) break;
                if (line.isBlank()) continue;

                JSONObject jsonResponse = new JSONObject(line);
                String chunk = jsonResponse.optString("response", "");
                if (chunk.isEmpty()) continue;

                if (isFirst) {
                    Platform.runLater(() -> textInfo.setText(chunk));
                    isFirst = false;
                } else {
                    Platform.runLater(() -> textInfo.setText(textInfo.getText() + chunk));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            Platform.runLater(() -> { textInfo.setText("Error during streaming."); setButtonsIdle(); });
        } finally {
            try { if (currentInputStream != null) currentInputStream.close(); } catch (Exception ignore) {}
            Platform.runLater(this::setButtonsIdle);
        }
    }

    // --- Small utils ---

    private String safeExtractTextResponse(String bodyStr) {
        // Extract "response" or fallback to error/message if present
        try {
            JSONObject o = new JSONObject(bodyStr);
            String r = o.optString("response", null);
            if (r != null && !r.isBlank()) return r;
            if (o.has("message")) return o.optString("message");
            if (o.has("error"))   return "Error: " + o.optString("error");
        } catch (Exception ignore) {}
        return bodyStr != null && !bodyStr.isBlank() ? bodyStr : "(empty)";
    }

    private String tryParseAnyMessage(String bodyStr) {
        try {
            JSONObject o = new JSONObject(bodyStr);
            if (o.has("response")) return o.optString("response", "");
            if (o.has("message"))  return o.optString("message", "");
            if (o.has("error"))    return "Error: " + o.optString("error", "");
        } catch (Exception ignore) {}
        return null;
    }

    private void cancelStreamRequest() {
        if (streamRequest != null && !streamRequest.isDone()) {
            try {
                if (currentInputStream != null) {
                    System.out.println("Cancelling InputStream");
                    currentInputStream.close();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            System.out.println("Cancelling StreamRequest");
            if (streamReadingTask != null) {
                streamReadingTask.cancel(true);
            }
            streamRequest.cancel(true);
        }
    }

    private void cancelCompleteRequest() {
        if (completeRequest != null && !completeRequest.isDone()) {
            System.out.println("Cancelling CompleteRequest");
            completeRequest.cancel(true);
        }
    }

    private void setButtonsRunning() {
        buttonCallStream.setDisable(true);
        buttonCallComplete.setDisable(true);
        buttonPicture.setDisable(true);
        buttonBreak.setDisable(false);
    }

    private void setButtonsIdle() {
        buttonCallStream.setDisable(false);
        buttonCallComplete.setDisable(false);
        buttonPicture.setDisable(false);
        buttonBreak.setDisable(true);
        streamRequest = null;
        completeRequest = null;
    }

    // Ensure given model is in memory; preload if needed
    private CompletableFuture<Void> ensureModelLoaded(String modelName) {
        return httpClient.sendAsync(
                HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:11434/api/ps"))
                    .GET()
                    .build(),
                HttpResponse.BodyHandlers.ofString()
            )
            .thenCompose(resp -> {
                boolean loaded = false;
                try {
                    JSONObject o = new JSONObject(resp.body());
                    JSONArray models = o.optJSONArray("models");
                    if (models != null) {
                        for (int i = 0; i < models.length(); i++) {
                            String name = models.getJSONObject(i).optString("name", "");
                            String model = models.getJSONObject(i).optString("model", "");
                            if (name.startsWith(modelName) || model.startsWith(modelName)) { loaded = true; break; }
                        }
                    }
                } catch (Exception ignore) {}

                if (loaded) return CompletableFuture.completedFuture(null);


                String preloadJson = new JSONObject()
                    .put("model", modelName)
                    .put("stream", false)
                    .put("keep_alive", "10m")
                    .toString();

                HttpRequest preloadReq = HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:11434/api/generate"))
                    .header("Content-Type", "application/json")
                    .POST(BodyPublishers.ofString(preloadJson))
                    .build();

                return httpClient.sendAsync(preloadReq, HttpResponse.BodyHandlers.ofString())
                        .thenAccept(r -> { /* warmed */ });
            });
    }
}
