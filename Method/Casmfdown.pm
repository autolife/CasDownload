package Method::Casmfdown;
use warnings;
use strict;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request::Common qw( POST GET);
use HTML::TreeBuilder::XPath;
use XML::Simple;
use Encode qw(decode);
use Win32::GUI();

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(downcasmf);

#use utf8 qw(to_utf8);
binmode STDIN,  ':utf8';
binmode STDOUT, ':utf8';

#定义一些 文件作用域 变量
my ( @pubchemids_down, $filepath, $downcas, $identy );

my $debug = 1;
my ( $ua, $req, $res, $url, $xpath );
my ( $casid, $mf, $mw, $savename );
$identy = '2d';    #小写的2d 否则不能成功下载

$ua = LWP::UserAgent->new( cookie_jar => {} );
$ua->agent(
    ssl_opts => { verify_hostname => 0 },
'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.4.2.2000 Chrome/30.0.1599.101 Safari/537.36'
);

$ua->requests_redirectable( [] );    #关闭自动跳转#重要

$url = 'http://pubchem.ncbi.nlm.nih.gov/';

$req = GET($url);

sub downcasmf {
    my @casnos = @{ $_[0] };
    my @mfs    = @{ $_[1] };
    my %wantmf;

    my $numofmol    = @casnos;
    my $downdir     = $_[2];
    my $progressbar = $_[3] ? $_[3] : 0;
    my $casid;

    my $logfile = $downdir . 'readme.log';
    open LOG, ">$logfile";
    select LOG;
    $|=1;
    #使用select操作符来改变默认的文件句柄
#将特殊变量$|设定为1，就会使当前的默认文件句柄在每次进行输出操作后，立刻刷新缓冲区。
    if ( $progressbar == 0 ) {
        for ( 1 .. $numofmol ) {
            $casid  = $casnos[ $_ - 1 ];
            %wantmf = &convert( $mfs[ $_ - 1 ] );
            &downcasidmf( $casid, \%wantmf, $downdir );
        }
    }
    else {
        $progressbar->Show(0);
        $progressbar->Show(1);
        $progressbar->SetRange( 0, $numofmol );
        for ( 1 .. $numofmol ) {
            $casid  = $casnos[ $_ - 1 ];
            %wantmf = &convert( $mfs[ $_ - 1 ] );
            &downcasidmf( $casid, \%wantmf, $downdir );
            Win32::GUI::DoEvents();    ###这一句话是什么意思？
            $progressbar->SetStep(1);
            $progressbar->StepIt();
         #   Win32::Sleep(1000);
        }
    }
    
    close(LOG);
}

sub downcasidmf {
    my $casid           = $_[0];
    my %wantmf          = %{ $_[1] };
    my $downdir         = $_[2];
    my @pubchemids_down = &casidmf2pubchemids( $casid, \%wantmf );

    if ( @pubchemids_down == 0 ) {
        print LOG "cas:$casid not  correpond to pubchemid\n";

        #			print  "cas:$casid not  correpond to pubchemid\n";
        #print LOG "0\n";

    }
    else {
        my $num = @pubchemids_down;

#		print "cas:$casid correspond to pubchemid ",join ", ",@pubchemids_down," have $num pubchemcidS\n";
        print LOG "cas:$casid correspond to pubchemid ", join ", ",
          @pubchemids_down, " have $num pubchemcidS\n";

        #print LOG "2";
        foreach my $id (@pubchemids_down) {
            $url =
                'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/'
              . $id
              . '/record/SDF/?response_type=save&record_type='
              . $identy;
            $savename = $downdir . $casid . '_cid_' . $id . '.sdf';

            #	   print "$url\n";
            #print $savename,"\n";
            #	   	print "$savename\n";
            $ua->get( $url, ':content_file' => $savename );

            #print "download $casid\n";
        }

    }

}

