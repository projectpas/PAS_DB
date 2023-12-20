/*************************************************************             
 ** File:   [USP_GetbulkstocklineadjustmentById]             
 ** Author:  AMIT GHEDIYA  
 ** Description: This stored procedure is used to Get Bulk Stockline Adjustment Details  
 ** Purpose:           
 ** Date:   08/10/2023        
            
 ** PARAMETERS: @BulkStkLineAdjId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date            Author                 Change Description              
 ** --   --------       -----------				--------------------------------            
    1    08/10/2023     AMIT GHEDIYA			Created
	2    31/10/2023     AMIT GHEDIYA			Added Isseralized for Qty check.
       
-- EXEC USP_GetbulkstocklineadjustmentById 8,2  
  
************************************************************************/  
CREATE         PROCEDURE [dbo].[USP_GetbulkstocklineadjustmentById]  
	@BulkStkLineAdjId BIGINT,
	@Opr INT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	IF(@Opr = 1)
	BEGIN
		SELECT BSA.[BulkStkLineAdjId] 
		  ,BSA.[BulkStkLineAdjNumber]  
		  ,BSA.[StatusId]  
		  ,BSA.[Status]  
		  ,BSA.[MasterCompanyId]  
		  ,BSA.[CreatedBy]  
		  ,BSA.[UpdatedBy]  
		  ,BSA.[CreatedDate]  
		  ,BSA.[UpdatedDate]  
		  ,BSA.[IsActive]  
		  ,BSA.[IsDeleted]
		  ,BSA.[StockLineAdjustmentTypeId]
	  FROM [dbo].[BulkStockLineAdjustment] BSA WITH (NOLOCK)   
	  WHERE BSA.[BulkStkLineAdjId] = @BulkStkLineAdjId; 
	END
	IF(@Opr = 2)
	BEGIN
		SELECT BSAD.[BulkStkLineAdjDetailsId]
			  ,BSAD.[StockLineId]  
			  ,BSAD.[Qty]  
			  ,BSAD.[NewQty]  
			  ,BSAD.[QtyAdjustment]
			  ,BSAD.[UnitCost]
			  ,BSAD.[NewUnitCost]
			  ,BSAD.[UnitCostAdjustment]
			  ,BSAD.[AdjustmentAmount]
			  ,BSAD.[FreightAdjustment]
			  ,BSAD.[TaxAdjustment]
			  ,BSAD.[LastMSLevel]
			  ,BSAD.[AllMSlevels]
			  ,BSAD.[StockLineAdjustmentTypeId]
			  ,BSAD.[ManagementStructureId]
			  ,BSAD.[MasterCompanyId]  
			  ,BSAD.[CreatedBy]  
			  ,BSAD.[UpdatedBy]  
			  ,BSAD.[CreatedDate]  
			  ,BSAD.[UpdatedDate]  
			  ,BSAD.[IsActive]  
			  ,BSAD.[IsDeleted] 
			  ,IM.[partnumber],
			   IM.[PartDescription],
			   IM.[ItemMasterId],
			   MF.[Name] AS 'Manufacturer',
			   STL.[SerialNumber],
			   STL.[StockLineNumber],
			   STL.[Condition],
			   STL.[ControlNumber],
			   STL.[IdNumber],
			   STL.[isSerialized],
			   BSAD.[FromManagementStructureId],
			   BSAD.[ToManagementStructureId]
		  FROM [dbo].[BulkStockLineAdjustmentDetails] BSAD WITH (NOLOCK)  
		  INNER JOIN [dbo].[Stockline] STL WITH (NOLOCK) ON  STL.StockLineId = BSAD.StockLineId
		  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON STL.[ItemMasterId] = IM.[ItemMasterId]
		  LEFT JOIN [dbo].[Manufacturer] MF WITH (NOLOCK) ON STL.ManufacturerId = MF.ManufacturerId
		  WHERE BSAD.[BulkStkLineAdjId] = @BulkStkLineAdjId AND BSAD.[IsActive] = 1;
	END
END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetbulkstocklineadjustmentById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@BulkStkLineAdjId, '') + ''  
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