
-- =============================================
-- Author:		Deep Patel
-- Create date: 12-may-2021
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateSpeedQuoteNameColumnsWithId] 5 
CREATE PROCEDURE [dbo].[UpdateSpeedQuoteNameColumnsWithId]
	@SpeedQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

	Update SQ
	SET 
	QuoteTypeName = MST.Name,
	AccountTypeName = CT.CustomerTypeName,
	CustomerName = C.Name,
	SalesPersonName = (SP.FirstName + ' ' + SP.LastName),
	CustomerServiceRepName = (CSR.FirstName + ' ' + CSR.LastName),
	ProbabilityName = P.PercentValue,
	LeadSourceName = L.LeadSources,
	CreditTermName = CTerm.Name,
	EmployeeName = (Ename.FirstName + ' ' + Ename.LastName),
	CurrencyName = Curr.Code,
	CustomerWarningName = CW.WarningMessage,
	ManagementStructureName = (MS.Code + ' - ' + MS.Name),
	CustomerCode = C.CustomerCode,
	CustomerContactName = customContact.FirstName +' '+ customContact.LastName + '-' +  customContact.WorkPhone,
	CustomerContactEmail = c.Email,
	StatusName = msqs.Name,
	VersionNumber = dbo.GenearteVersionNumber(SQ.Version)
	
	FROM [dbo].[SpeedQuote] SQ WITH (NOLOCK)
	LEFT JOIN DBO.MasterSpeedQuoteTypes MST WITH (NOLOCK) ON Id = SQ.SpeedQuoteTypeId
	LEFT JOIN DBO.CustomerType CT  ON CustomerTypeId = SQ.AccountTypeId
	LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SQ.CustomerId
	LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SQ.SalesPersonId
	LEFT JOIN DBO.Employee CSR  ON CSR.EmployeeId = SQ.CustomerSeviceRepId
	LEFT JOIN DBO.[Percent] P WITH (NOLOCK) ON P.PercentId = SQ.ProbabilityId
	LEFT JOIN DBO.LeadSource L WITH (NOLOCK) ON L.LeadSourceId = SQ.LeadSourceId
	LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = SQ.CreditTermId
	LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = SQ.EmployeeId
	LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = SQ.CurrencyId
	LEFT JOIN DBO.CustomerWarning CW WITH (NOLOCK) ON CW.CustomerWarningId = SQ.CustomerWarningId
	LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = SQ.ManagementStructureId
	LEFT JOIN DBO.CustomerContact CC WITH (NOLOCK) ON SQ.CustomerContactId = CC.CustomerContactId
	LEFT JOIN DBO.Contact customContact WITH (NOLOCK) ON CC.ContactId = customContact.ContactId
	LEFT JOIN DBO.MasterSpeedQuoteStatus msqs WITH (NOLOCK) ON SQ.StatusId = msqs.Id
	Where SQ.SpeedQuoteId = @SpeedQuoteId


	Update SQP
	SET PartNumber = im.partnumber,
	PartDescription = im.PartDescription,
	ConditionName = c.Description,
	Code = c.Code,
	CurrencyName = Curr.Code,
	StatusName = st.Description
	FROM [dbo].[SpeedQuotePart] SQP WITH (NOLOCK)
	LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON SQP.ItemMasterId = im.ItemMasterId
	LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = SQP.CurrencyId
	LEFT JOIN DBO.Condition c WITH (NOLOCK) ON SQP.ConditionId = c.ConditionId
	LEFT JOIN DBO.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON SQP.StatusId = st.Id
	LEFT JOIN DBO.MasterSpeedQuoteStatus msoqs WITH (NOLOCK) ON SQP.StatusId = msoqs.Id
	Where SQP.SpeedQuoteId = @SpeedQuoteId

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSpeedQuoteNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SpeedQuoteId, '') + ''
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