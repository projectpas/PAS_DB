/*************************************************************             
 ** File:  [USP_CheckDuplicateBillingInvoicingDetails]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to store Billing Details
 ** Purpose:           
 ** Date:   08/09/2025                      
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    08/09/2025   MOIN BLOCH     Created  

-- EXEC USP_CheckDuplicateBillingInvoicingDetails 
************************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_CheckDuplicateBillingInvoicingDetails]  
-------------------------------------------BillingInvoicing-------------------------------------------
@BillingInvoicingId BIGINT = NULL,  
@ModuleId INT = NULL,
@ReferenceId BIGINT = NULL,
@InvoiceTypeId INT= NULL,
@InvoiceNo VARCHAR(256) = NULL,
@InvoiceDate DATETIME2(7) = NULL,
@InvoiceTime VARCHAR(10) = NULL,
@PrintDate DATETIME2(7) = NULL,
@EmployeeId BIGINT = NULL,
@CurrencyId INT = NULL,
@RevisionTypeId BIGINT = NULL,
@InvoiceStatusId INT = NULL,
@InvoiceStatus VARCHAR(50) = NULL,
@InvoiceFilePath VARCHAR(1000) = NULL,
@RevType VARCHAR(200) = NULL,
@VersionNo VARCHAR(10) = NULL,
@CostPlusType VARCHAR(50) = NULL,
@IsPerformaInvoice BIT = 0,
@IsVersionIncrease BIT = 0,
@PostedDate DATETIME2(7) = NULL,
@SubTotal DECIMAL(18,2) = 0,
@OtherTax DECIMAL(18,2) = 0,
@SalesTax DECIMAL(18,2) = 0,
@DepositAmount DECIMAL(18,2) = 0,
@GrandTotal DECIMAL(18,2) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@WorkOrderShippingId  BIGINT = NULL,
@ManagementStructureId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@CreatedDate DATETIME2(7) = NULL,
@UpdatedDate DATETIME2(7) = NULL,
@IsActive BIT = 1,
@IsDeleted BIT = 0,
@IsReversedJE BIT = 0,
@QuickBooksReferenceId VARCHAR(200) = NULL,
@IsUpdated BIT = 0,
@LastSyncDate DATETIME2(7) = NULL,
@SyncToken VARCHAR(200) = NULL,
@IsCreatedFromQuote BIT = 0,
@IsQuickBookGeneratedInvoice BIT = NULL,
-------------------------------------------BillingInvoicingDetails-------------------------------------------
@SoldToCustomerId BIGINT = NULL,
@SoldToSiteId BIGINT = NULL,
@SoldToAttention VARCHAR(256) = NULL,
@ShipToCustomerId BIGINT = NULL,
@ShipToSiteId BIGINT = NULL,
@ShipToAttention VARCHAR(256) = NULL,
@ShipViaId BIGINT = NULL,
@WayBillRef VARCHAR(100) = NULL,
@ShipAccountInfo VARCHAR(200) = NULL,
@OriginCountryId INT = NULL,
@DestinationCountryId INT = NULL,
@SignEmpId BIGINT = NULL,
@SignEmpDate DATETIME2(7) = NULL,
@ShippingTermsName VARCHAR(256) = NULL,
-------------------------------------------BillingInvoicingItems-------------------------------------------
@tbl_BillingInvoicingItemsType BillingInvoicingItemsType READONLY
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1;
	DECLARE @Flag BIT = 1;
	DECLARE @SubModuleId BIGINT = 0;
	DECLARE @WOModuleId INT,@SOModuleId INT

	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	
	IF OBJECT_ID(N'tempdb..#tmprAddBillingInvoicingDetailsTempForExists') IS NOT NULL
	BEGIN
		DROP TABLE #tmprAddBillingInvoicingDetailsTempForExists
	END
		
	CREATE TABLE #tmprAddBillingInvoicingDetailsTempForExists
	(
		[PKID] [BIGINT] NOT NULL IDENTITY,			
		[BillingInvoicingId] [BIGINT] NULL,
		[ModuleId] [INT] NULL,
		[ReferenceId] [BIGINT] NULL,
		[SubModuleId] [INT] NULL,
		[SubReferenceId] [BIGINT] NULL,
		[StocklineId] [BIGINT] NULL,
		[IsPerformaInvoice] [BIT] NULL		
	)
	INSERT INTO #tmprAddBillingInvoicingDetailsTempForExists([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[StocklineId],[IsPerformaInvoice])
	SELECT [BillingInvoicingId],@ModuleId,[ReferenceId],[SubModuleId],[SubReferenceId],[StocklineId],[IsPerformaInvoice] FROM @tbl_BillingInvoicingItemsType
	
	IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
	BEGIN		
		SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';
	END
	ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
	BEGIN
		SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='SalesOrderPart';
	END

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprAddBillingInvoicingDetailsTempForExists    

	IF(@TotalRecord = 1)
	BEGIN		
		WHILE @MinId <= @TotalRecord 
		BEGIN		
			DECLARE @BillingInvoicingIdI BIGINT = 0;
			DECLARE @IsPerformaInvoiceI BIT = 0;
			DECLARE @ModuleIdI INT = 0;
			DECLARE @ReferenceIdI BIGINT = 0;			
			DECLARE @SubReferenceId BIGINT = 0;
			DECLARE @StocklineId BIGINT = 0;

	   	    SELECT @BillingInvoicingIdI = ISNULL([BillingInvoicingId],0),
			  	   @IsPerformaInvoice = ISNULL([IsPerformaInvoice],0),				  
				   @ReferenceIdI = ISNULL([ReferenceId],0),				  
				   @SubReferenceId = ISNULL([SubReferenceId],0),
				   @StocklineId = ISNULL([StocklineId],0)
			  FROM #tmprAddBillingInvoicingDetailsTempForExists WHERE [PKID] = @MinId

			IF(@BillingInvoicingIdI = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[BillingInvoicingItems] WHERE [MasterCompanyId] = @MasterCompanyId AND [ModuleId] = @ModuleId AND [ReferenceId] = @ReferenceIdI AND [SubModuleId] = @SubModuleId AND [SubReferenceId] = @SubReferenceId AND [StocklineId] = @StocklineId AND ISNULL([IsPerformaInvoice],0) = @IsPerformaInvoiceI AND ISNULL([IsVersionIncrease],0) = 0)
				BEGIN				
					SET @Flag = 0;
				END
				ELSE
				BEGIN
					SET @Flag = 1;
				END	
			END
			ELSE
			BEGIN
				SET @Flag = 1;
			END	
			SET @MinId = @MinId + 1;
		END
	END
	ELSE
	BEGIN
		SET @Flag = 1;
	END

	SELECT @Flag AS Flag
		   
 END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'      
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckDuplicateBillingInvoicingDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))   
             + '@Parameter4 = ''' + CAST(ISNULL(@InvoiceTypeId, '') AS VARCHAR(100))   
             + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))    
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
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