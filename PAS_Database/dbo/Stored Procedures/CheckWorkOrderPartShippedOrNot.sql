/*************************************************************           
 ** File:   [CheckWorkOrderPartShippedOrNot]           
 ** Author:   
 ** Description: This SP is Used to Check Part Shipping Done or not
 ** Purpose:         
 ** Date:               
 ** PARAMETERS:                    
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------  	
	1    29/12/2023   Moin Bloch		Created

EXEC DBO.CheckWorkOrderPartShippedOrNot 3801,3281
**************************************************************/ 
CREATE   PROCEDURE [dbo].[CheckWorkOrderPartShippedOrNot]
@WorkOrderId BIGINT,
@WorkOrderPartId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY		
		   SELECT WOS.[WorkOrderShippingId],
		          WOS.[AirwayBill]		          
			 FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
	         JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WO.[WorkOrderId] = WOP.[WorkOrderId]
	         JOIN [dbo].[WorkOrderShipping] WOS WITH (NOLOCK) ON WO.[WorkOrderId] = WOS.[WorkOrderId]
	         JOIN [dbo].[WorkOrderShippingItem] WOSI WITH (NOLOCK) ON WOS.[WorkOrderShippingId] = WOSI.[WorkOrderShippingId]
			 WHERE WOS.[WorkOrderId] = @WorkOrderId AND WOP.[ID] = @WorkOrderPartId;	
	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckWorkOrderPartShippedOrNot' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              --RETURN(1);
		END CATCH
END