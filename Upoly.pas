unit Upoly;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,math, ExtCtrls;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Imagetexture: TImage;
    procedure FormCreate(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageDblClick(Sender: TObject);
  private

  public
    procedure drawpolygone;
  end;

type
 polygone=record taille:integer; sommet:array of tpoint;  end;
 tligne  =record count:integer;  cote:array of integer; end;
 Tarray32=array[0..16000] of dword;
 parray32=^tarray32;

var
  Form1: TForm1;
  p:polygone;

implementation

{$R *.dfm}

procedure swapval(var x,y: integer);
var
 tmp:integer;
begin
 tmp:=x;
 x:=y;
 y:=tmp;
end;

procedure TForm1.drawpolygone;
var
 i,j,k:integer;
 ligne:TLigne;
 x0,y0,x1,y1,x2,y2:integer;
 mini,maxi:integer;
 texture,image:parray32;
begin
 // on ajout deux sommet qui ferons la boucle avec les deux premiers
 setlength(p.sommet,p.taille+2);
 p.sommet[p.taille].X:=p.sommet[0].X;
 p.sommet[p.taille].y:=p.sommet[0].y;
 p.sommet[p.taille+1].X:=p.sommet[1].X;
 p.sommet[p.taille+1].y:=p.sommet[1].y;

 // cherche la ligne la plus en haut et la plus en bas
 mini:=600;
 maxi:=0;
 for i:=1 to p.taille do
  begin
   if p.sommet[i].Y>maxi then maxi:=p.sommet[i].Y;
   if p.sommet[i].Y<mini then mini:=p.sommet[i].Y;
  end;

 for i:=mini to maxi do
  begin
   ligne.count:=0;
   setlength(ligne.cote,0);
   // recherche des points d'intersection avec les aretes
   for j:=1 to p.taille do
    begin
     x0:=p.sommet[j-1].x; y0:=p.sommet[j-1].y;
     x1:=p.sommet[j].x;   y1:=p.sommet[j].y;
     x2:=p.sommet[j+1].x; y2:=p.sommet[j+1].y;



     // cas particulier d'un sommet sur l'horizontal
     // si c'est le deuxième point, on le traitera à l'itération suivante
     if (i=y2) then  continue;
     // si c'est le premier point, on regarde comment
     if (i=y1) then
      begin
        // on enregistre l'intersection
        inc(ligne.count);
        setlength(ligne.cote,ligne.count);
        ligne.cote[ligne.count-1]:=x1;

        // si les deux aretes sont du même coté de la droite horizontale, le point compte double
        if sign(y1-y0)*sign(y1-y2)>=0 then
         begin
          inc(ligne.count);
          setlength(ligne.cote,ligne.count);
          ligne.cote[ligne.count-1]:=x1;
         end;
        continue;
      end;

     // l'arete est horizontal, on laisse tomber
     if y1=y2 then continue;

     // on tri les deux points par ordre des Y
     if y1>y2 then begin swapval(x1,x2); swapval(y1,y2); end;

     // si la ligne passe entre les deux ordonnées, il y a intersection
     if ((y1<=i) and (i<=y2)) then
      begin
       inc(ligne.count);
       setlength(ligne.cote,ligne.count);
       ligne.cote[ligne.count-1]:=round(x1+(i-y1)/(y2-y1)*(x2-x1));// formule donnant l'abscisse
      end;
   end;

   // on tri les points d'intersections dans l'ordre croissant
   for j:=0 to ligne.count-2 do
    for k:=j+1 to ligne.count-1 do
     if ligne.cote[j]>ligne.cote[k] then swapval(ligne.cote[j],ligne.cote[k]);

   // on pointe vers la ligne du canvas et de texture correspondante
   image:=image1.picture.Bitmap.ScanLine[i];
   texture:=Imagetexture.picture.Bitmap.ScanLine[i mod Imagetexture.height];

   // on trace les segments en prenant les intersections deux à deux.
   for j:=0 to (ligne.count div 2)-1 do
    for k:=ligne.cote[j*2] to ligne.cote[j*2+1] do
     image[k]:=texture[k mod Imagetexture.Width];
  end;

  //on trace les contours
  for i:=0 to p.taille do
   begin
    image1.canvas.MoveTo(p.sommet[i].x,p.sommet[i].y);
    image1.canvas.LineTo(p.sommet[i+1].x,p.sommet[i+1].y);
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 p.taille:=0;
 setlength(p.sommet,0);
 image1.Picture.Bitmap:=tbitmap.Create;
 image1.Picture.Bitmap.Width:=image1.Width;
 image1.Picture.Bitmap.Height:=image1.Height;
 image1.picture.Bitmap.PixelFormat:= pf32bit;
 Imagetexture.picture.Bitmap.PixelFormat:= pf32bit;
end;

procedure TForm1.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if p.taille=-1 then
  begin
   p.taille:=0;
   setlength(p.sommet,0);
   exit;
  end;

 inc(p.taille);
 setlength(p.sommet,p.taille);
 p.sommet[p.taille-1].X:=x;
 p.sommet[p.taille-1].y:=y;

 if p.taille=1 then
  begin
   image1.canvas.Pixels[x,y]:=clBlack;
  end
 else
  begin
   image1.canvas.MoveTo(p.sommet[p.taille-2].x,p.sommet[p.taille-2].y);
   image1.canvas.LineTo(p.sommet[p.taille-1].x,p.sommet[p.taille-1].y);
  end;   
end;

procedure TForm1.ImageDblClick(Sender: TObject);
begin
 image1.canvas.MoveTo(p.sommet[p.taille-1].x,p.sommet[p.taille-1].y);
 image1.canvas.LineTo(p.sommet[0].x,p.sommet[0].y);
 drawpolygone;
 p.taille:=-1;
end;

end.