/*************************************************************           
 ** File:   [CopyExistingBillingSOInvoicingDetails]           
 ** Author:   HEMANT SALIYA
 ** Description: Copy SO Billing Invoicing Details
 ** Purpose:         
 ** Date:   28/04/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/04/2025   HEMANT SALIYA    Created

DELETE from BillingInvoicing WHERE MasterCompanyId = 2
DELETE from dbo.BillingInvoicingItems WHERE MasterCompanyId = 2
DELETE from dbo.BillingInvoicingDetails  

EXEC CopySOItemDepositeDetails 18
**************************************************************/ 
CREATE     PROCEDURE [dbo].[CopySOItemDepositeDetails]
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	 BEGIN TRY  	
	
		DECLARE @ModuleId BIGINT;
		DECLARE @SubModuleId BIGINT;
		DECLARE @TotalRecords INT;
		DECLARE @MinId INT;

		DECLARE @InvoicedStatusId INT = 0
		SELECT @InvoicedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Invoiced'

		
		SET @ModuleId = 10; --Sales Order
		SET @SubModuleId = 66; --Sales Order Part
		DECLARE @ProformaDepositAmount DECIMAL(18,2) = 0;

		 IF OBJECT_ID(N'tempdb..#TempBillingInvoicing') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempBillingInvoicing
		END

		CREATE TABLE #TempBillingInvoicing
		(
			[PKID] [BIGINT] NOT NULL IDENTITY,			
			[BillingInvoicingId] [BIGINT],
			[ModuleId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,		
			[DepositAmount] [DECIMAL](18,2) NULL,
			[UsedDeposit] [DECIMAL](18,2) NULL				
		)

		INSERT INTO #TempBillingInvoicing([BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit])
		SELECT [BillingInvoicingId],[ModuleId],[ReferenceId],[DepositAmount],[UsedDeposit] 
		FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ISNULL([IsVersionIncrease],0) = 0 AND ISNULL(DepositAmount, 0) > 0 AND ISNULL([IsPerformaInvoice], 0) = 0

		SELECT @TotalRecords = COUNT(*), @MinId = MIN([PKID]) FROM #TempBillingInvoicing

		WHILE @MinId <= @TotalRecords
		BEGIN
			DECLARE @BillingInvoicingId BIGINT = 0;
			DECLARE @IsInvoicePosted BIT = NULL;

			SELECT @BillingInvoicingId = BillingInvoicingId FROM #TempBillingInvoicing WHERE [PKID] = @MinId

			SELECT @BillingInvoicingId = BillingInvoicingId	, @IsInvoicePosted = 1			
			FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)			
			WHERE BillingInvoicingId = @BillingInvoicingId AND InvoiceStatusId = @InvoicedStatusId

			EXEC USP_UpdateSOItemDepositAmount @BillingInvoicingId
		
			SET @MinId = @MinId + 1;
		END

END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBillingInvoicingDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END