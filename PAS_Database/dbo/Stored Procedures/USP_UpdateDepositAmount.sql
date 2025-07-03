/*************************************************************           
 ** File:   [UpdateBillingPayments]           
 ** Author:  Moin Bloch
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
    1    02/07/2025   Moin Bloch     Created

	EXEC  [dbo].[USP_UpdateDepositAmount] 10146,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateDepositAmount] 
@BillingInvoicingId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN			
		DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1, @Flag INT=0,@DepositAmount DECIMAL(18,2) = 0,@UsedDepositAmount DECIMAL(18,2) = 0,@UsedDeposit DECIMAL(18,2) = 0
		DECLARE @ModuleId INT
		DECLARE @ReferenceId BIGINT
		DECLARE @TotalRecordPRo INT = 0,@MinIdPro BIGINT = 1
		
		IF OBJECT_ID(N'tempdb..#TempUpdateBillingDetails') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempUpdateBillingDetails
		END

		IF OBJECT_ID(N'tempdb..#TempUpdateBillingDetailsForPerforma') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempUpdateBillingDetailsForPerforma
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

		CREATE TABLE #TempUpdateBillingDetailsForPerforma
		(
		    [PKID] [BIGINT] NOT NULL IDENTITY,			
			[BillingInvoicingId] [BIGINT],
			[ModuleId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,		
			[DepositAmount] [DECIMAL](18,2) NULL,
			[UsedDeposit] [DECIMAL](18,2) NULL	
			
		)

		INSERT INTO #TempUpdateBillingDetails([BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubReferenceId],[GrandTotal])
		                               SELECT [BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubReferenceId],[GrandTotal] 
		FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId

		SELECT @ReferenceId = [ReferenceId],
		       @ModuleId = [ModuleId] 
		  FROM [dbo].[BillingInvoicing] WHERE [BillingInvoicingId] = @BillingInvoicingId

		INSERT INTO #TempUpdateBillingDetailsForPerforma([BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit])
		                                          SELECT [BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit] 
		FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [ReferenceId] = @ReferenceId AND ModuleId = @ModuleId AND [IsPerformaInvoice] = 1 AND ISNULL([IsVersionIncrease],0) = 0

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #TempUpdateBillingDetails    

		WHILE @MinId <= @TotalRecord
		BEGIN		
			DECLARE @BillingInvoicingIdI BIGINT = 0,@BillingInvoicingItemId BIGINT = 0
			
			DECLARE @SubReferenceId BIGINT 
			DECLARE @GrandTotal DECIMAL(18,2) = 0
			
			DECLARE @RemainingDepositAmount DECIMAL(18,2) = 0
			
			SELECT @BillingInvoicingItemId = [BillingInvoicingItemId],
			       @BillingInvoicingIdI = [BillingInvoicingId],
				   @ModuleId = [ModuleId],
				   @ReferenceId = [ReferenceId],
				   @SubReferenceId = [SubReferenceId],
				   @GrandTotal = ISNULL([GrandTotal],0)				   
			  FROM #TempUpdateBillingDetails WHERE [PKID] = @MinId
			  	
			IF EXISTS(SELECT 1 FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [ReferenceId] = @ReferenceId AND [SubReferenceId] = @SubReferenceId AND [ModuleId] = @ModuleId AND [IsPerformaInvoice] = 1 AND @Flag = 0)
			BEGIN
				SELECT @DepositAmount = ISNULL(SUM(BI.[DepositAmount]),0) - ISNULL(SUM(BI.[UsedDeposit]),0)
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
				--INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BII.[BillingInvoicingId] = BI.[BillingInvoicingId]
				WHERE BI.[ReferenceId] = @ReferenceId 	
				--AND BI.[SubReferenceId] = @SubReferenceId	
				  AND BI.[ModuleId] = @ModuleId 
				  AND BI.[IsPerformaInvoice] = 1
				  AND ISNULL(BI.[IsVersionIncrease],0) = 0
				
				SET @Flag = 1;
				
				SELECT @UsedDepositAmount = CASE WHEN [GrandTotal] > @DepositAmount THEN @DepositAmount ELSE [GrandTotal] END FROM [dbo].[BillingInvoicing] WHERE [BillingInvoicingId] = @BillingInvoicingId  
				
				UPDATE [dbo].[BillingInvoicing] SET [DepositAmount] = CASE WHEN [GrandTotal] > @DepositAmount THEN @DepositAmount ELSE [GrandTotal] END,
				                                    [RemainingAmount] = CASE WHEN [GrandTotal] > @DepositAmount THEN [GrandTotal] - @DepositAmount ELSE 0 END											    
				WHERE [BillingInvoicingId] = @BillingInvoicingId  
					
			END

			IF(@DepositAmount > 0)
			BEGIN					
				UPDATE [dbo].[BillingInvoicingItems] SET [DepositAmount] = CASE WHEN @DepositAmount <= @GrandTotal THEN @DepositAmount ELSE @GrandTotal END,
				                                         [RemainingAmount] = CASE WHEN [GrandTotal] > @DepositAmount THEN [GrandTotal] - @DepositAmount ELSE 0 END 
				 WHERE [BillingInvoicingItemId] = @BillingInvoicingItemId
				
				SET @DepositAmount =  CASE WHEN @DepositAmount > @GrandTotal THEN @DepositAmount - @GrandTotal ELSE 0 END 				
			END

			SET @MinId = @MinId + 1;
		END

			   
		--SELECT @TotalRecordPRo = COUNT(*), @MinIdPro = MIN([PKID]) FROM #TempUpdateBillingDetailsForPerforma    

		--WHILE @MinIdPro <= @TotalRecordPRo
		--BEGIN
		--	DECLARE @PendingDeposit DECIMAL(18,2)=0

		--	SELECT @BillingInvoicingIdI = [BillingInvoicingId],
		--		   @ModuleId = [ModuleId],
		--		   @ReferenceId = [ReferenceId], 
		--		   @DepositAmount = [DepositAmount],
		--		   @UsedDeposit = ISNULL([UsedDeposit],0)
		--	  FROM #TempUpdateBillingDetailsForPerforma WHERE [PKID] = @MinIdPro
			
		--	IF(@UsedDepositAmount > 0)
		--	BEGIN	
		--		SET @PendingDeposit = @DepositAmount - @UsedDeposit

		--		UPDATE [dbo].[BillingInvoicing] SET [UsedDeposit] = CASE WHEN @UsedDepositAmount >= @PendingDeposit THEN @PendingDeposit ELSE [UsedDeposit] END
		--		 WHERE [BillingInvoicingId] = @BillingInvoicingIdI
				
		--		SET @UsedDepositAmount =  CASE WHEN @UsedDepositAmount >= @UsedDeposit THEN @UsedDepositAmount - @UsedDeposit ELSE 0 END 				
		--	END

		--	SET @MinIdPro = @MinIdPro + 1;
		--END
		
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