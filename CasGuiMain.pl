#!/usr/bin/perl -w
#这个代码在casgui下面
#各种子函数在method下面，怎么加载子函数
#BEGIN{unshift(@INC,"/cygdrive/f/cas/casgui/method/")}; 
 #如果你安装了cygwin环境，就不能再用win的路径F:\cas\casgui
#!/usr/bin/perl -w
#BEGIN{unshift(@INC,"./method")};
#require("onlycasdown.pl");
use lib './';
use   Method::Casmfdown qw(downcasmf);
#  Casmfdown::downcasmf
use   Method::Onlycasdown qw(onlycasdown);
#    Onlycasdown::onlycasdown



my $debug=1;
BEGIN {
        *CORE::GLOBAL::printdetail = sub { print @_ if $debug };
    }





use strict;
use warnings;

use Data::Dumper;
use Win32::GUI();
use Encode qw(decode encode  find_encoding  decode_utf8 from_to  _utf8_on _utf8_off  is_utf8);
use Encode::CN;
use Win32::GUI qw(DT_RIGHT DT_LEFT DT_CENTER DT_VCENTER);
use Win32::GUI::Grid qw(GVS_DATA);

#all the subroutine needed 

#require("onlycasdown.pl");


my $desktop     = Win32::GUI::GetDesktopWindow();  #获得显示屏信息
my $x           = Win32::GUI::Width($desktop);     #显示屏长度
my $y           = 0.9 * (Win32::GUI::Height($desktop)); #显示屏宽度
my $casfile;            #必须把这个变量放到最外面，否则无法传递出来
my $mffile;

#print "$x,$y\n";
my @colors = ([7,102,198],  #知乎蓝
              [255,255,255],#文本白
							);


my @fonts = (
  Win32::GUI::Font->new(                   #
    -name => 'Arial',
    -size => 20,
    -bold => 1,
   
  ),          
  Win32::GUI::Font->new(                   #
    -name   => 'Arial',
    -size   => 14,
    -italic => 1,
  ),
    Win32::GUI::Font->new(                   #
    -name   => 'Arial',
    -size   => 10,
    -italic => 1,
  ),
);

my $DOS = Win32::GUI::GetPerlWindow();
Win32::GUI::Hide($DOS);
###################图形界面中的一些变量    #######################

my $butx=110;
my $buty=40;
my $but_size=[$butx,$buty];
my $textx=270;
my $texty=40;
my $text_size=[$textx,$texty];
my $beginx=55;
my $label_x=55;
my $left=55;
my $left2=170;
my $label_size=[250,30];
my $beginy=100;
my $topy=$beginy;
my $indexy=50;






##################sub 转码###############################
sub showcode
{
	my $text=$_[0];
	#my $text="CAS下载器";#我默认是936gbk是乱码
#print $text;#说明是utf-8编码

  my $showtextt=decode_utf8($text);
$showtextt=encode('gbk', $showtextt); #win32 gui中默认采用的是gbk编码
	
	return $showtextt;
	
}
my $text;
my $showtext;
##################################################################




















#创建一个主窗口
my $main_window = new Win32::GUI::Window(
                                    -title  => 'CasDownload',
                                    -name   => 'Window',
                                    -left   => 400,
                                    -top    => 200,
                                    -width  => 520,
                                    -height => 650,
                                     -minsize=>[520,650],
                                    -maxsize=>[520,650],
                                   );
                                   
                                   
                                   
$main_window->AddLabel
(
-text=>'Contact: 744891290@qq.com',
-pos=>[320,590],
-font=>$fonts[2],

);
                                   
                                   
#\u521B\u5EFA\u4E00\u4E2A\u6807\u9898\u6587\u672C\u6846
##my $text="CAS下载器";#我默认是936gbk是乱码
##
##
##
###print $text;#说明是utf-8编码
##
##my $showtext=decode_utf8($text);
##$showtext=encode('gbk', $showtext); #win32 gui中默认采用的是gbk编码


$showtext=&showcode("CAS下载器");


#label 中没有valign,创建两个label显示居中效果
#label1
#label12居中效果
#label2

