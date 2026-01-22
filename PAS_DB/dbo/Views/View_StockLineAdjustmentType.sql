

CREATE    VIEW [dbo].[View_StockLineAdjustmentType]
AS
	SELECT StockLineAdjustmentTypeId, Name, MasterCompanyId, Description,IsActive,IsDeleted,ToolTip
	FROM     dbo.StockLineAdjustmentType WHERE IsActive = 1;