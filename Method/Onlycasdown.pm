package Method::Onlycasdown;


use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request::Common qw( POST GET);
use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use XML::Simple;
use warnings;
use strict;
use Encode qw(decode);
use Win32::GUI ();

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(onlycasdown);
#use utf8 qw(to_utf8);
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8'; 


#����һЩ �ļ������� ����
	my(@pubchemids_down,$filepath,$downcas,$identy);

	my ($ua,$req,$res,$url,$xpath); 
		my ($casid,$mf,$mw,$savename);	
	 $identy='2d';                     #Сд��2d �����ܳɹ�����
		
		$ua = LWP::UserAgent->new( cookie_jar=>{});
		$ua->agent(ssl_opts => { verify_hostname => 0 },'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.4.2.2000 Chrome/30.0.1599.101 Safari/537.36');
	
	$ua->requests_redirectable([ ]);  #�ر��Զ���ת#��Ҫ
	
	$url='http://pubchem.ncbi.nlm.nih.gov/';

$req=GET($url);

##test #########

#my @casnos=('987-65-5','98717-15-8','96946-42-8');
#my $downdir='f:/cas/';
#&onlycasdown(\@casnos,$downdir);
###

#	&onlycasdown(\@casnos,$downdir,$progressbar);
sub onlycasdown
{
	my @casnos=@{$_[0]};

	my $numofmol=@casnos;
	my $downdir=$_[1];
	my $progressbar=$_[2]?$_[2]:0;
  my $casid;
  my $logfile=$downdir.'readme.log';
	open LOG,">$logfile";
	select LOG;
    $|=1;
    #ʹ��select���������ı�Ĭ�ϵ��ļ����
#���������$|�趨Ϊ1���ͻ�ʹ��ǰ��Ĭ���ļ������ÿ�ν����������������ˢ�»�������
#	print LOG "start";
	if($progressbar==0)
	{
		for(1..$numofmol)
		{
			$casid=$casnos[$_-1];
			
			&downcasid($casid,$downdir);
			
		}
		
		
		
	}
	else
	{
		  $progressbar->Show(0); #���ڲ�����ʾ��û����յ�Ч�� ��������
			$progressbar->Show(1);
			###��һ�� ��ս������Ĵ���
	
  $progressbar->SetRange(0,$numofmol);
      for(1..$numofmol)
      {
   
			  $casid=$casnos[$_-1];
			  	&downcasid($casid,$downdir);
			 
        Win32::GUI::DoEvents(); ###��һ�仰��ʲô��˼��
        $progressbar->SetStep(1);
        $progressbar->StepIt();
    #    Win32::Sleep(1000);
      }
		
		
		
		
		
	}
		
	close(LOG);
}

sub downcasid
{
	my $casid=$_[0];
	my $downdir=$_[1];
	my @pubchemids_down=&casid2pubchemids($casid);
	
#	print "aaaaa$casid\n";
#	print join "---",@pubchemids_down;
#	print "\n";
	if(@pubchemids_down==0)
	{
		print LOG "cas:$casid not  correpond to pubchemid\n";
#			print  "cas:$casid not  correpond to pubchemid\n";
		#print LOG "0\n";
		
	}
	elsif(@pubchemids_down==1)
	{
		
		print LOG "cas:$casid correspond to pubchemid $pubchemids_down[0]\n";
#		print  "cas:$casid correspond to pubchemid $pubchemids_down[0]\n";

		
			  foreach my $id(@pubchemids_down)
	  {
	  	$url='https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/'.$id.'/record/SDF/?response_type=save&record_type='.$identy;
	   $savename=$downdir.$casid.'_cid_'.$id.'.sdf';
#	print "$url\n";
#	print "$savename\n";
	  	$ua->get($url, 
	  	':content_file'   => $savename);
	
	  }
		
		
	}
	else
	{
		my $last=pop @pubchemids_down;
#		print "cas:$casid correspond to pubchemid ",join ", ",@pubchemids_down," have $last MFS\n";
		print LOG "cas:$casid correspond to pubchemid ",join ", ",@pubchemids_down," have $last MFS\n";
		#print LOG "2";
		foreach my $id(@pubchemids_down)
	  {
	  	$url='https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/'.$id.'/record/SDF/?response_type=save&record_type='.$identy;
	   $savename=$downdir.$casid.'_cid_'.$id.'.sdf';
#	   print "$url\n";
	   #print $savename,"\n";
#	   	print "$savename\n";
	  	$ua->get($url, 
	  	':content_file'   => $savename);
	    #print "download $casid\n";
	  }
		
	}
	
	
	
}



