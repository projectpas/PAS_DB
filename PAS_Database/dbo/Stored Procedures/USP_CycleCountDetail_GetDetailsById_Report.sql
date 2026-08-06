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
			  ,CASE WHEN LEN(UPPER(CC.[SerialNumber])) > 15 then LEFT(UPPER(CC.[SerialNumber]), 15) + '...' else  UPPER(CC.[SerialNumber]) end as SerialNumber 
			  ,CASE WHEN LEN(UPPER(CC.[PartNumber])) > 13 then LEFT(UPPER(CC.[PartNumber]), 13) + '...' else  UPPER(CC.[PartNumber]) end as PartNumber
			  ,CASE WHEN LEN(UPPER(CC.PartDescription)) > 23 then LEFT(UPPER(CC.PartDescription), 23) + '...' else  UPPER(CC.PartDescription) end as PartDescription 
			  ,CASE WHEN LEN(UPPER(CC.[ManufacturerName])) > 19 then LEFT(UPPER(CC.[ManufacturerName]), 19) + '...' else  UPPER(CC.[ManufacturerName]) end as ManufacturerName
			  ,CC.[ConditionName]
			  ,CC.[UnitOfMeasureName]
			  ,CC.[UnitCost]
			  ,CC.[CurrencyName]
			  ,CASE WHEN LEN(UPPER(CC.[Site])) > 18 then LEFT(UPPER(CC.[Site]), 18) + '...' else  UPPER(CC.[Site]) end as [Site] 
			  ,CASE WHEN LEN(UPPER(CC.[Warehouse])) > 9 then LEFT(UPPER(CC.[Warehouse]), 9) + '...' else  UPPER(CC.[Warehouse]) end as [Warehouse] 
			  ,CASE WHEN LEN(UPPER(CC.[Location])) > 8 then LEFT(UPPER(CC.[Location]), 8) + '...' else  UPPER(CC.[Location]) end as [Location] 
			  ,CASE WHEN LEN(UPPER(CC.[Shelf])) > 8 then LEFT(UPPER(CC.[Shelf]), 8) + '...' else  UPPER(CC.[Shelf]) end as [Shelf] 
			  ,CASE WHEN LEN(UPPER(CC.[Bin])) > 7 then LEFT(UPPER(CC.[Bin]), 7) + '...' else  UPPER(CC.[Bin]) end as [Bin] 
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