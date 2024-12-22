/*************************************************************           
 ** File:   [dbo].[USP_GetCycleCountSetting]          
 ** Author:   BHARGAV SALIA
 ** Description: Get Sales Order Quote Print Data
 ** Date:   12/20/2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		--------------------------------          
	1    12/20/2024   BHARGAV SALIA	     Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCycleCountSetting]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		SELECT 
		    [CycleCountSettingId],
		    [IsEnforceApproval],
		    ISNULL([IsOnlineCount], 0) [IsOnlineCount],
		    ISNULL([IsPrintUnitCostOnCountSheet], 0) [IsPrintUnitCostOnCountSheet],
		    ISNULL([IsPrintSystemQty], 0) [IsPrintSystemQty],
		    ISNULL([IsPartNumber], 0) [IsPartNumber],
		    ISNULL([IsPartDescription], 0) [IsPartDescription],
		    ISNULL([IsStockLineNumber], 0) [IsStockLineNumber],
		    ISNULL([IsSerialNumber], 0) [IsSerialNumber],
		    ISNULL([IsControlNumber], 0) [IsControlNumber],
		    ISNULL([IsIdNumber], 0) [IsIdNumber],
		    ISNULL([IsCondition], 0) [IsCondition],
		    ISNULL([IsSite], 0) [IsSite],
		    ISNULL([IsWarehouse], 0) [IsWarehouse],
		    ISNULL([IsLocation], 0) [IsLocation],
		    ISNULL([IsShelf], 0) [IsShelf],
		    ISNULL([IsBin], 0) [IsBin],
		    ISNULL([IsUnitOfMeasure], 0) [IsUnitOfMeasure],
		    ISNULL(CAST([IsQtyOnHand] AS INT), 0) [IsQtyOnHand],
		    ISNULL(CAST([IsQtyCounted] AS INT), 0) [IsQtyCounted],
		    ISNULL(CAST([IsDifferenceQuantity]AS INT), 0) [IsDifferenceQuantity],
		    ISNULL(CAST([IsUnitCost] AS INT), 0) [IsUnitCost],
		    [MasterCompanyId],
		    [CreatedBy],
		    [UpdatedBy],
		    [CreatedDate],
		    [UpdatedDate],
		    [IsActive],
		    [IsDeleted],
		    [Effectivedate],
		    [StatusId]
		FROM [CycleCountSettingMaster] WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId;
	END TRY
	BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCycleCountSetting' 
			  , @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    
END