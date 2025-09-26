/*************************************************************
 ** File:  [usp_SaveVendorRFQPartDetails] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used save Vendor RFQ Part Details
 ** Date:  27-Aug-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    27-Aug-2025		Devendra Shekh		  Created
    2    28-Aug-2025		Devendra Shekh		  Modified (added ModuleRef Related Changes)
    3    25-Sep-2025		Devendra Shekh		  Modified (Added Merge Insert/Update Changes)

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_SaveVendorRFQPartDetails] (
	@tbl_VendorRFQPartType VendorRFQPartType READONLY,
	@EmployeeId  BIGINT = NULL
)
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		DECLARE @POModuleId INT, @RFQPOModuleId INT, @ReferenceNumber VARCHAR(256) = '';
		SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'PurchaseOrder';
		SELECT @RFQPOModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'VendorRFQPurchaseOrder';

		IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL
		BEGIN
			DROP TABLE #tmpResult
		END
		
		--IF OBJECT_ID(N'tempdb..#tmpVendorRFQPart') IS NOT NULL
		--BEGIN
		--	DROP TABLE #tmpVendorRFQPart
		--END

		--SELECT VRFQ.* INTO #tmpVendorRFQPart
		--FROM [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK) 
		--INNER JOIN @tbl_VendorRFQPartType TMP ON VRFQ.ItemId = TMP.ItemId AND VRFQ.ItemSupplierPartId = TMP.ItemSupplierPartId AND VRFQ.ILSRFQDetailId = TMP.ILSRFQDetailId
	
		--DELETE VR FROM [dbo].[VendorRFQPart] VR INNER JOIN @tbl_VendorRFQPartType TMP ON VR.ItemId = TMP.ItemId AND VR.ItemSupplierPartId = TMP.ItemSupplierPartId AND VR.ILSRFQDetailId = TMP.ILSRFQDetailId;

		--INSERT INTO [dbo].[VendorRFQPart] ( [ILSRFQDetailId], [ItemId], [ItemSupplierPartId], [VendorName], [VendorId], [Email], [Phone], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure], [Price], [PriceType], [LeadTime], [Qty], [RequestedQty], [MinQuantity],
		--		[Condition], [Address1], [Address2], [City], [Country], [PostalCode], [StateProvince], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive]
		--)
		--SELECT	[ILSRFQDetailId], [ItemId], [ItemSupplierPartId], [VendorName], [VendorId], [Email], [Phone], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure], [Price], [PriceType], [LeadTime], [Qty], [RequestedQty], [MinQuantity],
		--		[Condition], [Address1], [Address2], [City], [Country], [PostalCode], [StateProvince], [MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(), 0, 1
		--FROM @tbl_VendorRFQPartType;

		--UPDATE VRFQ
		--SET
		--	VRFQ.ModuleId = TMP.ModuleId,
		--	VRFQ.ReferenceId = TMP.ReferenceId
		--FROM [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK) 
		--INNER JOIN #tmpVendorRFQPart TMP ON VRFQ.ItemId = TMP.ItemId AND VRFQ.ItemSupplierPartId = TMP.ItemSupplierPartId AND VRFQ.ILSRFQDetailId = TMP.ILSRFQDetailId

		MERGE INTO [dbo].[VendorRFQPart] AS VR
		USING @tbl_VendorRFQPartType AS TMP
			ON  VR.ItemId = TMP.ItemId
			AND VR.ItemSupplierPartId = TMP.ItemSupplierPartId
			AND VR.ILSRFQDetailId = TMP.ILSRFQDetailId
			AND VR.MasterCompanyId = TMP.MasterCompanyId

		-- If record exists, update it
		WHEN MATCHED THEN
			UPDATE SET 
				  VR.VendorName       = TMP.VendorName,
				  VR.VendorId         = TMP.VendorId,
				  VR.Email            = TMP.Email,
				  VR.Phone            = TMP.Phone,
				  VR.PartNumber       = TMP.PartNumber,
				  VR.RfqId            = TMP.RfqId,
				  VR.Description      = TMP.Description,
				  VR.AltPartNumber    = TMP.AltPartNumber,
				  VR.ReferenceNumber  = TMP.ReferenceNumber,
				  VR.Traceability     = TMP.Traceability,
				  VR.UnitOfMeasure    = TMP.UnitOfMeasure,
				  VR.Price            = TMP.Price,
				  VR.PriceType        = TMP.PriceType,
				  VR.LeadTime         = TMP.LeadTime,
				  VR.Qty              = TMP.Qty,
				  VR.RequestedQty     = TMP.RequestedQty,
				  VR.MinQuantity      = TMP.MinQuantity,
				  VR.[Condition]      = TMP.[Condition],
				  VR.Address1         = TMP.Address1,
				  VR.Address2         = TMP.Address2,
				  VR.City             = TMP.City,
				  VR.Country          = TMP.Country,
				  VR.PostalCode       = TMP.PostalCode,
				  VR.StateProvince    = TMP.StateProvince,
				  VR.UpdatedBy        = TMP.UpdatedBy,
				  VR.UpdatedDate      = GETUTCDATE()

		-- If record doesn’t exist, insert it
		WHEN NOT MATCHED BY TARGET THEN
			INSERT ([ILSRFQDetailId], [ItemId], [ItemSupplierPartId], [VendorName], [VendorId], [Email], [Phone], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure], [Price], [PriceType], [LeadTime], 
					[Qty], [RequestedQty], [MinQuantity], [Condition], [Address1], [Address2], [City], [Country], [PostalCode], [StateProvince], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive]
			)
			VALUES (TMP.[ILSRFQDetailId], TMP.[ItemId], TMP.[ItemSupplierPartId], TMP.[VendorName], TMP.[VendorId], TMP.[Email], TMP.[Phone], TMP.[PartNumber], TMP.[RfqId], TMP.[Description], TMP.[AltPartNumber], TMP.[ReferenceNumber], TMP.[Traceability], TMP.[UnitOfMeasure], TMP.[Price], TMP.[PriceType], TMP.[LeadTime], 
					TMP.[Qty], TMP.[RequestedQty], TMP.[MinQuantity], TMP.[Condition], TMP.[Address1], TMP.[Address2], TMP.[City], TMP.[Country], TMP.[PostalCode], TMP.[StateProvince], TMP.[MasterCompanyId], TMP.[CreatedBy], TMP.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), 0, 1
			);

		SELECT	VRFQ.[VendorRFQPartId], VRFQ.[ILSRFQDetailId], VRFQ.[ItemId], VRFQ.[ItemSupplierPartId], VRFQ.[VendorName], VRFQ.[VendorId], VRFQ.[Email], VRFQ.[Phone], VRFQ.[PartNumber], VRFQ.[RfqId], VRFQ.[Description], VRFQ.[AltPartNumber], VRFQ.[ReferenceNumber], VRFQ.[Traceability], VRFQ.[UnitOfMeasure], VRFQ.[Price], VRFQ.[PriceType], VRFQ.[LeadTime], VRFQ.[Qty], VRFQ.[RequestedQty], VRFQ.[MinQuantity],
				VRFQ.[Condition], VRFQ.[Address1], VRFQ.[Address2], VRFQ.[City], VRFQ.[Country], VRFQ.[PostalCode], VRFQ.[StateProvince], VRFQ.[MasterCompanyId], VRFQ.[CreatedBy], VRFQ.[UpdatedBy], VRFQ.[CreatedDate], VRFQ.[UpdatedDate], VRFQ.[IsDeleted], VRFQ.[IsActive],
				VRFQ.[VendorName] as SupplierName, IM.ItemMasterId, VRFQ.ModuleId, VRFQ.ReferenceId, @ReferenceNumber AS ModuleReferenceNumber
		INTO #tmpResult
		FROM [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK) 
		INNER JOIN @tbl_VendorRFQPartType TMP ON VRFQ.ItemId = TMP.ItemId AND VRFQ.ItemSupplierPartId = TMP.ItemSupplierPartId AND VRFQ.ILSRFQDetailId = TMP.ILSRFQDetailId AND VRFQ.MasterCompanyId = TMP.MasterCompanyId
		LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON LOWER(TRIM(VRFQ.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) AND VRFQ.[MasterCompanyId] = IM.[MasterCompanyId] AND IM.IsActive = 1 AND IM.IsDeleted = 0
	
		UPDATE TMP
		SET
			TMP.ModuleReferenceNumber = CASE	WHEN TMP.ModuleId = @POModuleId THEN PO.PurchaseOrderNumber
												WHEN TMP.ModuleId = @RFQPOModuleId THEN VPO.VendorRFQPurchaseOrderNumber
												ELSE '' END
		FROM #tmpResult TMP
		LEFT JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON TMP.ReferenceId = PO.PurchaseOrderId AND TMP.[MasterCompanyId] = PO.[MasterCompanyId] AND TMP.ModuleId = @POModuleId 
		LEFT JOIN [dbo].[VendorRFQPurchaseOrder] VPO WITH(NOLOCK) ON TMP.ReferenceId = VPO.VendorRFQPurchaseOrderId AND TMP.[MasterCompanyId] = VPO.[MasterCompanyId] AND TMP.ModuleId = @RFQPOModuleId 

		SELECT * FROM #tmpResult;

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_SaveVendorRFQPartDetails' 
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