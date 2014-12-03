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

#����һЩ �ļ������� ����
my ( @pubchemids_down, $filepath, $downcas, $identy );

my $debug = 1;
my ( $ua, $req, $res, $url, $xpath );
my ( $casid, $mf, $mw, $savename );
$identy = '2d';    #Сд��2d �����ܳɹ�����

$ua = LWP::UserAgent->new( cookie_jar => {} );
$ua->agent(
    ssl_opts => { verify_hostname => 0 },
'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.4.2.2000 Chrome/30.0.1599.101 Safari/537.36'
);

$ua->requests_redirectable( [] );    #�ر��Զ���ת#��Ҫ

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
    #ʹ��select���������ı�Ĭ�ϵ��ļ����
#���������$|�趨Ϊ1���ͻ�ʹ��ǰ��Ĭ���ļ������ÿ�ν����������������ˢ�»�������
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
            Win32::GUI::DoEvents();    ###��һ�仰��ʲô��˼��
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

    if ( $code == 303 )    #�������cas���ܲ鵽1��pubchemid��
    {
        if ( $res->header('Location') ) {
            $location = $res->header('Location');
            if ( $location =~ /compound\/(\d+)/ ) {
                $chemid = $1;
            }
            else {
                die "location is error��$location\n";
            }

#����xml�ļ�url
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
        $html = $res->content;               ##�õ���������ݲ���utf8ͷ��
        $html = decode( "utf-8", $html );    ##�õ�utf8ͷ

        $tree = HTML::TreeBuilder::XPath->new_from_content($html);

#cid����
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[2]/div/dl/dd
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[2]/div/dl/dd
        $xpath =
'/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div/div[2]/div/div[2]/div/dl/dd';
        @cids = $tree->findvalues($xpath);

#������
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[1]/dl[1]/dd[1]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[1]/dl[1]/dd[1]
#����ʽ
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
            #####�����һ��value���������ͼ�һ�����ֱ������ٸ�����ʽ

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
    my @elements = $string =~ /([A-Z][a-z]*)(\d*)/g;  ##���Զ���ӿ�Ԫ��nice����
         #    print join "\n",@elements;

    #      print "\n";
    my $num = @elements;

    for ( 0 .. $num / 2 - 1 ) {

        ##��Ԫ��ת���ɴ�д  Ca--��CA��   c--��C
        ##
        ##��������������2����ĸ������һ��дһСд
        ##���еķ���ʽ�����������ʾ��
        ################################
        $_ *= 2;
        $hash{ $elements[$_] } += $elements[ $_ + 1 ] ? $elements[ $_ + 1 ] : 1;

        #  print "$_ *****\n";
    }
    return %hash;
}

1;
