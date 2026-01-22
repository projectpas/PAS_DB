/*************************************************************             
 ** File:   [UpdateExchangeSONameColumnsWithId]
 ** Author:   Deep Patel
 ** Description:	Update name columns into corrosponding reference Id values from respective master table
 ** Purpose:           
 ** Date:   01-Jun-2021

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    06/01/2021   Deep Patel		Created
    2    02/22/2024   Vishal Suthar		Modified to update values based on IsVendor flag
	3	 04/04/2024	  Bhargav Saliya   Credit terms Changes

--  EXEC [dbo].[UpdateExchangeSONameColumnsWithId] 338
**************************************************************/
CREATE PROCEDURE [dbo].[UpdateExchangeSONameColumnsWithId]
	@ExchangeSalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update ESO
		SET TypeName = CASE WHEN ESO.TypeId = 1 THEN 'Exchange' WHEN ESO.TypeId = 2 THEN 'Loan' ELSE '' END,
		AccountTypeName = CT.CustomerTypeName,
		CustomerName = CASE WHEN ISNULL(ESO.IsVendor, 0) = 0 THEN C.Name ELSE V.VendorName END,
		SalesPersonName = (SP.FirstName + ' ' + SP.LastName),
		CustomerServiceRepName = (CSR.FirstName + ' ' + CSR.LastName),
		EmployeeName = (Ename.FirstName + ' ' + Ename.LastName),
		CurrencyName = Curr.Code,
		CustomerWarningName = CW.WarningMessage,
		ManagementStructureName = (MS.Code + ' - ' + MS.Name),
		CreditTermName = CASE WHEN ISNULL(ESO.CreditTermName,'') != '' THEN ESO.CreditTermName ELSE CTerm.[Name] END,
		VersionNumber = dbo.GenearteVersionNumber(ESO.Version)
		FROM [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK)
		LEFT JOIN DBO.CustomerType CT WITH (NOLOCK) ON CustomerTypeId = ESO.AccountTypeId
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = ESO.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = ESO.SalesPersonId
		LEFT JOIN DBO.Employee CSR WITH (NOLOCK) ON CSR.EmployeeId = ESO.CustomerSeviceRepId
		LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = ESO.EmployeeId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = ESO.CurrencyId
		LEFT JOIN DBO.CustomerWarning CW WITH (NOLOCK) ON CW.CustomerWarningId = ESO.CustomerWarningId
		LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = ESO.ManagementStructureId
		LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = ESO.CreditTermId
		LEFT JOIN DBO.Vendor V WITH (NOLOCK) ON V.VendorId = ESO.CustomerId
		Where ESO.ExchangeSalesOrderId = @ExchangeSalesOrderId

		Update EQP
		SET StockLineName = sl.StockLineNumber,
		PartNumber = im.partnumber,
		PartDescription = im.PartDescription,
		ConditionName = c.[Description]
		FROM [dbo].[ExchangeSalesOrderPart] EQP WITH (NOLOCK)
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