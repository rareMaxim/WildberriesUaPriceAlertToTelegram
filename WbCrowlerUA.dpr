program WbCrowlerUA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  WildBerries.Client,
  WildBerries.Types,
  WildBerries.DB in 'WildBerries.DB.pas' {DataModule1: TDataModule};

type
  TwbCore = class
  private
    fWb: TWildBerriesClient;
    fMenu: TwbMenuItems;
    FDB: TDataModule1;
  protected
    procedure WriteMenu(ANodes: TArray<TwbMenuItem>; APrefixLength: Integer);
    procedure WritePrice(ANode: TwbMenuItem);
  public
    procedure ReadConfig;
    procedure OpenMenu;

    constructor Create;
    destructor Destroy; override;
    property Menu: TwbMenuItems read fMenu write fMenu;
  end;

  { TwbCore }

constructor TwbCore.Create;
begin
  fWb := TWildBerriesClient.Create;
  FDB := TDataModule1.Create(nil);
end;

destructor TwbCore.Destroy;
begin
  fWb.Free;
  FDB.Free;
  inherited;
end;

procedure TwbCore.OpenMenu;
begin
  fMenu := fWb.GetMenu.Data;
end;

procedure TwbCore.ReadConfig;
begin
  fWb.GetConfiguration;
end;

procedure TwbCore.WriteMenu(ANodes: TArray<TwbMenuItem>; APrefixLength: Integer);
var
  I: Integer;
  lPrefix: string;
begin
  for I := 0 to APrefixLength do
    lPrefix := lPrefix + '-';
  for I := Low(ANodes) to High(ANodes) do
  begin
    Writeln(lPrefix + ' ' + ANodes[I].Name + ' - ' + ANodes[I].ShardKey);
    if Assigned(ANodes[I].Nodes) then
      WriteMenu(ANodes[I].Nodes, APrefixLength + 1)
    else
    begin
      WritePrice(ANodes[I]);
    end;
  end;
end;

procedure TwbCore.WritePrice(ANode: TwbMenuItem);
var
  lCatalog: TArray<TwbProductItem>;
  lProduct: TwbProductItem;
  lFilters: TwbFilters;
  lCursor: Integer;
begin
  lFilters := fWb.GetFilters(ANode).Data;
  lCursor := 0;
  while lCursor * 100 <= lFilters.Total do
  begin
    Inc(lCursor);
    lCatalog := fWb.OpenCatalog(ANode, 100, lCursor, 'popular').Data.Products;
    for lProduct in lCatalog do
    begin
      FDB.UpdateProduct(lProduct);
    end;
    // Sleep(500);
  end;
end;

procedure Main;
var
  lWB: TwbCore;
begin
  lWB := TwbCore.Create;
  try
    lWB.ReadConfig;
    lWB.OpenMenu;
    lWB.WriteMenu(lWB.Menu, 0);
  finally
    lWB.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
