program WbCrowlerUA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  CloudAPI.Exceptions,
  System.SysUtils,
  System.NetEncoding,
  TelegramBotApi.Client,
  TelegramBotApi.Types,
  TelegramBotApi.Types.Enums,
  TelegramBotApi.Types.Request,

  WildBerries.Client,
  WildBerries.Types,
  WildBerries.DB in 'WildBerries.DB.pas' {DataModule1: TDataModule} ,
  Winapi.Windows,
  System.Generics.Collections;

type
  TwbCore = class
  private
    fWb: TWildBerriesClient;
    fMenu: TObjectList<TwbMenuItem>;
    FDB: TDataModule1;
    fTg: TTelegramBotApi;
  protected
    procedure ReportNewPrice(AProd: TwbProductItem; AOldPrice: Integer);
    procedure WriteMenu(ANodes: TObjectList<TwbMenuItem>; APrefixLength: Integer; const AMenuPath: string);
    procedure WritePrice(ANode: TwbMenuItem; const AMenuPath: string);
  public
    procedure ReadConfig;
    procedure OpenMenu;

    constructor Create;
    destructor Destroy; override;
    property Menu: TObjectList<TwbMenuItem> read fMenu;
  end;

  { TwbCore }

constructor TwbCore.Create;
begin
  fMenu := TObjectList<TwbMenuItem>.Create;
  fWb := TWildBerriesClient.Create;
  fWb.CloudAPI.ExceptionManager.AlertEvent := True;
  fWb.CloudAPI.ExceptionManager.OnAlert := procedure(E: ECloudApiException)
    begin
      Writeln(E.ToString);
    end;

  FDB := TDataModule1.Create(nil);
  FDB.OnNewPrice := ReportNewPrice;

  fTg := TTelegramBotApi.Create;
  fTg.BotToken := {$I token.inc};
  Writeln(fTg.GetMe.Result.Username);
end;

destructor TwbCore.Destroy;
begin
  fMenu.Free;
  fTg.Free;
  fWb.Free;
  FDB.Free;
  inherited;
end;

procedure TwbCore.OpenMenu;
begin
  fMenu.Clear;
  fMenu.AddRange(fWb.GetMenu);
end;

procedure TwbCore.ReadConfig;
begin
  fWb.GetConfiguration;
end;

procedure TwbCore.ReportNewPrice(AProd: TwbProductItem; AOldPrice: Integer);
var
  lMsg: TtgMessageArgument;
begin
  Writeln('НОВАЯ ЦЕНА: ' + AProd.Name + ' ' + AProd.Brand + ' ' + AProd.SalePriceU.ToString);
  lMsg := TtgMessageArgument.Create;
  try
    lMsg.ChatId := '@WildberriesUA';
    lMsg.ParseMode := TtgParseMode.HTML;
    lMsg.Text := //
      AProd.Name + ' <a href="' + fWb.GetProductImages(AProd)[0] + '">' + AProd.Brand + '</a>' + sLineBreak + //
      '<i>' + AProd.MenuPath + '</i>' + sLineBreak + //
      'Старая цена: ' + (AOldPrice / 100).ToString + sLineBreak + //
      'Новая цена: ' + (AProd.SalePriceU / 100).ToString + sLineBreak + //
      'https://wildberries.ua/product?card=' + AProd.ID.ToString + //
    { } '';
    try
      fTg.SendMessage(lMsg);
    except
      on E: Exception do
        Writeln('Ошибка отправки соообщения в ТГ: ' + E.ToString);
    end;
  finally
    lMsg.Free;
  end;
end;

procedure TwbCore.WriteMenu(ANodes: TObjectList<TwbMenuItem>; APrefixLength: Integer; const AMenuPath: string);
var
  I: Integer;
  lPrefix: string;
begin
  for I := 0 to APrefixLength do
    lPrefix := lPrefix + '-';
  for I := 0 to ANodes.Count - 1 do
  begin
    Writeln(lPrefix + ' ' + ANodes[I].Name + ' - ' + ANodes[I].ShardKey);
    if ANodes[I].Nodes.Count > 0 then
      WriteMenu(ANodes[I].Nodes, APrefixLength + 1, string.Join(' #', [AMenuPath, ANodes[I].Name]))
    else
    begin
      WritePrice(ANodes[I], AMenuPath);
    end;
  end;
end;

procedure TwbCore.WritePrice(ANode: TwbMenuItem; const AMenuPath: string);
var
  lCatalog: TwbProducts;
  lFilters: TwbFilters;
  lCursor: Integer;
  I: Integer;
const
  FILTER = 'КроссовкиКедыОбувь';
begin
  // if not FILTER.Contains(ANode.Name) then Exit;
  lFilters := fWb.GetFilters(ANode);
  if lFilters = nil then
    Exit;
  try
    lCursor := 0;
    while lCursor * 100 <= lFilters.Total do
    begin
      Inc(lCursor);
      try
        lCatalog := fWb.OpenCatalog(ANode, 100, lCursor, 'popular');
        if not Assigned(lCatalog) then
          Continue;
        try
          for I := 0 to lCatalog.Products.Count - 1 do
          begin
            SetConsoleTitle(PWideChar(ANode.Name + ': ' + (I).ToString + '/' + (lCursor * 100).ToString + '/' +
              lFilters.Total.ToString));
            lCatalog.Products[I].MenuPath := AMenuPath;
            FDB.UpdateProduct(lCatalog.Products[I]);
          end;
        except
          on E: Exception do
            Writeln(E.ToString);
        end;
        if lCursor >= 1 then
          Break;
        // Sleep(1000);
      finally
        if Assigned(lCatalog) then
          lCatalog.Free;
      end;
    end;
  finally
    lFilters.Free;
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
      lWB.WriteMenu(lWB.Menu, 0, '');
    end;
  finally
    lWB.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    ReportMemoryLeaksOnShutdown := True;
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;

end.
