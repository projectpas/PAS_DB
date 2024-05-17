CREATE   VIEW [dbo].[vw_GLAccountWithName]
AS
		SELECT [GLAccountId],
	   (ISNULL([AccountCode],'') +'-'+ ISNULL([AccountName],'')) 'AccountName' ,
	           [IsActive],
               [IsDeleted],
               [MasterCompanyId]
		FROM dbo.[GLAccount]  WITH (NOLOCK)