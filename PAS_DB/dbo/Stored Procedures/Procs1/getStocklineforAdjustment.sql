/***************************************************************************
-- EXEC [dbo].[getStocklineforAdjustment] '',1,'0',1,11,1
****************************************************************************/
CREATE PROCEDURE [dbo].[getStocklineforAdjustment]
@StartWith VARCHAR(50)='',
@IsActive bit = true,
@Count VARCHAR(10) = '0',
--@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@ItemMasterId bigint,
@ManagementStructureId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
		--BEGIN TRANSACTION
			--BEGIN
				DECLARE @Sql NVARCHAR(MAX);	
				IF(@Count = '0') 
				   BEGIN
				   set @Count='50';	
				END	

					SELECT DISTINCT TOP 50 stl.StocklineId,stl.StockLineNumber + '-' + stl.ControlNumber as StockLineNumber,im.ItemMasterId,im.partnumber,im.PartDescription,stl.Quantity,stl.QuantityAvailable as QuantityOnHand,stl.SerialNumber,stl.ControlNumber,
					stl.SiteId,stl.WarehouseId,stl.LocationId,stl.ShelfId,stl.BinId,stl.ManagementStructureId from Stockline stl WITH(NOLOCK)
					inner join ItemMaster im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
					WHERE (stl.IsActive = 1 AND ISNULL(stl.IsDeleted, 0) = 0 AND stl.MasterCompanyId = @MasterCompanyId AND (stl.StockLineNumber LIKE '%' + @StartWith + '%') AND stl.ItemMasterId = @ItemMasterId AND stl.ManagementStructureId = @ManagementStructureId
					AND stl.QuantityOnHand > 0) AND stl.IsParent=1 and im.ItemTypeId=1 and stl.IsCustomerStock=0
					--GROUP by stl.StocklineId,stl.StockLineNumber,im.ItemMasterId,im.partnumber,im.PartDescription,stl.Quantity,stl.QuantityOnHand,stl.SerialNumber,stl.ControlNumber
					ORDER BY StockLineNumber
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
               , @AdhocComments     VARCHAR(150)    = 'getStocklineforAdjustment' 
			   , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName        = @DatabaseName
                     , @AdhocComments       = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName     =  @ApplicationName
                     , @ErrorLogID          = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END