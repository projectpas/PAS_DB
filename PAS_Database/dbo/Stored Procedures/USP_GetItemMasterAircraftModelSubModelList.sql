/*************************************************************
** Author:  Kishor Makwana
** Create date: 11/09/2026
** Description: Get the distinct AircraftModel / DashNumber combinations
**              dbo.ItemMasterAircraftMapping has for the same PartNumber as
**              the given @ItemMasterAircraftMappingId - backs the Aircraft /
**              Fleet Quote header's "Aircraft Model / Sub-Model" dropdown
**              (see fleet-quote.component.ts), which previously used a
**              hardcoded static array. This dropdown cascades off the
**              "Aircraft / Fleet" dropdown's selection (dbo.FleetQuote.FleetName,
**              which stores ItemMasterAircraftMappingId - see
**              dbo.USP_GetItemMasterAircraftPartNumberList): a PartNumber can
**              have several ItemMasterAircraftMapping rows, one per
**              AircraftType/AircraftModel/DashNumber combination it's
**              compatible with (IMAM_Unique), so this resolves the selected
**              row's PartNumber first, then returns every distinct
**              AircraftModel/DashNumber combo for that PartNumber. Same
**              READ UNCOMMITTED / spLogException convention as
**              dbo.USP_GetItemMasterAircraftPartNumberList.
**
** EXEC [USP_GetItemMasterAircraftModelSubModelList] 1
**************************************************************
** Change History
**************************************************************
** PR   Date        Author            Change Description
** --   --------    -------           --------------------------------
** 1    11/09/2026   Kishor Makwana    Created [PN-17698]
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetItemMasterAircraftModelSubModelList]
    @ItemMasterAircraftMappingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        DECLARE @PartNumber VARCHAR(50), @MasterCompanyId INT

        SELECT
            @PartNumber = [PartNumber],
            @MasterCompanyId = [MasterCompanyId]
        FROM [dbo].[ItemMasterAircraftMapping] WITH (NOLOCK)
        WHERE [ItemMasterAircraftMappingId] = @ItemMasterAircraftMappingId;

        SELECT
            [AircraftModel] + ' / ' + [DashNumber] AS [Label],
            [AircraftModel],
            [DashNumber]
        FROM [dbo].[ItemMasterAircraftMapping] WITH (NOLOCK)
        WHERE [PartNumber] = @PartNumber
          AND [MasterCompanyId] = @MasterCompanyId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
        GROUP BY [AircraftModel], [DashNumber]
        ORDER BY [AircraftModel], [DashNumber];
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterAircraftModelSubModelList'
              , @ProcedureParameters VARCHAR(3000)  = '@ItemMasterAircraftMappingId = '+ ISNULL(CAST(@ItemMasterAircraftMappingId AS VARCHAR(20)), '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END
