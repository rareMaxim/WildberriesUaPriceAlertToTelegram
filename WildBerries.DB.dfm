object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 274
  Width = 380
  object FDConnection1: TFDConnection
    Params.Strings = (
      
        'Database=C:\Users\admin\Documents\WildberriesUaPriceAlertToTeleg' +
        'ram\Win32\Debug\wildberries.db'
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 56
    Top = 24
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    VendorLib = 'sqlite3.dll'
    Left = 176
    Top = 120
  end
end
