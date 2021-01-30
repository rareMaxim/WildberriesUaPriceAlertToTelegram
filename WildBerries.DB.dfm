object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 274
  Width = 380
  object FDConnection1: TFDConnection
    ConnectionName = 'wb'
    Params.Strings = (
      
        'Database=C:\Users\admin\Documents\Wildberries\Win32\Debug\wildbe' +
        'rries.db'
      'DriverID=SQLite')
    Connected = True
    LoginPrompt = False
    Left = 56
    Top = 24
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    VendorLib = 'sqlite3.dll'
    EngineLinkage = slDynamic
    Left = 176
    Top = 120
  end
end
