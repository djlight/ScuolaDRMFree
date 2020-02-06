void main(string[] args) {
	import std.stdio : writeln, readln;
	import std.path : absolutePath;
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
	assert(outputPath.exists && outputPath.isDir, "The output path is not a directory or does not exist");
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
