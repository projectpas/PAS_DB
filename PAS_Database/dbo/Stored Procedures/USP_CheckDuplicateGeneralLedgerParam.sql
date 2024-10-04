/*************************************************************             
	** File:   [USP_CheckDuplicateGeneralLedgerParam]             
	** Author:   Devendra Shekh
	** Description: This stored procedure is USED TO Check Duplicate General Ledger Search Params
	** Date:   
         
 **************************************************************             
	** Change History             
 **************************************************************             
	** PR   Date			Author					Change Description  
	** --   --------		-------					--------------------------------
	** 1	03/10/2024		Devendra Shekh			Created

	EXEC [dbo].[USP_CheckDuplicateGeneralLedgerParam] 4,55,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckDuplicateGeneralLedgerParam]
@GeneralLedgerSearchParamsId BIGINT = NULL,
@EmployeeId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@GeneralLedgerEmployeeMappingId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		
		DECLARE @MappingId BIGINT = 0;
		SELECT @MappingId = GeneralLedgerEmployeeMappingId FROM [GeneralLedgerEmployeeMapping] WITH(NOLOCK) WHERE [GeneralLedgerSearchParamsId] = @GeneralLedgerSearchParamsId AND [EmployeeId] = @EmployeeId AND [MasterCompanyId] = @MasterCompanyId;
			
		SET @GeneralLedgerEmployeeMappingId = ISNULL(@MappingId, 0);	
		
    END
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CheckDuplicateGeneralLedgerParam' 
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