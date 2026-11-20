
/*************************************************************
 ** File:   [USP_PublicApi_GetStocklineList]
 ** Author: Moin Bloch
 ** Description: 4.7 GET /api/v1/stocklines. Rows of the PAS Stockline List, limited to the credential employee's management structures.
 **              @OnHandOnly = 1 is the PAS "Qty OH" view (QuantityOnHand > 0, the screen default), 0 is "All".
 **              @PartNumber / @SerialNumber match anywhere in the value; @StockLineNumber / @Condition are exact;
 **              @ItemType is Stock, Non-Stock or Asset (as shown in PAS).
 **              @ReceivedDateFrom / @ReceivedDateTo: received date range, both inclusive (dates only).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/stocklines
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added received date filter (@ReceivedDateFrom / @ReceivedDateTo)
    3    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetStocklineList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetStocklineList]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT,
    @PageNumber      INT,
    @PageSize        INT,
    @OnHandOnly      BIT          = 1,
    @PartNumber      VARCHAR(100) = NULL,
    @StockLineNumber VARCHAR(100) = NULL,
    @SerialNumber    VARCHAR(100) = NULL,
    @Condition       VARCHAR(100) = NULL,
    @ItemType        VARCHAR(20)  = NULL,
    @ReceivedDateFrom DATE        = NULL,
    @ReceivedDateTo   DATE        = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @MSModuleId INT = 2; -- Stockline (StocklineManagementStructureDetails.ModuleID), as in ProcStockList

        ;WITH Filtered AS
        (
            SELECT stl.[StockLineId],
                   CASE WHEN ISNULL(stl.[IsAsset], 0) = 1 THEN 'Asset' WHEN ISNULL(stl.[IsNonStock], 0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS [ItemType]
            FROM [dbo].[Stockline] stl WITH (NOLOCK)
            WHERE stl.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(stl.[IsActive], 1) = 1
              AND ISNULL(stl.[IsParent], 0) = 1
              AND ISNULL(stl.[IsDeleted], 0) = 0
              AND (@OnHandOnly = 0 OR ISNULL(stl.[QuantityOnHand], 0) > 0)
              AND EXISTS (SELECT 1 FROM [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK)
                          WHERE MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = stl.[StockLineId])
              AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                          INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
                          WHERE RMS.[EntityStructureId] = stl.[ManagementStructureId])
              AND (@PartNumber IS NULL OR stl.[PartNumber] LIKE '%' + @PartNumber + '%')
              AND (@StockLineNumber IS NULL OR stl.[StockLineNumber] = @StockLineNumber)
              AND (@SerialNumber IS NULL OR stl.[SerialNumber] LIKE '%' + @SerialNumber + '%')
              AND (@Condition IS NULL OR stl.[Condition] = @Condition)
              AND (@ReceivedDateFrom IS NULL OR stl.[ReceivedDate] >= @ReceivedDateFrom)
              AND (@ReceivedDateTo IS NULL OR stl.[ReceivedDate] < DATEADD(DAY, 1, @ReceivedDateTo))
        ),
        Paged AS
        (
            SELECT F.[StockLineId], F.[ItemType], COUNT(1) OVER () AS [TotalRecords]
            FROM Filtered F
            WHERE (@ItemType IS NULL OR F.[ItemType] = @ItemType)
            ORDER BY F.[StockLineId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            stl.[StockLineNumber],
            stl.[ControlNumber],
            stl.[IdNumber],
            stl.[PartNumber],
            stl.[PNDescription] AS [PartDescription],
            stl.[Manufacturer],
            stl.[RevicedPNNumber] AS [RevisedPartNumber],
            P.[ItemType],
            stl.[ItemGroup],
            CASE WHEN stl.[IsPMA] = 1 THEN 'PMA' WHEN stl.[IsDER] = 1 THEN 'DER' WHEN stl.[OEM] = 1 THEN 'OEM' ELSE NULL END AS [PNSource],
            stl.[Condition],
            UOM.[ShortName] AS [UnitOfMeasure],
            stl.[SerialNumber],
            ISNULL(stl.[QuantityOnHand], 0) AS [QuantityOnHand],
            ISNULL(stl.[QuantityAvailable], 0) AS [QuantityAvailable],
            ISNULL(stl.[QuantityReserved], 0) AS [QuantityReserved],
            ISNULL(stl.[QuantityIssued], 0) AS [QuantityIssued],
            stl.[UnitCost],
            stl.[Site],
            stl.[Warehouse],
            stl.[Location],
            stl.[Shelf],
            stl.[Bin],
            MSD.[Level1Name] AS [LegalEntity],
            MSD.[Level2Name] AS [BusinessUnit],
            MSD.[Level3Name] AS [Division],
            MSD.[Level4Name] AS [Department],
            stl.[ReceivedDate],
            stl.[ReceiverNumber],
            stl.[PurchaseOrderNumber],
            stl.[RepairOrderNumber],
            stl.[WorkOrderNumber],
            CAST(ISNULL(stl.[IsCustomerStock], 0) AS BIT) AS [IsCustomerStock],
            stl.[CustomerName],
            stl.[TraceableToName],
            stl.[OwnerName],
            stl.[ObtainFromName],
            stl.[TagDate],
            stl.[TagType],
            stl.[TaggedByName],
            stl.[ExpirationDate],
            stl.[PartCertificationNumber],
            stl.[CertifiedBy],
            stl.[CertifiedDate],
            stl.[LotNumber],
            stl.[BatchNumber],
            stl.[ManufacturerLotNumber],
            stl.[ShippingReference],
            stl.[CreatedDate],
            stl.[UpdatedDate],
            P.[TotalRecords]
        FROM Paged P
        INNER JOIN [dbo].[Stockline] stl WITH (NOLOCK) ON stl.[StockLineId] = P.[StockLineId]
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = stl.[StockUnitOfMeasureId]
        -- Plain level names (AllMSlevels is HTML for the PAS screen).
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name] FROM [dbo].[StocklineManagementStructureDetails] M WITH (NOLOCK)
                     WHERE M.[ModuleID] = @MSModuleId AND M.[ReferenceID] = stl.[StockLineId]) MSD
        ORDER BY P.[StockLineId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetStocklineList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@OnHandOnly, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@PartNumber, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@StockLineNumber, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@SerialNumber, '') AS VARCHAR(100))
                                                   + '@Parameter9 = ''' + CAST(ISNULL(@Condition, '') AS VARCHAR(100))
                                                   + '@Parameter10 = ''' + CAST(ISNULL(@ItemType, '') AS VARCHAR(100))
                                                   + '@Parameter11 = ''' + CAST(ISNULL(@ReceivedDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter12 = ''' + CAST(ISNULL(@ReceivedDateTo, '') AS VARCHAR(100))
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