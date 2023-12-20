 --spGETPU '003-Accessory Aviation,500-Admn & Mkting,Total 1080-Sales'
 --open','AMEETEK MRO
 CREATE Procedure [dbo].[spGETPU]
--@level1 varchar(30)
@status varchar(20)
AS
BEGIN 
	DECLARE @var_status varchar(30)
	SET @var_status = REPLACE(@status, ',', ''',''')
	print @var_status
END