$main_window->AddLabel(
        -name => 'L1',
        -font =>$fonts[0],
      -align=>'center',
    #-valign => "center",
        -pos  => [50,5],
        -size => [400,40],
    
     -background => [7,102,198], ###蓝色
   #  -bandborders => 1,
   #  -visible =>1,
    
);

$main_window->AddLabel(
        -name => 'L2',
        -font =>$fonts[0],
      -align=>'center',
    #-valign => "center",
        -pos  => [50,15],
        -size => [400,40],
        -text => $showtext,
     -background => [7,102,198], ###蓝色
   #  -bandborders => 1,
   #  -visible =>1,
    
);



###########################################################

######为CAS部分创建一个label################################
$main_window->AddLabel(
        -name => 'CAS',

        -pos  => [50,85],
        -size => [400,450],
     # -frame => black/gray/white/etched/none
     -frame => [0,0,222],
     -fill =>'white',
        -sunken   => 1,# (default 0)
      # -background =>'grey', ###蓝色
   #  -bandborders => 1,
     -visible =>1,
    
);
      
$showtext=&showcode('cas 号码文件:');   
$main_window->AddLabel(
        -name => 'fieldcas',
        -font =>$fonts[0],
      -align=>'left',
    #-valign => "center",
        -pos  => [$label_x,$beginy],
        -size => $label_size,
        -text => $showtext,
        -background => $colors[1], ###
   #  -bandborders => 1,
   #  -visible =>1,
    
);   

#######创建一个选择按钮 cas文件的按钮#############
$topy+=$indexy;;
$main_window->AddButton(
                   -name   => 'selectfile',
                   -left   => $left,
                   -top    => $topy,
                   -text   => 'SelectCasFile:',
                    -size=> $but_size,
                 
               
                  );                            
#-onClick => sub { selectfile( \$file, @_ ) },
 
sub selectfile_Click             #应该是回调函数自动执行的
{
  
     my $filee= Win32::GUI::GetOpenFileName(
                                  -owner    => $main_window,
                                  -title    => "Select  cas file",
                               
                                
                                 )  or die "can't get open";
#     print "aaaaaaaa\n";
     
#     print Dumper($filee);  
#     print "$filee\n";
     $casfile=$filee;
     $main_window->castext->Text($casfile);
    # return $file;                       
    return 1;


}

##################创建一个文本，自动填充cas文件的路径################

 $main_window->AddTextfield(
                   -name   => 'castext',
                   -left   => $left2,
                   -top    => $topy,
                   -text   => "cas file path",
                   -size => $text_size,
                   -font =>$fonts[1],

               
                  );       

##############创建一个label:  分子式MF###########

$topy+=$indexy;
#$text='分子式文件:';
# $showtext=decode_utf8($text);
#$showtext=encode('gbk', $showtext); #win32 gui中默认采用的是gbk编码

$showtext=&showcode('分子式文件:');

$main_window->AddLabel(
        -name => 'fieldmf',
        -font =>$fonts[0],
        -align=>'left',
    #-valign => "center",
        -left=>$left,
        -top=>$topy,
       
        -size =>$label_size,
        -text => $showtext,
           -background => $colors[1], ###蓝色
   #  -bandborders => 1,
   #  -visible =>1,
    
); 

############创建一个按钮：选择分子式文件###########
$topy+=$indexy;
$main_window->AddButton(
                   -name   => 'selectmfile',
                   -left   => $left,
                   -top    => $topy,
                   -text   => 'SelectMfFile:',
                   -size  => $but_size,
                 
               
                  );       


##########创建一个文本框：填充分子式文件的路径

 $main_window->AddTextfield(
                   -name   => 'mftext',
                   -left   => $left2,
                   -top    => $topy,
                   -text   => "MF file path",
                   -size=>$text_size,
                   -font =>$fonts[1],

                  );

