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

void main(string[] args) {
	import std.stdio : writeln, readln;
	import std.path : absolutePath, dirName;
	import std.file : write, exists, isDir;
	import drm : computePdfMagic, removeDrm;
	import util : parseScuolaDb, readPdf, printPdfList;

	writeln();
	writeln("Welcome to ScuolaDRMFree!");
	writeln("Copyright 2020 Ernesto Castellotti <mail@ernestocastellotti.it>");
	writeln("License: AGPL-3.0");
	writeln();

	auto scuoladb = parseScuolaDb();

	if (args.length != 3) {
		writeln("Usage: [BOOK ID] [OUTPUT PDF PATH]");
		writeln();
		printPdfList(scuoladb);
		return;
	}

	auto bookName = args[1];
	auto outputPath = args[2].absolutePath;
	assert(outputPath.dirName.exists && outputPath.dirName.isDir, "The output path directory does not exist");
	auto pdf = readPdf(bookName, scuoladb);
	auto magic = computePdfMagic(bookName, pdf, scuoladb);
	writeln("Output path: ", outputPath);
	writeln();
	writeln("--------");
	writeln("USE THIS SOFTWARE ONLY TO REMOVE THE DRM FROM BOOKS, TO ALLOW YOU A STUDY IN FREEDOM!");
	writeln("PLEASE DO NOT INFRINGE THE COPYRIGHT WITH THIS TOOL, THE DRM WOULD NOT EXIST IF EVERYONE WAS RESPONSIBLE");
	writeln("--------");
	writeln();
	writeln("Press any key to confirm the removal of the DRM");
	readln();
	removeDrm(magic, pdf);
	write(outputPath, pdf);
	writeln();
	writeln("DRMs have been successfully removed!");
	writeln("Your eBook is freely available at ", outputPath);
}
