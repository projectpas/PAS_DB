
CREATE   VIEW [dbo].[View_CreditMemoList]
AS
	SELECT Id, Name, MasterCompanyId, Description,IsActive,IsDeleted
	FROM     dbo.CreditMemoStatus WHERE IsActive = 1 AND Name != 'Refund Request Sent';