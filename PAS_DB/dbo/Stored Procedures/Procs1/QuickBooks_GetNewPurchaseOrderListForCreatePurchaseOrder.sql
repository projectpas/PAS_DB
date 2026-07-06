/*************************************************************           
 ** File:   [QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder]           
 ** Author:   Abhishek Jirawla
 ** Description: Get PurchaseOrder List to Create PurchaseOrder in QuickBooks    
 ** Purpose:         
 ** Date:   07-Feb-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    07-Feb-2025   Abhishek Jirawla	Created
	2    06-MAY-2026   Moin Bloch       Added Xero PN-16011
	3    29/05/2026    Bhargav Saliya   Added Case For PO 
    4    11/06/2026    Moin Bloch       Fixed PO Creation Issue
    5    16/06/2026    Bhargav Saliya   Fixed Description
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder] 3,1,2768,13
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceModuleId INT = NULL
AS
BEGIN
	DECLARE @InvModuleId INT = 0, @POModuleId INT = 0, @POModuleName VARCHAR(200) = '', @ROModuleId INT = 0, @ROModuleName VARCHAR(200) = '';
	DECLARE @InvModuleName VARCHAR(200) = '';
	DECLARE @POGLAccountId BIGINT, @ROGLAccountId BIGINT;
	DECLARE @QBIntegrationTypeId INT=1,@NSIntegrationTypeId INT=2,@XeroIntegrationTypeId INT=3

	SELECT @QBIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'QuickBooks';
	SELECT @NSIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'NetSuite';
	SELECT @XeroIntegrationTypeId = [IntegrationTypeId] FROM [dbo].[AccountingIntegrationType] WITH(NOLOCK) WHERE [IntegrationType] = 'Xero';
	
	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'PurchaseOrder';
	SELECT @POModuleId = ModuleId, @POModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'PurchaseOrder';
	SELECT @ROModuleId = ModuleId, @ROModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'RepairOrder';

	SELECT @ROGLAccountId = GlAccountId FROM DistributionSetup WHERE DistributionMasterId = (SELECT ID FROM DistributionMaster WHERE Name = 'ReceivingROStockline') AND MasterCompanyId = 1 AND DistributionSetupCode = 'RROACCPAYABLE'
	SELECT @POGLAccountId = GlAccountId FROM DistributionSetup WHERE DistributionMasterId = (SELECT ID FROM DistributionMaster WHERE Name = 'ReceivingPOStockline') AND MasterCompanyId = 1 AND DistributionSetupCode = 'RPOACCPAYABLE'

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = @QBIntegrationTypeId) 
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
					@POModuleName AS ReferenceModuleName
				FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON PO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @POGlAccountId
					LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @POModuleId AND AA.ReffranceId = PO.PurchaseOrderId AND AA.IsShippingAdd = 1
				WHERE ISNULL(PO.QuickBooksReferenceId, '') = '' AND ISNULL(PO.IsUpdated, 0) = 1 AND PO.PurchaseOrderId = @ReferenceId AND PO.MasterCompanyId = @MasterCompanyId
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
					PO.UpdatedBy
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
					@ROModuleName AS ReferenceModuleName
				FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = ROP.ItemMasterId
					 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @ROGlAccountId
					LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @ROModuleId AND AA.ReffranceId = RO.RepairOrderId AND AA.IsShippingAdd = 1
				WHERE ISNULL(RO.QuickBooksReferenceId, '') = '' AND ISNULL(RO.IsUpdated, 0) = 1 AND RO.RepairOrderId = @ReferenceId AND RO.MasterCompanyId = @MasterCompanyId
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
					RO.UpdatedBy
			END
		END
		-- FOR Xero
		IF(ISNULL(@IntegrationTypeId, 0) = ISNULL(@XeroIntegrationTypeId, 0)) 
		BEGIN	
			IF(ISNULL(@ReferenceModuleId, 0) = ISNULL(@POModuleId, 0)) 
			BEGIN
				 SELECT PO.PurchaseOrderId AS ReferenceId,
						PO.PurchaseOrderNumber AS ReferenceNumber,
						VN.QuickBooksReferenceId AS ContactID,
						VN.VendorName AS VendorName,	
						PO.VendorContactEmail,
						PO.OpenDate,
						PO.NeedByDate,
						DeliveryAddress = (SELECT dbo.FN_ValidatePDFAddress(AA.[Line1],AA.[Line2],NULL,AA.[City],AA.[StateOrProvince],AA.[PostalCode],ISNULL(AA.[Country], ''),NULL,NULL,NULL)),
						AA.ContactPhoneNo,				
						PO.MasterCompanyId,
						PO.UpdatedBy					
					FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
						INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON PO.VendorId = VN.VendorId					
						LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @POModuleId AND AA.ReffranceId = PO.PurchaseOrderId AND AA.IsShippingAdd = 1
					WHERE ISNULL(PO.QuickBooksReferenceId, '') = ''					  
					  AND ISNULL(PO.IsUpdated, 1) = 1
					  AND (@ReferenceId IS NULL OR @ReferenceId = 0 OR PO.PurchaseOrderId = @ReferenceId) 
					  AND PO.MasterCompanyId = @MasterCompanyId
					  AND PO.IsActive = 1
					  AND PO.IsDeleted = 0
				
					SELECT PO.[PurchaseOrderId] AS ReferenceId,										
						  POP.[PurchaseOrderPartRecordId],
						   IM.[QuickBooksReferenceId] AS [ItemID],
						  POP.[ItemMasterId],
						  POP.[PartDescription] [Description],
						  POP.[UnitCost],
						  POP.[QuantityOrdered],				
						   GL.[AccountName] AS POAPAccountName,
						   GL.[QuickBooksReferenceId] AS POAPAccountValue	
					   
					FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
					   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON PO.VendorId = VN.VendorId
						LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
						LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
						 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @POGlAccountId
					WHERE ISNULL(PO.QuickBooksReferenceId, '') = '' AND 
						  ISNULL(PO.IsUpdated, 1) = 1 AND
						  (@ReferenceId IS NULL OR @ReferenceId = 0 OR PO.PurchaseOrderId = @ReferenceId) AND  
						  PO.MasterCompanyId = @MasterCompanyId AND		
						  POP.IsActive = 1 AND
						  POP.IsDeleted = 0
			END
			IF(ISNULL(@ReferenceModuleId, 0) = ISNULL(@ROModuleId, 0)) 
			BEGIN
				 SELECT RO.RepairOrderId AS ReferenceId,
						RO.RepairOrderNumber AS ReferenceNumber,
						VN.QuickBooksReferenceId AS ContactID,
						VN.VendorName AS VendorName,	
						RO.VendorContactEmail,
						RO.OpenDate,
						RO.NeedByDate,
						DeliveryAddress = (SELECT dbo.FN_ValidatePDFAddress(AA.[Line1],AA.[Line2],NULL,AA.[City],AA.[StateOrProvince],AA.[PostalCode],ISNULL(AA.[Country], ''),NULL,NULL,NULL)),
						AA.ContactPhoneNo,				
						RO.MasterCompanyId,
						RO.UpdatedBy					
					FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
						INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RO.VendorId = VN.VendorId					
						LEFT JOIN [dbo].[AllAddress] AA WITH(NOLOCK) ON AA.ModuleId = @ROModuleId AND AA.ReffranceId = RO.RepairOrderId AND AA.IsShippingAdd = 1
					WHERE ISNULL(RO.QuickBooksReferenceId, '') = ''
					  AND ISNULL(RO.IsUpdated, 1) = 1 					  
					  AND (@ReferenceId IS NULL OR @ReferenceId = 0 OR RO.RepairOrderId = @ReferenceId) 
					  AND RO.MasterCompanyId = @MasterCompanyId
					  AND RO.IsActive = 1
					  AND RO.IsDeleted = 0
				
					SELECT RO.[RepairOrderId] AS ReferenceId,										
						  ROP.[RepairOrderPartRecordId],
						   IM.[QuickBooksReferenceId] AS [ItemID],
						  ROP.[ItemMasterId],
						  ROP.[PartDescription] [Description],
						  ROP.[UnitCost],
						  ROP.[QuantityOrdered],				
						   GL.[AccountName] AS ROAPAccountName,
						   RO.[QuickBooksReferenceId] AS ROAPAccountValue						   
					FROM [dbo].[RepairOrder] RO WITH(NOLOCK)
					   INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON RO.VendorId = VN.VendorId
						LEFT JOIN [dbo].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId
						LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = ROP.ItemMasterId
						 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = @ROGlAccountId
					WHERE ISNULL(RO.QuickBooksReferenceId, '') = '' AND 
						  ISNULL(RO.IsUpdated, 1) = 1 AND 						  
						  (@ReferenceId IS NULL OR @ReferenceId = 0 OR RO.RepairOrderId = @ReferenceId) AND  
						  RO.MasterCompanyId = @MasterCompanyId AND		
						  ROP.IsActive = 1 AND
						  ROP.IsDeleted = 0
			END
		END

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetNewPurchaseOrderListForCreatePurchaseOrder'
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