подключение
$SqlServer = "(LocalDB)\MSSQLLocalDB";
$SqlCatalog = "AIS"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=$SqlServer; Database=$SqlCatalog; Integrated Security=True"
$SqlConnection.Open()	

ВЫВОД
$SqlCmd = $SqlConnection.CreateCommand()
$SqlCmd.CommandText = "Select Пароль, Логин from Пользователи"
$objReader = $SqlCmd.ExecuteReader()
   while ($objReader.read()) {
      echo $objReader.GetValue(0)
   }
$objReader.close()

ДОБАВЛЕНИЕ
$SqlCmd = $SqlConnection.CreateCommand()
$SqlCmd.CommandText = "Insert into Пользователи values ('FOF','12345')"
$objReader = $SqlCmd.ExecuteNonQuery() | Out-Null

ОБНОВЛЕНИЕ
$SqlCmd = $SqlConnection.CreateCommand()
$SqlCmd.CommandText = "UPDATE Пользователи SET Пароль ='123465' WHERE Логин ='FOF'"
$objReader = $SqlCmd.ExecuteNonQuery() | Out-Null

УДАЛЕНИЕ
$SqlCmd = $SqlConnection.CreateCommand()
$SqlCmd.CommandText = "Delete from Пользователи Where Логин = 'FOF'"
$objReader = $SqlCmd.ExecuteNonQuery() | Out-Null



$SqlConnection.Close()