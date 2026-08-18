/*************************************************************           
 ** File:   [QuickBooks_GetUpdateSyncPendingCreditMemo]           
 ** Author:   Devendra Shekh
 ** Description: Get Credit Memo Details to Create Credit Memo in QuickBooks    
 ** Purpose:         
 ** Date:   12-Feb-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					--------------------------------          
    1   12-Feb-2025			Devendra Shekh			Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

EXEC [dbo].[QuickBooks_GetUpdateSyncPendingCreditMemo] 1, 1, 87
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetUpdateSyncPendingCreditMemo]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @CMModuleId INT = 0, @CreditMemoModuleId INT = 0;
		DECLARE @CreditMemoModuleName VARCHAR(200) = '';
		DECLARE @WOInvoiceTypeId INT = 0, @SOInvoiceTypeId INT = 0, @ExchInvoiceTypeId INT = 0;

		SELECT @CMModuleId = AccountingModuleId, @CreditMemoModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITMEMO';
		SELECT @CreditMemoModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'CREDITMEMO';

		IF OBJECT_ID('tempdb..#CreditMemoDetails') IS NOT NULL
			DROP TABLE #CreditMemoDetails

		CREATE TABLE #CreditMemoDetails
		(
			[Id] BIGINT IDENTITY(1,1) NOT NULL,
			[ReferenceId] BIGINT NULL,
			[ItemDescription] NVARCHAR(MAX) NULL,
			[Reason] VARCHAR(500) NULL,
			[Quantity] INT NULL,
			[UnitPrice] DECIMAL(13,2) NULL,
			[InvoiceTypeId] BIGINT NULL,
			[InvoiceId] BIGINT NULL,
			[InvoiceQuickBooksReferenceId] VARCHAR(200) NULL,
			[DocNumber] VARCHAR(250) NULL,
			[CustomerId] VARCHAR(200) NULL,
			[CustomerQuickBooksReferenceId] VARCHAR(200) NULL,
			[CustomerName] VARCHAR(100) NULL,
			[CustomerEmail] VARCHAR(200) NULL,
			[BillLine1] VARCHAR(50) NULL,
			[BillLine2] VARCHAR(50) NULL,
			[BillLine3] VARCHAR(50) NULL,
			[BillCity] VARCHAR(50) NULL,
			[BillPostalCode] VARCHAR(50) NULL,
			[PartNumber] VARCHAR(50) NULL,
			[PartDescription] VARCHAR(MAX) NULL,
			[ShipLine1] VARCHAR(50) NULL,
			[ShipLine2] VARCHAR(50) NULL,
			[ShipLine3] VARCHAR(50) NULL,
			[ShipCity] VARCHAR(50) NULL,
			[ShipPostalCode] VARCHAR(50) NULL,
			[ItemQuickBooksReferenceId] VARCHAR(200) NULL,
			[QuickBooksReferenceId] VARCHAR(200) NULL,
			[SyncToken] VARCHAR(200) NULL,
			[MasterCompanyId] INT NULL,
			[UpdatedBy] VARCHAR(256) NULL,
			[ModuleName] VARCHAR(256) NULL,
			[ModuleId] INT NULL,
			[ReferenceModuleId] INT NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			--Inserting Work Order Invoice Data
			INSERT INTO #CreditMemoDetails ([ReferenceId], [ItemDescription], [Reason], [Quantity], [UnitPrice], [InvoiceTypeId], [InvoiceId], [InvoiceQuickBooksReferenceId], [DocNumber], [CustomerId], [CustomerQuickBooksReferenceId], 
			[CustomerName], [CustomerEmail], [BillLine1], [BillLine2], [BillLine3], [BillCity], [BillPostalCode], [PartNumber], [PartDescription], [ShipLine1], [ShipLine2], [ShipLine3], [ShipCity], [ShipPostalCode], 
			[ItemQuickBooksReferenceId], [QuickBooksReferenceId], [SyncToken], [MasterCompanyId], [UpdatedBy], [ModuleName], [ModuleId], [ReferenceModuleId])
			SELECT	CMH.CreditMemoHeaderId,
					IM.PartDescription,
					CMD.Reason,
					ABS(ISNULL(CMD.Qty, 0)),
					ABS(ISNULL(CMD.Amount, 0)),
					CMD.InvoiceTypeId,
					CMD.InvoiceId,
					0,
					CMH.CreditMemoNumber,
					CMH.CustomerId,
					C.QuickBooksReferenceId,
					C.[Name] AS Customer,
					C.Email AS CustomerEmail,
					COALESCE(billToAddress.Line1, '') AS BillLine1,
					COALESCE(billToAddress.Line2, '') AS BillLine2,
					COALESCE(billToAddress.Line3, '') AS BillLine3,
					COALESCE(billToAddress.City, '') AS BillCity,
					COALESCE(billToAddress.PostalCode, '') AS BillPostalCode,
					'',
					'',
					COALESCE(shipToAddress.Line1, '') AS ShipLine1,
					COALESCE(shipToAddress.Line2, '') AS ShipLine2,
					COALESCE(shipToAddress.Line3, '') AS ShipLine3,
					COALESCE(shipToAddress.City, '') AS ShipCity,
					COALESCE(shipToAddress.PostalCode, '') AS ShipPostalCode,
					IM.QuickBooksReferenceId, 
					CMH.QuickBooksReferenceId, 
					CMH.SyncToken, 
					CMH.MasterCompanyId,
					CMH.UpdatedBy,
					@CreditMemoModuleName,
					@CMModuleId,
					@CreditMemoModuleId
			FROM [dbo].[CreditMemo] CMH WITH(NOLOCK) 
				JOIN [dbo].[CreditMemoDetails] CMD WITH(NOLOCK) ON CMD.CreditMemoHeaderId = CMH.CreditMemoHeaderId
				JOIN [dbo].[Customer] C WITH(NOLOCK) ON C.CustomerId = CMH.CustomerId
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0
				LEFT JOIN [dbo].[CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerId = C.CustomerId AND billToSite.IsPrimary = 1
				LEFT JOIN [dbo].[Address] billToAddress WITH(NOLOCK) ON billToSite.AddressId = billToAddress.AddressId
				LEFT JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON shipToSite.CustomerId = C.CustomerId AND shipToSite.IsPrimary = 1
				LEFT JOIN [dbo].[Address] shipToAddress WITH(NOLOCK) ON shipToSite.AddressId = shipToAddress.AddressId
			WHERE	ISNULL(CMH.QuickBooksReferenceId, '') != '' AND ISNULL(CMH.IsUpdated, 0) = 1 AND CMH.CreditMemoHeaderId = @ReferenceId

			SELECT * FROM #CreditMemoDetails;

		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetUpdateSyncPendingCreditMemo'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END