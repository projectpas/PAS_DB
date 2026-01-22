/*************************************************************           
 ** File:		 [USP_updateWorkOrderShipDate]         
 ** Author:		 BHARGAV SALIYA
 ** Description: This Stored Procedure Is Used To Update mpn table fied.
 ** Purpose:         
 ** Date:   11-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    08-SEP-2025		BHARGAV SALIYA    	Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_updateWorkOrderShipDate]
	 @WorkOrderShippingId BIGINT,
	 @WorkOrderId BIGINT,
	 @MasterCompanyId BIGINT,
	 @UpdatedBy VARCHAR(50) = NULL

AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY
		
		DECLARE @ShipDate DATETIME2 = NULL;
		SELECT @ShipDate = MAX([ShipDate]) 
		FROM WorkOrderShipping WHERE WorkOrderId = @WorkOrderId AND UpdatedBy = @UpdatedBy AND MasterCompanyId = @MasterCompanyId

		UPDATE mpn
		SET [ShipDate] = @ShipDate 
		FROM [dbo].[WorkOrderPartNumber] mpn WITH(NOLOCK)
		INNER JOIN [dbo].WorkOrderShippingItem wsi WITH(NOLOCK) on mpn.ID = wsi.WorkOrderPartNumId
		WHERE wsi.WorkOrderShippingId = @WorkOrderShippingId AND wsi.MasterCompanyId = @MasterCompanyId
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_updateWorkOrderShipDate'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',  
                @Parameter2 = ' + ISNULL(@MasterCompanyId,'') + ',   
                @Parameter3 = ' + ISNULL(@UpdatedBy,'') + ''   
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
  END CATCH  
END