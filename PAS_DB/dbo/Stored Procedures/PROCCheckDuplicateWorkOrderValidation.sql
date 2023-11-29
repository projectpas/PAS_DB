/*************************************************************           
 ** File:   [PROCCheckDuplicateWorkOrderValidation]           
 ** Author:  MOIN BLOCH
 ** Description: This stored procedure is used ckeck Duplicate WorkOrder Validation
 ** Purpose:         
 ** Date:   23/05/2023  
          
 ** PARAMETERS: @CustomerId BIGINT,@ItemMasterId BIGINT,@SerialNumber VARCHAR(50),@MasterCompanyId INT
     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    23/05/2023   MOIN BLOCH     Created
     
-- EXEC PROCCheckDuplicateWorkOrderValidation 1122,3,'1STYOMPMO7-JD',1

************************************************************************/
CREATE   PROCEDURE [dbo].[PROCCheckDuplicateWorkOrderValidation]
@CustomerId BIGINT,
@ItemMasterId BIGINT,
@SerialNumber VARCHAR(50),
@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	
		SELECT WO.[WorkOrderNum],
			   IM.[partnumber],
			   SL.[SerialNumber] 
			 FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
	   INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WO.WorkOrderId = WP.WorkOrderId
	   INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON WP.StockLineId = SL.StockLineId
	   INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId
		    WHERE WO.[MasterCompanyId] = @MasterCompanyId
			  AND WO.[CustomerId] = @CustomerId 
			  AND WP.[ItemMasterId] = @ItemMasterId 
			  AND SL.[SerialNumber] = @SerialNumber
			  AND WP.[IsFinishGood] = 0
			  AND WP.[IsClosed] = 0;
		  
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCCheckDuplicateWorkOrderValidation' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CustomerId, '') AS varchar(100))
			                                        + '@Parameter2 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@SerialNumber, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END