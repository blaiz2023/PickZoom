unit pickzoom2;
//##############################################################################
//## Name......... Pick Zoom
//## Type......... User Program
//## Desciption... Zoom images
//## Notes........ -
//## Version...... 1.00.100
//## Date......... 03nov2023
//## Lines........ 1993
//## Copyright.... (c) 1997-2023 Blaiz Enterprises
//##############################################################################

interface

uses
{$ifdef D3}
   Windows, Forms, Controls, SysUtils, Classes, ShellApi, ShlObj, Graphics, Clipbrd,
   messages, math, extctrls{tpanel}, filectrl{tdrivetype}, ActiveX, ComObj, registry,
   gosscore, gossdat;
{$endif}
{$ifdef D10}
   System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
   FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.surfaces,
   system.dateutils, gosscore, gossdat;
{$endif}

type
{tprogram}
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxx//sssssssssssssssssssssssssssssssssss
   tprogram=class(tbasicprg2)
   private
    iscreen:tbasiccontrol;
    ibuffer,ibuffer2:tbasicimage;
    ibyzoom,ibyfixedzoom,ibysize,ibyfixedsize:tbasictoolbar;
    isizelimit,isoftenpert,iscreenstyleCount,iscreenstyle,itransstyle,ibufferid,imargin,idownx,idowny,iscreencolor,ilastfilterindex,ilastfilterindex2,isw,ish,idw,idh,idx,idy:longint;
    icansave,icenter,ismartdrag,imirror,iflip,itransparent,igrey,isepia,isoften,iinvert,inoise,iresetposition,imustpaint,ibuildingcontrol,iloaded:boolean;
    iinfotimer,itimer100,itimer250,itimer500,itimerslow:comp;
    isoftenref,ilastpage,ilastref,ibufferref,ilowopenfilename,ilastfilename,ilastfilename2,iinforef,ilasterror,isettingsref:string;
    procedure xcmd(sender:tobject;xcode:longint;xcode2:string);
    procedure __onclick(sender:tobject);
    procedure __ontimer(sender:tobject); override;
    procedure xloadsettings;
    procedure xsavesettings;
    procedure xautosavesettings;
    procedure xsyncinfo;
    function xtoolbarclick(sender:tbasiccontrol;xstyle:string;xcode:longint;xcode2:string;xtepcolor:longint):boolean;
    procedure xscreenpaint(sender:tobject);
    function xscreennotify(sender:tobject):boolean;
    function xfilterx(x:longint):longint;
    function xfiltery(x:longint):longint;
    procedure xfilter;
    function xbuffer:tbasicimage;
    function xempty:boolean;
    procedure xonshowmenuFill1(sender:tobject;xstyle:string;xmenudata:tstr8;var ximagealign:longint;var xmenuname:string);
    function xonshowmenuClick1(sender:tbasiccontrol;xstyle:string;xcode:longint;xcode2:string;xtepcolor:longint):boolean;
    function xoptions:currency;
    function xscreencolor:longint;
    function xcansave:boolean;
    function __onaccept(sender:tobject;xfolder,xfilename:string;xindex,xcount:longint):boolean;
   public
    //create
    constructor create(xminsysver:longint;xhost:tobject;dwidth,dheight:longint); override;
    destructor destroy; override;
   end;

function low__createprogram(xhost:tobject):tbasicprg1;


//support for Gossamer
procedure program__init;
procedure program__close;

implementation

uses PickZoom1;

//## low__createprogram ##
function low__createprogram(xhost:tobject):tbasicprg1;
begin
try
result:=tprogram.create(0,xhost,1600,950);
result.createfinish;//perform form and POST create operations like sync main form's help visible state - 30jul2021
except;end;
end;
//## program__init ##
procedure program__init;
begin
//nil
end;
//## program__close ##
procedure program__close;
begin
//nil
end;

//## tpickzoom #################################################################
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxx//ssssssssssssssssssssssssssssssssssss
//## create ##
constructor tprogram.create(xminsysver:longint;xhost:tobject;dwidth,dheight:longint);
const
   s1=-15;
   s1b=-15;
   s2=0;
