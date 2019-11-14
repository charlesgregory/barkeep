module barcodes;
import std.stdio;
import dklib.klib.khash;

string[] loadBarcodes(string filename){
    string[] barcodes;
    foreach(line;File(filename).byLineCopy){
        barcodes~=line;
    }
    return barcodes;
}

string * [][string][] getBarcodeKmers(string[] barcodes){
    auto kmerNum=barcodes[0].length-4;
    string *[][string][] kmers = new string *[][string][kmerNum];
    for(auto j=0;j<barcodes.length;j++){
        for(auto i=0;i<kmerNum;i++){
            kmers[i][barcodes[j][i..i+4]]~=&(barcodes[j]);
        }
    }
    return kmers;
}

byte[string] getBarcodeHashmap(string[] barcodes){
    byte[string] hashmap;
    foreach(barcode;barcodes){
        hashmap[barcode]=0;
    }
    return hashmap;
}

unittest{
    string[] barcodes=["GATCGATGCTACGTACGAT","GATCGATGCTACGTACGAT","GATCGATGCTACGTACGAT"];
    getBarcodeKmers(barcodes);
}