/********************************************************************
 ** File:   [USP_DeleteRestoreCustomerCCPaymentById]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to Active or InActive [CustomerCCPayments] record
 ** Purpose: Active or InActive [CustomerCCPayments] record
 ** Date:   09/04/2023  
          
 ** PARAMETERS:  
     
 ***********************************************************************    
 ** Change History           
 *********************************************************************** 
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				------------------------------------
    1    09/04/2023   Devendra Shekh			    Created
    1    09/05/2023   Devendra Shekh			    added InActive

	exec USP_CustomerCardPayment_StatusUpdate @CustomerCCPaymentsId=4,@isActive=0,@userName=N'ADMIN User'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CustomerCardPayment_StatusUpdate] 
	@CustomerCCPaymentsId BIGINT,
	@IsActive bit = NULL,
	@userName varchar(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN

		IF(@IsActive = 1)
			BEGIN 
				UPDATE [CustomerCCPayments]
				SET IsActive = 1, UpdatedBy = @userName, UpdatedDate = GETUTCDATE(), InActive = 0
				WHERE CustomerCCPaymentsId = @CustomerCCPaymentsId
			END
		ELSE
			BEGIN 
				UPDATE [CustomerCCPayments]
				SET IsActive = 0, UpdatedBy = @userName, UpdatedDate = GETUTCDATE(), InActive = 1
				WHERE CustomerCCPaymentsId = @CustomerCCPaymentsId
			END
		 
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_CustomerCardPayment_StatusUpdate',
            @ProcedureParameters varchar(3000) = '@CustomerCCPaymentsId = ''' + CAST(ISNULL(@CustomerCCPaymentsId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END