import std.stdio;
import std.getopt;
import dhtslib;
import barcodes;
import hamming;

void main(string[] args)
{	
	int threads = 0;
    bool u;
    bool s;
    bool b;
	int maxmis=3;
	string oldtag="OB";
	string barcodetag="RX";
    GetoptResult res;
    try
    {
        res = getopt(args, 
			"threads|t", "Threads for decompression/compression (will be split)",&threads,
			"max-mismatches|m","maximum number of mismatches allowed in barcode", &maxmis,
			"old-tag|x","tag to store old, uncorrected barcode", &oldtag,
			"tag|z","tag that contains barcode and tag to store corrected barcode", &barcodetag,
			"bam|b", "output uncompressed bam", &b, 
			"ubam|u", "output bam", &u, 
			"sam|s", "output sam", &s);
    }
    catch (GetOptException e)
    {
        stderr.writeln(e.msg);
        stderr.writeln("Run with --help/-h for detailed usage information");
    }
    if (res.helpWanted || args.length < 2)
    {
        defaultGetoptPrinter("\nnmasker usage: ./nmasker [options] [bam/sam] (bam/sam out)\n",
                res.options);
        stderr.writeln();
        return;
    }
    auto bamr = SAMReader(args[1], (threads >> 1) + (threads & 1));
    SAMWriter bamw;
    if (args.length > 3)
    {
        bamw = SAMWriter(args[3], bamr.header, SAMWriterTypes.DEDUCE, threads >> 1);
    }
    else
    {
        switch ((b << 2) | (u << 1) | (s))
        {
        case 0b100:
            bamw = SAMWriter(stdout, bamr.header, SAMWriterTypes.BAM, threads >> 1);
            break;
        case 0b10:
            bamw = SAMWriter(stdout, bamr.header, SAMWriterTypes.UBAM, threads >> 1);
            break;
        case 0b1:
        case 0:
            bamw = SAMWriter(stdout, bamr.header, SAMWriterTypes.SAM, threads >> 1);
            break;
        default:
            stderr.writeln("Odd combination of output flags");
            return;
        }
    }
	auto barcodes = loadBarcodes(args[2]);
	auto kmers = getBarcodeKmers(barcodes);
	auto hashmap = getBarcodeHashmap(barcodes);
	foreach(rec;bamr.all_records){
		// if(rec["CB"].data is null) continue;
		auto barcode = rec[barcodetag].toString;
		rec[oldtag]=barcode;
		string match = compareBarcodes(barcode,kmers,hashmap,barcodes,float(maxmis)/float(barcodes[0].length));
		if(match=="") continue;
		rec[barcodetag]=match;
		bamw.write(&rec);
	}
}
