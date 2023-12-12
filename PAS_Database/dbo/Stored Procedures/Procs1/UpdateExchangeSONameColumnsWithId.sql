
-- =============================================
-- Author:		Deep Patel
-- Create date: 01-Jun-2021
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateExchangeSONameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateExchangeSONameColumnsWithId]
	@ExchangeSalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update SO
		SET TypeName = CASE WHEN SO.TypeId = 1 THEN 'Exchange' WHEN SO.TypeId = 2 THEN 'Loan' ELSE '' END,
		AccountTypeName = CT.CustomerTypeName,
		CustomerName = C.Name,
		SalesPersonName = (SP.FirstName + ' ' + SP.LastName),
		CustomerServiceRepName = (CSR.FirstName + ' ' + CSR.LastName),
		EmployeeName = (Ename.FirstName + ' ' + Ename.LastName),
		CurrencyName = Curr.Code,
		CustomerWarningName = CW.WarningMessage,
		ManagementStructureName = (MS.Code + ' - ' + MS.Name),
		CreditTermName = CTerm.Name,
		VersionNumber = dbo.GenearteVersionNumber(SO.Version)
		FROM [dbo].[ExchangeSalesOrder] SO WITH (NOLOCK)
		--LEFT JOIN DBO.MasterSalesOrderQuoteTypes MST ON Id = SO.TypeId
		LEFT JOIN DBO.CustomerType CT WITH (NOLOCK) ON CustomerTypeId = SO.AccountTypeId
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SO.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SO.SalesPersonId
		LEFT JOIN DBO.Employee CSR WITH (NOLOCK) ON CSR.EmployeeId = SO.CustomerSeviceRepId
		LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = SO.EmployeeId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = SO.CurrencyId
		LEFT JOIN DBO.CustomerWarning CW WITH (NOLOCK) ON CW.CustomerWarningId = SO.CustomerWarningId
		LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = SO.ManagementStructureId
		LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = SO.CreditTermId
		Where SO.ExchangeSalesOrderId = @ExchangeSalesOrderId

		Update EQP
		SET StockLineName = sl.StockLineNumber,
		PartNumber = im.partnumber,
		PartDescription = im.PartDescription,
		ConditionName = c.Description
		--CurrencyName = Curr.Code,
		--PriorityName = P.Description,
		--StatusName = st.Description
		FROM [dbo].[ExchangeSalesOrderPart] EQP
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON EQP.ItemMasterId = im.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON EQP.StockLineId = sl.StockLineId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = EQP.CurrencyId
		LEFT JOIN DBO.Condition c WITH (NOLOCK) ON EQP.ConditionId = c.ConditionId
		Where EQP.ExchangeSalesOrderId = @ExchangeSalesOrderId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeSONameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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