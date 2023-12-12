/*************************************************************           
 ** File:   [USP_GetInternalWorkorderDeatils]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create USP_GetInternalWorkorderDeatils   
 ** Purpose:         
 ** Date:   05/24/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/24/2023   Subhash Saliya		Created
	2    06/07/2023   MOIN BLOCH            REMOVED TRANSACTION AND MAKES CAPITAL RESERVED KEY WORDS  
     
-- EXEC [USP_GetInternalWorkorderDeatils] 2940
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetInternalWorkorderDeatils]
@WorkOrderPartNoId bigint 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  
				
               SELECT Im.partnumber AS PartNumber
			         ,SL.StockLineNumber AS StockLine
					 ,ISNULL(WOP.StocklineCost,0) AS OriginalCost
					 ,ISNULL(wop.TendorStocklineCost,0) AS AllocatedCost
					 ,((ISNULL(WOP.StocklineCost,0) + ISNULL(WOPC.PartsCost,0) + ISNULL(WOPC.LaborCost,0) + ISNULL(WOPC.OtherCost,0)) - ISNULL(wop.TendorStocklineCost,0)) AS RemainingCost
                     ,ISNULL(WOPC.PartsCost,0) AS MaterialCost
                     ,ISNULL(WOPC.LaborCost,0) AS LaborCost
                     ,ISNULL(WOPC.OtherCost,0) AS OtherCost
                     ,(Isnull(WOP.StocklineCost,0) + ISNULL(WOPC.PartsCost,0) + ISNULL(WOPC.LaborCost,0) + ISNULL(WOPC.OtherCost,0)) AS TotalCost
               FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
                LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOPC WITH(NOLOCK) ON WOP.ID = WOPC.WOPartNoId
               INNER JOIN [dbo].[ItemMaster]  IM WITH(NOLOCK) ON WOP.ItemMasterId=IM.ItemMasterId
               INNER JOIN [dbo].[Stockline]  SL WITH(NOLOCK) ON WOP.StockLineId=SL.StockLineId               
               WHERE WOP.ID = @WorkOrderPartNoId;
                
		--	END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_WorkOrderTurnArroundTime' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNoId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END