/*************************************************************             
 ** File:   [UpdateExchangeQuoteNameColumnsWithId]
 ** Author:   Deep Patel
 ** Description:	Update name columns into corrosponding reference Id values from respective master table
 ** Purpose:           
 ** Date:   31-March-2021

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    31-March-2021   Deep Patel		Created
	3	 04/04/2024	  Bhargav Saliya   Credit terms Changes

--  EXEC [dbo].[UpdateExchangeQuoteNameColumnsWithId] 5
**************************************************************/
CREATE PROCEDURE [dbo].[UpdateExchangeQuoteNameColumnsWithId]
	@ExchangeQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update EQ
		SET 
		--TypeName = MST.Name,
		TypeName = CASE WHEN EQ.Type = 1 THEN 'Exchange' WHEN EQ.Type = 2 THEN 'Loan' ELSE '' END,
		CustomerName = C.Name,
		CustomerCode = C.CustomerCode,
		SalesPersonName = (SP.FirstName + ' ' + SP.LastName),
		CreditTermName =  CASE WHEN ISNULL(EQ.CreditTermName,'') != '' THEN EQ.CreditTermName ELSE CTerm.[Name] END,
		VersionNumber = dbo.GenearteVersionNumber(EQ.Version),
		StatusName = eqs.[Name],
		CustomerContactName = customContact.FirstName +' '+ customContact.LastName + '-' +  customContact.WorkPhone,
		CustomerContactEmail = c.Email,
		ManagementStructureName = (MS.Code + ' - ' + MS.Name),
		CustomerServiceRepName = (CSR.FirstName + ' ' + CSR.LastName),
		EmployeeName = (Ename.FirstName + ' ' + Ename.LastName)
		FROM [dbo].[ExchangeQuote] EQ WITH (NOLOCK)
		--LEFT JOIN DBO.MasterSalesOrderQuoteTypes MST ON Id = EQ.TypeId
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = EQ.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = EQ.SalesPersonId
		LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = EQ.CreditTermId
		LEFT JOIN DBO.CustomerContact CC WITH (NOLOCK) ON EQ.CustomerContactId = CC.CustomerContactId
		LEFT JOIN DBO.Contact customContact WITH (NOLOCK) ON CC.ContactId = customContact.ContactId
		LEFT JOIN DBO.ExchangeStatus eqs WITH (NOLOCK) ON EQ.StatusId = eqs.ExchangeStatusId
		LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = EQ.ManagementStructureId
		LEFT JOIN DBO.Employee CSR WITH (NOLOCK) ON CSR.EmployeeId = EQ.CustomerSeviceRepId
		LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = EQ.EmployeeId
		Where EQ.ExchangeQuoteId = @ExchangeQuoteId

		Update EQP
		SET StockLineName = sl.StockLineNumber,
		PartNumber = im.partnumber,
		PartDescription = im.PartDescription,
		ConditionName = c.Description
		--CurrencyName = Curr.Code,
		--PriorityName = P.Description,
		--StatusName = st.Description
		FROM [dbo].[ExchangeQuotePart] EQP WITH (NOLOCK)
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON EQP.ItemMasterId = im.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON EQP.StockLineId = sl.StockLineId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = EQP.CurrencyId
		LEFT JOIN DBO.Condition c WITH (NOLOCK) ON EQP.ConditionId = c.ConditionId
		Where EQP.ExchangeQuoteId = @ExchangeQuoteId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeQuoteNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeQuoteId, '') + ''
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