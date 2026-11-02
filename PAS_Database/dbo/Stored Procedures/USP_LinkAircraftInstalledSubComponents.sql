
/*************************************************************
 ** File:   [USP_LinkAircraftInstalledSubComponents]
 ** Description: Links the stocklines of the installed components of an Aircraft / Engine as Sub Components of the aircraft / engine stockline.
                 Used (1) when the aircraft / engine is received (usp_SaveTurnInAircraftMaterials) because components can be installed before
                 the aircraft / engine has a stockline, and (2) to back-fill the existing data (@RegistryId NULL = every aircraft / engine).
                 Whole stockline is linked (no split, no qty change). A stockline is skipped when it is
                   - already linked (to this or another parent), or has its own sub-components,
                   - the aircraft / engine stockline itself, or the aircraft / engine stockline is itself a sub-component.
 ** Date:   10/23/2026
 ** Author:  Kishor Makwana
 ** RETURN VALUE: @Linked OUTPUT = number of stocklines linked (no result set, safe to call inside other procedures)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/OCT/2026  Kishor Makwana   [PN-18118] Created
-- EXEC [dbo].[USP_LinkAircraftInstalledSubComponents] @RegistryId = 1, @IsFromAircraft = 1, @MasterCompanyId = 1, @UpdatedBy = 'admin'
-- EXEC [dbo].[USP_LinkAircraftInstalledSubComponents] @RegistryId = NULL, @IsFromAircraft = NULL, @MasterCompanyId = 1, @UpdatedBy = 'admin'   -- back-fill all
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_LinkAircraftInstalledSubComponents]
	@RegistryId BIGINT = NULL,
	@IsFromAircraft BIT = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256),
	@Linked INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Rows TABLE ([StockLineId] BIGINT PRIMARY KEY, [ParentStocklineId] BIGINT NOT NULL, [Qty] DECIMAL(18, 6) NULL);

	INSERT INTO @Rows ([StockLineId], [ParentStocklineId], [Qty])
	SELECT a.[StockLineId],
		   MAX(CASE WHEN ISNULL(a.[IsFromAircraft], 0) = 1 THEN arh.[StockLineId] ELSE erh.[StockLineId] END),
		   MAX(a.[Quantity])
	FROM [dbo].[AircraftInstalledPartDetails] a WITH (NOLOCK)
		LEFT JOIN [dbo].[AircraftRegistryHeader] arh WITH (NOLOCK) ON ISNULL(a.[IsFromAircraft], 0) = 1 AND arh.[AircraftRegistryId] = a.[AircraftRegistryId]
		LEFT JOIN [dbo].[EngineRegistryHeader] erh WITH (NOLOCK) ON ISNULL(a.[IsFromAircraft], 0) = 0 AND erh.[EngineRegistryId] = a.[EngineRegistryId]
	WHERE a.[MasterCompanyId] = @MasterCompanyId AND ISNULL(a.[IsDeleted], 0) = 0 AND ISNULL(a.[IsActive], 1) = 1 AND ISNULL(a.[StockLineId], 0) > 0
	  AND (@IsFromAircraft IS NULL OR ISNULL(a.[IsFromAircraft], 0) = @IsFromAircraft)
	  AND (@RegistryId IS NULL OR (ISNULL(a.[IsFromAircraft], 0) = 1 AND a.[AircraftRegistryId] = @RegistryId)
							   OR (ISNULL(a.[IsFromAircraft], 0) = 0 AND a.[EngineRegistryId] = @RegistryId))
	  AND ISNULL(CASE WHEN ISNULL(a.[IsFromAircraft], 0) = 1 THEN arh.[StockLineId] ELSE erh.[StockLineId] END, 0) > 0
	GROUP BY a.[StockLineId];

	UPDATE s
	SET s.[SubComponentParentStocklineId] = r.[ParentStocklineId],
		s.[SubComponentQty] = CASE WHEN ISNULL(r.[Qty], 0) <= 0 OR r.[Qty] > ISNULL(s.[QuantityOnHand], 0) OR ISNULL(s.[isSerialized], 0) = 1
								   THEN ISNULL(s.[QuantityOnHand], 0) ELSE r.[Qty] END,
		s.[IsSubComponent] = 1,
		s.[UpdatedBy] = @UpdatedBy,
		s.[UpdatedDate] = GETUTCDATE()
	FROM [dbo].[Stockline] s
		INNER JOIN @Rows r ON r.[StockLineId] = s.[StockLineId]
	WHERE s.[MasterCompanyId] = @MasterCompanyId
	  AND ISNULL(s.[isDeleted], 0) = 0
	  AND s.[SubComponentParentStocklineId] IS NULL
	  AND s.[StockLineId] <> r.[ParentStocklineId]
	  AND NOT EXISTS (SELECT 1 FROM [dbo].[Stockline] c WITH (NOLOCK) WHERE c.[SubComponentParentStocklineId] = s.[StockLineId])
	  AND NOT EXISTS (SELECT 1 FROM [dbo].[Stockline] p WITH (NOLOCK) WHERE p.[StockLineId] = r.[ParentStocklineId] AND p.[SubComponentParentStocklineId] IS NOT NULL);

	SET @Linked = @@ROWCOUNT;
END