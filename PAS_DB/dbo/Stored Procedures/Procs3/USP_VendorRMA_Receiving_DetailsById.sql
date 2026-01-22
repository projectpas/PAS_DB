/*************************************************************           
 ** File:   [USP_VendorRMA_Receiving_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Vendor RMA Receiving List Details
 ** Date:   06/20/2023
 ** PARAMETERS: @VendorRMAId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/20/2023   Moin Bloch     Created
*******************************************************************************
EXEC USP_VendorRMA_Receiving_DetailsById 34
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_Receiving_DetailsById] 
@VendorRMAId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
            SELECT VD.[VendorRMADetailId]
				  ,VD.[VendorRMAId]	
				  ,VD.[RMANum]
				  ,1 AS [ItemTypeId]
				  ,0 AS [QuantityRejected]          --> Default SET 0   
				  --,VD.[Qty] AS [QuantityOrdered]				  
				  ,VD.[QtyShipped] AS [QuantityOrdered]		
  			    --,[QuantityBackOrdered] = (VD.[Qty] - (SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[StockLine] SL WITH (NOLOCK) WHERE SL.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SL.[IsDeleted] = 0 AND SL.[IsParent] = 1))
				  ,[QuantityBackOrdered] = (VD.[QtyShipped] - (SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[StockLine] SL WITH (NOLOCK) WHERE SL.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SL.[IsDeleted] = 0 AND SL.[IsParent] = 1))
				  ,[QuantityDrafted] = (SELECT ISNULL(SUM(ISNULL(SD.[Quantity],0)),0) FROM [dbo].[StockLineDraft] SD WITH (NOLOCK) WHERE SD.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SD.[IsDeleted] = 0 AND SD.[IsParent] = 1 AND ISNULL(SD.[StockLineId],0) = 0)
				  ,[QuantityReceived] = (SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[StockLine] SL WITH (NOLOCK) WHERE SL.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SL.[IsDeleted] = 0 AND SL.[IsParent] = 1)
				  ,VD.[SerialNumber]
				  ,SL.[ConditionId]
				  ,SL.[Condition]
				  ,0 AS [DiscountAmount]   --> Default SET 0  
				  ,0 AS [DiscountPercent]  --> Default SET 0  
				  ,0 AS [DiscountPerUnit]  --> Default SET 0  				  
				  ,VD.[ExtendedCost]
				  ,0 AS [ForeignExchangeRate]
				  ,NULL AS [FunctionalCurrencyId] --> Default SET NULL 
				  ,SL.[GLAccountId]
				  ,SL.[GlAccountName] AS [GLAccount]
				  ,1 AS [IsParent]
				  ,NULL AS [ParentId]  --> Default SET NULL 
				  ,VD.[ItemMasterId]	
				  ,SL.[ManagementStructureId]
				  ,SL.[ManufacturerId]
				  ,SL.[Manufacturer] AS [ManufacturerName]
				  ,SL.[MasterCompanyId]
				  ,SL.[Memo]
				  ,NULL AS [NeedByDate]            --> Default SET NULL 
				  ,NULL AS [ReportCurrencyId]      --> Default SET NULL 
				  ,0 AS [SalesOrderId]               --> Default SET 0  
				  ,0 AS [WorkOrderId]              --> Default SET 0  
				  ,VD.[UnitCost]
				  ,SL.[PurchaseUnitOfMeasureId] AS [UOMId]				 
				  ,SL.[ShippingViaId] AS [ShipViaId]
                  ,'' AS [ShipVia]
				  ,HS.[StatusName] AS [Stautus]
				  ,VR.[VendorRMAStatusId] AS [StatusId]
				  ,SL.[StockLineNumber]
				  ,SL.[ShippingAccount] AS [ShippingAccountInfo]
				  ,0  AS [AltEquiPartNumberId]
                  ,'' AS [AltEquiPartNumber]
                  ,'' AS [AltEquiPartDescription]
				  ,'Stock' AS [ItemType]
				  ,'' AS [StockType]
				  ,NULL AS [RevisedPartId]
                  ,NULL AS [RevisedPartNumber]
				  ,SL.AircraftTailNumber AS [ACTailNum]
				  ,0  AS [IsAsset]
				  ,'' AS [ManufacturerPN]
				  ,'' AS [AssetClass]
                  ,'' AS [AssetModel]
				  ,0  AS [AssetAcquisitionTypeId]
				  ,0 AS [IsIntangible]
                  ,0 AS [IsCalibration] 
                  ,0 AS [CalibrationDays]
				  ,SL.[ConditionId] AS [PartConditionId]
				  ,0  AS [LotId]
				  ,'' AS [LotNumber]     
				  ,MS.[LastMSLevel]
				  ,MS.[AllMSlevels]
				  ,VD.[CreatedBy]
				  ,VD.[UpdatedBy]				  
				  ,VD.[CreatedDate]
				  ,VD.[UpdatedDate]
			  FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
			  INNER JOIN [dbo].[VendorRMA] VR WITH(NOLOCK) ON VD.[VendorRMAId] = VR.[VendorRMAId]			  
			  INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
			  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON VD.[ItemMasterId] = IM.[ItemMasterId]	
			   LEFT JOIN [dbo].[VendorRMAHeaderStatus] HS WITH (NOLOCK) ON VR.[VendorRMAStatusId] = HS.[VendorRMAStatusId]
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.ReferenceID = VD.StockLineId AND MS.ModuleID = 2			
			  WHERE VD.[VendorRMAId] = @VendorRMAId;
	END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			--ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_Receiving_DetailsById]'			
			,@ProcedureParameters VARCHAR(3000) = '@VendorRMAId = ''' + CAST(ISNULL(@VendorRMAId, '') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END