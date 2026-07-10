
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder   (source: PAS_DB/dbo/Stored Procedures/Procs1/QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder.sql)
-- ---------------------------------------------------------------------------------------------------
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
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder] 1
**************************************************************/ 
CREATE       PROCEDURE [dbo].[QuickBooks_GetPurchaseOrderDetailsForUpdatePurchaseOrder]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceModuleId INT = NULL
AS
BEGIN
	DECLARE @InvModuleId INT = 0, @POModuleId INT = 0, @POModuleName VARCHAR(200) = '', @ROModuleId INT = 0, @ROModuleName VARCHAR(200) = '';
	DECLARE @InvModuleName VARCHAR(200) = '';
	DECLARE @POGLAccountId BIGINT, @ROGLAccountId BIGINT;
	
	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'PurchaseOrder';
	SELECT @POModuleId = ModuleId, @POModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'PurchaseOrder';
	SELECT @ROModuleId = ModuleId, @ROModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'RepairOrder';

	SELECT @ROGLAccountId = GlAccountId FROM DistributionSetup WHERE DistributionMasterId = (SELECT ID FROM DistributionMaster WHERE Name = 'ReceivingROStockline') AND MasterCompanyId = 1 AND DistributionSetupCode = 'RROACCPAYABLE'
	SELECT @POGLAccountId = GlAccountId FROM DistributionSetup WHERE DistributionMasterId = (SELECT ID FROM DistributionMaster WHERE Name = 'ReceivingPOStockline') AND MasterCompanyId = 1 AND DistributionSetupCode = 'RPOACCPAYABLE'

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			IF(ISNULL(@ReferenceModuleId, 0) = ISNULL(@POModuleId, 0)) 
			BEGIN
				SELECT PO.PurchaseOrderId AS ReferenceId,
					PO.PurchaseOrderNumber AS ReferenceNumber,
					VN.QuickBooksReferenceId AS VendorValue,
					VN.VendorName AS VendorName,
					POP.PurchaseOrderPartRecordId,
					IM.QuickBooksReferenceId AS IMQuickBooksReferenceId,
					POP.PartNumber,
					POP.PartDescription,
					POP.UnitCost,
					SUM(ISNULL(POP.ExtendedCost, 0)) AS TotalAmt,
					POP.QuantityOrdered,
					GL.AccountName AS POAPAccountName,
					GL.QuickBooksReferenceId AS POAPAccountValue,
					--GL.QuickBooksReferenceId AS POAPAccountValue,
					--GL.AccountName AS POAPAccountName,
					ISNULL(POP.ExtendedCost, 0) AS Amount,
					PO.VendorContactEmail,
					UPPER(AA.AddressId) AS AddressId,
					UPPER(AA.Line1) AS AddressLine1,
					UPPER(AA.Line2) AS AddressLine2,
					UPPER(AA.City) AS City,
					UPPER(AA.StateOrProvince) StateOrProvince,
					AA.PostalCode,
					AA.CountryId,
					UPPER(AA.Country) Country,
					@InvModuleName AS ModuleName,
					@InvModuleId AS ModuleId,
					PO.MasterCompanyId,
					PO.UpdatedBy,
					@POModuleId AS ReferenceModuleId,
					@POModuleName AS ReferenceModuleName,
					PO.QuickBooksReferenceId AS POQuickBooksReferenceId,
					PO.SyncToken
				FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON PO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @POGlAccountId
					LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @POModuleId AND AA.ReffranceId = PO.PurchaseOrderId AND AA.IsShippingAdd = 1
				WHERE PO.QuickBooksReferenceId IS NOT NULL AND PO.PurchaseOrderId = @ReferenceId AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.PurchaseOrderId,
					PO.PurchaseOrderNumber,
					VN.QuickBooksReferenceId,
					VN.VendorName,
					POP.PurchaseOrderPartRecordId,
					IM.QuickBooksReferenceId,
					GL.AccountName,
					GL.QuickBooksReferenceId,
					POP.PartNumber,
					POP.PartDescription,
					POP.UnitCost,
					POP.ExtendedCost,
					PO.VendorContactEmail,
					AA.AddressId,
					AA.Line1,
					AA.Line2,
					AA.City,
					AA.StateOrProvince,
					AA.PostalCode,
					AA.CountryId,
					AA.Country,
					POP.QuantityOrdered,
					PO.MasterCompanyId,
					PO.UpdatedBy,
					PO.QuickBooksReferenceId,
					PO.SyncToken
			END
			ELSE IF(ISNULL(@ReferenceModuleId, 0) = ISNULL(@ROModuleId, 0)) 
			BEGIN
				SELECT RO.RepairOrderId AS ReferenceId,
					RO.RepairOrderNumber AS ReferenceNumber,
					VN.QuickBooksReferenceId AS VendorValue,
					VN.VendorName AS VendorName,
					ROP.RepairOrderPartRecordId,
					IM.QuickBooksReferenceId AS IMQuickBooksReferenceId,
					ROP.PartNumber,
					ROP.PartDescription,
					ROP.UnitCost,
					SUM(ISNULL(ROP.ExtendedCost, 0)) AS TotalAmt,
					ROP.QuantityOrdered,
					GL.AccountName AS POAPAccountName,
					GL.QuickBooksReferenceId AS POAPAccountValue,
					--GL.QuickBooksReferenceId AS POAPAccountValue,
					--GL.AccountName AS POAPAccountName,
					ISNULL(ROP.ExtendedCost, 0) AS Amount,
					RO.VendorContactEmail,
					UPPER(AA.AddressId) AS AddressId,
					UPPER(AA.Line1) AS AddressLine1,
					UPPER(AA.Line2) AS AddressLine2,
					UPPER(AA.City) AS City,
					UPPER(AA.StateOrProvince) StateOrProvince,
					AA.PostalCode,
					AA.CountryId,
					UPPER(AA.Country) Country,
					@InvModuleName AS ModuleName,
					@InvModuleId AS ModuleId,
					RO.MasterCompanyId,
					RO.UpdatedBy,
					@ROModuleId AS ReferenceModuleId,
					@ROModuleName AS ReferenceModuleName,
					RO.QuickBooksReferenceId AS POQuickBooksReferenceId,
					RO.SyncToken
				FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = ROP.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @ROGlAccountId
					LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @ROModuleId AND AA.ReffranceId = RO.RepairOrderId AND AA.IsShippingAdd = 1
				WHERE RO.QuickBooksReferenceId IS NOT NULL AND RO.RepairOrderId = @ReferenceId AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.RepairOrderId,
					RO.RepairOrderNumber,
					VN.QuickBooksReferenceId,
					VN.VendorName,
					ROP.RepairOrderPartRecordId,
					IM.QuickBooksReferenceId,
					GL.AccountName,
					GL.QuickBooksReferenceId,
					ROP.PartNumber,
					ROP.PartDescription,
					ROP.UnitCost,
					ROP.ExtendedCost,
					RO.VendorContactEmail,
					AA.AddressId,
					AA.Line1,
					AA.Line2,
					AA.City,
					AA.StateOrProvince,
					AA.PostalCode,
					AA.CountryId,
					AA.Country,
					ROP.QuantityOrdered,
					RO.MasterCompanyId,
					RO.UpdatedBy,
					RO.QuickBooksReferenceId,
					RO.SyncToken
			END
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