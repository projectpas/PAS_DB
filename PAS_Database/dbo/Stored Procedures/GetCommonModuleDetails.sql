/*************************************************************           
 ** File:   [GetCommonModuleDetails]           
 ** Author:   Moin Bloch
 ** Description: Get Billing Invoicing Details
 ** Purpose:         
 ** Date:   26/05/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    26/05/2025   Moin Bloch    Created
    2    27/05/2025   Rajesh Gami   Added SO and Exchange
  EXEC [dbo].[GetCommonModuleDetails] 8781,15
**************************************************************/ 
Create   PROCEDURE [dbo].[GetCommonModuleDetails]
@ReferenceId BIGINT=NULL,
@ModuleId INT=NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
		
		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		DECLARE @AllowInvoiceBeforeShipping BIT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN			
			SELECT [WorkOrderId] ReferenceId,
				   [WorkOrderNum] ReferenceNum	
			  FROM [dbo].[WorkOrder] WITH(NOLOCK)
			 WHERE [WorkOrderId] = @ReferenceId
		 
		END /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
			SELECT [SalesOrderId] ReferenceId,
				   [SalesOrderNumber] ReferenceNum	
			  FROM [dbo].[SalesOrder] WITH(NOLOCK)
			 WHERE [SalesOrderId] = @ReferenceId
					
		END /*********END: SALES ORDER ********/
		ELSE IF(@ModuleId = @EXModuleId) /*********START: EXCHANGE ********/
		BEGIN
			SELECT [ExchangeSalesOrderId] ReferenceId,
				   [ExchangeSalesOrderNumber] ReferenceNum	
			  FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			 WHERE [ExchangeSalesOrderId] = @ReferenceId
					
		END /*********END: EXCHANGE ********/
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCommonModuleDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END