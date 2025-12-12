/*************************************************************
 ** File:  [usp_MapRFQReferences] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save the Purchase Order Part Reference
 ** Date:  12-Dec-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    12-Dec-2025		Devendra Shekh		  Created

EXEC [dbo].[usp_MapRFQReferences] 10, 1028, 1, 'ADMIN USER'
EXEC [dbo].[usp_MapRFQReferences] 13, 7960, 1, 'ADMIN USER'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_MapRFQReferences]
(
    @ModuleId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@UserName VARCHAR(250) = NULL
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		IF OBJECT_ID('tempdb..#tmpModulePartReference') IS NOT NULL
			DROP TABLE #tmpModulePartReference;
		
		IF OBJECT_ID('tempdb..#PartReferenceTemp') IS NOT NULL
			DROP TABLE #PartReferenceTemp;

		CREATE TABLE #PartReferenceTemp (
			PartNumber VARCHAR(200) NULL,
			Condition VARCHAR(200) NULL,
			ReferenceNum VARCHAR(200) NULL,
			ReferenceId BIGINT NULL,
			RequestedQty INT NULL,
			PromisedDate DATETIME2 NULL,
			EstimatedCompletionDate DATETIME2 NULL,
			EstimatedShipDate DATETIME2 NULL,
			ViewType VARCHAR(100) NULL,
		);

		CREATE TABLE #tmpModulePartReference (
			RowId BIGINT IDENTITY(1,1) NOT NULL,
			PurchaseOrderId BIGINT NULL,
			PurchaseOrderPartRecordId BIGINT NULL,
			ItemMasterId BIGINT NULL,
			ConditionId BIGINT NULL,
		);

		DECLARE @tbl_PurchaseOrderPartReferenceType [dbo].[PurchaseOrderPartReferenceType];
		DECLARE @SOQModuleId BIGINT, @SOModuleId BIGINT, @POModuleId BIGINT;
		DECLARE @TotalRow INT, @CurrentRow INT;
		DECLARE @SalesOrderQuoteId BIGINT, @SalesOrderId BIGINT, @CustomerRfqId BIGINT, @ILSRFQDetailId BIGINT;
		DECLARE @viewType VARCHAR (50) = 'soview', @ItemMasterId BIGINT, @ConditionId BIGINT, @PurchaseOrderId BIGINT, @PurchaseOrderPartRecordId BIGINT, @PartReferenceModuleId INT = 3; 

		SELECT @SOQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';

		IF(@SOModuleId = @ModuleId)
		BEGIN
			SELECT @SalesOrderQuoteId = [SalesOrderQuoteId], @SalesOrderId = @ReferenceId FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId AND [MasterCompanyId] = @MasterCompanyId;
			SELECT @CustomerRfqId = [CustomerRfqId] FROM [dbo].[CustomerRFQ] WITH(NOLOCK) WHERE [ReferenceId] = @SalesOrderQuoteId AND [ModuleId] = @SOQModuleId AND [MasterCompanyId] = @MasterCompanyId;
			SELECT TOP 1 @ILSRFQDetailId = [ILSRFQDetailId] FROM [dbo].[ILSRFQPart] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId AND [MasterCompanyId] = @MasterCompanyId;
			
			INSERT INTO #tmpModulePartReference
			SELECT POP.PurchaseOrderId, POP.PurchaseOrderPartRecordId, POP.ItemMasterId, POP.ConditionId
			FROM [dbo].[PurchaseOrderPart] POP WITH(NOLOCK)
			INNER JOIN [dbo].[VendorRFQPart] VRP WITH(NOLOCK) ON POP.PurchaseOrderId = VRP.ReferenceId AND VRP.ModuleId = @POModuleId
			WHERE VRP.ILSRFQDetailId = @ILSRFQDetailId AND POP.MasterCompanyId = @MasterCompanyId;
		END
		ELSE IF(@POModuleId = @ModuleId)
		BEGIN
			SELECT TOP 1 @ILSRFQDetailId = [ILSRFQDetailId] FROM [dbo].[VendorRFQPart] WITH(NOLOCK) WHERE [ReferenceId] = @ReferenceId AND [ModuleId] = @POModuleId AND [MasterCompanyId] = @MasterCompanyId;
			SELECT TOP 1 @CustomerRfqId = [CustomerRfqId] FROM [dbo].[ILSRFQPart] WITH(NOLOCK) WHERE [ILSRFQDetailId] = @ILSRFQDetailId AND [MasterCompanyId] = @MasterCompanyId AND [CustomerRfqId] IS NOT NULL;
			SELECT @SalesOrderQuoteId = [ReferenceId] FROM [dbo].[CustomerRFQ] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId AND [ModuleId] = @SOQModuleId AND [MasterCompanyId] = @MasterCompanyId;
			SELECT TOP 1 @SalesOrderId = [SalesOrderId] FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [MasterCompanyId] = @MasterCompanyId;
			
			INSERT INTO #tmpModulePartReference
			SELECT POP.PurchaseOrderId, POP.PurchaseOrderPartRecordId, POP.ItemMasterId, POP.ConditionId
			FROM [dbo].[PurchaseOrderPart] POP WITH(NOLOCK)
			INNER JOIN [dbo].[VendorRFQPart] VRP WITH(NOLOCK) ON POP.PurchaseOrderId = VRP.ReferenceId AND VRP.ModuleId = @POModuleId
			WHERE POP.PurchaseOrderId = @ReferenceId AND POP.MasterCompanyId = @MasterCompanyId;			
		END

		SELECT @TotalRow = MAX(RowId), @CurrentRow = MIN(RowId) FROM #tmpModulePartReference;
		
		WHILE(@TotalRow >= @CurrentRow) AND ISNULL(@CurrentRow, 0) > 0
		BEGIN

			SELECT 
				@ItemMasterId = [ItemMasterId], @ConditionId = [ConditionId], @PurchaseOrderId = [PurchaseOrderId], @PurchaseOrderPartRecordId = [PurchaseOrderPartRecordId]
			FROM #tmpModulePartReference WHERE RowId = @CurrentRow;

			-- Empty Type Data
			TRUNCATE TABLE #PartReferenceTemp;

			INSERT INTO #PartReferenceTemp
			EXEC [dbo].[USP_GetDataForAddMultipleSOWO] @viewType, @ItemMasterId, @ConditionId, @PurchaseOrderId, @PurchaseOrderPartRecordId;

			-- Save Type Data
			INSERT INTO @tbl_PurchaseOrderPartReferenceType (
				[PurchaseOrderPartReferenceId], [PurchaseOrderId], [PurchaseOrderPartId], [ModuleId], [ReferenceId], [Qty], [RequestedQty], [ReservedQty],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IssuedQty]
			)
			SELECT	0, @PurchaseOrderId, @PurchaseOrderPartRecordId, @PartReferenceModuleId, [ReferenceId], [RequestedQty], NULL, NULL,
					@MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL
			FROM #PartReferenceTemp WHERE [ReferenceId] = @SalesOrderId;

			SET @CurrentRow += 1;
		END
		
		-- Save To PO Part Reference
		IF EXISTS(SELECT 1 FROM @tbl_PurchaseOrderPartReferenceType)
		BEGIN
			EXEC [dbo].[usp_MergePurchaseOrderPartReference] @tbl_PurchaseOrderPartReferenceType;
		END
	END
	END TRY
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_MergePurchaseOrderPartReference' 
			, @ProcedureParameters VARCHAR(3000)  = ''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName				= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
			, @ApplicationName			= @ApplicationName
			, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END