#############设置click的事件函数回调函数
sub selectmfile_Click
{
	
	     my $filee= Win32::GUI::GetOpenFileName(
                                  -owner    => $main_window,
                                  -title    => "Select  mf file",
                                  -filter   => [
                                              'Txt file (*.txt)' => '*.txt',
                                              'All files'         => '*.*',
                                             ],
                                
                                 )  or die "can't get open";
    
     

     $mffile=$filee;
     $main_window->mftext->Text($mffile);
    # return $file;                       
    return 1;
    
}

###选择文件的下载目录
###增加一个label 
#$text='下载目录:';
# $showtext=decode_utf8($text);
#$showtext=encode('gbk', $showtext); #win32 gui中默认采用的是gbk编码
$topy+=$indexy;
$showtext=showcode('下载目录:');
$main_window->AddLabel(
        -name => 'fielddir',
        -font =>$fonts[0],
         -align=>'left',
    #-valign => "center",
        -top=> $topy,
        -left=>$left,
        -size =>$label_size,
        -text => $showtext,
        -background => $colors[1],
   #  -background => [7,102,198], ###蓝色
   #  -bandborders => 1,
   #  -visible =>1,
    
); 




############增加选择下载目录的按钮###################
$topy+=$indexy;

 $main_window->AddButton
(
	
	
   -name   => 'selectdir',
   -left   => $left,
   -top    => $topy,
   -text   => 'SelectDir:',
   -size => $but_size,

	
);

######增加填充目录路径的文本fonts

 $main_window->AddTextfield(
                   -name   => 'dirpath',
                   -left   => $left2,
                   -top    => $topy,
                   -text   => "download dir",
                   -size=> $text_size,
                   -font =>$fonts[1],
                  );
                  
                  
                  
###################添加事件函数

sub selectdir_Click
{

      my $Dir = Win32::GUI::BrowseForFolder (
                        -title     => "Select download directory",
                        #-directory => $Directory,
                        -folderonly => 1,
                        );

     $main_window->dirpath->Text($Dir);
    # return $file;                       
    return 1;

	
	
}

################添加一个下载按钮
$topy+=$indexy+10;
 $main_window->AddButton
(
	
	
   -name   => 'download',
   -left   => $left+100,
   -top    => $topy,
   -text   => 'DownLoad',
   -size=> [200,50],

	
);



#################添加下载的事件回调函数##############################





#####弹出一个窗口，上面有两个按钮，
##### 重新选择MF文件
##### 强制下载 
####  “不建议强制下载，建议指定分子式，这样可以提高搜索的准确性”

my $sbut_size=[300,50];
my $second_window=new Win32::GUI::Window(
                                     -name   => 'swin',
                                    -title  => &showcode('重新选择'),
                                    
                                    -left   => 300,
                                    -top    => 200,
                                    -width  => 420,
                                    -height => 400,
                                    -minsize=>[420,400],
                                    -maxsize=>[420,400],
                                   );
                                   
sub swin_Terminate
{
	$second_window->Hide();
	return 0;
	
	
}

######重新选择
$second_window->AddButton(
-name=>'button_back',
-title =>&showcode('指定分子式文件'),
-top =>30,
-left=>50,
-size=>$sbut_size,
);

$second_window->AddButton(
-name=>'button_run',
-title =>&showcode('直接下载'),
-top =>100,
-left=>50,
-size=>$sbut_size,


);

