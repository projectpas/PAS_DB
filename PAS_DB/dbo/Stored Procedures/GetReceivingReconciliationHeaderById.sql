/*************************************************************           
 ** File:   [GetReceivingReconciliationHeaderById]
 ** Author: unknown
 ** Description: This stored procedure is used TO Get Receiving Reconciliation Header Details
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1                 unknown        Created
	2    09/27/2023   Moin Bloch     Modify(Added Invoice Date)
	3    09/30/2023   Hemant Saliya  Modify(Added Accounting Calendor Id)

***********************************************************************     
-- EXEC GetReceivingReconciliationHeaderById 106
************************************************************************/
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationHeaderById]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT RRH.[ReceivingReconciliationId]
               ,RRH.[ReceivingReconciliationNumber]
               ,RRH.[InvoiceNum]
               ,RRH.[StatusId]
               ,RRH.[Status]
               ,RRH.[VendorId]
               ,RRH.[VendorName]
               ,RRH.[CurrencyId]
               ,RRH.[CurrencyName]
               ,RRH.[OpenDate]
               ,ISNULL(RRH.[OriginalTotal],0) AS OriginalTotal
               ,ISNULL(RRH.[RRTotal],0) AS RRTotal
               ,ISNULL(RRH.[InvoiceTotal],0) AS InvoiceTotal
			   ,ISNULL(RRH.[DIfferenceAmount],0) AS DIfferenceAmount
			   ,ISNULL(RRH.[TotalAdjustAmount],0) AS TotalAdjustAmount
               ,RRH.[MasterCompanyId]
               ,RRH.[CreatedBy]
               ,RRH.[UpdatedBy]
               ,RRH.[CreatedDate]
               ,RRH.[UpdatedDate]
               ,RRH.[IsActive]
               ,RRH.[IsDeleted]
			   ,RRH.[InvoiceDate]
			   ,RRH.[AccountingCalendarId]
          FROM [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK) WHERE ReceivingReconciliationId = @ReceivingReconciliationId


    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchHeaderById' 
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