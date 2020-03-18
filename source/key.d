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

module key;

import util : ScuolaDB;
import std.digest.md : digestLength, MD5;

ulong computePdfKey(string book, ScuolaDB scuoladb) {
    import std.bitmanip : nativeToBigEndian, bigEndianToNative;
    import std.digest.md : md5Of;
    import std.digest : toHexString;
    import util : parseScuolaDb;
    import std.stdio : writeln;

    auto usernameHash = md5Of(scuoladb.username);
    auto deviceId = getDeviceId();
    auto activationKey = getActivationKey(book, scuoladb);
    ubyte[digestLength!MD5] key1;
    ubyte[8] keyBytes;

    foreach (i, ref elem; key1) {
      elem = deviceId[i] ^ usernameHash[i];
    }

    foreach(i, ref elem; keyBytes) {
        elem = activationKey[i + 8] ^ key1[i + 8];
    }

    auto key = bigEndianToNative!ulong(keyBytes);
    
    writeln("Book: ", book);
    writeln("Username: ", scuoladb.username);
    writeln("Username Hash: ", usernameHash.toHexString);
    writeln("Device Id: ", deviceId.toHexString);
    writeln("Activation key: ", activationKey.toHexString);
    return key;
}

ubyte[digestLength!MD5] getDeviceId() {
    import std.digest.md : md5Of;
    
    version(Posix) {
        import util : getMacAddress;
        auto address = getMacAddress();
        return md5Of(address);
    } else {
        static assert(0, "This operating system is not supported");
    }
}

ubyte[] getActivationKey(string book, ScuolaDB scuoladb) {
    import std.algorithm.iteration : map;
    import std.range : chunks;
    import std.conv : to;
    import std.array : array;

    auto activationKey = scuoladb.activactionKeys[book];
    auto activationKeyHash = activationKey.chunks(2)
                        .map!(digits => digits.to!ubyte(16))
                        .array;
    
    assert(activationKeyHash.length == digestLength!MD5, "The book activation key is not valid");
    return activationKeyHash;
}
