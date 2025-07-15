/*************************************************************           
 ** File:   [UpdateBillingPayments]           
 ** Author:  Hemnat Saliya 
 ** Description: This stored procedure is used to save asset depericiation data
 ** Purpose:         
 ** Date:    02/07/2025
 ** PARAMETERS: @BillingInvoicingId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		 Change Description            
 ** --   --------     -------		 --------------------------------          
    1    02/07/2025   Hemnat Saliya     Created

	EXEC  [dbo].[USP_UpdateSOItemDepositAmount] 4377,1
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateSOItemDepositAmount] 
@BillingInvoicingId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN			
		DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1, @DepositAmount DECIMAL(18,2) = 0
		
		IF OBJECT_ID(N'tempdb..#TempUpdateBillingDetails') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempUpdateBillingDetails
		END

		CREATE TABLE #TempUpdateBillingDetails 
		(
		    [PKID] [BIGINT] NOT NULL IDENTITY,
			[BillingInvoicingItemId] [BIGINT],
			[BillingInvoicingId] [BIGINT],
			[ModuleId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,
			[SubReferenceId] [BIGINT] NULL,
			[GrandTotal] [DECIMAL](18,2) NULL,
			[DepositAmount] [DECIMAL](18,2) NULL,
			[RemainingAmount] [DECIMAL](18,2) NULL	 		
		)
		
		INSERT INTO #TempUpdateBillingDetails([BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubReferenceId],[GrandTotal])
		                               SELECT [BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubReferenceId],[GrandTotal] 
		FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId

		SELECT @DepositAmount = ISNULL([DepositAmount],0) - ISNULL([UsedDeposit],0)
		FROM [dbo].[BillingInvoicing] WHERE [BillingInvoicingId] = @BillingInvoicingId
		
		DECLARE @BillingInvoicingItemId BIGINT = 0
			
		DECLARE @GrandTotal DECIMAL(18,2) = 0

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #TempUpdateBillingDetails   

		WHILE @MinId <= @TotalRecord
		BEGIN		
		
			SELECT @BillingInvoicingItemId = [BillingInvoicingItemId],
				   @GrandTotal = ISNULL([GrandTotal],0)				   
			  FROM #TempUpdateBillingDetails WHERE [PKID] = @MinId

			  UPDATE [dbo].[BillingInvoicingItems] SET [DepositAmount] = CASE WHEN @DepositAmount <= @GrandTotal THEN @DepositAmount ELSE @GrandTotal END,
													   [RemainingAmount] = CASE WHEN [GrandTotal] > @DepositAmount THEN [GrandTotal] - @DepositAmount ELSE 0 END 
			  WHERE [BillingInvoicingItemId] = @BillingInvoicingItemId
			
			  SET @DepositAmount =  CASE WHEN @DepositAmount > @GrandTotal THEN @DepositAmount - @GrandTotal ELSE 0 END 	

			SET @MinId = @MinId + 1;
		END
		
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
                ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SaveAssetDeprciationData' 
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END