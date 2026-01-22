CREATE    VIEW [dbo].[View_StocklineAdjustmentListStatus]
AS
	SELECT Id, Name, MasterCompanyId, Description,IsActive,IsDeleted
	FROM     dbo.StocklineAdjustmentStatus WHERE IsActive = 1;