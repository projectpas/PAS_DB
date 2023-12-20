CREATE   VIEW [dbo].[View_VendorCreditMemoStatus]
AS
	SELECT [Id], 
		   [Name], 
		   [MasterCompanyId], 
		   [Description],
		   [IsActive],
		   [IsDeleted]
	  FROM [dbo].[CreditMemoStatus] WITH(NOLOCK)
	 WHERE [IsActive] = 1 
	   AND [Name] != 'Refund Request Sent' 
	   AND [Name] != 'Refunded'
	   AND [Name] != 'Refund Requested'