/*************************************************************           
 ** File:   [USP_CycleCountReviewDetail_GetDetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to get Cycle Count Review Details 
 ** Purpose:         
 ** Date:   06/11/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** -----------------------------------------------------------          
    1    06/11/2024   Moin Bloch		Created
	2    07/11/2024   Moin Bloch		Added IsActive,IsDeleted
	3    27/12/2024   Moin Bloch		Added LegalEntityId,[LedgerId] Field	
	4    14/05/2025   Amit Ghediya      Added Adjustment Reason.
	     
    EXEC USP_CycleCountReviewDetail_GetDetailsById 23,1
************************************************************************/    
CREATE   PROCEDURE [dbo].[USP_CycleCountReviewDetail_GetDetailsById]  
@CycleCountId [bigint] NULL,
@MasterCompanyId [int] NULL 
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  	
 BEGIN TRY 
        DECLARE @ModuleID INT = 2;
		DECLARE @ApprovalStatusId INT = 2;
		DECLARE @IsEnforce BIT = 0
        SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'STOCKLINE'
		SELECT @ApprovalStatusId = [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'APPROVED'
		SELECT @IsEnforce = ISNULL([IsEnforce],0) FROM [dbo].[CycleCount] WITH(NOLOCK) WHERE [CycleCountId] = @CycleCountId;
		IF(@IsEnforce = 1)
		BEGIN
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
				  ,CC.[LegalEntityId]
				  ,(SELECT TOP 1 [ledgerId] FROM [dbo].[AccountingCalendar] AC WITH(NOLOCK) WHERE AC.[LegalEntityId] = CC.[LegalEntityId] ORDER BY [AccountingCalendarId] DESC) AS [LedgerId]
			      ,CC.[MasterCompanyId]
			      ,CC.[CreatedBy]
			      ,CC.[UpdatedBy]
			      ,CC.[CreatedDate]
			      ,CC.[UpdatedDate]
			      ,CC.[IsActive]
			      ,CC.[IsDeleted]
			      ,MS.[LastMSLevel]
			      ,MS.[AllMSlevels]
				  ,CO.[StatusId]
				  ,sar.[Description] 'AdjustmentReasonName'
			FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)	
				INNER JOIN [dbo].[CycleCount] CO WITH(NOLOCK) ON CO.[CycleCountId] = CC.[CycleCountId]
				INNER JOIN [dbo].[CycleCountApproval] CA WITH(NOLOCK) ON CA.[CycleCountDetailId] = CC.[CycleCountDetailId] AND CA.[StatusId] = @ApprovalStatusId
				LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ModuleID] = @ModuleID AND MS.[ReferenceID] = CC.StockLineId 
				LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON CC.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	
			WHERE CC.[MasterCompanyId] = @MasterCompanyId 
				AND CC.[CycleCountId] = @CycleCountId	
				AND CC.[IsActive] = 1 AND CC.IsDeleted = 0;				
		END
		ELSE
		BEGIN
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
			  ,CC.[LegalEntityId]
			  ,(SELECT TOP 1 [ledgerId] FROM [dbo].[AccountingCalendar] AC WITH(NOLOCK) WHERE AC.[LegalEntityId] = CC.[LegalEntityId] ORDER BY [AccountingCalendarId] DESC) AS [LedgerId]
			  ,CC.[MasterCompanyId]
			  ,CC.[CreatedBy]
			  ,CC.[UpdatedBy]
			  ,CC.[CreatedDate]
			  ,CC.[UpdatedDate]
			  ,CC.[IsActive]
			  ,CC.[IsDeleted]
			  ,MS.[LastMSLevel]
			  ,MS.[AllMSlevels]
			  ,CA.[StatusId]
			  ,sar.[Description] 'AdjustmentReasonName'
		 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)	
		 INNER JOIN [dbo].[CycleCount] CA WITH(NOLOCK) ON CA.[CycleCountId] = CC.[CycleCountId]
		 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ModuleID] = @ModuleID AND MS.[ReferenceID] = CC.StockLineId 
		 LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON CC.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	
		  WHERE CC.[MasterCompanyId] = @MasterCompanyId 
		    AND CC.[CycleCountId] = @CycleCountId	
			AND CC.[IsActive] = 1 AND CC.IsDeleted = 0;		
		END
 END TRY        
 BEGIN CATCH  
  IF @@trancount > 0    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountReviewDetail_GetDetailsById'     
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