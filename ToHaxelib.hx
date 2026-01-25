import sys.FileSystem;
import sys.io.File;

class ToHaxelib {
    static function main() {
        var outDir = "haxelib";

        Sys.println("Preparing haxelib package in " + outDir + "...");

        // Clean previous export
        if (FileSystem.exists(outDir)) {
            Sys.println("Cleaning " + outDir + "...");
            deleteRecursively(outDir);
        }

        FileSystem.createDirectory(outDir);

        var items = ["src", "README.md", "build.hxml", "haxelib.json"];
        
        for (item in items) {
            if (FileSystem.exists(item)) {
                var dest = outDir + "/" + item;
                if (FileSystem.isDirectory(item)) {
                    copyDir(item, dest);
                } else {
                    File.copy(item, dest);
                }
                Sys.println("Copied " + item);
            } else {
                Sys.println("Warning: " + item + " not found!");
            }
        }

        Sys.println("Done. Files are in '" + outDir + "'.");
        Sys.println("Ready to submit.");
    }

    static function deleteRecursively(path:String) {
        if (FileSystem.isDirectory(path)) {
            for (entry in FileSystem.readDirectory(path)) {
                deleteRecursively(path + "/" + entry);
            }
            FileSystem.deleteDirectory(path);
        } else {
            FileSystem.deleteFile(path);
        }
    }

    static function copyDir(src:String, dest:String) {
        FileSystem.createDirectory(dest);
        for (entry in FileSystem.readDirectory(src)) {
            var srcPath = src + "/" + entry;
            var destPath = dest + "/" + entry;
            if (FileSystem.isDirectory(srcPath)) {
                copyDir(srcPath, destPath);
            } else {
                File.copy(srcPath, destPath);
            }
        }
    }
}