var
   xheadcount,p:longint;
   str1,dfolder,e:string;
   xcurrent:tbasictoolbar;
   //## xp ##
   procedure xp(x:longint);
   begin
   if (xcurrent<>nil) and (x>=1) then xcurrent.csadd(inttostr(x)+'%',tepNone,0,'p.'+inttostr(x),'Zoom to '+inttostr(x)+'%',s2);
   end;
   //## xwh ##
   procedure xwh(xw,xh:longint);
   begin
   if (xw=0) then xw:=xh;
   if (xh=0) then xh:=xw;
   if (xcurrent<>nil) and (xw>=1) and (xh>=1) then xcurrent.csadd(inttostr(xw)+'x'+inttostr(xh),tepNone,0,'s:'+inttostr(xw)+'x'+inttostr(xh),'Set new size '+inttostr(xw)+'x'+inttostr(xh),0);
   end;
   //## xwh2 ##
   procedure xwh2(xcap:string;xw,xh:longint);
   begin
   if (xw=0) then xw:=xh;
   if (xh=0) then xh:=xw;
   if (xcap='') then xcap:=inttostr(xw)+'x'+inttostr(xh);
   if (xcurrent<>nil) and (xw>=1) and (xh>=1) then xcurrent.csadd(xcap,tepNone,0,'s:'+inttostr(xw)+'x'+inttostr(xh),'Set new size '+inttostr(xw)+'x'+inttostr(xh),0);
   end;
   //## xnewbar ##
   function xnewbar(var xoutcontrol:tbasictoolbar;xpagename,xhelp:string):tbasictoolbar;
   begin
   result:=rootwin.xhigh2.ntoolbar_buttons(xhelp);
   result.opagename:=xpagename;
   result.ominrows:=3;
   result.onclick2:=xtoolbarclick;
   result.oequalwidths:=true;
   xcurrent:=result;
   xoutcontrol:=result;
   end;
   //## xnewhead2 ##
   procedure xnewhead2(xcap,xhelp,xid:string);
   begin
   if (xcurrent<>nil) then
      begin
      if (xid='') then
         begin
         inc(xheadcount);
         xid:='header'+inttostr(xheadcount);
         end;
      xcurrent.csadd(xcap,tepNone,0,xid,xhelp,s1);
      xcurrent.bhighlight2[xid]:=true;
      xcurrent.bcan2[xid]:=false;
      end;
   end;
   //## xnewhead ##
   procedure xnewhead(xcap,xhelp:string);
   begin
   xnewhead2(xcap,xhelp,'');
   end;
   //## xrestore ##
   procedure xrestore(xstyle:string);
   var
      xhelp:string;
   begin
   //check
   if (xcurrent=nil) then exit;
   //get
   xstyle:=low__lowercase(xstyle);
   if      (xstyle='w') then xhelp:='Restore original width'
   else if (xstyle='h') then xhelp:='Restore original height'
   else
      begin
      xstyle:='';
      xhelp:='Restore original dimensions';
      end;
   //set
   xcurrent.csadd('Restore',tepNone,0,low__insstr(xstyle+'.',xstyle<>'')+'restore',xhelp,s2);
   end;
   //##xhelphint ##
   function xhelphint(x:longint;xstyle,xunit:string):string;
   var
      xtype,xdes:string;
   begin
   try
   result:='';
   //get
   if (x>=0) then xtype:='Increase' else xtype:='Decrease';

   if (xstyle='w') then xdes:='width'
   else if (xstyle='h') then xdes:='height'
   else xdes:='size';
   //set
   result:=xtype+' image '+xdes+' by '+inttostr(low__posn(x))+xunit;
   except;end;
   end;
   //## xzoom ##
   procedure xzoom(x:longint;xstyle:string);
   var
      xval,xsign:string;
   begin
   //check
   if (xcurrent=nil) then exit;
   //get
   xstyle:=low__lowercase(xstyle);
   if (xstyle<>'w') and (xstyle<>'h') then xstyle:='';
   xval:=inttostr(low__posn(x));
   if (x>=0) then xsign:='+' else xsign:='-';
   xcurrent.csadd(xsign+#32+xval+'%',tepNone,0,'%%'+low__insstr(xstyle+'.',xstyle<>'')+xsign+xval,xhelphint(x,xstyle,'%'),s2);
   end;
   //## xzoomset ##
   procedure xzoomset(xstyle:string);
   begin
   xzoom(-1,xstyle);
   xzoom(+1,xstyle);
   xzoom(-5,xstyle);
   xzoom(+5,xstyle);
   xzoom(-10,xstyle);
   xzoom(+10,xstyle);
   xzoom(-25,xstyle);
   xzoom(+25,xstyle);
   xzoom(-50,xstyle);
   xzoom(+50,xstyle);
   xzoom(+100,xstyle);
   xrestore(xstyle);
   end;
   //## xsize ##
   procedure xsize(x:longint;xstyle:string);
   var
      xval,xsign:string;
   begin
   //check
   if (xcurrent=nil) then exit;
   //get
   xstyle:=low__lowercase(xstyle);
   if (xstyle<>'w') and (xstyle<>'h') then xstyle:='';
   xval:=inttostr(low__posn(x));
   if (x>=0) then xsign:='+' else xsign:='-';
   //set
   xcurrent.csadd(xsign+#32+xval+'px',tepNone,0,low__insstr(xstyle+'.',xstyle<>'')+xsign+xval,xhelphint(x,xstyle,'px'),s2);
   end;
   //## xsizeset ##
   procedure xsizeset(xstyle:string);
   begin
   //check
   if (xcurrent=nil) then exit;
   //get
   xsize(-1,xstyle);
   xsize(+1,xstyle);
   xsize(-10,xstyle);
   xsize(+10,xstyle);
   xsize(-100,xstyle);
   xsize(+100,xstyle);
   xsize(-1000,xstyle);
   xsize(+1000,xstyle);
   xcurrent.csadd('Change',tepNone,0,low__insstr(xstyle+'.',xstyle<>'')+'set','Set image dimensions',s2);
   xrestore(xstyle);
   end;
   //## xtweak ##
   procedure xtweak;
   begin
   if (xcurrent=nil) then exit;
   with xcurrent do
   begin
   xnewhead('Tweak','Tweak');
   xzoom(-1,'');
   xzoom(1,'');
   xzoom(-5,'');
   xzoom(5,'');
   xzoom(-10,'');
   xzoom(10,'');

   xsize(-1,'');
   xsize(+1,'');
   xsize(-10,'');
   xsize(+10,'');
   csadd('Restore',tepNone,0,'restore','Restore image to original dimensions',s2);
   end;
   end;

begin
if system_debug then dbstatus(38,'Debug 012');//yyyy
//self
inherited create(10020462,xhost,dwidth,dheight);//low__gossver check - 21sep2021
ibuildingcontrol:=true;


//need checkers
need_jpeg;
need_gif;

//init
isizelimit:=10000000;//10mil pixels
iinfotimer:=ms64;
itimer100:=ms64;
itimer250:=ms64;
itimer500:=ms64;
itimerslow:=ms64;
xcurrent:=nil;
xheadcount:=0;
//vars
ilastpage:='';
ilastref:='';
isoftenref:='';//11sep2021
iloaded:=false;
ilasterror:='';
imustpaint:=false;
icansave  :=false;
ibuffer   :=misimg24(1,1);//no alpha support - 09sep2021
ibuffer2  :=misimg24(1,1);//no alpha support - 09sep2021
ibufferid :=0;
imargin   :=32;
isw       :=misw(ibuffer);
ish       :=mish(ibuffer);
idw       :=isw;
idh       :=ish;
idx       :=0;
idy       :=0;
idownx    :=0;
idowny    :=0;
iscreenstyleCount:=7;
iscreenstyle:=0;
iscreencolor:=0;
ilastfilterindex:=0;
ilastfilterindex2:=0;
ilowopenfilename:='';
ilastfilename:='';
ilastfilename2:='';
iresetposition:=false;
igrey     :=false;
isepia    :=false;
iinvert   :=false;
isoften   :=false;
isoftenpert:=100;
inoise    :=false;
itransparent:=false;
itransstyle:=0;
imirror   :=false;
iflip     :=false;
ismartdrag:=true;
icenter:=false;
//controls
with rootwin do
begin
ocanshowmenu:=true;
scroll:=false;
xhead;
xtoolbar;
xtoolbar.add('Open',tepOpen20,0,'open','Open image from file');
xtoolbar.add('Save As',tepSave20,0,'saveas','Save image to file');
//xtoolbar.add('Save',tepSave20,0,'save','Save image to file without prompting');
xtoolbar.add('-',tepNone,0,'sep1','');
xtoolbar.add('Menu',tepMenu20,0,'menu','Show menu');
xtoolbar.add('Settings',tepSettings20,0,'settings','Show settings');
xtoolbar.add('-',tepNone,0,'sep1','');
xtoolbar.add('Copy',tepCopy20,0,'copy','Copy image zoomed to Clipboard');
xtoolbar.add('Paste',tepPaste20,0,'paste','Paste image from Clipboard');
xtoolbar.add('Paste Fit',tepPaste20,0,'pastefit','Paste to fit image from Clipboard');
xtoolbar.add('Colors',tepColors20,0,'colors','Count colors in image');
xtoolbar.add('Home',tepHome20,0,'home','Shift image to top-left of screen');
xtoolbar.add('-',tepNone,0,'sep2','');

//.screen
iscreen:=ncontrol;
iscreen.oautoheight:=true;
iscreen.oroundstyle:=corNone;//corToSquare;//corNone;
iscreen.bordersize:=0;

with xhigh2 do
begin
xtoolbar;
xtoolbar.otitle:=true;
xtoolbar.caption:='Zoom by';
xtoolbar.hcsadd('Percentage',tepSizeto20,0,'page:byzoom','Zoom by percentage',0);
xtoolbar.hcsadd('Pixels',tepSizeto20,0,'page:bysize','Zoom by pixels',0);
xtoolbar.hcsadd('Set %',tepSizeto20,0,'page:byfixedzoom','Set to fixed %',0);
xtoolbar.hcsadd('Set Pixels',tepSizeto20,0,'page:byfixedsize','Set to fixed pixels',0);

xtoolbar.addsep2('sep1');
xtoolbar.hcsadd('Mirror',tepNone,100,'mirror','Toggle "Mirror"',0);
xtoolbar.hcsadd('Flip',tepNone,100,'flip','Toggle "Flip"',0);
xtoolbar.hcsadd('Grey',tepNone,100,'grey','Toggle "Grey" filter',0);
xtoolbar.hcsadd('Sepia',tepNone,100,'sepia','Toggle "Sepia" filter',0);
xtoolbar.hcsadd('Noise',tepNone,100,'noise','Toggle "Noise" filter',0);
xtoolbar.hcsadd('Invert',tepNone,100,'invert','Toggle "Invert" filter',0);
xtoolbar.hcsadd('Soften',tepNone,100,'soften','Toggle "Soften" filter',0);
xtoolbar.hcsadd('Transparency',tepNone,100,'transparent','Toggle "Transparency"',0);


//.zoom options ----------------------------------------------------------------
with xnewbar(ibyzoom,'byzoom','Adjust zoom by percentage') do
begin
xnewhead2('Image Size','Image size','z1');
xzoomset('');
newline;

xnewhead2('Image Width','Image width','z2');
xzoomset('w');
newline;

xnewhead2('Image Height','Image height','z3');
xzoomset('h');
end;

//.fixed options ----------------------------------------------------------------
with xnewbar(ibyfixedzoom,'byfixedzoom','Adjust zoom by set percentage') do
begin
xnewhead('Decrease','Shrink image');
xp(5);
xp(10);
xp(20);
xp(30);
xp(40);
xp(50);
xp(60);
xp(70);
xp(80);
xp(90);

newline;

xnewhead('Increase','Enlarge image');
xp(110);
xp(125);
xp(150);
xp(175);
xp(200);
xp(300);
xp(400);
xp(500);
xp(650);
xp(800);

newline;
xtweak;
end;

//.pixel options ---------------------------------------------------------------
with xnewbar(ibysize,'bysize','Adjust zoom by pixels') do
begin
xnewhead2('Image Size','Image size','p1');//?????????????????//p1?????????
xsizeset('');
newline;

xnewhead2('Image Width','Image width','p2');
xsizeset('w');
newline;

xnewhead2('Image Height','Image height','p3');
xsizeset('h');
end;//pixel



//.fixedsize
with xnewbar(ibyfixedsize,'byfixedsize','Adjust zoom by set pixels') do
begin
xnewhead('Square / Tile','Square dimensions');
xwh2('1200',1200,0);
xwh2('600',600,0);
xwh2('300',300,0);
xwh2('180',180,0);
xwh2('152',152,0);
xwh2('128',128,0);
xwh2('100',100,0);
xwh2('96',96,0);
xwh2('64',64,0);
xwh2('57',57,0);
xwh2('48',48,0);
xwh2('32',32,0);
xwh2('20',20,0);
xwh2('16',16,0);

newline;

xnewhead('Video','Video dimensions');
xwh2('2160p',3840,2160);
xwh2('1440p',2560,1440);
xwh2('1080p',1920,1080);
xwh2('720p',1280,720);
xwh2('480p',640,480);
xwh2('240p',320,240);
xwh2('120p',160,120);

newline;
xtweak;

{
xwh(2048,1080);
xwh(3840,2160);

xwh(1367,768);
{}
end;

//defaults
page:='byzoom';
end;//nscroll
end;


//.last links on toolbar - 22mar2021
with rootwin do
begin
xtoolbar.xaddoptions;
xtoolbar.xaddhelp;
end;

with rootwin.xstatus2 do
begin
cellwidth[0]:=200;
cellwidth[1]:=200;
cellwidth[2]:=200;
cellwidth[3]:=200;
end;


//events
rootwin.xtoolbar.onclick:=__onclick;
rootwin.xhigh2.xtoolbar.onclick:=__onclick;
iscreen.onpaint:=xscreenpaint;
iscreen.onnotify:=xscreennotify;
iscreen.onaccept:=__onaccept;//drag and drop support
rootwin.showmenuFill1:=xonshowmenuFill1;
rootwin.showmenuClick1:=xonshowmenuClick1;

//start timer event
ibuildingcontrol:=false;
xloadsettings;
xstarttimer;

//.defaults
//misfromdata2(ibuffer,programfile_spring_jpg,e);//sample image -> default on start - 18jun2021
missize(ibuffer,100,100);
miscls(ibuffer,clwhite);
xcmd(nil,0,'init');
//ilastfilename:='Spring.jpg';

//.low__paramstr1
str1:=low__paramstr1;
if (str1<>'') then __onaccept(self,'',str1,0,0);
//.mark not modified - 04sep2021
xsyncinfo;
end;
//## destroy ##
destructor tprogram.destroy;
begin
try
//settings
xautosavesettings;
//controls
freeobj(@ibuffer);
freeobj(@ibuffer2);

//self
inherited destroy;
except;end;
end;
//## __onaccept ##
function tprogram.__onaccept(sender:tobject;xfolder,xfilename:string;xindex,xcount:longint):boolean;
begin
try
result:=false;
ilowopenfilename:=xfilename;
xcmd(self,100,'lowopen');
except;end;
end;
//## xloadsettings ##
procedure tprogram.xloadsettings;
var
   a:tvars8;
begin
try
//defaults
a:=nil;
//check
if zznil(prgsettings,5001) then exit;
//init
a:=vnew2(950);
a.b['resetpos']:=prgsettings.bdef('resetpos',true);
a.b['grey']:=prgsettings.bdef('grey',false);
a.b['sepia']:=prgsettings.bdef('sepia',false);
a.b['invert']:=prgsettings.bdef('invert',false);
a.b['soften']:=prgsettings.bdef('soften',false);
a.i['soften%']:=prgsettings.idef('soften%',100);
a.b['noise']:=prgsettings.bdef('noise',false);
a.b['transparent']:=prgsettings.bdef('transparent',false);
a.i['transstyle']:=prgsettings.idef('transstyle',clTopLeft);
a.b['mirror']:=prgsettings.bdef('mirror',false);
a.b['flip']:=prgsettings.bdef('flip',false);
a.i['screenstyle']:=prgsettings.idef('screenstyle',0);
a.i['screencolor']:=prgsettings.idef('screencolor',low__rgb(60,60,60));
a.b['smartdrag']:=prgsettings.bdef('smartdrag',true);
a.b['center']:=prgsettings.bdef('center',true);
a.s['page']:=prgsettings.sdef('page','byzoom');
//get
iresetposition:=a.b['resetpos'];
igrey:=a.b['grey'];
isepia:=a.b['sepia'];
iinvert:=a.b['invert'];
isoften:=a.b['soften'];
isoftenpert:=frcrange(a.i['soften%'],1,100);
inoise:=a.b['noise'];
itransparent:=a.b['transparent'];
itransstyle:=a.i['transstyle'];
imirror:=a.b['mirror'];
iflip:=a.b['flip'];
iscreenstyle:=frcrange(a.i['screenstyle'],0,iscreenstyleCount-1);
iscreencolor:=a.i['screencolor'];
//ismartdrag:=a.b['smartdrag'];
icenter:=a.b['center'];
rootwin.xhigh2.page:=a.s['page'];
//sync
prgsettings.data:=a.data;
except;end;
try
freeobj(@a);
iloaded:=true;
except;end;
end;
//## xsavesettings ##
procedure tprogram.xsavesettings;
var
   a:tvars8;
begin
try
//check
if not iloaded then exit;
//defaults
a:=nil;
a:=vnew2(951);
//get
a.b['resetpos']:=iresetposition;
a.b['grey']:=igrey;
a.b['sepia']:=isepia;
a.b['invert']:=iinvert;
a.b['soften']:=isoften;
a.i['soften%']:=frcrange(isoftenpert,1,100);
a.b['noise']:=inoise;
a.b['transparent']:=itransparent;
a.i['transstyle']:=itransstyle;
a.b['mirror']:=imirror;
a.b['flip']:=iflip;
a.i['screenstyle']:=frcrange(iscreenstyle,0,iscreenstyleCount-1);
a.i['screencolor']:=iscreencolor;
//a.b['smartdrag']:=ismartdrag;
a.b['center']:=icenter;
a.s['page']:=rootwin.xhigh2.page;
//set
prgsettings.data:=a.data;
siSaveprgsettings;
except;end;
try;freeobj(@a);except;end;
end;
//## xscreencolor ##
function tprogram.xscreencolor:longint;
begin
try
case iscreenstyle of
0:result:=vinormal.background;
1:result:=low__rgb(60,60,60);
2:result:=low__rgb(120,120,120);
3:result:=low__rgb(0,0,0);
4:result:=low__rgb(255,255,255);
5:result:=low__rgb(240,240,240);
else result:=iscreencolor;
end;
except;end;
end;
//## xautosavesettings ##
procedure tprogram.xautosavesettings;
var
   str1:string;
begin
try
//check
if not iloaded then exit;
//get
str1:=rootwin.xtoolbar.visref+'_'+rootwin.xhigh2.xtoolbar.visref+'_'+inttostr(isoftenpert)+'_'+inttostr(iscreenstyle)+'_'+inttostr(xscreencolor)+'_'+inttostr(itransstyle)+'_'+bnc(imirror)+bnc(iflip)+bnc(itransparent)+bnc(igrey)+bnc(isepia)+bnc(inoise)+bnc(iinvert)+bnc(isoften)+bnc(icenter)+bnc(ismartdrag)+bnc(iresetposition)+bnc(rootwin.xtoolbar.bvisible2['open'])+bnc(rootwin.xtoolbar.bvisible2['save'])+bnc(rootwin.xtoolbar.bvisible2['saveas'])+bnc(rootwin.xtoolbar.bvisible2['copy'])+bnc(rootwin.xtoolbar.bvisible2['paste'])+bnc(rootwin.xtoolbar.bvisible2['pastefit'])+bnc(rootwin.xtoolbar.bvisible2['colors'])+'_'+rootwin.xhigh2.page;
if low__setstr(isettingsref,str1) then xsavesettings;
except;end;
end;
//## __onclick ##
procedure tprogram.__onclick(sender:tobject);
begin
try;xcmd(sender,0,'');except;end;
end;
//## xcansave ##
function tprogram.xcansave:boolean;
begin
try;result:=(ilastfilename<>'') and (not xempty) and icansave;except;end;
end;
//## xcmd ##
procedure tprogram.xcmd(sender:tobject;xcode:longint;xcode2:string);
label
   skipend;
var
   b:tstr8;
   d:tbasicimage;
   xtranscol,xfilterindex,int1,xtepcolor:longint;
   bol1,xresult,zok:boolean;
   str1,e:string;
   //## swh ##
   procedure swh;
   begin
   isw:=misw(ibuffer);
   ish:=mish(ibuffer);
   end;
   //## dwh ##
   procedure dwh;
   begin
   idw:=isw;
   idh:=ish;
   end;
   //## dhome ##
   procedure dhome;
   begin
   idx:=0;
   idy:=0;
   end;
   //## xinitd ##
   function xinitd(xfull:boolean):boolean;
   begin
   try
   result:=false;
   d:=misimg32(1,1);
   case xfull of
   true:result:=low__copyimgto2(xbuffer,d,idw,idh,xoptions,imirror,iflip,low__aorb(clnone,itransstyle,itransparent),0,false,xtranscol);
   false:result:=low__copyimgto2(xbuffer,d,isw,ish,xoptions,imirror,iflip,low__aorb(clnone,itransstyle,itransparent),0,false,xtranscol);//smaller -> use when "noise=false"
   end;
   except;end;
   end;
begin//use for testing purposes only - 15mar2020
try
//defaults
xresult:=false;
e:=gecTaskfailed;
b:=nil;
d:=nil;
//init
zok:=zzok(sender,7455);
if zok and (sender is tbasictoolbar) then
   begin
   //ours next
   xcode:=(sender as tbasictoolbar).ocode;
   xcode2:=low__lowercase((sender as tbasictoolbar).ocode2);
   end;
//get
if (xcode2='home') then
   begin
   icenter:=false;//23sep2021
   idx:=0;
   idy:=0;
   end
else if (xcode2='init') then
   begin
   swh;
   dwh;
   end
else if (xcode2='menu') then rootwin.showmenu2('menu')
else if (xcode2='settings') then rootwin.showmenu2('settings')
else if (xcode2='lowopen') or (xcode2='open') then
   begin
   if (xcode2='lowopen') or sys.popopenimg(ilastfilename,ilastfilterindex,'') then
      begin
      if (xcode2='lowopen') then ilastfilename:=ilowopenfilename;
      b:=bnew;
      if not low__fromfile(ilastfilename,b,e) then goto skipend;
      if iresetposition then dhome;
      if not misfromdata(ibuffer,b,e) then
         begin
         missize(ibuffer,1,1);
         low__iroll(ibufferid,1);
         swh;
         dwh;
         goto skipend;
         end;
      low__iroll(ibufferid,1);
      swh;
      dwh;
      icansave:=true;
      end;
   end
else if (xcode2='save') then
   begin
   if xcansave then
      begin
      b:=bnew;
      if not xinitd(true) then goto skipend;
      if not mistodata2(d,b,ilastfilename,xtranscol,0,0,false,e) then goto skipend;
      freeobj(@d);//reduce ram
      if not low__tofile(ilastfilename,b,e) then goto skipend;
      end;
   end
else if (xcode2='saveas') then
   begin
   if not xempty then
      begin
      if sys.popsaveimg(ilastfilename,'') then
         begin
         b:=bnew;
         if not xinitd(true) then goto skipend;
         if not mistodata2(d,b,ilastfilename,xtranscol,0,0,false,e) then goto skipend;
         freeobj(@d);//reduce ram
         if not low__tofile(ilastfilename,b,e) then goto skipend;
         icansave:=true;
         end;
      end;
   end
else if (xcode2='saveas2') then
   begin
   if not xempty then
      begin
      if sys.popsaveimg(ilastfilename2,'') then
         begin
         b:=bnew;
         if not xinitd(true) then goto skipend;
         if not mistodata2(d,b,ilastfilename2,xtranscol,0,0,false,e) then goto skipend;
         freeobj(@d);//reduce ram
         if not low__tofile(ilastfilename2,b,e) then goto skipend;
         end;
      end;
   end
else if (xcode2='copy') then
   begin
   if (not xempty) and (not low__copyimg2(xbuffer,idw,idh,xoptions,imirror,iflip,low__aorb(clnone,itransstyle,itransparent),0,false)) then goto skipend;
   end
else if (xcode2='paste') or (xcode2='pastefit') then
   begin
   bol1:=low__pasteimg(ibuffer);
   swh;
   if (xcode2='paste') then
      begin
      dwh;
      if iresetposition then dhome;
      end;
   low__iroll(ibufferid,1);
   if not bol1 then goto skipend;
   end
else if (xcode2='colors') then
   begin
   if not xinitd(inoise and ((idw>isw) or (idh>ish))) then goto skipend;
   int1:=miscountcolors(d);
   if (int1<=1) then str1:='1 color' else str1:=low__64(int1)+' colors';
   sys.popinfo('Color Count',str1);
   end
else if (xcode2='mirror') then imirror:=not imirror
else if (xcode2='flip') then iflip:=not iflip
else if (xcode2='transparent') then itransparent:=not itransparent
else if (xcode2='transparency.0') then itransparent:=false
else if (xcode2='transparency.1') then itransparent:=true
else if (xcode2='transstyle.custom') then
   begin
   int1:=itransstyle;
   if sys.popcolor(int1) then
      begin
      itransstyle:=int1;
      itransparent:=true;
      end;
   end
else if (strcopy1(xcode2,1,11)='transstyle.') then
   begin
   itransstyle:=strint(strcopy1(xcode2,12,length(xcode2)));
   itransparent:=true;
   end
else if (xcode2='grey') then igrey:=not igrey
else if (xcode2='sepia') then isepia:=not isepia
else if (xcode2='invert') then iinvert:=not iinvert
else if (xcode2='soften.0') then isoften:=false
else if (xcode2='soften.1') then isoften:=true
else if (xcode2='soften') then isoften:=not isoften
else if (strcopy1(xcode2,1,11)='softenpert.') then//11sep2021
   begin
   isoftenpert:=frcrange(strint(strcopy1(xcode2,12,length(xcode2))),1,100);
   isoften:=true;
   end
else if (xcode2='noise') then inoise:=not inoise
else if (xcode2='effectsoff') then
   begin
   imirror:=false;
   iflip:=false;
   igrey:=false;
   isepia:=false;
   iinvert:=false;
   isoften:=false;
   inoise:=false;
   end
else if (strcopy1(xcode2,1,12)='screenstyle.') then
   begin
   iscreenstyle:=frcrange(strint(strcopy1(xcode2,13,length(xcode2))),0,iscreenstyleCount-1);
   if (iscreenstyle=6) then sys.popcolor(iscreencolor);
   end
else if (xcode2='resetpos') then iresetposition:=not iresetposition
else if (xcode2='smartdrag') then ismartdrag:=not ismartdrag
else if (xcode2='center') then icenter:=not icenter
else
   begin
   if system_debug then showbasic('Unknown Command>'+xcode2+'<<');
   end;

//successful
xresult:=true;
skipend:
except;end;
try
freeobj(@d);
bfree(b);
except;end;
try
xfilter;
xsyncinfo;
if not xresult then sys.poperror(e);
except;end;
end;
//xxxxxxxxxxxxxxxxxxxxxxxxx//ssssssssssssssssssssssssssssssss
//## __ontimer ##
procedure tprogram.__ontimer(sender:tobject);//._ontimer
label
   skipend;
var
   str1:string;
   xmustpaint:boolean;
begin
try
//init
xmustpaint:=false;

//timer100
if (ms64>=itimer100) and iloaded then
   begin
   //filter
   xfilter;
   if low__setstr(ilastpage,rootwin.xhigh2.page) then iinfotimer:=ms64;//fast page change detection - 04sep2021
   //reset
   itimer100:=ms64+100;
   end;


//iinfotimer
if (ms64>=iinfotimer) then
   begin
   xsyncinfo;
   //reset
   iinfotimer:=ms64+500;
   end;

//timer500
if (ms64>=itimer500) and iloaded then
   begin
   //savesettings
   xautosavesettings;

   //reset
   itimer500:=ms64+500;
   end;

//timerslow
if (ms64>=itimerslow) then
   begin

   //reset
   itimerslow:=ms64+2000;
   end;

//mustpaint
if xmustpaint or imustpaint then
   begin
   imustpaint:=false;
   iscreen.paintnow;
   end;

//debug support
if system_debug then
   begin
   if system_debugFAST then rootwin.paintallnow;
   end;
if system_debug and system_debugRESIZE then
   begin
   if (system_debugwidth<=0) then system_debugwidth:=gui.host.width;
   if (system_debugheight<=0) then system_debugheight:=gui.host.height;
   //change the width and height to stress
   //was: if (random(10)=0) then gui.setbounds(gui.left,gui.top,system_debugwidth+random(32)-16,system_debugheight+random(128)-64);
   gui.setbounds(gui.left,gui.top,system_debugwidth+random(32)-16,system_debugheight+random(128)-64);
   end;

skipend:
except;end;
end;
//## xsyncinfo ##
procedure tprogram.xsyncinfo;
var
   xtransparentstr,str1:string;
   xsw,xsh,xdw,xdh:longint;
   acanpaste,aempty,wok,hok,whok:boolean;
   xuncompressedsize:comp;
   //## xmarktab ##
   procedure xmarktab(xname:string);
   var
      bol1:boolean;
   begin
   bol1:=(rootwin.xhigh2.page=xname);
   rootwin.xhigh2.xtoolbar.bhighlight2['page:'+xname]:=bol1;
   //rootwin.xhigh2.xtoolbar.bflash2['page:'+xname]:=bol1;
   end;
begin
try
//mustcloseprompt - 26aug2021
//was: gui.mustcloseprompt:=imodified;
//init
aempty:=xempty;
xtransparentstr:='Transparency: '+low__aorbstr('Off',mistransLABEL(itransstyle,''),itransparent);
rootwin.xhead.caption2:=low__insstr(' - '+low__extractfilename(ilastfilename),ilastfilename<>'');
xuncompressedsize:=low__mult64(low__mult64(idw,idh),misb(ibuffer) div 8);
//button panels
if (ibyzoom<>nil) and (ibyfixedzoom<>nil) and (ibysize<>nil) and (ibyfixedsize<>nil) then
   begin
   //init
   xsw:=isw;
   xsh:=ish;
   xdw:=idw;
   xdh:=idh;
   wok:=(xdw>=2);
   hok:=(xdh>=2);
   whok:=wok or hok;
   //w x h
   str1:='Size: '+low__64(xdw)+'w x '+low__64(xdh)+'h';
   if (ibyzoom.bcap2['z1']<>str1) then ibyzoom.bcap2['z1']:=str1;
   if (ibysize.bcap2['p1']<>str1) then ibysize.bcap2['p1']:=str1;
   //w
   str1:='Width: '+low__64(xdw);
   if (ibyzoom.bcap2['z2']<>str1) then ibyzoom.bcap2['z2']:=str1;
   if (ibysize.bcap2['p2']<>str1) then ibysize.bcap2['p2']:=str1;
   //h
   str1:='Height: '+low__64(xdh);
   if (ibyzoom.bcap2['z3']<>str1) then ibyzoom.bcap2['z3']:=str1;
   if (ibysize.bcap2['p3']<>str1) then ibysize.bcap2['p3']:=str1;
   //byzoom --------------------------------------------------------------------
   with ibyzoom do
   begin
   //.wh-
   benabled2['%-1']:=whok;
   benabled2['%-10']:=whok;
   benabled2['%-100']:=whok and (xdw>xsw) and (xdh>xsh);
   benabled2['%-1000']:=whok and (xdw>(10*xsw)) and (xdh>(10*xsh));
   benabled2['restore']:=(xdw<>xsw) or (xdh<>xsh);
   //.w
   benabled2['%w.-1']:=wok;
   benabled2['%w.-10']:=wok;
   benabled2['%w.-100']:=wok and (xdw>xsw);
   benabled2['%w.-1000']:=wok and (xdw>(10*xsw));
   benabled2['w.restore']:=(xdw<>xsw);
   //.h
   benabled2['%h.-1']:=hok;
   benabled2['%h.-10']:=hok;
   benabled2['%h.-100']:=hok and (xdh>xsh);
   benabled2['%h.-1000']:=hok and (xdh>(10*xsh));
   benabled2['h.restore']:=(xdh<>xsh);
   end;
   //bysize --------------------------------------------------------------------
   with ibysize do
   begin
   //.wh-
   benabled2['-1']:=whok;
   benabled2['-10']:=whok;
   benabled2['-100']:=whok;
   benabled2['-1000']:=whok;
   benabled2['restore']:=(xdw<>xsw) or (xdh<>xsh);
   //.w
   benabled2['w.-1']:=wok;
   benabled2['w.-10']:=wok;
   benabled2['w.-100']:=wok;
   benabled2['w.-1000']:=wok;
   benabled2['w.restore']:=(xdw<>xsw);
   //.h
   benabled2['h.-1']:=hok;
   benabled2['h.-10']:=hok;
   benabled2['h.-100']:=hok;
   benabled2['h.-1000']:=hok;
   benabled2['h.restore']:=(xdh<>xsh);
   end;
   //byfixedzoom ---------------------------------------------------------------
   with ibyfixedzoom do
   begin
   benabled2['restore']:=(xdw<>xsw) or (xdh<>xsh);
   end;
   //byfixedsize ---------------------------------------------------------------
   with ibyfixedsize do
   begin
   benabled2['restore']:=(xdw<>xsw) or (xdh<>xsh);
   end;

   end;
//status
//was: rootwin.xstatus2.celltext[0]:='Input Image: '+low__64(misw(ibuffer))+'w x '+low__64(mish(ibuffer))+'h ('+low__mb(low__mult64(low__mult64(misw(ibuffer),mish(ibuffer)),misb(ibuffer) div 8),true)+')';
//was: rootwin.xstatus2.celltext[1]:='Output Image: '+low__64(idw)+'w x '+low__64(idh)+'h ('+low__mb(low__mult64(low__mult64(idw,idh),misb(ibuffer) div 8),true)+')';
//was: rootwin.xstatus2.celltext[0]:='Input Dimensions: '+low__64(misw(ibuffer))+'w x '+low__64(mish(ibuffer))+'h ('+low__mbAUTO2(low__mult64(low__mult64(misw(ibuffer),mish(ibuffer)),misb(ibuffer) div 8),2,true)+')';
//was: rootwin.xstatus2.celltext[1]:='Output Dimensions: '+low__64(idw)+'w x '+low__64(idh)+'h ('+low__mbAUTO2(low__mult64(low__mult64(idw,idh),misb(ibuffer) div 8),2,true)+')';

rootwin.xstatus2.celltext[0]:='Input Dimensions: '+low__64(misw(ibuffer))+'w x '+low__64(mish(ibuffer))+'h';
rootwin.xstatus2.celltext[1]:='Output Dimensions: '+low__64(idw)+'w x '+low__64(idh)+'h';
rootwin.xstatus2.celltext[2]:='Uncompressed Size: '+low__mbAUTO2(xuncompressedsize,2,true);
rootwin.xstatus2.cellpert[2]:=low__pert32(xuncompressedsize,350*1000*1000);
rootwin.xstatus2.celltext[3]:=xtransparentstr;
//main toolbar
acanpaste:=low__canpasteimg;
rootwin.xtoolbar.benabled2['home']:=true;//23sep2021 - ((idx<>0) or (idy<>0));//23sep2021 and (not icenter);
rootwin.xtoolbar.benabled2['save']:=xcansave;
rootwin.xtoolbar.benabled2['saveas']:=not aempty;
rootwin.xtoolbar.benabled2['copy']:=not aempty;
rootwin.xtoolbar.benabled2['colors']:=not aempty;
rootwin.xtoolbar.benabled2['paste']:=acanpaste;
rootwin.xtoolbar.benabled2['pastefit']:=acanpaste;
rootwin.xtoolbar.bvisible2['sep1']:=rootwin.xtoolbar.bvisible2['colors'] or rootwin.xtoolbar.bvisible2['copy'] or rootwin.xtoolbar.bvisible2['paste'] or rootwin.xtoolbar.bvisible2['pastefit'];
rootwin.xtoolbar.bvisible2['sep2']:=rootwin.xtoolbar.bvisible2['colors'] or rootwin.xtoolbar.bvisible2['copy'] or rootwin.xtoolbar.bvisible2['paste'] or rootwin.xtoolbar.bvisible2['pastefit'];
//bottom boolbar - options
rootwin.xhigh2.xtoolbar.bhighlight2['mirror']:=imirror;
rootwin.xhigh2.xtoolbar.bhighlight2['flip']:=iflip;
rootwin.xhigh2.xtoolbar.bhighlight2['grey']:=igrey;
rootwin.xhigh2.xtoolbar.bhighlight2['sepia']:=isepia;
rootwin.xhigh2.xtoolbar.bhighlight2['invert']:=iinvert;
rootwin.xhigh2.xtoolbar.bhighlight2['soften']:=isoften;
rootwin.xhigh2.xtoolbar.bhighlight2['noise']:=inoise;
rootwin.xhigh2.xtoolbar.bcap2['transparent']:=xtransparentstr;
rootwin.xhigh2.xtoolbar.bhighlight2['transparent']:=itransparent;
rootwin.xhigh2.xtoolbar.bvisible2['sep1']:=rootwin.xhigh2.xtoolbar.bvisible2['mirror'] or rootwin.xhigh2.xtoolbar.bvisible2['flip'] or rootwin.xhigh2.xtoolbar.bvisible2['grey'] or rootwin.xhigh2.xtoolbar.bvisible2['sepia'] or rootwin.xhigh2.xtoolbar.bvisible2['noise'] or rootwin.xhigh2.xtoolbar.bvisible2['invert'] or rootwin.xhigh2.xtoolbar.bvisible2['soften'] or rootwin.xhigh2.xtoolbar.bvisible2['transparent'];
//bottom boolbar - tab markers
xmarktab('byzoom');
xmarktab('byfixedzoom');
xmarktab('bysize');
xmarktab('byfixedsize');

except;end;
end;
//## xtoolbarclick ##
function tprogram.xtoolbarclick(sender:tbasiccontrol;xstyle:string;xcode:longint;xcode2:string;xtepcolor:longint):boolean;
var
   int1,int2,xoldx,xoldy,xoldw,xoldh,xval,xval2:longint;
   ext1,ext2:extended;
   str1,str2:string;
   xstr1:array[0..19] of string;
   //## dhome ##
   procedure dhome;
   begin
   idx:=0;
   idy:=0;
   end;
   //## xok ##
   function xok(n:string):boolean;
   begin
   result:=low__comparetext(xcode2,n);
   end;
   //## xokval ##
   function xokval(n:string):boolean;
   begin
   xval:=0;
   result:=low__comparetext(strcopy1(xcode2,1,length(n)),n);
   if result then
      begin
      xval:=strint(strcopy1(xcode2,length(n)+1,length(xcode2)));
      if (strcopy1(xcode2,length(n),1)='-') then xval:=-xval;
      end;
   end;
   //## xokwh ##
   function xokwh(n:string):boolean;
   var
      str1:string;
      p:longint;
   begin
   xval:=0;
   xval2:=0;
   result:=low__comparetext(strcopy1(xcode2,1,length(n)),n);
   if result then
      begin
      str1:=strcopy1(xcode2,length(n)+1,length(xcode2));
      if (length(str1)>=1) then
         begin
         for p:=1 to length(str1) do if (strcopy1(str1,p,1)='x') then
            begin
            //.w
            xval:=strint(strcopy1(str1,1,p-1));
            //.h
            xval2:=strint(strcopy1(str1,p+1,length(str1)));
            //.stop
            break;
            end;//p
         end;
      end;
   end;
   //## xpixel ##
   procedure xpixel(xstyle:string;xadd:boolean);
   var
      v:longint;
   begin
   //check
   if (xval=0) then exit;
   //init
   xstyle:=low__lowercase(xstyle);
   //w
   if (xstyle='') or (xstyle='w') then idw:=frcrange(low__insint(idw,xadd)+xval,1,isizelimit);
   //h
   if (xstyle='') or (xstyle='h') then idh:=frcrange(low__insint(idh,xadd)+xval,1,isizelimit);
   end;
   //## xzoom ##
   procedure xzoom(xstyle:string;xadd:boolean);
   var
      v:longint;
   begin
   //check
   if (xval=0) then exit;
   //init
   xstyle:=low__lowercase(xstyle);
   //w
   if (xstyle='') or (xstyle='w') then
      begin
      v:=round(isw*(xval/100));
      if (v=0) then
         begin
         if (xval<0) then v:=-1 else v:=1;
         end;
      idw:=frcrange(low__insint(idw,xadd)+v,1,isizelimit);
      end;
   //h
   if (xstyle='') or (xstyle='h') then
      begin
      v:=round(ish*(xval/100));
      if (v=0) then
         begin
         if (xval<0) then v:=-1 else v:=1;
         end;
      idh:=frcrange(low__insint(idh,xadd)+v,1,isizelimit);
      end;
   end;
   //## xzoomREL ##
   procedure xzoomREL(xstyle:string;xadd:boolean);
   var
      v:longint;
   begin
   //check
   if (xval=0) then exit;
   //init
   xstyle:=low__lowercase(xstyle);
   //w
   if (xstyle='') or (xstyle='w') then
      begin
      v:=round(idw*(xval/100));
      if (v=0) then
         begin
         if (xval<0) then v:=-1 else v:=1;
         end;
      idw:=frcrange(low__insint(idw,xadd)+v,1,isizelimit);
      end;
   //h
   if (xstyle='') or (xstyle='h') then
      begin
      v:=round(idh*(xval/100));
      if (v=0) then
         begin
         if (xval<0) then v:=-1 else v:=1;
         end;
      idh:=frcrange(low__insint(idh,xadd)+v,1,isizelimit);
      end;
   end;
begin
try
//defaults
result:=true;
//init
xoldx:=idx;
xoldy:=idy;
xoldw:=idw;
xoldh:=idh;

//get
if xok('w.restore')     then
   begin
   idw:=isw;
   idx:=0;
   end
else if xok('h.restore')then
   begin
   idh:=ish;
   idy:=0;
   end
else if xok('restore')  then
   begin
   idw:=isw;
   idh:=ish;
   if iresetposition then dhome;
   end
//bpixel -----------------------------------------------------------------------
//.wh
else if xokval('-')     then xpixel('',true)
else if xokval('+')     then xpixel('',true)
else if xokval('set') then
   begin
   xstr1[0]:=low__64(idw);
   xstr1[1]:=low__64(idh);
   if sys.popmanyedit2(2,xstr1,tepIcon32,'Image Size',['Type a new width','Type a new height'],['Type a new width in pixels | Range 1..N','Type a new height in pixels | Range 1..N'],'','',50) then
      begin
      idw:=frcmin(strint(xstr1[0]),1);
      idh:=frcmin(strint(xstr1[1]),1);
      end;
//function tbasicsystem.popmanyedit2(var x:array of string;xtep32:longint;xtitle:string;xcap:array of string;xhelp:array of string;xcancelcap,xokcap:string;xsize:longint):boolean;

   end
//.w-/+
else if xokval('w.-')   then xpixel('w',true)
else if xokval('w.+')   then xpixel('w',true)
else if xokval('w.set') then
   begin
   str1:=low__64(idw);
   if sys.popedit2(str1,tepIcon32,'Image Width','Type a new width','Type a new width in pixels | Range 1..N','','',50) then idw:=frcmin(strint(str1),1);
   end
//.h-/+
else if xokval('h.-')   then xpixel('h',true)
else if xokval('h.+')   then xpixel('h',true)
else if xokval('h.set') then
   begin
   str1:=low__64(idh);
   if sys.popedit2(str1,tepIcon32,'Image Height','Type a new height','Type a new height in pixels | Range 1..N','','',50) then idh:=frcmin(strint(str1),1);
   end

//byzoom ----------------------------------------------------------------------
//.wh
else if xokval('%-')    then xzoom('',true)
else if xokval('%+')    then xzoom('',true)
//.w-/+
else if xokval('%w.-')  then xzoom('w',true)
else if xokval('%w.+')  then xzoom('w',true)
//.h-/+
else if xokval('%h.-')  then xzoom('h',true)
else if xokval('%h.+')  then xzoom('h',true)

//byzoomREL --------------------------------------------------------------------
//.wh
else if xokval('%%-')    then xzoomREL('',true)
else if xokval('%%+')    then xzoomREL('',true)
//.w-/+
else if xokval('%%w.-')  then xzoomREL('w',true)
else if xokval('%%w.+')  then xzoomREL('w',true)
//.h-/+
else if xokval('%%h.-')  then xzoomREL('h',true)
else if xokval('%%h.+')  then xzoomREL('h',true)

//bypreset ---------------------------------------------------------------------
//.p
else if xokval('p.')    then xzoom('',false)
//.special
else if xokwh('s:') then
   begin
   idw:=xval;
   idh:=xval2;
   end
else if xokval('facebook') then
   begin
   idw:=1160;
   idh:=1080;
   end
else if xokval('instagram') then
   begin
   idw:=1080;
   idh:=1080;
   end
else if xokval('twitter') then
   begin
   idw:=1080;
   idh:=620;
   end
else
   begin

   end;

//reposition
if ((xoldw<>idw) or (xoldh<>idh)) and ((idx<>0) or (idy<>0)) then
   begin
//   idx:=(iscreen.clientwidth-idw) div 2;
//   idy:=(iscreen.clientheight-idh) div 2;

   end;

//sync rightaway
xsyncinfo;
imustpaint:=true;
iinfotimer:=ms64;
except;end;
end;
//xxxxxxxxxxxxxxxxxxxxxxxxxxx//pppppppppppppppppppppppppp
//## xscreenpaint ##
procedure tprogram.xscreenpaint(sender:tobject);
var
   a:tbasicimage;
   xtrans,xtc,lx,rx,dcolor,dx,dy,dw,dh,cw,ch:longint;
begin
try
//init
a:=xbuffer;
cw:=iscreen.clientwidth;
ch:=iscreen.clientheight;
dx:=idx;
dy:=idy;
dw:=idw;
dh:=idh;
if xempty then
   begin
   dw:=0;
   dh:=0;
   end;
if icenter then
   begin
   dx:=(cw-dw) div 2;
   dy:=(ch-dh) div 2;
   end;

dcolor:=xscreencolor;
lx:=0;
rx:=cw-1;
xtrans:=low__aorb(0,1,itransparent);//0=none, 1=1bit, 2=8bit, 3=8bit enhanced -> dual purpose -> sharp, blur, blur2 AND transparent color
xtc:=mistranscol(a,itransstyle,itransparent);
//cls
case itransparent of
false:iscreen.ldsOUTSIDE(dx,dy,dw,dh,dcolor);
true:iscreen.lds(rect(0,0,cw-1,ch-1),dcolor,false);
end;
//get
if (dw>=1) and (dh>=1) then iscreen.ldc2(rect(0,0,cw,ch),dx,dy,dw*low__aorb(1,-1,imirror),dh*low__aorb(1,-1,iflip),rect(0,0,isw-1,ish-1),a,255,xtrans,xtc,clnone,xoptions,false);
except;end;
end;
//## xoptions ##
function tprogram.xoptions:currency;
begin
try;result:=misoptions(iinvert,igrey,isepia,inoise);except;end;//11sep2021
end;
//## xempty ##
function tprogram.xempty:boolean;
begin
try;result:=(misw(ibuffer)<=1) and (mish(ibuffer)<=1);except;end;
end;
//## xscreennotify ##
function tprogram.xscreennotify(sender:tobject):boolean;
   //## xzoom ##
   function xzoom(xmag:longint;xmin:boolean):extended;
   begin
   try
   if (xmag<1) then xmag:=1;
   if ismartdrag then result:=xmag*(idw/frcmin(iscreen.clientwidth,1)) else result:=xmag;
   if xmin and (result<1) then result:=1;
   except;end;
   end;
   //## yzoom ##
   function yzoom(xmag:longint;xmin:boolean):extended;
   begin
   try
   if (xmag<1) then xmag:=1;
   if ismartdrag then result:=xmag*(idh/frcmin(iscreen.clientheight,1)) else result:=xmag;
   if xmin and (result<1) then result:=1;
   except;end;
   end;
begin
try
//defaults
result:=false;
//get
if sys.mousedownstroke then
   begin
   idownx:=idx;
   idowny:=idy;
   end;
if sys.mousedraggingfine then
   begin
   if not icenter then
      begin
      idx:=xfilterx(round(idownx+xzoom(1,true)*(sys.mousemovexy.x-sys.mousedownxy.x)));
      idy:=xfiltery(round(idowny+yzoom(1,true)*(sys.mousemovexy.y-sys.mousedownxy.y)));
      app__turbo;//sys.turbonow;
      imustpaint:=true;
      end;
   end;
if (sys.wheel<>0) then
   begin
   if not icenter then
      begin
      idy:=xfiltery(round(idy+gui.wheel*100));//better expectations - 05jun2021
      //was: idy:=xfiltery(round(idy+gui.wheel*yzoom(10,true)));
      app__turbo;//sys.turbonow;
      imustpaint:=true;
      end;
   end;
//.right click menu
if sys.mouseupstroke and sys.mouseright then rootwin.showmenu2('menu');
except;end;
end;
//## xfilterx ##
function tprogram.xfilterx(x:longint):longint;
begin
try;result:=frcrange(x,frcmax(-idw+imargin,0),low__aorb(maxint,iscreen.clientwidth-imargin,sys.showing));except;end;
end;
//## xfiltery ##
function tprogram.xfiltery(x:longint):longint;
begin
try;result:=frcrange(x,frcmax(-idh+imargin,0),low__aorb(maxint,iscreen.clientheight-imargin,sys.showing));except;end;
end;
//## xfilter ##
procedure tprogram.xfilter;
begin
try
idx:=xfilterx(idx);
idy:=xfiltery(idy);
if low__setstr(ibufferref,inttostr(iscreenstyle)+'_'+inttostr(xscreencolor)+'_'+inttostr(itransstyle)+'_'+bnc(imirror)+bnc(iflip)+bnc(itransparent)+bnc(igrey)+bnc(isepia)+bnc(inoise)+bnc(iinvert)+bnc(isoften)+'_'+inttostr(isoftenpert)+'_'+inttostr(ibufferid)+'_'+inttostr(idx)+'_'+inttostr(idy)+'_'+inttostr(idw)+'_'+inttostr(idh)+'_'+inttostr(sys.width)+'_'+inttostr(sys.height)) then imustpaint:=true;
except;end;
end;
//## xbuffer ##
function tprogram.xbuffer:tbasicimage;
var
   dpower255:longint;
begin
try
//defaults
result:=ibuffer;
//init
dpower255:=round((low__insint(isoftenpert,isoften)/100)*255);
//get
if low__setstr(isoftenref,inttostr(dpower255)+'|'+inttostr(ibufferid)+'|'+inttostr(misw(ibuffer))+'|'+inttostr(mish(ibuffer))) then
   begin
   case (dpower255>=1) of
   true:begin
      missize(ibuffer2,misw(ibuffer),mish(ibuffer));
      miscopyareaxx1(0,0,misw(ibuffer2),mish(ibuffer2),misarea(ibuffer),ibuffer2,ibuffer);
      misblur82432b(ibuffer2,false,dpower255,low__aorb(clnone,itransstyle,itransparent));
      end;
   false:missize(ibuffer2,1,1);//reduce RAM
   end;//case
   end;
//set
if (dpower255>=1) then result:=ibuffer2;
except;end;
end;
//## xshowmenuFill1 ##
procedure tprogram.xonshowmenuFill1(sender:tobject;xstyle:string;xmenudata:tstr8;var ximagealign:longint;var xmenuname:string);
var
   xhelp,str1:string;
   p,int1,int2:longint;
   bol1,acanpaste,aempty,aimgok:boolean;
begin
try
//check
if zznil(xmenudata,5000) then exit;

//init
xmenuname:='pickzoom.'+xstyle;
aempty:=xempty;
aimgok:=not aempty;
acanpaste:=low__canpasteimg;
//menu
if (xstyle='menu') then
   begin
   //file
   low__menutitle(xmenudata,tepnone,'File','File options');
   low__menuitem2(xmenudata,tepOpen20,'Open...','Open image from file','open',100,aknone,true);
   low__menuitem2(xmenudata,tepSave20,'Save As...','Save image to file','saveas',100,aknone,aimgok);
   low__menuitem2(xmenudata,tepSave20,'Save A Copy...','Save a copy of image to file','saveas2',100,aknone,aimgok);
   //edit
   low__menutitle(xmenudata,tepnone,'Edit','Edit options');
   low__menuitem2(xmenudata,tepCopy20,'Copy','Copy zoomed image to clipboard','copy',100,aknone,aimgok);
   low__menuitem2(xmenudata,tepPaste20,'Paste','Paste image from clipboard','paste',100,aknone,acanpaste);
   low__menuitem2(xmenudata,tepPaste20,'Paste Fit','Paste image to fit from clipboard','pastefit',100,aknone,acanpaste);
   //effects
   low__menutitle(xmenudata,tepnone,'Effects','Effects');
   low__menuitem2(xmenudata,tep__yes(imirror),'Mirror','Ticked: Mirror image','mirror',100,aknone,true);
   low__menuitem2(xmenudata,tep__yes(iflip),'Flip','Ticked: Flip image','flip',100,aknone,true);
   low__menuitem2(xmenudata,tep__yes(igrey),'Grey','Ticked: Apply "Grey" filter','grey',100,aknone,true);
   low__menuitem2(xmenudata,tep__yes(isepia),'Sepia','Ticked: Apply "Sepia" filter','sepia',100,aknone,true);
   low__menuitem2(xmenudata,tep__yes(inoise),'Noise','Ticked: Apply "Noise" filter','noise',100,aknone,true);
   low__menuitem2(xmenudata,tep__yes(iinvert),'Invert','Ticked: Invert colors','invert',100,aknone,true);
//   low__menuitem2(xmenudata,tep__yes(isoften),'Soften','Ticked: Soften image','soften',100,aknone,true);
   low__menusep(xmenudata);
   low__menuitem2(xmenudata,tepSub20,'All Off','Turn all effects off','effectsoff',100,aknone,imirror or iflip or igrey or isepia or inoise or iinvert or isoften);

{
   //soften strength
   low__menutitle(xmenudata,tepnone,'Soften','Soften Mode');
   low__menuitem2(xmenudata,tep__tick(not isoften),'Off','Do not soften','soften.0',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=25)),'25% - Mild','Soften at 25% strength','softenpert.25',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=50)),'50% - Low','Soften at 50% strength','softenpert.50',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=75)),'75% - Medium','Soften at 75% strength','softenpert.75',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=100)),'100% - High','Soften at 100% strength','softenpert.100',100,aknone,true);

   //transparent
   low__menutitle(xmenudata,tepnone,'Transparency','Transparency Mode');
   low__menuitem2(xmenudata,tep__tick(not itransparent),'Off','Do use transparency','transparency.0',100,aknone,true);
   for p:=0 to maxint do
   begin
   if not mistransNEXT2(int1,int2,str1,bol1,'Custom...',p=0) then break;
   //.help
   if (int2=clTopLeft) then xhelp:='Use top-left pixel color as transparency color' else xhelp:='Use "'+str1+'" as transparency color';
   //.menu item
   low__menuitem2(xmenudata,tep__tick(itransparent and mistransISOK(itransstyle,int2)),'Use '+str1,xhelp,'transstyle.'+low__aorbstr(inttostr(int2),'custom',bol1),100,aknone,true);
   end;//p
{}
   end
