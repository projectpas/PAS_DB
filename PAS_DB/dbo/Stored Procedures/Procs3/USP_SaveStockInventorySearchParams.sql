/*************************************************************   
** Author:  <BHARGAV SALIYA>  
** Create date: <20/11/2024>  [mm/dd/yyyy]
** Description: <INSERT/UPDATE  DATA IN THE PARAMS TABLE>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		BHARGAV SALIYA			Created
** 2	26/11/2024		BHARGAV SALIYA			Change The Filter Field Stockline Number To Control Number
**************************************************************/
-----------------------------------------------------------------------------
CREATE     PROCEDURE [dbo].[USP_SaveStockInventorySearchParams]
	@tblType_StockInvenorySearchParamsType [StockInvenorySearchParamsType] READONLY,
	@UserRoleId BIGINT = NULL,
	@CurrentUserEmployeeId BIGINT = NULL,
	@UserName VARCHAR(256) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN

				DECLARE @SaveStockInventorySearchParams BIGINT = 0;
				DECLARE @UserlName VARCHAR(500) = NULL;
				DECLARE @MasterCompanyId INT = 0;

				INSERT INTO [dbo].[StockInventorySearchParams] 
						(UrlName, FromReceivedDate, ToReceivedDate, FromControlNumber, ToControlNumber, FromUnitCost, ToUnitCost, ItemMasterId, VendorId,ConditionId,LotId,TraceableTo,SiteId,WarehouseId,LocationId,ShelfId,BinId,PoRoRefrences,
						Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted) 

				SELECT	UrlName, FromReceivedDate, ToReceivedDate, FromControlNumber, ToControlNumber, FromUnitCost, ToUnitCost, ItemMasterId, VendorId,ConditionId,LotId,TraceableTo,SiteId,WarehouseId,LocationId,ShelfId,BinId,PoRoRefrences,
						Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM @tblType_StockInvenorySearchParamsType WHERE ISNULL(StockInventorySearchParamsId, 0) = 0;

				SET @SaveStockInventorySearchParams = SCOPE_IDENTITY();

				IF(ISNULL(@SaveStockInventorySearchParams, 0) > 0)
				BEGIN
					SELECT @MasterCompanyId = [MasterCompanyId], @UserlName = [CreatedBy] FROM [dbo].[StockInventorySearchParams] WITH(NOLOCK) WHERE [StockInventorySearchParamsId] = @SaveStockInventorySearchParams;

					EXEC [USP_StockInventoryEmployeeMappingData] @SaveStockInventorySearchParams, @CurrentUserEmployeeId, @MasterCompanyId, @UserlName;
				END
				ELSE
				BEGIN
					UPDATE GLS
					SET 
						GLS.FromReceivedDate = t.FromReceivedDate,
						GLS.ToReceivedDate = t.ToReceivedDate,
						GLS.FromControlNumber = t.FromControlNumber,
						GLS.ToControlNumber = t.ToControlNumber,
						GLS.FromUnitCost = t.FromUnitCost,
						GLS.ToUnitCost = t.ToUnitCost,
						GLS.ItemMasterId = t.ItemMasterId,
						GLS.VendorId = t.VendorId,
						GLS.ConditionId = t.ConditionId,
						GLS.LotId = t.LotId,
						GLS.TraceableTo = t.TraceableTo,
						GLS.SiteId = t.SiteId,
						GLS.WarehouseId = t.WarehouseId,
						GLS.LocationId = t.LocationId,
						GLS.ShelfId = t.ShelfId,
						GLS.BinId = t.BinId,
						GLS.PoRoRefrences = t.PoRoRefrences,
						GLS.Level1 = t.Level1,
						GLS.Level2 = t.Level2,
						GLS.Level3 = t.Level3,
						GLS.Level4 = t.Level4,
						GLS.Level5 = t.Level5,
						GLS.Level6 = t.Level6,
						GLS.Level7 = t.Level7,
						GLS.Level8 = t.Level8,
						GLS.Level9 = t.Level9,
						GLS.Level10 = t.Level10,
						GLS.UpdatedBy = t.CreatedBy,
						
						GLS.UpdatedDate = GETUTCDATE()
					FROM [dbo].[StockInventorySearchParams] GLS WITH(NOLOCK)
					INNER JOIN @tblType_StockInvenorySearchParamsType t ON GLS.StockInventorySearchParamsId = t.StockInventorySearchParamsId
					WHERE ISNULL(t.StockInventorySearchParamsId, 0) <> 0;
				END

			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveStockInventorySearchParams' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END