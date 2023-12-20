/*************************************************************           
 ** File:  [GetSpeedQuoteByID]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get SpeedQuoteDAta.
 ** Purpose:         
 ** Date:   31/03/2023      
          
 ** PARAMETERS: @SpeedQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    31/03/2023  Amit Ghediya    Created
    2    25/04/2023  Vishal Suthar   Added Missing MasterCompanyId
     
-- EXEC GetSpeedQuoteByID 83
************************************************************************/
CREATE PROCEDURE [dbo].[GetSpeedQuoteByID]  
  @SpeedQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN

			SELECT 
					SpeedQuoteId,
					SpeedQuoteTypeId,
					SpeedQuoteNumber,
					Version AS 'Version',
					VersionNumber,
					OpenDate,
					ValidForDays,
					QuoteExpireDate,
					AccountTypeId,
					CustomerId,
					CustomerContactId,
					CustomerReference,
					ContractReference,
					SalesPersonId,
					AgentName,
					CustomerSeviceRepId,
					ProbabilityId,
					LeadSourceId,
					LeadSourceReference,
					CreditLimit,
					CreditTermId,
					EmployeeId,
					RestrictPMA,
					RestrictDER,
					ApprovedDate,
				    CurrencyId ,
					CustomerWarningId ,
					Memo,
					Notes,
					StatusId ,
				    StatusName ,
					StatusChangeDate ,
				    ManagementStructureId ,
					AgentId ,
					QtyRequested ,
					QtyToBeQuoted ,
					QuoteSentDate ,
					IsNewVersionCreated ,
					QuoteParentId ,
					QuoteTypeName ,
					AccountTypeName ,
					CustomerContactName ,
					CustomerContactEmail ,
					CustomerCode ,
					CustomerName ,
					SalesPersonName ,
					CustomerServiceRepName ,
					ProbabilityName ,
					LeadSourceName ,
					CreditTermName ,
					CreditLimitName ,
					EmployeeName ,
					CustomerWarningName ,
					CurrencyName ,
					Level1 ,
					Level2 ,
					Level3 ,
					Level4 ,
					CreatedBy,
					CreatedDate,
					MasterCompanyId
				FROM SpeedQuote Where SpeedQuoteId = @SpeedQuoteId

		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSpeedQuoteByID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SpeedQuoteId, '') + ''''
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