//settings
else if (xstyle='settings') then
   begin
   //screen color
   low__menutitle(xmenudata,tepnone,'Screen Color','Screen color');
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=0),'Default','Default color','screenstyle.0',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=1),'Grey','Grey','screenstyle.1',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=2),'Light Grey','Light Grey','screenstyle.2',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=3),'Black','Black','screenstyle.3',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=4),'White','White','screenstyle.4',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=5),'Off White','Off White','screenstyle.5',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(iscreenstyle=6),'Custom...','Custom','screenstyle.6',100,aknone,true);
   //settings
   low__menutitle(xmenudata,tepnone,'Settings','Settings');
   low__menuitem2(xmenudata,tep__yes(icenter),'Center on Screen','Ticked: Center image on screen','center',100,aknone,true);
   //low__menuitem2(xmenudata,tep__yes(ismartdrag),'Smart Drag','Ticked: Drag large images faster','smartdrag',100,aknone,not icenter);
   low__menuitem2(xmenudata,tep__yes(iresetposition),'Automatic "Home" Position','Automatically restore image to "Home" position (top-left of screen) after an "Open", "Paste" or "Restore" action','resetpos',100,aknone,not icenter);
   //transparency
   low__menutitle(xmenudata,tepnone,'Transparency','Transparency Mode');
   low__menuitem2(xmenudata,tep__tick(not itransparent),'Off','Do use transparency','transparency.0',100,aknone,true);
   for p:=0 to maxint do
   begin
   if not mistransNEXT2(int1,int2,str1,bol1,'Custom...',p=0) then break;
   //.help
   if (int2=clTopLeft) then xhelp:='Use top-left pixel color as transparency color' else xhelp:='Use "'+str1+'" as transparency color';
   //.menu item
   low__menuitem2(xmenudata,tep__tick(itransparent and mistransISOK(itransstyle,int2)),'Use '+str1,xhelp,'transstyle.'+low__aorbstr(inttostr(int2),'custom',bol1),100,aknone,true);
   end;//p

   //soften strength
   low__menutitle(xmenudata,tepnone,'Soften','Soften Mode');
   low__menuitem2(xmenudata,tep__tick(not isoften),'Off','Do not soften','soften.0',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=25)),'25% - Mild','Soften at 25% strength','softenpert.25',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=50)),'50% - Low','Soften at 50% strength','softenpert.50',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=75)),'75% - Medium','Soften at 75% strength','softenpert.75',100,aknone,true);
   low__menuitem2(xmenudata,tep__tick(isoften and (isoftenpert=100)),'100% - High','Soften at 100% strength','softenpert.100',100,aknone,true);
   end;

//get
//xxxxxxxxxxxxlow__menuitem3(xmenudata,tep__tick(iintro=4),'30 secs','Ticked: Play first 30 seconds of midi','intro:4',100,aknone,false,true);
except;end;
end;
//## xshowmenuClick1 ##
function tprogram.xonshowmenuClick1(sender:tbasiccontrol;xstyle:string;xcode:longint;xcode2:string;xtepcolor:longint):boolean;
begin
try;result:=true;xcmd(sender,xcode,xcode2);except;end;
end;



initialization
   siInit;

finalization
   siHalt;

end.
