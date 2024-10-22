/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <14/10/2024>  [mm/dd/yyyy]
** Description: <Remove Ledger Search Params For Employee Mapping Data>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	14/10/2024		Devendra Shekh			Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_RemoveGeneralLedgerSearchParams_ById]
	@GeneralLedgerEmployeeMappingId BIGINT = NULL,
	@GeneralLedgerSearchParamsId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN
				DECLARE @EmployeeCount INT = 0;

				DELETE FROM [dbo].[GeneralLedgerEmployeeMapping] WHERE [GeneralLedgerEmployeeMappingId] = @GeneralLedgerEmployeeMappingId

				SELECT @EmployeeCount = COUNT(GeneralLedgerEmployeeMappingId) FROM [dbo].[GeneralLedgerEmployeeMapping] WITH(NOLOCK) WHERE [GeneralLedgerSearchParamsId] = @GeneralLedgerSearchParamsId;

				IF(ISNULL(@EmployeeCount, 0) = 0)
				BEGIN
					DELETE FROM [dbo].[GeneralLedgerSearchParams] WHERE [GeneralLedgerSearchParamsId] = @GeneralLedgerSearchParamsId;
				END
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_RemoveGeneralLedgerSearchParams_ById' 
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