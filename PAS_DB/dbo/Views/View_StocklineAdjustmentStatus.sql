

CREATE    VIEW [dbo].[View_StocklineAdjustmentStatus]
AS
	SELECT Id, Name, MasterCompanyId, Description,IsActive,IsDeleted
	FROM     dbo.StocklineAdjustmentStatus WHERE IsActive = 1 AND Name != 'Posted';