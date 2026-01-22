/*************************************************************   
** Author:  <SHREY CHANDEGARA>  
** Create date: <12/01/2025>  [mm/dd/yyyy]
** Description:  <Save Cash Receipt Search Params For Employee Mapping Data>
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	12/01/2025		SHREY CHANDEGARA			Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CashReceiptEmployeeMappingData]
	@SaveCashReceiptSearchParamsId BIGINT = NULL,
	@EmployeeId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@UserName VARCHAR(256) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN
				INSERT INTO [dbo].[CashReceiptEmployeeMapping] ([CashReceiptSearchParamsId], [EmployeeId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]) 
				VALUES (@SaveCashReceiptSearchParamsId, @EmployeeId, @MasterCompanyId, @UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0);
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CashReceiptEmployeeMappingData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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