unit WildBerries.DB;

interface

uses
  WildBerries.Types,
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.ConsoleUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet;

type
  TDataModule1 = class(TDataModule)
    FDConnection1: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
  private
    { Private declarations }
  public
    { Public declarations }

    procedure UpdateProduct(AProd: TwbProductItem);
    function IsAvaibleProduct(AProd: TwbProductItem): Boolean;
    procedure AddProduct(AProd: TwbProductItem);
    procedure AddPrice(AProd: TwbProductItem);
    function LastPrice(AID: Integer): Integer;
    constructor Create(AOwner: TComponent); override;
  end;

var
  DataModule1: TDataModule1;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}
{$R *.dfm}

procedure TDataModule1.AddPrice(AProd: TwbProductItem);
// INSERT INTO "wildberries"."prices" ("productID", "date", "actualPrice") VALUES ('1', '2', '3');
const
  CMD = 'INSERT INTO "prices" (productID, date, actualPrice) VALUES (:productID, :date, :actualPrice)';
var
  lQuery: TFDQuery;
begin
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FDConnection1;
    lQuery.SQL.Text := CMD;
    lQuery.ParamByName('productID').AsInteger := AProd.ID;
    lQuery.ParamByName('date').AsDateTime := NOW;
    lQuery.ParamByName('actualPrice').AsInteger := AProd.SalePriceU;
    lQuery.Prepare;
    lQuery.Execute;
  finally
    lQuery.Close;
    lQuery.Free;
  end;

end;

procedure TDataModule1.AddProduct(AProd: TwbProductItem);
const
  CMD = 'INSERT INTO "product" (' + //
    '"ID", root, kindId, subjectId, "name","brand", brandId, siteBrandId,  "sale", "priceU", "salePriceU", pics, rating, feedbacks) '
    + 'VALUES (' + //
    ':ID, :root, :kindId, :subjectId, :NAME, :BRAND, :brandId, :siteBrandId, :SALE, :priceU, :salePriceU, :pics, :rating, :feedbacks)';
var
  lQuery: TFDQuery;
begin

  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FDConnection1;
    lQuery.SQL.Text := CMD;
    lQuery.ParamByName('ID').AsInteger := AProd.ID;
    lQuery.ParamByName('root').AsInteger := AProd.Root;
    lQuery.ParamByName('kindId').AsInteger := AProd.KindID;
    lQuery.ParamByName('subjectId').AsInteger := AProd.SubjectID;
    lQuery.ParamByName('NAME').AsString := AProd.Name;
    lQuery.ParamByName('BRAND').AsString := AProd.Brand;
    lQuery.ParamByName('brandId').AsInteger := AProd.BrandID;
    lQuery.ParamByName('siteBrandId').AsInteger := AProd.SiteBrandID;
    lQuery.ParamByName('SALE').AsInteger := AProd.Sale;
    lQuery.ParamByName('priceU').AsInteger := AProd.PriceU;
    lQuery.ParamByName('salePriceU').AsInteger := AProd.SalePriceU;
    lQuery.ParamByName('pics').AsInteger := AProd.Pics;
    lQuery.ParamByName('rating').AsInteger := AProd.Rating;
    lQuery.ParamByName('feedbacks').AsInteger := AProd.Feedbacks;
    lQuery.Prepare;
    lQuery.Execute;
  finally
    lQuery.Close;
    lQuery.Free;
  end;

end;

constructor TDataModule1.Create(AOwner: TComponent);
begin
  inherited;
  FDConnection1.Params.Database := 'wildberries.db';
end;

function TDataModule1.IsAvaibleProduct(AProd: TwbProductItem): Boolean;
var
  lQuery: TFDQuery;
begin
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FDConnection1;
    lQuery.SQL.Text := 'SELECT * FROM `product` WHERE `ID`="' + AProd.ID.ToString + '" LIMIT 1';
    lQuery.Active := True;
    Result := not lQuery.IsEmpty;
  finally
    lQuery.Close;
    lQuery.Free;
  end;
end;

function TDataModule1.LastPrice(AID: Integer): Integer;
// SELECT * FROM "prices" WHERE productID=1 ORDER BY "date" DESC LIMIT 1000;
var
  lQuery: TFDQuery;
begin
  Result := -1;
  lQuery := TFDQuery.Create(nil);
  try
    lQuery.Connection := FDConnection1;
    lQuery.SQL.Text := 'SELECT * FROM "prices" WHERE productID=:productID ORDER BY "date" DESC LIMIT 1';
    lQuery.ParamByName('productID').AsInteger := AID;
    lQuery.Open();
    while not lQuery.Eof do
    begin
      Result := lQuery.FieldByName('actualPrice').AsInteger;
      lQuery.Next;
    end;
  finally
    lQuery.Close;
    lQuery.Free;
  end;

end;

procedure TDataModule1.UpdateProduct(AProd: TwbProductItem);
var
  lIsAvaibleProduct: Boolean;
  lLastPrice: Integer;
begin
  lIsAvaibleProduct := IsAvaibleProduct(AProd);
  if not lIsAvaibleProduct then
  begin
    AddProduct(AProd);
    AddPrice(AProd);
  end;
  lLastPrice := LastPrice(AProd.ID);
  if lLastPrice > 0 then
    if lLastPrice <> AProd.SalePriceU then
    begin
      AddPrice(AProd);
      Writeln('НОВАЯ ЦЕНА: ' + AProd.Name + ' ' + AProd.Brand + ' ' + AProd.SalePriceU.ToString);
    end;
end;

end.
