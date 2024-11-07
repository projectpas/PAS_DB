/*************************************************************           
 ** File:   [USP_CycleCountDetail_GetDetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to get Cycle Count Details 
 ** Purpose:         
 ** Date:   23/10/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    23/10/2024   Moin Bloch    Created
	     
    EXEC USP_CycleCountDetail_GetDetailsById 7,1
************************************************************************/    
CREATE   PROCEDURE [dbo].[USP_CycleCountDetail_GetDetailsById]  
@CycleCountId [bigint] NULL,
@MasterCompanyId [int] NULL 
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  	
 BEGIN TRY 
        DECLARE @ModuleID INT = 2;
        SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'Stockline'
		
		SELECT CC.[CycleCountDetailId]
			  ,CC.[CycleCountId]
			  ,CC.[StockLineId]
			  ,CC.[StockLineNumber]
			  ,CC.[ControlNumber]
			  ,CC.[IdNumber]
			  ,CC.[SerialNumber]
			  ,CC.[ItemMasterId]
			  ,CC.[PartNumber]
			  ,CC.[PartDescription]
			  ,CC.[ManufacturerId]
			  ,CC.[ManufacturerName]
			  ,CC.[ConditionId]
			  ,CC.[ConditionName]
			  ,CC.[UnitOfMeasureId]
			  ,CC.[UnitOfMeasureName]
			  ,CC.[UnitCost]
			  ,CC.[CurrencyId]
			  ,CC.[CurrencyName]
			  ,CC.[SiteId]
			  ,CC.[Site]
			  ,CC.[WarehouseId]
			  ,CC.[Warehouse]
			  ,CC.[LocationId]
			  ,CC.[Location]
			  ,CC.[ShelfId]
			  ,CC.[Shelf]
			  ,CC.[BinId]
			  ,CC.[Bin]
			  ,CC.[CurrentStockQuantity]
			  ,CC.[CountedQuantity]
			  ,CC.[DifferenceQuantity]
			  ,CC.[DifferenceAmount]
			  ,CC.[IsCustomerStock]
			  ,CC.[ManagementStructureId]
			  ,CC.[MasterCompanyId]
			  ,CC.[CreatedBy]
			  ,CC.[UpdatedBy]
			  ,CC.[CreatedDate]
			  ,CC.[UpdatedDate]
			  ,CC.[IsActive]
			  ,CC.[IsDeleted]
			  ,MS.[LastMSLevel]
			  ,MS.[AllMSlevels]
		 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)	
		 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ModuleID] = @ModuleID AND MS.[ReferenceID] = CC.StockLineId 
		  WHERE CC.[MasterCompanyId] = @MasterCompanyId 
		    AND CC.[CycleCountId] = @CycleCountId
 END TRY        
 BEGIN CATCH  
  IF @@trancount > 0    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_GetDetailsById'     
			, @ProcedureParameters VARCHAR(3000) = '@CycleCountId = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH    
END