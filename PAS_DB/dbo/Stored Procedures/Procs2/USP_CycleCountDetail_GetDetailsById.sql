-- ===== PROCEDURE: [dbo].[USP_CycleCountDetail_GetDetailsById]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_CycleCountDetail_GetDetailsById.sql) =====
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
 ** PR   Date         Author			Change Description            
 ** -----------------------------------------------------------          
    1    23/10/2024   Moin Bloch		Created
	2    18/11/2024   Moin Bloch		Added IsSerialized Field
	3    25/11/2024   Moin Bloch		Added QuantityReserved Field	
	4    26/12/2024   Moin Bloch		Added LegalEntityId Field	
	5    14/05/2025   Amit Ghediya      Added Adjustment Reason.
	6    09/July/2026   RAJESH GAMI      [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	     
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
			  ,CASE WHEN SL.[isSerialized] = 1 THEN 1 ELSE 0 END [IsSerialized]
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
			  ,ISNULL(SL.[QuantityReserved],0) [QuantityReserved]			  
			  ,CC.[ManagementStructureId]
			  ,CC.[LegalEntityId]
			  ,CC.[MasterCompanyId]
			  ,CC.[CreatedBy]
			  ,CC.[UpdatedBy]
			  ,CC.[CreatedDate]
			  ,CC.[UpdatedDate]
			  ,CC.[IsActive]
			  ,CC.[IsDeleted]
			  ,MS.[LastMSLevel]
			  ,MS.[AllMSlevels]
			  ,CC.[AdjustmentReasonId]
		 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)	
		 INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = CC.[StockLineId]
		 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ModuleID] = @ModuleID AND MS.[ReferenceID] = CC.StockLineId 
		  WHERE CC.[MasterCompanyId] = @MasterCompanyId 
		    AND CC.[CycleCountId] = @CycleCountId AND ISNULL(SL.IsNonStock,0) = 0
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