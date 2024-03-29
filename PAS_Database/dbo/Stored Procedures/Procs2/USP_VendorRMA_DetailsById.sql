/*************************************************************           
 ** File:   [USP_VendorRMA_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Vendor RMA Details
 ** Date:   06/15/2023
 ** PARAMETERS: @VendorRMAId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/15/2023   Moin Bloch     Created
	2    29-03-2024   Shrey Chandegara            Add RevisedStocklineId
*******************************************************************************
EXEC USP_VendorRMA_DetailsById 113,2
*******************************************************************************/
CREATE    PROCEDURE [dbo].[USP_VendorRMA_DetailsById] 
@VendorRMAId BIGINT,
@Opr INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		IF(@Opr = 1)
		BEGIN
			SELECT VR.[VendorRMAId]
				  ,VR.[RMANumber]
				  ,VR.[VendorId]
				  ,VO.[VendorName]
			      ,VO.[VendorCode]
				  ,VR.[OpenDate]
				  ,VR.[VendorRMAStatusId]
				  ,VR.[RequestedById]	
				  ,HS.[StatusName] 'VendorRMAStatus'
				  ,VR.[Notes]
				  ,VR.[MasterCompanyId]
			  FROM [dbo].[VendorRMA] VR WITH(NOLOCK) 
			  INNER JOIN [dbo].[Vendor] VO WITH (NOLOCK) ON VR.[VendorId] = VO.[VendorId]
			   LEFT JOIN [dbo].[VendorRMAHeaderStatus] HS WITH (NOLOCK) ON VR.[VendorRMAStatusId] = HS.[VendorRMAStatusId]
			  WHERE VR.[VendorRMAId] = @VendorRMAId;
		END
		IF(@Opr = 2)
		BEGIN
			SELECT VD.[VendorRMADetailId]
				  ,VD.[VendorRMAId]
				  ,VD.[RMANum]
				  ,VD.[StockLineId]
				  ,VD.[RevisedStocklineId]
				  ,SL.[StockLineNumber]
				  ,SL.[IdNumber]
				  ,SL.[ControlNumber]
			      ,SL.[ReceivedDate]
				  ,VD.[ReferenceId]
				  ,VD.[ItemMasterId]				  
				  ,IM.[partnumber] 'PartNumber'
			      ,IM.[PartDescription]
				  ,VD.[SerialNumber]
				  ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END 'ReferenceNumber' 
				  ,VD.[Qty]
				  ,(SL.[QuantityAvailable] + VD.[Qty]) AS OriginalQty
				  ,VD.[UnitCost]
				  ,VD.[ExtendedCost]
				  ,VD.[VendorRMAReturnReasonId]
				  ,RR.[Reason]
				  ,VD.[VendorRMAStatusId]
				  ,RS.[VendorRMAStatus]
				  ,VD.[VendorShippingAddressId]
				  ,VD.[Notes]	
				  ,(SELECT TOP 1 ISNULL(SUM(SP.[QtyShipped]), 0) FROM [dbo].[RMAShippingItem] SP WITH(NOLOCK)
					INNER JOIN [dbo].[RMAShipping] RS ON SP.[RMAShippingId] = RS.[RMAShippingId] 
					WHERE RS.[VendorRMAId] = @VendorRMAId AND SP.[VendorRMADetailId] = VD.[VendorRMADetailId]) AS [QtyShipped]	
			  FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
			  INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
			  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON VD.[ItemMasterId] = IM.[ItemMasterId]	
			  LEFT JOIN  [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId]
		      LEFT JOIN  [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
			  LEFT JOIN  [dbo].[VendorRMAReturnReason] RR WITH (NOLOCK) ON VD.[VendorRMAReturnReasonId] = RR.[VendorRMAReturnReasonId]
			  LEFT JOIN  [dbo].[VendorRMAStatus] RS WITH (NOLOCK) ON VD.[VendorRMAStatusId] = RS.[VendorRMAStatusId]			   
			  WHERE VD.[VendorRMAId] = @VendorRMAId;
		END	
	END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_DetailsById]'			
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