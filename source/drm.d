/* 
Copyright (C) 2020 Ernesto Castellotti <mail@ernestocastellotti.it>
Copyright (C) 2020 Davide Repetto

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

module drm;

import util : ScuolaDB;

void removeDrm(uint magic, ubyte[] pdf) {
    import std.stdio : writeln;
    import std.algorithm.searching : findSkip, countUntil;
    
    auto pdfNew = pdf;
    while (true) {  
        if (!pdfNew.findSkip("\x0D\x0Axref\x0D\x0A")) {
            break;
        }

        auto endXref = pdfNew.countUntil("\x0D\x0Atrailer\x0D\x0A");
        auto table = pdfNew[0..endXref];
        fixXrefTable(magic, cast(char[]) table, pdf);
    }
}

void fixXrefTable(uint magic, char[] table, ubyte[] pdf) {
    import std.stdio : writeln;
    import std.format :  formattedRead, formattedWrite;
    import std.algorithm.searching : findSkip, countUntil;

    while (true) {
        uint start;
        uint len;

        if (table[0] < '0' || table[0] > '9') {
            break;
        }

        table.formattedRead!"%u %u"(start, len);
        table.findSkip("\x0D\x0A");
        auto end = start + len;

        foreach (i; start..end) {
            uint offset;
            uint gen;

            auto tableReader = table;
            auto tableWriter = table;
            tableReader.formattedRead!"%u %u"(offset, gen);

            if (offset != 0) {
                writeln("Obfuscated offset: ", offset);
                offset ^= magic;
                assert(offset <= pdf.length, "The computed magic number is wrong, probably this tool is no longer compatible");
                tableWriter.formattedWrite!"%010u"(offset);
                table[10] = ' ';
                auto object = pdf[offset..$];
                auto endObject = object.countUntil("endobj");
                object = object[0..endObject];
                fixObjectNumber(i, object);
                writeln("Fixed offset: ", offset);
            }

            table.findSkip("\x0D\x0A");
        }
    }
}

void fixObjectNumber(uint number, ubyte[] object) {
    import std.algorithm.searching : countUntil;
    import std.format : format, formattedWrite;

    auto objectWriter = object;
    auto oldObjectNumberLength = object.countUntil("\x20");
    assert(oldObjectNumberLength != 0, "The PDF file is not valid, probably this tool is no longer compatible");
    auto objectNumberFormat = format!"%%0%uu"(oldObjectNumberLength);
    objectWriter.formattedWrite(objectNumberFormat, number);
    object[oldObjectNumberLength] = ' ';
    assert(oldObjectNumberLength == object.countUntil("\x20"), "There is no more space in the PDF file, currently this tool cannot remove the DRM from this file");
}

uint computePdfMagic(string book, ubyte[] pdf, ScuolaDB scuoladb) {
    import key : computePdfKey;
    import std.digest : toHexString;
    import std.stdio : writeln;

	auto pdfKey = computePdfKey(book, scuoladb);
	auto bookKey = decodeBookKey(pdf);
    auto magic = cast(uint) (pdfKey % bookKey);

    writeln("PDF computed key: ", pdfKey);
    writeln("PDF decoded key: ", bookKey);
    writeln("PDF magic key: ", magic);
    return magic;
}

private ulong decodeBookKey(ubyte[] pdf) {
    import std.conv : to;

    ubyte[] header = pdf[11 .. 11 + 42];
    int x = pdf.length & 0x7F;

    foreach(ref ubyte headerElem; header) {
        headerElem ^= x;
        x = (x + 1) & 0x7F;
    }

    char[] bookKeyStr = cast(char[]) header[26 .. $];
    auto bookKey = to!ulong(bookKeyStr, 16);
    header[0..$] = 0;
    return bookKey;
}