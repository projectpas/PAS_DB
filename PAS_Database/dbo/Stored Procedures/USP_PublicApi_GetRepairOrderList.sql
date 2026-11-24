
/*************************************************************
 ** File:   [USP_PublicApi_GetRepairOrderList]
 ** Author: Moin Bloch
 ** Description: 4.21 RO headers, oldest first. Limited to the management structures of the employee's roles, like
 **              ProcGetRoList. @Status is the RO status (Open, Pending, Fulfilling, Closed, Canceled).
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 **              PartsCount / TotalPartsCost count main lines only (split lines repeat the quantity).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/repairorders (headers)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetRepairOrderList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetRepairOrderList]
    @MasterCompanyId   INT,
    @EmployeeId        BIGINT,
    @PageNumber        INT,
    @PageSize          INT,
    @RepairOrderNumber VARCHAR(50) = NULL,
    @Status            VARCHAR(50) = NULL,
    @OpenDateFrom      DATE = NULL,
    @OpenDateTo        DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @MSModuleId INT = 24; -- Repair Order (RepairOrderManagementStructureDetails.ModuleID), as in ProcGetRoList
        DECLARE @ShipViaModuleId BIGINT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'RepairOrder' AND [CodePrefix] = 'RO');

        ;WITH PagedRO AS
        (
            SELECT RO.[RepairOrderId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[RepairOrder] RO WITH (NOLOCK)
            WHERE RO.[MasterCompanyId] = @MasterCompanyId
              AND RO.[IsDeleted] = 0
              AND (@RepairOrderNumber IS NULL OR RO.[RepairOrderNumber] = @RepairOrderNumber)
              AND (@Status IS NULL OR RO.[Status] = @Status)
              AND (@OpenDateFrom IS NULL OR RO.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR RO.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
              AND EXISTS (SELECT 1 FROM [dbo].[RepairOrderManagementStructureDetails] MSD WITH (NOLOCK)
                          WHERE MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = RO.[RepairOrderId])
              AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                          INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
                          WHERE RMS.[EntityStructureId] = RO.[ManagementStructureId])
            ORDER BY RO.[RepairOrderId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            RO.[RepairOrderId],   -- used by the API to attach parts, freight and charges; not returned to clients
            RO.[RepairOrderNumber],
            RO.[Status],
            RO.[Priority],
            RO.[OpenDate],
            RO.[NeedByDate],
            RO.[ClosedDate],
            RO.[ApprovedDate],
            NULLIF(LTRIM(RTRIM(RO.[ApprovedBy])), '') AS [ApprovedBy],
            RO.[Requisitioner],
            RO.[VendorCode],
            RO.[VendorName],
            RO.[VendorContact],
            RO.[VendorContactPhone],
            RO.[VendorContactEmail],
            RO.[Terms] AS [CreditTerms],
            RO.[CreditLimit],
            FC.[Code] AS [FunctionalCurrency],
            RC.[Code] AS [ReportCurrency],
            CASE WHEN RO.[ForeignExchangeRate] > 0 THEN RO.[ForeignExchangeRate] ELSE NULL END AS [ForeignExchangeRate],
            CAST(ISNULL(RO.[Resale], 0) AS BIT) AS [IsResale],
            CAST(ISNULL(RO.[DeferredReceiver], 0) AS BIT) AS [IsDeferredReceiver],
            ISNULL(PP.[PartsCount], 0) AS [PartsCount],
            ISNULL(PP.[TotalPartsCost], 0) AS [TotalPartsCost],
            ISNULL(RO.[TotalFreight], 0) AS [TotalFreight],
            ISNULL(RO.[TotalCharges], 0) AS [TotalCharges],
            SV.[ShipVia],
            SV.[ShippingTerms],
            SV.[ShippingAccountNo],
            MSD.[Level1Name] AS [LegalEntity],
            MSD.[Level2Name] AS [BusinessUnit],
            MSD.[Level3Name] AS [Division],
            MSD.[Level4Name] AS [Department],
            RO.[CreatedDate],
            RO.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedRO P
        INNER JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON RO.[RepairOrderId] = P.[RepairOrderId]
        LEFT JOIN [dbo].[Currency] FC WITH (NOLOCK) ON FC.[CurrencyId] = RO.[FunctionalCurrencyId]
        LEFT JOIN [dbo].[Currency] RC WITH (NOLOCK) ON RC.[CurrencyId] = RO.[ReportCurrencyId]
        OUTER APPLY (SELECT TOP (1) S.[ShipVia], S.[ShippingTerms], S.[ShippingAccountNo]
                     FROM [dbo].[AllShipVia] S WITH (NOLOCK)
                     WHERE S.[ReferenceId] = RO.[RepairOrderId] AND S.[ModuleId] = @ShipViaModuleId
                     ORDER BY S.[AllShipViaId] DESC) SV
        -- Plain level names (AllMSlevels is HTML for the PAS screen).
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[RepairOrderManagementStructureDetails] M WITH (NOLOCK)
                     WHERE M.[ModuleID] = @MSModuleId AND M.[ReferenceID] = RO.[RepairOrderId]) MSD
        OUTER APPLY (
            SELECT COUNT(1) AS [PartsCount], SUM(ROP.[ExtendedCost]) AS [TotalPartsCost]
            FROM [dbo].[RepairOrderPart] ROP WITH (NOLOCK)
            WHERE ROP.[RepairOrderId] = RO.[RepairOrderId] AND ISNULL(ROP.[IsDeleted], 0) = 0 AND ISNULL(ROP.[IsParent], 0) = 1
        ) PP
        ORDER BY RO.[RepairOrderId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetRepairOrderList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@RepairOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END