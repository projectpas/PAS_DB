/*************************************************************           
 ** File:   [USP_GetPOHeaderDetails]           
 ** Author:   [Ayushi Patel]
 ** Description: This stored procedure retrieves the purchase order header details.
 ** Date:   [01/04/2025]      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    01-04-2025     Ayushi Patel			      Created
    2    28-08-2025     Devendra Shekh			      Modified (added SourceBy, MarketplaceRef)
	3    08-12-2025     Sahdev Saliya                 Added New Field :- VendorRFQPurchaseOrderNumber

	USP_GetPOHeaderDetails 12345
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetPOHeaderDetails]
    @PurchaseOrderId BIGINT
AS

BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        BEGIN 
		declare @moduleId int = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'POHeader')
            SELECT TOP 1
                po.PurchaseOrderId,
                po.PurchaseOrderNumber,
                po.PriorityId,
                po.Priority,
                po.OpenDate,
                po.NeedByDate,
                po.StatusId,
                po.Status,
                po.VendorId,
                po.VendorName,
                po.VendorCode,
                po.VendorContactId,
                po.VendorContact,
                po.VendorContactPhone,
                po.VendorContactEmail,
                po.CreditTermsId,
                po.Terms,
                po.CreditLimit,
                po.RequestedBy,
                po.Requisitioner,
                po.ClosedDate,
                po.ApproverId,
                po.ApprovedBy,
                po.DateApproved,
                po.Resale,
                po.DeferredReceiver,
                po.ManagementStructureId,
                po.MasterCompanyId,
                po.POMemo,
                po.Notes,
                ISNULL(po.IsActive, 0) AS IsActive,
				ISNULL(po.IsDeleted, 0) AS IsDeleted,
                po.CreatedDate,
                po.UpdatedDate,
                po.CreatedBy,
                po.UpdatedBy,
                po.Level1,
                po.Level2,
                po.Level3,
                po.Level4,
                po.IsEnforce,
                Ve.CurrencyId,
                ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
                ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
                ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
                ISNULL(po.IsLotAssigned, 0) AS IsLotAssigned,
                ISNULL(po.LotId, 0) AS LotId,
                ISNULL(po.FunctionalCurrencyId, 0) AS FunctionalCurrencyId,
                ISNULL(po.ReportCurrencyId, 0) AS ReportCurrencyId,
                ISNULL(po.ForeignExchangeRate, 0) AS ForeignExchangeRate,
                ISNULL(po.SourceBy, '') AS SourceBy,
                ISNULL(po.MarketplaceRef, '') AS MarketplaceRef,
				VRFQ.VendorRFQPurchaseOrderNumber
            FROM dbo.PurchaseOrder po WITH (NOLOCK)
            LEFT JOIN dbo.PurchaseOrderManagementStructureDetails msd WITH (NOLOCK)
                ON po.PurchaseOrderId = msd.ReferenceID AND msd.ModuleID = @moduleId
            LEFT JOIN dbo.Vendor Ve WITH (NOLOCK)
                ON po.VendorId = Ve.VendorId
			LEFT JOIN dbo.VendorRFQPurchaseOrder VRFQ WITH (NOLOCK) ON po.VendorRFQPurchaseOrderId = VRFQ.VendorRFQPurchaseOrderId
				WHERE po.PurchaseOrderId = @PurchaseOrderId;
        END
        COMMIT TRANSACTION;
    END TRY    
    BEGIN CATCH      
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_GetPOHeaderDetails';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@PurchaseOrderId = ' + CAST(ISNULL(@PurchaseOrderId, '') AS VARCHAR);
        DECLARE @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
             @DatabaseName = @DatabaseName,
             @AdhocComments = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName = @ApplicationName,
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected error occurred. Please contact support with error number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END;