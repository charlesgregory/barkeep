module hamming;
import std.stdio;

float hammingDistanceNaive(string one,string two){
    auto mis=0;
    for(auto i=0;i<one.length;i++){
        if(one[i]!=two[i]) mis++;
    }
    return float(mis)/float(one.length);
}

string getClosestNeighbor(string barcode, string * [] barcodes,float maxDiff){
    string closest;
    float score=1000.0;
    float val;
    foreach(b;barcodes){
        val=hammingDistanceNaive(barcode,*b);
        if(val<score){
            score=val;
            closest=*b;
        }
    }
    if(score<maxDiff) return closest;
    else return "";
}
string getClosestNeighbor(string barcode, string[] barcodes,float maxDiff){
    string closest;
    float score=1000.0;
    float val;
    foreach(b;barcodes){
        val=hammingDistanceNaive(barcode,b);
        if(val<score){
            score=val;
            closest=b;
        }
    }
    if(score<maxDiff) return closest;
    else return "";
}

string compareBarcodes(string barcode, string * [][string][] kmers, byte[string] hashmap, string[] barcodes, float maxDiff){
    if((barcode in hashmap) !is null) return barcode;
    auto kmerNum=barcodes[0].length-4;
    string * [] matches;
    for(auto i=0;i<kmerNum;i+=4){
        auto ptr =barcode[i..i+4] in kmers[i];
        if((ptr) !is null) matches~=*(ptr);
    }
    if(matches.length>0){
        return getClosestNeighbor(barcode,matches,maxDiff);
    }
    for(auto i=0;i<kmerNum;i++){
        auto ptr =barcode[i..i+4] in kmers[i];
        if((ptr) !is null) matches~=*(ptr);
    }
    if(matches.length>0) {
        return getClosestNeighbor(barcode,matches,maxDiff);
    }
    return getClosestNeighbor(barcode,barcodes,maxDiff);
}