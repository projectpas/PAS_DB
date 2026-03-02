/*************************************************************           
 ** File: [InsertEmailApproval]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to insert EmailApproval
 ** Purpose:         
 ** Date:   16/07/2025    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/07/2025   Amit Ghediya     Created
	2    26/02/2026   Amit Ghediya     Update fro WOQ Approval code (PN-15575)
     
-- EXEC [InsertEmailApproval] 
************************************************************************/

CREATE   PROCEDURE [dbo].[InsertEmailApproval]
	@EmailApproval EmailApprovalType READONLY,
	@ApprovalCode VARCHAR(200) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @RefrenceId BIGINT = 0,
				@SubRefrenceId BIGINT = 0,
				@ModuleId BIGINT = 0,
				@SOQModuleId BIGINT = 0,
				@SOModuleId BIGINT = 0,
				@WOQModuleId BIGINT = 0;

		SELECT @SOQModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
		SELECT @SOModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @WOQModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WOQuote';

		INSERT INTO [DBO].[EmailApproval] ([PartNumber],[PartDescription],[Qty],[TotalSales],[RefrenceId],[SubRefrenceId],[ModuleId],[CustomerApprovedById],[CustomerId],[InternalStatusId],
										   [IsActive],[IsDeleted],[MasterCompanyId],[UpdatedBy],[ApprovalActionId],[Email],[ContactId])
									SELECT [PartNumber],[PartDescription],[Qty],[TotalSales],[RefrenceId],[SubRefrenceId],[ModuleId],[CustomerApprovedById],[CustomerId],[InternalStatusId],
										   [IsActive],[IsDeleted],[MasterCompanyId],[UpdatedBy],[ApprovalActionId],[Email],[ContactId] 
		FROM @EmailApproval;

		SELECT TOP 1 @RefrenceId = [RefrenceId], @SubRefrenceId = [SubRefrenceId], @ModuleId = [ModuleId] FROM @EmailApproval;

		--Add ApprovalCode for Email Authentication
		IF(@RefrenceId > 0)
		BEGIN
			IF(@SOQModuleId = @ModuleId)
			BEGIN
				 UPDATE [DBO].[SalesorderQuote] SET [ApprovalCode] = @ApprovalCode WHERE [SalesOrderQuoteId]  = @RefrenceId;
			END

			IF(@SOModuleId = @ModuleId)
			BEGIN
				 UPDATE [DBO].[Salesorder] SET [ApprovalCode] = @ApprovalCode WHERE [SalesOrderId]  = @RefrenceId;
			END		
			
			IF(@WOQModuleId = @ModuleId)
			BEGIN
				 UPDATE [DBO].[WorkOrderQuote] SET [ApprovalCode] = @ApprovalCode WHERE [WorkOrderQuoteId]  = @RefrenceId;
			END
		END
	END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'InsertEmailApproval' 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = ''
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END