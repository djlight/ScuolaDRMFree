module key;

import util : ScuolaDB;
import std.digest.md : digestLength, MD5;

ulong computePdfKey(string book, ScuolaDB scuoladb) {
    import std.digest.md : md5Of;
    import std.digest : toHexString;
    import util : parseScuolaDb;
    import std.stdio : writeln;

    auto usernameHash = md5Of(scuoladb.username);
    auto deviceId = getDeviceId();
    auto activationKey = getActivationKey(book, scuoladb);

    ubyte[digestLength!MD5] key1;
    for(int i = 0; i < digestLength!MD5; i++) {
        key1[i] = deviceId[i] ^ usernameHash[i];  
    }

    ulong key;
    auto keyPtr = cast(ubyte*) &key;
    for(int i = 0; i < 8; i++) {
        keyPtr[7 - i] = activationKey[i + 8] ^ key1[i + 8];
    }
    
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