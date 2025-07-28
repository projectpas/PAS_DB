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
     
-- EXEC [InsertEmailApproval] 
************************************************************************/

CREATE   PROCEDURE [dbo].[InsertEmailApproval]
	@EmailApproval EmailApprovalType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		INSERT INTO [DBO].[EmailApproval] ([PartNumber],[PartDescription],[Qty],[TotalSales],[RefrenceId],[SubRefrenceId],[ModuleId],[CustomerApprovedById],[CustomerId],[InternalStatusId],
										   [IsActive],[IsDeleted],[MasterCompanyId],[UpdatedBy],[ApprovalActionId],[Email],[ContactId])
									SELECT [PartNumber],[PartDescription],[Qty],[TotalSales],[RefrenceId],[SubRefrenceId],[ModuleId],[CustomerApprovedById],[CustomerId],[InternalStatusId],
										   [IsActive],[IsDeleted],[MasterCompanyId],[UpdatedBy],[ApprovalActionId],[Email],[ContactId] 
		FROM @EmailApproval;

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