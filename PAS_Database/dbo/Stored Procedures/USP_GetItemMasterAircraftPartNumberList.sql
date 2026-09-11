/*************************************************************
** Author:  Kishor Makwana
** Create date: 11/09/2026
** Description: Get the distinct list of dbo.ItemMasterAircraftMapping.PartNumber
**              values for a MasterCompany - backs the Aircraft / Fleet Quote
**              header's "Aircraft / Fleet" dropdown (see fleet-quote.component.ts),
**              which previously used a hardcoded static array. Same
**              READ UNCOMMITTED / spLogException convention as
**              dbo.USP_GetFleetQuoteById, and same DISTINCT-list-by-
**              MasterCompanyId/IsActive/IsDeleted shape as
**              dbo.USP_GetAircraftTailNumberList (AircraftRegistryHeader.TailNum).
**
**              dbo.FleetQuote.FleetName persists the dropdown's VALUE, which is
**              ItemMasterAircraftMappingId (not the PartNumber text) - same
**              id-not-text-storage convention as AircraftTailNumber (which
**              persists AircraftRegistryId, resolved back to TailNum for
**              display). Since PartNumber is not unique on
**              ItemMasterAircraftMapping (multiple AircraftType/Model/DashNumber
**              rows can share one PartNumber), the lowest
**              ItemMasterAircraftMappingId per distinct PartNumber is returned
**              so the dropdown has one row per PartNumber.
**
** EXEC [USP_GetItemMasterAircraftPartNumberList] 1
**************************************************************
** Change History
**************************************************************
** PR   Date        Author            Change Description
** --   --------    -------           --------------------------------
** 1    11/09/2026   Kishor Makwana    Created [PN-17698]
** 2    11/09/2026   Kishor Makwana    Now also returns ItemMasterAircraftMappingId -
                                       this is the value dbo.FleetQuote.FleetName
                                       stores (not the PartNumber text) [PN-17698]
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetItemMasterAircraftPartNumberList]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        SELECT
            [PartNumber],
            CAST(MIN([ItemMasterAircraftMappingId]) AS VARCHAR(20)) AS [ItemMasterAircraftMappingId]
        FROM [dbo].[ItemMasterAircraftMapping] WITH (NOLOCK)
        WHERE [MasterCompanyId] = @MasterCompanyId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
        GROUP BY [PartNumber]
        ORDER BY [PartNumber];
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterAircraftPartNumberList'
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = '+ ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), '')
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
