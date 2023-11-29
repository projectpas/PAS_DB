-- =============================================
-- Author:		Vishal Suthar
-- Create date: 23-Dec-2020
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateSOQNameColumnsWithId] 31
CREATE PROCEDURE [dbo].[UpdateSOQNameColumnsWithId]
	@SalesOrderQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update SOQ
		SET QuoteTypeName = MST.Name,
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
		--CustomerContactEmail = c.Email,
		CustomerContactEmail = customContact.Email,
		StatusName = msoqs.Name,
		VersionNumber = dbo.GenearteVersionNumber(SOQ.Version)
		FROM [dbo].[SalesOrderQuote] SOQ WITH (NOLOCK)
		LEFT JOIN DBO.MasterSalesOrderQuoteTypes MST WITH (NOLOCK) ON Id = SOQ.QuoteTypeId
		LEFT JOIN DBO.CustomerType CT WITH (NOLOCK) ON CustomerTypeId = SOQ.AccountTypeId
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SOQ.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SOQ.SalesPersonId
		LEFT JOIN DBO.Employee CSR WITH (NOLOCK) ON CSR.EmployeeId = SOQ.CustomerSeviceRepId
		LEFT JOIN DBO.[Percent] P WITH (NOLOCK) ON P.PercentId = SOQ.ProbabilityId
		LEFT JOIN DBO.LeadSource L WITH (NOLOCK) ON L.LeadSourceId = SOQ.LeadSourceId
		LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = SOQ.CreditTermId
		LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = SOQ.EmployeeId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = SOQ.CurrencyId
		LEFT JOIN DBO.CustomerWarning CW WITH (NOLOCK) ON CW.CustomerWarningId = SOQ.CustomerWarningId
		LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = SOQ.ManagementStructureId
		LEFT JOIN DBO.CustomerContact CC WITH (NOLOCK) ON soq.CustomerContactId = CC.CustomerContactId
		LEFT JOIN DBO.Contact customContact WITH (NOLOCK) ON CC.ContactId = customContact.ContactId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus msoqs WITH (NOLOCK) ON SOQ.StatusId = msoqs.Id
		Where SOQ.SalesOrderQuoteId = @SalesOrderQuoteId

		Update SOQP
		SET StockLineName = sl.StockLineNumber,
		PartNumber = im.partnumber,
		PartDescription = im.PartDescription,
		ConditionName = c.Description,
		CurrencyName = Curr.Code,
		PriorityName = P.Description,
		StatusName = st.Description,
		UnitSalesPricePerUnit = (soqp.GrossSalePricePerUnit - soqp.DiscountAmount)
		FROM [dbo].[SalesOrderQuotePart] soqp WITH (NOLOCK)
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON soqp.ItemMasterId = im.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON soqp.StockLineId = sl.StockLineId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = soqp.CurrencyId
		LEFT JOIN DBO.Condition c WITH (NOLOCK) ON soqp.ConditionId = c.ConditionId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON soqp.StatusId = st.Id
		LEFT JOIN DBO.Priority p WITH (NOLOCK) ON soqp.PriorityId = p.PriorityId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus msoqs WITH (NOLOCK) ON soqp.StatusId = msoqs.Id
		Where soqp.SalesOrderQuoteId = @SalesOrderQuoteId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSOQNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@SalesOrderQuoteId AS VARCHAR), '') + ''
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