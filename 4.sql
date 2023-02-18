use master
go
create database EDB37
GO

use EDB37
go
create table dbo.CCI
(PersonID int Primary key,
CreditCardNumber varbinary (max))
go

use EDB37
go
create master key encryption by password = '$tr0nGPa$$w0rd'
go

use EDB37
go
create asymmetric key MyAsymmetricKey
with algorithm = RSA_2048
encryption by password = 'StrongPa$$w0rd'
go
Create symmetric key MySymmetricKey
with algorithm = AES_256
Encryption by asymmetric key MyAsymmetricKey

use EDB37
go
open symmetric key MySymmetricKey
Decryption by asymmetric key MyAsymmetricKey
with password = 'StrongPa$$w0rd'
go

use EDB37
go
Select * from sys.openkeys



USE EDB37
GO
DECLARE @SymmetricKeyGUID AS [uniqueidentifier]
SET @SymmetricKeyGUID = KEY_GUID('MySymmetrickey')
IF (@SymmetricKeyGUID IS NOT NULL)
BEGIN
INSERT INTO dbo.CCI
VALUES (07, ENCRYPTBYKEY(@SymmetricKeyGUID,
N'9876-1234-8765-4321'))
INSERT INTO dbo.CCI
VALUES (08, ENCRYPTBYKEY(@SymmetricKeyGUID,
N'9876-8765-8765-1234'))
INSERT INTO dbo.CCI
VALUES (09, ENCRYPTBYKEY(@SymmetricKeyGUID,
N'9876-1234-1111-2222'))
END
TRUNCATE TABLE dbo.CCI


USE EDB37
go
select * from dbo.CCI


USE EDB37
go
SELECT PersonID,
CONVERT ([nvarchar](32), DECRYPTBYKEY (CreditCardNumber) )
as Creditcardlumber
FROM dbo.CCI

use master
go
create master key encryption by
password = '$tr0ngPa$$w0rd1'
go

create certificate EncryptedDBCert
with subject = 'Certificate to encrypt EncryptedDB';
go

--шифрование

use [master]
go
create database encryption key
with algorithm = AES_256
encryption by server certificate [EncryptedDBCert]

--status of all databases at server

use master
go
select db.[name]
, db.[is_encrypted]
, dm.[encryption_state]
, dm.[percent_complete]
, dm.[key_algorithm]
, dm.[key_length]
, db.[is_encrypted]
from [sys].[databases] db
left outer join [sys].[dm_database_encryption_keys] dm 
on db.[database_id] = dm.[database_id]
go