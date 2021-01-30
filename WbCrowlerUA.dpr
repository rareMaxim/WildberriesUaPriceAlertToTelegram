program WbCrowlerUA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.NetEncoding,
  TelegramBotApi.Client,
  TelegramBotApi.Types,
  TelegramBotApi.Types.Enums,
  TelegramBotApi.Types.Request,

  WildBerries.Client,
  WildBerries.Types,
  WildBerries.DB in 'WildBerries.DB.pas' {DataModule1: TDataModule};

type
  TwbCore = class
  private
    fWb: TWildBerriesClient;
    fMenu: TwbMenuItems;
    FDB: TDataModule1;
    fTg: TTelegramBotApi;
  protected
    procedure ReportNewPrice(AProd: TwbProductItem; NewPrice, OldPrice: Integer);
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
  FDB.OnNewPrice := ReportNewPrice;

  fTg := TTelegramBotApi.Create;
  fTg.BotToken := {$I token.inc};
  Writeln(fTg.GetMe.Result.Username);
end;

destructor TwbCore.Destroy;
begin
  fTg.Free;
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

procedure TwbCore.ReportNewPrice(AProd: TwbProductItem; NewPrice, OldPrice: Integer);
var
  lMsg: TtgMessageArgument;
  lTgMsg: string;
const
  // Тип Бренд
  // Старая цена:
  // Новая цена:
  // Ссылка
  MSG = '%s %s' + #13#10 + //
  // 'Старая цена: %f' + #13#10 + //
  // 'Новая цена: %f' + #13#10 + //
  // 'https://wildberries.ua/product?card=%d' + //
    '';
begin //
  lTgMsg := AProd.Name + ' <a href="' + fWb.GetProductImages(AProd)[0] + '">' + AProd.Brand + '</a>' + sLineBreak + //
    'Старая цена: ' + (OldPrice / 100).ToString + sLineBreak + //
    'Новая цена: ' + (NewPrice / 100).ToString + sLineBreak + //
    'https://wildberries.ua/product?card=' + AProd.ID.ToString + //
  { } '';
  lMsg := TtgMessageArgument.Create;
  try
    lMsg.ChatId := '@WildberriesUA';
    lMsg.ParseMode := TtgParseMode.HTML;
    lMsg.Text := lTgMsg;
    fTg.SendMessage(lMsg);
  finally
    lMsg.Free;
  end;
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
const
  FILTER = 'КроссовкиКедыОбувь';
begin
  if not FILTER.Contains(ANode.Name) then
    Exit;
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
 //   Sleep(1000);
  end;
end;

procedure Main;
var
  lWB: TwbCore;
begin
  lWB := TwbCore.Create;
  try
    while True do
    begin
      lWB.ReadConfig;
      lWB.OpenMenu;
      lWB.WriteMenu(lWB.Menu, 0);
    end;
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
