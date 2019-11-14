import std.stdio;
import std.getopt;
import dhtslib;
import barcodes;
import hamming;

string message = "
                               ,g#@@@@#pww_
                            ,#bMM\"M\"7[}#@#@@w
                          _j@\"*WH@@#@K\"  ' }@@
                          $M   `\\FF`      |j@@@
                          b[               `*@@ ~
                          ]@p             jy ]N.@
                          =@p  ~.,,  ,;,g@@@hj@@$h
                          [%Mb}@@##@@@@hJ}jb ]]bj@M
                        _,,{@ }*^jF}F@p \"=F  j]@@@2
         ___         ,mF. ,#@#_ `\" # \"*0#@w @.@@@@@@@@#w,__
        j |j]      ,\"\"=,: [\"@AMV[VFWp_@@@@@Nj@@@@@@@@@@@@@@F@#,
        m sppp   .*    jp}[/ ]@W_~@@@@#M}@Y5]@@F@@@@@@@@@@@jFY\"\"@w,
       ]   } }   F   \\, ]@F'b|]@@@b,}@@bM\"}@m}F@@@@@@@@@@}Tb, ;F 'F]w,
       [   j   .~      Y!$]pjpj@@@@@pw,pp@#\"/j@}}@@@@@@@@bF;.F '_,*|jpb
              @~  ,`y_  _\"pbF@}@@@p|f\"@@@@@pp# @I@@@@@@@@F;; F ^  |'_#j
      j       ]b` '_ `. }U]@F]p@@$\"@@@@@@@@@   @@@@@@@@@jm ;F ,@ _p@@@@N_
      [.       b, ,F. *@,,}@@jb}@F,\"}@@@@\"@@@_ @@@@@@@@@@P;\"bm_#@@@M\"\"\"\"\"p
     /       _ *@%@@@@hp|@@I@p]_!@pp ]@@@Fj@@@ @@@@@@@@@@ ,]@@@K\"F-w;@}jW,h
    './`      F,`@\"*#@@@@@@@@@@@@@@pb]@@U}|\"@@b)@@@@@@@@@pbj@M \",g#KM\"\" `\"\"@
   [    ,    ! 'pj     \"\"]\"@@@@@@@@@@@_` \"##@I@@@@@@@@@@@@p@bFj@  __,       @p
   r            F] _|p  @@#/@@@@@@|@@@@h_  '=\"]@@@@j@@@@@@@b@,]F /1@@@M\"*=W_!j
   s.__      | ! ]F\"f\"~spw#@@@@@@@@@@@@@pN_Vp#/]@@@@@@@@@@@@@@ !/@M\"'     j@p\"h
   }p     ] ```` j_,\"_,gWw}@@@@@@@@@@@@@@@p@U}@@b@@@@@@@@@@@@N jM      ..` j@F]
    b     ]###@@ jpM*   '_w#M*MKB@@@@@@@@@@@N@@@@]@@@@@@@@@@@@@P    -     ;@@bF
    ,     ] | 'j ]   .=@@M                      \"}@@@@@@@@@@@P         ,j@@\"f\"
   !      ] jF!j ] Vp@F\"  ,                   ,  ]#@@@@@@@\"`        ,#@F\" _M
   j      ] |,!j,]_@@                   .,,ww=p@@5~IF@}M         .j@\"' _M`
   jp_   .]p|,.jF]p@b .,,_,..   ,_,,,,#@F\"\"_,@@@M^\"`         ;j@@F_,w#MpmW,_
   ]#pp.,,@Fj5F@@@lKb@F@@@pwpp@_,,ap@@@@@@\"\"``'..  _ /'    !pF_,#K\"\" ``.    #_
   ] I[ j  ||]bw``_,,w#@@@@@F\"IF\"\"\"\"\"*~:M s`.#/# . jb_ .w_,/)@\"`   `,@QX `'\"` p
   ] @b ]@F`\"}b| j @F@j@bbb...~~~*\"j*\"\" ;F ;|/@  |/@@  j@_w@@\"  ;,@@@\"K@m=*** [
   j@p\"=MM%\"\"}@*bj\"`.\\@@F.'**~^!@\"\"~ /.,\" @@@M_-,@@M ,@@bF-.,_;@#M\"\",;wwF    #
  j,  `\"\"@@\"\"\"}@_,j#@@@@F\",,'''\"U__ `\"\"=##M\"\".m;M\" ,;#\"~~__p##_a#@@F|\"\"`    \",
   _]#m ``'''\"! `\"\"\"\"\"~=#=F' .!||@@@ppa,,@_   ` pw_,,w#M,m##\"\"\"\"\"    ``\"\"\"****h
  [\"8@@@@@\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"B%\"\"fhM[\"$*]@BB@@hwMB@BM\",@@BBM@M@@@M*@BBR\"*]BBBBR@%
  *@@@@@@@@@@@@@@@@@@@@@@@@@w@wNw@@w@w@_@U__w@Uwww@@@B@ww@@ww_@Nwww@w#l@@wwwal@
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
			"\nbarkeep: He'll clean up those barcodes for ya"~
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
	bamw.close;
}