sub casidmf2pubchemids {
    my $casid  = $_[0];
    my %wantmf = %{ $_[1] };
    my ( %mfpubchem, $mf_pubid );
    my ( $html, );

    my $xml;
    my $data;
    my ( $chemid, $location, $code, @chemids );
    my ( $tree, @cids, @mfs );

    ## my $savename='1.xml';
    $url = 'http://www.ncbi.nlm.nih.gov/pccompound?term=' . $casid;
    $req = GET($url);

    $res  = $ua->request($req);
    $code = $res->code;

    if ( $code == 303 )    #根据这个cas号能查到1个pubchemid号
    {
        if ( $res->header('Location') ) {
            $location = $res->header('Location');
            if ( $location =~ /compound\/(\d+)/ ) {
                $chemid = $1;
            }
            else {
                die "location is error：$location\n";
            }

#构建xml文件url
#'https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/13770/XML/?response_type=display
#https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/60750/record/SDF/?record_type=2d&response_type=display
            $url =
                'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/'
              . $chemid
              . '/record/SDF/?record_type=2d&response_type=display';
            $html = get($url);

            #> <PUBCHEM_MOLECULAR_WEIGHT>
            #263.198146
            if ( $html =~ /PUBCHEM_MOLECULAR_FORMULA>\n(\S+)\n/ms ) {
                $mf_pubid  = $1;
                %mfpubchem = &convert($mf_pubid);
            }
            else {
                die "can't find weight\n";
            }

            # print output

#print Dumper($data);
#  $mw_pubid= $data->{Section}->[3]->{Section}->{Section}->[0]->{Information}->{NumValue};

            if ( %mfpubchem eq %wantmf ) {
                push @chemids, $chemid;
            }
            else {
#	    	print "error:can't find the compound cas id:    $casid  pubchem id $chemid, the mf is differnt\n";
            }
        }
    }
    elsif ( $code == 200 ) {
        $html = $res->content;               ##得到的这个内容不带utf8头的
        $html = decode( "utf-8", $html );    ##得到utf8头

        $tree = HTML::TreeBuilder::XPath->new_from_content($html);

#cid号码
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[2]/div/dl/dd
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[2]/div/dl/dd
        $xpath =
'/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div/div[2]/div/div[2]/div/dl/dd';
        @cids = $tree->findvalues($xpath);

#分子量
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[1]/dl[1]/dd[1]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[1]/dl[1]/dd[1]
#分子式
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[1]/dl[1]/dd[2]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[3]/div[2]/div/div[1]/dl[1]/dd[2]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[*]/div[2]/div/div[1]/dl[1]/dd[2]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[1]/dl[1]/dd[2]
        $xpath =
'/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div/div[2]/div/div[1]/dl[1]/dd[2]';
        @mfs = $tree->findvalues($xpath);

        ####
        if ( $#cids != $#mfs ) { die "praser error " }
        my %cidmf = map { $cids[$_], $mfs[$_] } ( 0 .. $#cids );
        foreach my $key ( keys %cidmf ) {
            #########*************************************
            ###########*******************************
            #####如果是一个value，数组最后就加一个数字表征多少个分子式

            #print "ffff$cidmf{$key}\n";
            %mfpubchem = &convert( $cidmf{$key} );

            #print Dumper(%mfpubchem);

            if ( %mfpubchem eq %wantmf ) {
                push @chemids, $key;
            }
            else {

                # 		print Dumper(%mfpubchem);
                # 		print "aaaa\n";
                # 		print Dumper(%wantmf);
                # 		print "bbbb\n";
            }
        }
    }
    return @chemids;
}

sub convert {
    my $string   = $_[0];
    my %hash     = ();
    my @elements = $string =~ /([A-Z][a-z]*)(\d*)/g;  ##会自动添加空元素nice特性
         #    print join "\n",@elements;

    #      print "\n";
    my $num = @elements;

    for ( 0 .. $num / 2 - 1 ) {

        ##把元素转换成大写  Ca--〉CA；   c--〉C
        ##
        ##正则表达是利用了2个字母的特性一大写一小写
        ##所有的分子式都是这样彪表示的
        ################################
        $_ *= 2;
        $hash{ $elements[$_] } += $elements[ $_ + 1 ] ? $elements[ $_ + 1 ] : 1;

        #  print "$_ *****\n";
    }
    return %hash;
}

1;
