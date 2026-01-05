/*************************************************************           
 ** File:   [USP_GetVendorRFQPurchaseOrderDetails]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for RFQ PO Header Data    
 ** Purpose:         
 ** Date:   22-April-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    22-April-2025   Bhargav Saliya		Created
	2    28-Aug-2025     Devendra Shekh		Modified (added SourceBy, MarketplaceRef)
	3    02-01-2026      Bhargav Saliya     Added New Field :- CustomerRFQNo
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorRFQPurchaseOrderDetails]
    @VendorRFQPurchaseOrderId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @poModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) Where ModuleName = 'PurchaseOrder' AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0 )
		DECLARE @MSModuleId BIGINT = (SELECT ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'VendorRFQPOHeader');

		;WITH RFQData AS
		(
			SELECT 
			    vpop.VendorRFQPurchaseOrderId,
				MIN(rfq.RfqId) AS CustomerRFQNo
			FROM dbo.VendorRFQPurchaseOrderPart vpop WITH (NOLOCK)
			INNER JOIN dbo.VendorRFQPart rfqPart WITH (NOLOCK) ON rfqPart.ReferenceId = vpop.PurchaseOrderId AND rfqPart.ModuleId = @poModuleId
			INNER JOIN dbo.ILSRFQPart ilsPart WITH (NOLOCK) ON rfqPart.ILSRFQDetailId = ilsPart.ILSRFQDetailId INNER JOIN dbo.CustomerRfq rfq WITH (NOLOCK) ON ilsPart.CustomerRfqId = rfq.CustomerRfqId
			GROUP BY vpop.VendorRFQPurchaseOrderId
		)

		SELECT TOP 1
			po.VendorRFQPurchaseOrderId,
			po.VendorRFQPurchaseOrderNumber,
			po.OpenDate,
			po.ClosedDate,
			po.NeedByDate,
			po.PriorityId,
			po.Priority,
			po.VendorId,
			po.VendorName,
			po.VendorCode,
			po.VendorContactId,
			po.VendorContact,
			po.VendorContactPhone,
			po.CreditTermsId,
			po.Terms,
			po.CreditLimit,
			po.RequestedBy,
			po.Requisitioner,
			po.StatusId,
			po.Status,
			po.StatusChangeDate,
			po.Resale,
			po.DeferredReceiver,
			po.Memo,
			po.Notes,
			po.ManagementStructureId,
			po.Level1,
			po.Level2,
			po.Level3,
			po.Level4,
			po.PDFPath,
			po.MasterCompanyId,
			po.CreatedBy,
			po.CreatedDate,
			po.UpdatedBy,
			po.UpdatedDate,
			po.IsDeleted,
			po.IsActive,
			ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
			ISNULL(po.VendorReference, '') AS VendorReference,
			po.FreightBilingMethodId,
			po.TotalFreight,
			po.ChargesBilingMethodId,
			po.TotalCharges,
			CASE WHEN po.FunctionalCurrencyId > 0 THEN po.FunctionalCurrencyId ELSE 0 END AS FunctionalCurrencyId,
			CASE WHEN po.ReportCurrencyId > 0 THEN po.ReportCurrencyId ELSE 0 END AS ReportCurrencyId,
			CASE WHEN po.ForeignExchangeRate > 0 THEN po.ForeignExchangeRate ELSE 0 END AS ForeignExchangeRate,
			ISNULL(po.SourceBy, '') AS SourceBy,
			ISNULL(po.MarketplaceRef, '') AS MarketplaceRef,
			ISNULL(rfq.CustomerRFQNo, '') AS CustomerRFQNo
		FROM [dbo].[VendorRFQPurchaseOrder] po WITH(NOLOCK)
		LEFT JOIN [dbo].[PurchaseOrderManagementStructureDetails] msd WITH(NOLOCK) ON po.VendorRFQPurchaseOrderId = msd.ReferenceID AND msd.ModuleID = @MSModuleId 
		LEFT JOIN RFQData rfq ON rfq.VendorRFQPurchaseOrderId = po.VendorRFQPurchaseOrderId
		WHERE po.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId
	END TRY
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRFQPurchaseOrderDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPurchaseOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END