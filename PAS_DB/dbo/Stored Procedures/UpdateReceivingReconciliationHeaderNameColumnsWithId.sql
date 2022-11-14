--  EXEC [dbo].[UpdateReceivingReconciliationHeaderNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateReceivingReconciliationHeaderNameColumnsWithId]
	@ReceivingReconciliationId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update SO
		SET Status = BS.Name,
		VendorName = VR.VendorName,
		CurrencyName = C.Code
		FROM [dbo].[ReceivingReconciliationHeader] SO WITH (NOLOCK)
		LEFT JOIN DBO.BatchStatus BS WITH (NOLOCK) ON Id = SO.StatusId
		LEFT JOIN DBO.Vendor VR WITH (NOLOCK) ON VR.VendorId = SO.VendorId
		LEFT JOIN DBO.Currency C WITH (NOLOCK) ON C.CurrencyId = SO.CurrencyId
		Where SO.ReceivingReconciliationId = @ReceivingReconciliationId

		Update RRDE
		SET GlAccountNumber = G.AccountCode,
		GlAccountName = G.AccountName
		FROM [dbo].[ReceivingReconciliationDetails] RRDE WITH (NOLOCK)
		LEFT JOIN DBO.GLAccount G WITH (NOLOCK) ON G.GlAccountId = RRDE.GlAccountId
		Where RRDE.ReceivingReconciliationId = @ReceivingReconciliationId
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
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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