sub casid2pubchemids
{
	my $casid=$_[0];
	
  my ($code,$location,$chemid,@chemids,$xpath,$tree,$html,$mw_pubid);
    $tree= HTML::TreeBuilder::XPath->new;
  my (@mfs,@cids,%cidmf,$url,$req,$res);
  my %pubidmf;
 # my %cidmf;
  my $xml;
  my $data;
  my $savename='1.xml';
  $url='http://www.ncbi.nlm.nih.gov/pccompound?term='.$casid;
  $req=GET($url);                                   

  $res = $ua->request($req);
  $code=$res->code;

  if($code==303)  #�������cas���ܲ鵽1��pubchemid��
  {
    if($res->header('Location'))
   {
	    $location=$res->header('Location');
	    if($location=~/compound\/(\d+)/)
	    {
	    	$chemid=$1;
	    }
	    else
	    {
	    	die "location is error��$location\n";
	    }
	    #����xml�ļ�url
	    #'https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/13770/XML/?response_type=display
	    #https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/60750/record/SDF/?record_type=2d&response_type=display
	    $url='https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/'.$chemid.'/record/SDF/?record_type=2d&response_type=display';
     $html=get($url);
     #> <PUBCHEM_MOLECULAR_WEIGHT>
#263.198146
#PUBCHEM_MOLECULAR_FORMULA
#     if($html=~/PUBCHEM_MOLECULAR_FORMULA>\n(\S+)\n/ms)  #��ȡ����ʽ ���hash�ṹ
#     {
#      $pubidmf{$chemid}=$1;
#     	
#    }
#    else
#    {
#    	die "can't find weight\n";
#    }
	    	push @chemids,$chemid;

	    	

   }
	
	
  }
  elsif($code==200)
  {
  		$html=$res->content;    ##�õ���������ݲ���utf8ͷ��
  #	$html=decode("utf-8",$html);  ##�õ�utf8ͷ
	    $tree= HTML::TreeBuilder::XPath->new_from_content($html);
	    
#	    open FH,">mypage.html";
#	   print FH $html;
#	   close(FH); 
#	  
#  $tree->parse_file( "mypage.html");
	    
  	#cid����
    #    /html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[2]/div/dl/dd
        #/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[2]/div/dl/dd
$xpath='/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div/div[2]/div/div[2]/div/dl/dd';
 @cids=$tree->findvalues($xpath);


#������
       #/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[1]/dl[1]/dd[1]
       #/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[1]/dl[1]/dd[1]
#����ʽ
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[2]/div[2]/div/div[1]/dl[1]/dd[2]
#/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[3]/div[2]/div/div[1]/dl[1]/dd[2]
         #/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[*]/div[2]/div/div[1]/dl[1]/dd[2]
        #/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div[1]/div[2]/div/div[1]/dl[1]/dd[2]
$xpath='/html/body/div/div[1]/form/div[1]/div[3]/div/div[4]/div/div[2]/div/div[1]/dl[1]/dd[2]';
 @mfs=$tree->findvalues($xpath);
 
 ####
 if($#cids != $#mfs){die "praser error "}
 %cidmf=map{$cids[$_],$mfs[$_]}(0..$#cids);
 foreach my $key(keys%cidmf)
 {
 	#########*************************************
 	###########*******************************
 	#####�����һ��value���������ͼ�һ�����ֱ������ٸ�����ʽ
 	 push @chemids,$key;
 	
 }
 my %filter;
 map($filter{$_}=0,@mfs);
 my $nummfs=(keys %filter);
 
 
 
 
 push @chemids,$nummfs;
 	
 	
  } 	
 	
  
 
 
 return @chemids;
 



  	
}	


1;