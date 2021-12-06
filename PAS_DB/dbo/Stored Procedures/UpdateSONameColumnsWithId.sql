
-- =============================================
-- Author:		Vishal Suthar
-- Create date: 23-Dec-2020
-- Description:	Update name columns into corrosponding reference Id values from respective master table
-- =============================================
--  EXEC [dbo].[UpdateSONameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateSONameColumnsWithId]
	@SalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		
		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#SalesOrderPartMSDATA') IS NOT NULL
		BEGIN
			DROP TABLE #SalesOrderPartMSDATA 
		END

			CREATE TABLE #SalesOrderPartMSDATA
			(
			 MSID bigint,
			 Level1 varchar(200) NULL,
			 Level2 varchar(200) NULL,
			 Level3 varchar(200) NULL,
			 Level4 varchar(200) NULL 
			)


		IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #MSDATA 
		END
		CREATE TABLE #MSDATA
		(
			ID int IDENTITY, 
			MSID bigint 
		)
		INSERT INTO #MSDATA (MSID)
		  SELECT SO.ManagementStructureId FROM dbo.SalesOrder SO WITH(NOLOCK) Where SO.SalesOrderId = @SalesOrderId

		DECLARE @LoopID as int 
		SELECT  @LoopID = MAX(ID) FROM #MSDATA
		WHILE(@LoopID > 0)
		BEGIN
		SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

		EXEC dbo.GetMSNameandCode @MSID,
		 @Level1 = @Level1 OUTPUT,
		 @Level2 = @Level2 OUTPUT,
		 @Level3 = @Level3 OUTPUT,
		 @Level4 = @Level4 OUTPUT

		INSERT INTO #SalesOrderPartMSDATA
					(MSID, Level1,Level2,Level3,Level4)
			  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		SET @LoopID = @LoopID - 1;
		END 

		Update SO
		SET TypeName = MST.Name,
		AccountTypeName = CT.CustomerTypeName,
		CustomerName = C.Name,
		SalesPersonName = (SP.FirstName + ' ' + SP.LastName),
		CustomerServiceRepName = (CSR.FirstName + ' ' + CSR.LastName),
		EmployeeName = (Ename.FirstName + ' ' + Ename.LastName),
		CurrencyName = Curr.Code,
		CustomerWarningName = CW.WarningMessage,
		ManagementStructureName = (MS.Code + ' - ' + MS.Name),
		CreditTermName = CTerm.Name,
		SO.Level1 = PMS.Level1,
		SO.Level2 = PMS.Level2,
		SO.Level3 = PMS.Level3,
		SO.Level4 = PMS.Level4,
		VersionNumber = dbo.GenearteVersionNumber(SO.Version)
		FROM [dbo].[SalesOrder] SO WITH (NOLOCK)
		LEFT JOIN #SalesOrderPartMSDATA PMS ON PMS.MSID = SO.ManagementStructureId
		LEFT JOIN DBO.MasterSalesOrderQuoteTypes MST WITH (NOLOCK) ON Id = SO.TypeId
		LEFT JOIN DBO.CustomerType CT WITH (NOLOCK) ON CustomerTypeId = SO.AccountTypeId
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SO.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SO.SalesPersonId
		LEFT JOIN DBO.Employee CSR WITH (NOLOCK) ON CSR.EmployeeId = SO.CustomerSeviceRepId
		LEFT JOIN DBO.Employee Ename WITH (NOLOCK) ON Ename.EmployeeId = SO.EmployeeId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = SO.CurrencyId
		LEFT JOIN DBO.CustomerWarning CW WITH (NOLOCK) ON CW.CustomerWarningId = SO.CustomerWarningId
		LEFT JOIN DBO.ManagementStructure MS WITH (NOLOCK) ON MS.ManagementStructureId = SO.ManagementStructureId
		LEFT JOIN DBO.CreditTerms CTerm WITH (NOLOCK) ON CTerm.CreditTermsId = SO.CreditTermId
		Where SO.SalesOrderId = @SalesOrderId

		Update SOP
		SET UnitSalesPricePerUnit = (sop.GrossSalePricePerUnit - sop.DiscountAmount)
		FROM [dbo].[SalesOrderPart] sop WITH (NOLOCK)
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sop.StockLineId = sl.StockLineId
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = sop.CurrencyId
		LEFT JOIN DBO.Condition c WITH (NOLOCK) ON sop.ConditionId = c.ConditionId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON sop.StatusId = st.Id
		LEFT JOIN DBO.Priority p WITH (NOLOCK) ON sop.PriorityId = p.PriorityId
		LEFT JOIN DBO.MasterSalesOrderQuoteStatus msoqs WITH (NOLOCK) ON sop.StatusId = msoqs.Id
		Where sop.SalesOrderId = @SalesOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSONameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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