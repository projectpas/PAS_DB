/*************************************************************           
 ** File:   [USP_CycleCountDetail_GetDetailsById_Repot]           
 ** Author: BHARGAV SALIYA 
 ** Description: This stored procedure is used to get Cycle Count Details for the reports
 ** Purpose:         
 ** Date:   21/11/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR     Date            Author		    Change Description            
    1    23/11/2024   BHARGAV SALIYA       Created
    2    25/12/2024   BHARGAV SALIYA       Truncate the PartNumber
    3    09/July/2026   RAJESH GAMI       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
    4    12/10/2026   SAHDEV SALIYA       [PN-18223] - Cycle Count print: show the full name of the last available Site / Warehouse / Location / Shelf
    5    20/10/2026   SAHDEV SALIYA       [PN-18227] - Cycle Count print: show full text for all fields (no truncation)
 ** -----------------------------------------------------------          
	exec [USP_CycleCountDetail_GetDetailsById_Report] 15,1
************************************************************************/    
CREATE PROCEDURE [dbo].[USP_CycleCountDetail_GetDetailsById_Report]  
@CycleCountId [bigint] NULL,
@MasterCompanyId [int] NULL 
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  	
 BEGIN TRY 
		
		SELECT CC.[CycleCountDetailId]
			  ,CC.[CycleCountId]
			  ,CC.[StockLineId]
			  ,CC.[StockLineNumber]
			  ,CC.[ControlNumber]
			  ,CC.[IdNumber]
			  ,UPPER(CC.[SerialNumber]) AS SerialNumber 
			  ,UPPER(CC.[PartNumber]) AS PartNumber
			  ,UPPER(CC.PartDescription) AS PartDescription 
			  ,UPPER(CC.[ManufacturerName]) AS ManufacturerName
			  ,CC.[ConditionName]
			  ,CC.[UnitOfMeasureName]
			  ,CC.[UnitCost]
			  ,CC.[CurrencyName]
			  ,UPPER(CC.[Site]) AS [Site]
			  ,UPPER(CC.[Warehouse]) AS [Warehouse]
			  ,UPPER(CC.[Location]) AS [Location]
			  ,UPPER(CC.[Shelf]) AS [Shelf]
			  ,UPPER(CC.[Bin]) AS [Bin] 
			  ,CC.[CurrentStockQuantity]
			  ,CC.[CountedQuantity]
			  ,CC.[DifferenceQuantity]
			  ,CC.[DifferenceAmount]
			  ,ISNULL(SL.[QuantityAvailable],0) [QuantityAvailable]
			  ,ISNULL(SL.[QuantityOnHand],0) [QuantityOnHand]
			  ,ISNULL(SL.[QuantityReserved],0)  [QuantityReserved]
			  ,ISNULL(SL.[QuantityIssued],0) [QuantityIssued]
		 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)	
		 INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = CC.[StockLineId]
		  WHERE CC.[MasterCompanyId] = @MasterCompanyId 
		    AND CC.[CycleCountId] = @CycleCountId AND ISNULL(SL.IsNonStock,0) = 0
 END TRY        
 BEGIN CATCH  
  IF @@trancount > 0    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_GetDetailsById_Report'     
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