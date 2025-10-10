/*************************************************************           
 ** File:		 [USP_checkEnforceCustomerCreditRestrictions]          
 ** Author:		 Bhargav Saliya
 ** Description: This Stored Procedure Is Used To check Enforce Customer Credit Restrictions.
 ** Purpose:         
 ** Date:   05-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    05-Oct-2025		Bhargav Saliya      Created
    2    07-Oct-2025		Bhargav Saliya      Modefied

--[USP_checkEnforceCustomerCreditRestrictions] @LegalEntityId = 1, @CustomerId = 77, @MastercompanyId = 1
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_checkEnforceCustomerCreditRestrictions]
@LegalEntityId BIGINT,
@CustomerId BIGINT,
@MastercompanyId BIGINT
AS
BEGIN
	DECLARE @IsCreaditRestriction BIT = 0,
			@CreditLimit DECIMAL = 0,
			@IsRestrict BIT = 0,
			@IsWarning BIT = 0,
			@RestrictMessage varchar(MAX) = 0;

	DECLARE @WarningTypeId INT = (SELECT [CustomerWarningTypeId] FROM dbo.[CustomerWarningType] WITH(NOLOCK) WHERE UPPER([Name]) = 'IF CREDIT LIMIT IS NEGATIVE');

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT @IsCreaditRestriction = ISNULL(IsCreaditRestriction,0),
			   @RestrictMessage = CASE WHEN IsCreaditRestriction = 1 THEN RestrictMessage ELSE '' END
		FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE LegalEntityId = @LegalEntityId and MasterCompanyId = @MastercompanyId;

		SELECT @CreditLimit = ISNULL([CreditLimit],0) FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE CustomerId = @CustomerId and MasterCompanyId = @MastercompanyId;

		IF(@CreditLimit < 0 AND @IsCreaditRestriction = 1)
		BEGIN
				SELECT 
					ISNULL([Restrict],0) as IsRestrict,
					ISNULL([Warning],0) as IsWarning,
					ISNULL([RestrictMessage],'') as [RestrictMessage],
					ISNULL([WarningMessage],'') as [WarningMessage],
					@RestrictMessage AS LeRestriction,
					@IsCreaditRestriction as IsCreaditRestriction
				FROM [dbo].[CustomerWarning] WITH(NOLOCK) WHERE CustomerId = @CustomerId AND CustomerWarningTypeId = @WarningTypeId and MasterCompanyId = @MastercompanyId;
		END

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_checkEnforceCustomerCreditRestrictions'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END