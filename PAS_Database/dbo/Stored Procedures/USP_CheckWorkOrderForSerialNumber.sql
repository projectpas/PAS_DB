/*************************************************************           
 ** File:   [USP_CheckWorkOrderForSerialNumber]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used CheckWorkOrderForSerialNumber
 ** Purpose:         
 ** Date:   13/12/2023  
          
 ** PARAMETERS: @ItemMasterId BIGINT,@SerialNumber VARCHAR(50),@MasterCompanyId INT
     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    13/12/2023   AMIT GHEDIYA     Created
     
-- EXEC USP_CheckWorkOrderForSerialNumber 41216,'AMIT6767',1

************************************************************************/
CREATE     PROCEDURE [dbo].[USP_CheckWorkOrderForSerialNumber]
	@ItemMasterId BIGINT,
	@SerialNumber VARCHAR(50),
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	
		SELECT WO.[WorkOrderNum],
			   WO.[WorkOrderId]
		FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
		LEFT JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WO.WorkOrderId = WP.WorkOrderId
		LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON WP.StockLineId = SL.StockLineId
		LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId
		WHERE 
			  WP.[ItemMasterId] = @ItemMasterId
			  AND SL.[SerialNumber] = @SerialNumber
			  AND WO.[MasterCompanyId] = @MasterCompanyId
			  AND YEAR(WO.[CreatedDate]) = YEAR(DATEADD(YEAR, 0, SYSDATETIME())) 
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckWorkOrderForSerialNumber' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter2 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)) 
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