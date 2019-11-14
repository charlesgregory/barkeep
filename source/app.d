import std.stdio;
import std.getopt;
import dhtslib;
import barcodes;
import hamming;

string message = "
                               ,g@@@@@@Www_
                            ,#@MK\"M\"7@@@@#@@W
                          _j@\"*WH@@@@KM\"`\"|@@@
                          $@   `]bM\"     |I@@@@
                          @b             \"|\"*@@w~
                          ]@p       -   ' jp#@@j@
                          =@@ '~.,;s_,pwg@@@Nj@@@h
                          [@B@]@@@@@@@@h}}@bF]@@@@M
                        _,J@@ ]X5@F}M@@_\"@@F @]@@@F
         ___         ,#FV ,#@@_`'\"|# \"@@@@pI@U@@@@@@@@@w,__
        jbjj@      ,\"\"#p) [\"@AM#@YFW@_@@@@@@@@@@@@@@@@@@@@@@@@,
        m ap@F   .*    j@}[@`]@@p5@@@@#K@@@@@@@b@@@@@@@@@@@@bjb}@pw
       ]   } }   F   \\, ]@b\"@!}@@@@@@@@@M\"@@@}@@@@@@@@@@@@@b}Fj@'}F]w,
       [   j   .h_     Yj@]pj@j@@@@@@ppp@@@b#}@@@@@@@@@@@@b@\\F.F_,M|@bb
              @~p ,`W_ `_\"@@@@@@@@@@@@@@@@@@@@|@@@@@@@@@@bj}.F.^  j/_@@
      j      ,]b`,jp \"V }F]@p@@@@@@@@@@@@@@@_ j@@@@@@@@@jm jb ,@ _#@@@@N_
      @;    !  b, ;b. j@jU}@@j@}@@b\"@@@@@@@@@pj@@@@@@@@@@bj}bm,@@@@M\"\"\"\"@N
     / .     , *@@@@@@@p@@@@@p@pj@@p`]@@@@@@@@|@@@@@@@@@@U,]@@@KbF-w;@@@#@h
   .',#\"     'pp`@\"=#@@@@@@@@@@@@@@@W]@@@@@@@@Nj@@@@@@@@@@b]@M.\",@#BM\"\" `T\"@
   [ |  ,|   j\"@p]_   `\"\"$M@@@@@@@@@@@,` \"@@@@@@@@@@@@@@@@@@bpj@F _,,      |@p
   [.         |`F]__}# !@@#@@@@@@@@@@@@N_ F'=\"@@@@@@@@@@@@@@@|]M./@@@@M\"\"=@pj@p
   sw__   _  j jh]#\"f\"F#@@@@@@@@@@@@@@@@@@pp##@]@@@@@@@@@@@@@@ !/@M\"'     j@pF@
   }p     ] '``\" ]_wF_,@#@@@@@@@@@@@@@@@@@@@b@@@@@@@@@@@@@@@@@ jM    . ,;I|j@F]
   jb     ]m#@@@ ]@K*`  \"_@@M=K#B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P    ~.' .|j@@@P
   jF     ]bj|j@h]   .#@@M                     '\"]@@@@@@@@@@@M\"     , ,j@@@F@\"
   jF     ]b}Fj@h] ##@F}\\F,~                  ,~,]@@@@@@@@M\"        w@@@FF)m
   jF     ]bjFj@b]p@@                  _,,,p##@@@@@@@@@M`        .@@F\"|jM\"
   ]b_   ,]p@@j@p]@@b;w,,_|,w|,,,,pppw@@@@@@@@@@KM\"\"`    _   s@@@@@@@@@pmW,_
   ]#@p,,@@@j@M@@@@Kb@K@@@@pp@@@@@@@@@@@@@\"\"\"\"'|w ___/' ` |jpF@@@KM\" ``U||||@_
   ] @b j@Fj@]bw``,,,w#@@@@@@@@FFF}}555jM j`.#p@ ;|}b_`wwp|@j@P\" . `w@@X|}|||}b
   ] @@ ]@@@}@bj jF@@@]@@@F@##=#m@@@\"\"f ;F ;j@@ .j@@@ .}@@@@@\" `},@@@@@@@mm==U[
   j@@]KBBbfF@@Fbj\"}jh@@b@b55m5@@\"\"~ /.z\" @@@M_~j@@M_,@@@Fw.,_z@@K\"\",gwp@F|||@
  jp||\"\"@@@@@@@@_,j#@@@@@@}@\"\"\"\"@p, \"\"\"=##M\"\".#jM\" ,j#^~~p_p@@@@@@@@@F\"\"||||},
   _@hm.`\"\"I\"IF'\"\"\"\"\"\"####6F.sj@j@@@p@#,,@_   `_ppwp,p#@@##@bb\"FF|||||\"\"\"\"X555h
  @@@@@@@@@@\"\"\"\"\"\"\"\"\"\"\"\"\"\"@B%@\"MRM@\"@M]@BB@@hwMB@BM},@@BBM@M@@@@*@BBR@*@BBBBR@@
  ]@@@@@@@@@@@@@@@@@@@@@@@@@w@w&w@@w@w@_@U__w@Uwww@@@B@ww@@ww_@Nwww@w@@@@wwwgl@
";

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
        defaultGetoptPrinter(message~
			"\nbarkeep: He'll clean up those barcodes for ya"
			"\nbarkeep usage: ./barkeep [options] [bam/sam] [list of barcodes] (bam/sam out)\n",
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
