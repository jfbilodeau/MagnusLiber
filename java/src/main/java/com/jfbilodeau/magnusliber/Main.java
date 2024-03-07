package com.jfbilodeau.magnusliber;

import com.google.gson.Gson;

import java.nio.file.Files;
import java.nio.file.Paths;

public class Main {
    public static void main(String[] args) throws Exception {
        // Do we have a `MagnusLiber.dev.json` file?
        var configurationFile = Paths.get("../MagnusLiber.dev.json");

        if (!Files.exists(configurationFile)) {
            // No, use the default `MagnusLiber.json` file
            configurationFile = Paths.get("../MagnusLiber.json");
        }

        // Read the configuration file
        String configurationJson = Files.readString(configurationFile);
        Configuration configuration = new Gson().fromJson(configurationJson, Configuration.class);

        // Create and run the application
        MagnusLiber app = new MagnusLiber(configuration);
        app.run();

        // Force exit
        System.exit(0);
    }
}