$second_window->AddLabel(

        -name => 'comment',
      #  -font =>$fonts[0],
     -align=>'left',
    #-valign => "center",
        -pos  => [10,150],
        -size => [370,160],
        -text =>&showcode('
  建议：
  1>指定分子式文件,这样能提高下载准确性;
  2>如果没有分子式文件，可以选择直接下载。
  ！！！下载完成后要阅读log文件！！！
    
    '), 
        -font=>$fonts[1],
  #      "suggest specify MF file,so it will check MF,improve accuracy.If you don't have MF,just click force downdlod",
   #  -background => [7,102,198], ###蓝色
   #  -bandborders => 1,
   #  -visible =>1,



);
$topy+=80;
my $progressbar =
  $main_window->AddProgressBar(
                          -left   => $left,
                          -top    => $topy,
                          -width  => 390,
                          -height => 30,
                           -background=>[0,0,85],
                          -smooth => 1,
                         );
                         
                         
                         
#my $Progress_bars=$Upload_win->AddProgressBar(
#    -pos=>[20,400],
#    -background=>[0,255,85],
#    -smooth   => 1,
#    -size=>[470,20],
#);
$progressbar->Show(0);  #hide progressbar,执行下载程序的时候再显示进度条
$progressbar->Show(1);  #show progressbar

##############button_black
sub button_back_Click
{
	
	$second_window->Hide();
	
}

sub button_run_Click
{
	$second_window->Hide();
	my $casfile=$main_window->castext->Text();
	my $downdir=$main_window->dirpath->Text();
	$downdir=$downdir.'/';
	open FH,$casfile;
	my @casnos=<FH>;
	chomp(@casnos);
	@casnos=grep(/\S+/,@casnos);
#	print "force down\n";
	
#	&Onlycasdown::onlycasdown(\@casnos,$downdir,$progressbar);
	
	&onlycasdown(\@casnos,$downdir,$progressbar);
}


	
	
	
	










sub download_Click
{
	my $casfile;
	my $downdir;
	my $mffile;
	
	
	##判断cas文件是否存在
	##判断mf文件是否存在
	##
	if( $main_window->castext->Text()  eq "cas file path")
	{
		#print "please slect a file\n";
		$main_window->MessageBox("cascas file path");  #弹出对话框
		return 1;
		
	}
	else
	{
		$casfile=$main_window->castext->Text();
		
	}
	
	####判断是否定义下载目录
	
	if($main_window->dirpath->Text() eq 'download dir')
	{
		
			
		$main_window->MessageBox("specify the download dir");  #弹出对话框
		return 1;
		
		
	}
	else
	{
		$downdir=$main_window->dirpath->Text();
		$downdir=$downdir.'/';
	}
	
	

		if( $main_window->mftext->Text()  eq "MF file path")
	{
#####弹出一个窗口，上面有两个按钮，
##### 重新选择MF文件
##### 强制下载 
####  “不建议强制下载，建议指定分子式，这样可以提高搜索的准确性”
     
	$second_window->Show();    #显示了第二个窗口
	}
	else
	{
		$mffile=$main_window->mftext->Text();
			open FH,$casfile;
	my @casnos=<FH>;
	chomp(@casnos);
	@casnos=grep(/\S+/,@casnos);
				open FH,$mffile;
	my @mfs=<FH>;
	chomp(@mfs);
	@mfs=grep(/\S+/,@mfs);
	   if($#casnos==$#mfs)
	   {
			#&Casmfdown::downcasmf(\@casnos,\@mfs,$downdir,$progressbar);
			&downcasmf(\@casnos,\@mfs,$downdir,$progressbar);
			
		 }
	}
	
	return 1;
	

	
}






                                   
$main_window->Show();
Win32::GUI::Dialog();
Win32::GUI::Show($DOS);

  sub Window_Terminate { -1 };

# -align    => left/center/right (default left)
#     Set text align.
#   -bitmap   => Win32::GUI::Bitmap object
#   -fill     => black/gray/white/none (default none)
#      Fills the control rectangle ("black", "gray" and "white" are
#      the window frame color, the desktop color and the window
#      background color respectively).
#   -frame    => black/gray/white/etched/none (default none)
#      Draws a border around the control. colors are the same
#      of -fill, with the addition of "etched" (a raised border).
#   -icon     => Win32::GUI::Icon object
#   -noprefix => 0/1 (default 0)
#      Disables the interpretation of "&" as accelerator prefix.
#   -notify   => 0/1 (default 0)
#      Enables the Click(), DblClick, etc. events.
#   -picture  => see -bitmap
#   -sunken   => 0/1 (default 0)
#      Draws a half-sunken border around the control.
#   -truncate => 0/1/word/path (default 0)
#      Specifies how the text is to be truncated:
#         0 the text is not truncated
#         1 the text is truncated at the end
#        path the text is truncated before the last "\"
#             (used to shorten paths).
#   -wrap     => 0/1 (default 1)
#      The text wraps automatically to a new line.
#   -simple   => 0/1 (default 1)
#      Set/Unset simple style.



