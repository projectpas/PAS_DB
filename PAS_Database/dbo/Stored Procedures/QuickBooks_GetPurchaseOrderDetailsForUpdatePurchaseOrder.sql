/*************************************************************           
 ** File:   [QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder]           
 ** Author:   Abhishek Jirawla
 ** Description: Get PurchaseOrder Details to Update PurchaseOrder in QuickBooks    
 ** Purpose:         
 ** Date:   07-Feb-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    07-Feb-2025   Abhishek Jirawla	Created
     
 EXECUTE [QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder] 1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL
AS
BEGIN
	DECLARE @InvModuleId INT = 0;
	DECLARE @InvModuleName VARCHAR(200) = '';

	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'Purchase Order';

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
				SELECT PO.PurchaseOrderId AS PurchaseOrderId,
					VN.QuickBooksReferenceId AS VendorValue,
					VN.VendorName AS VendorName,
					POP.PurchaseOrderPartRecordId,
					IM.QuickBooksReferenceId AS IMQuickBooksReferenceId,
					POP.PartNumber,
					--POP.PartDescription,
					POP.UnitCost,
					SUM(ISNULL(POP.ExtendedCost, 0)) AS TotalAmt,
					POP.QuantityOrdered,
					'Accounts Payable (A/P)' AS POAPAccountName,
					CAST('33' AS VARCHAR) AS POAPAccountValue,
					--GL.QuickBooksReferenceId AS POAPAccountValue,
					--GL.AccountName AS POAPAccountName,
					ISNULL(POP.ExtendedCost, 0) AS Amount,
					@InvModuleName AS ModuleName,
					@InvModuleId AS ModuleId,
					PO.MasterCompanyId,
					PO.UpdatedBy,
					PO.QuickBooksReferenceId AS POQuickBooksReferenceId,
					PO.SyncToken
				FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON PO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
					--LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = PO.GlAccountId
				WHERE PO.QuickBooksReferenceId IS NOT NULL AND PO.PurchaseOrderId = @ReferenceId AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.PurchaseOrderId,
					VN.QuickBooksReferenceId,
					VN.VendorName,
					POP.PurchaseOrderPartRecordId,
					IM.QuickBooksReferenceId,
					POP.PartNumber,
					POP.UnitCost,
					POP.ExtendedCost,
					POP.QuantityOrdered,
					PO.MasterCompanyId,
					PO.UpdatedBy,
					PO.QuickBooksReferenceId,
					PO.SyncToken
		END
	END TRY     
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder'
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