/* 
Copyright (C) 2020 Ernesto Castellotti <mail@ernestocastellotti.it>

	This file is part of ScuolaDRMFree.

    ScuolaDRMFree is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ScuolaDRMFree is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with ScuolaDRMFree.  If not, see <http://www.gnu.org/licenses/>.
*/

module util;

// Configs
enum SCUOLADB_POSIX = ".config/Hoplo/Scuolabook.conf";
enum LINUX_NET = "/sys/class/net";
enum MAC_NULL = "00:00:00:00:00:00";

struct ScuolaDB {
    import semver : SemVer;

    string username;
    string sessionId;
    SemVer clientVersion;
    string[string] activactionKeys;
}

ubyte[] readPdf(string book, ScuolaDB scuoladb) {
    import std.file : read, exists;
    import std.path : buildPath;
    import std.process : environment;

    version(Posix) {
        auto homeDir = environment["HOME"];
        auto pdfFile = buildPath(homeDir, ".scuolabook", scuoladb.username, "books", book, book ~ ".pdf");
        auto pdpFile = buildPath(homeDir, ".scuolabook", scuoladb.username, "books", book, book ~ ".pdp");

        if (!pdfFile.exists) {
            pdfFile = pdpFile;
        }

        assert(pdfFile.exists, "The book was not found, check if the book has been downloaded");
        auto pdf = pdfFile.read();
        assert(pdf.length >= 53, "The pdf is not valid, try to download it again");
        return cast(ubyte[]) pdf;
    } else {
        static assert(0, "This operating system is not supported");
    }

}

ScuolaDB parseScuolaDb() {
    import std.algorithm.searching : findSkip;
    import std.array : replace, split, empty;
    import std.stdio : File;
    import std.file : exists;
    import std.path : buildPath;
    import std.process : environment;
    import semver : SemVer;

    version(Posix) {
        auto homeDir = environment["HOME"];
        auto scuoladbPath = buildPath(homeDir, SCUOLADB_POSIX);
    } else {
        static assert(0, "This operating system is not supported");
    }

    assert(scuoladbPath.exists, "The scuolabook client appears to be installed incorrectly or never opened");
    auto scuolaDbFile = File(scuoladbPath, "r");
    auto scuolaDb = ScuolaDB();

    foreach (line; scuolaDbFile.byLine) {
        if (line.findSkip("sessionID=")) {
            scuolaDb.sessionId = line.idup;
        }

        if (line.findSkip("username=")) {
            scuolaDb.username = line.idup;
        }

        if (line.findSkip("version=")) {
            auto versionStr = line.idup;
            scuolaDb.clientVersion = SemVer(versionStr);
        }
    }

    assert(!scuolaDb.sessionId.empty, "Your sessionID was not found, make sure you are logged into the ScuolaBook client");
    assert(!scuolaDb.username.empty, "Your username was not found, make sure you are logged into the ScuolaBook client");
    assert(scuolaDb.clientVersion.isValid, "It was impossible to detect the version of the ScuolaBook client, check if it has been installed correctly");
    auto backupKeyFormat = scuolaDb.username ~ "\\backupKeys\\";
    scuolaDbFile.rewind();

    // Second foreach to ensure that username has already been obtained
    foreach (line; scuolaDbFile.byLine) {
        line = line.replace("%40", "@");
        if (line.findSkip(backupKeyFormat)) {
            auto lineSplit = line.split("=");
            auto book = lineSplit[0];
            auto key = lineSplit[1];
            scuolaDb.activactionKeys[book.idup] = key.idup;
        }
    }

    assert(scuolaDb.activactionKeys.length >= 1, "The book activation key was not found, check if the book has been downloaded");
    return scuolaDb;
}

string getMacAddress() {
    version(linux) {
        import std.file : readText, exists, isDir, dirEntries, SpanMode;
        import std.path : buildPath;
        import std.algorithm.searching : canFind;
        import std.uni : toUpper;
        import std.string : strip;
        import core.stdc.string : strlen;
        
        assert(LINUX_NET.exists, "Directory " ~ LINUX_NET ~ "does not exist");
        assert(LINUX_NET.isDir, LINUX_NET ~ " is not a directory");

        foreach (string netInterface; dirEntries(LINUX_NET, SpanMode.shallow)) {
            if (netInterface.canFind("eth") || netInterface.canFind("en")) {
                auto addressFile = buildPath(LINUX_NET, netInterface, "address");
                auto address = addressFile.readText;

                if (address != MAC_NULL) {
                    return strip(address).toUpper;
                } 
            }
        }

        assert(0, "The machine's mac address was not found");
    } else {
        static assert(0, "This operating system is not supported");
    }
}

void printPdfList(ScuolaDB scuoladb) {
    import std.file : dirEntries, isDir, exists, SpanMode;
    import std.path : buildPath, baseName;
    import std.process : environment;
    import std.stdio : writeln;

    version(Posix) {
        auto homeDir = environment["HOME"];
        auto booksDir = buildPath(homeDir, ".scuolabook", scuoladb.username, "books");
        assert(booksDir.exists && booksDir.isDir, "The scuolabook client appears to be installed incorrectly or never opened");
        writeln("Books available in your profile:");

        foreach (string book; dirEntries(booksDir, SpanMode.shallow)) {
            if (book.exists && book.isDir) {
                writeln("\t[ID]: ", book.baseName);
            }
        }
    } else {
        static assert(0, "This operating system is not supported");
    }
}