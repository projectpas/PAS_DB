/*************************************************************           
 ** File:   [USP_GetROHeaderDetails]          
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used RO Header Details By RepairOrderId
 ** Purpose:         
 ** Date:   09/04/2025     
          
 ** PARAMETERS: @RepairOrderId int
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/04/2025  Ayushi Patel     Created
    2    16/04/2025  Vishal Suthar    Added IsEnforcePickTicket flag

 EXEC [USP_GetROHeaderDetails] 2554
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetROHeaderDetails]
    @RepairOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
	 DECLARE @RoHeaderModuleId INT = (select ManagementStructureModuleId from DBO.ManagementStructureModule WITH (NOLOCK) where ModuleName = 'ROHeader');
        SELECT
            ro.RepairOrderId,
            ro.RepairOrderNumber,
            ro.OpenDate,
            ro.ClosedDate,
            ro.NeedByDate,
            ro.PriorityId,
            ro.Priority,
            ro.VendorId,
            ro.VendorName,
            ro.VendorCode,
            ro.VendorContactId,
            ro.VendorContact,
            ro.VendorContactPhone,
            ro.VendorContactEmail,
            ro.CreditLimit,
            ro.CreditTermsId,
            ro.Terms,
            ro.RequisitionerId AS RequestedBy,
            ro.RequisitionerId,
            ro.Requisitioner,
            ro.ApproverId,
            ro.ApprovedBy,
            ro.ApprovedDate,
            ro.StatusId,
            ro.Status,
            ro.Resale,
            ro.DeferredReceiver,
            ro.ManagementStructureId,
            ro.MasterCompanyId,
            ro.IsActive,
            ro.IsDeleted,
            ro.CreatedDate,
            ro.UpdatedDate,
            ro.CreatedBy,
            ro.UpdatedBy,
            ro.RoMemo,
            ro.Notes,
            ro.Level1,
            ro.Level2,
            ro.Level3,
            ro.Level4,
            ro.IsEnforce,
            Ve.CurrencyId,
            ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
            ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
            ISNULL(msd.AllMSlevels, '') AS AllMSlevels,
            ro.IsLotAssigned,
            ro.LotId,
            ISNULL(ro.FunctionalCurrencyId, 0) AS FunctionalCurrencyId,
            ISNULL(ro.ReportCurrencyId, 0) AS ReportCurrencyId,
            ISNULL(ro.ForeignExchangeRate, 0) AS ForeignExchangeRate,
			ISNULL(ro.IsEnforcePickTicket, 0) AS IsEnforcePickTicket
        FROM dbo.RepairOrder ro WITH (NOLOCK)
        LEFT JOIN dbo.RepairOrderManagementStructureDetails msd WITH (NOLOCK)
            ON ro.RepairOrderId = msd.ReferenceID 
           AND msd.ModuleID = @RoHeaderModuleId 
        LEFT JOIN dbo.Vendor Ve WITH (NOLOCK)
            ON ro.VendorId = Ve.VendorId

        WHERE ro.RepairOrderId = @RepairOrderId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END