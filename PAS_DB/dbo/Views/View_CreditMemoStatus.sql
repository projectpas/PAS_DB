
CREATE   VIEW [dbo].[View_CreditMemoStatus]
AS
	SELECT Id, Name, MasterCompanyId, Description,IsActive,IsDeleted
	FROM     dbo.CreditMemoStatus WHERE IsActive = 1 AND Name != 'Refund Request Sent' AND Name != 'Approved';