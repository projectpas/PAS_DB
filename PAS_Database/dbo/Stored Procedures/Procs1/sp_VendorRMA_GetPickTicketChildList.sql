/*************************************************************
 ** File:   [sp_VendorRMA_GetPickTicketChildList]
 ** Author:   Amit Ghediya
 ** Description: Retrieve pick ticket child listing (STK details) for Vendor RMA
 ** Change History:
 ** PR   Date         Author          Description
 ** 1    06/19/2023   Amit Ghediya    Created
 ** 2    02/03/2026   Amit Ghediya    UOM Conversion Changes [PN-15140]
 ** 3    [today]      [Hemant]        Performance & readability optimization
 ** 4	 19/06/2026	  Ayushi		  [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
**************************************************************/
CREATE PROCEDURE [dbo].[sp_VendorRMA_GetPickTicketChildList]
    @VendorRMAId        BIGINT,
    @VendorRMADetailId  BIGINT,
    @ItemMasterId       BIGINT,
    @ConditionId        BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            sopt.RMAPickTicketId,
            sopt.RMAPickTicketNumber,
            sopt.VendorRMAId,
            sopt.VendorRMADetailId,
            sopt.IsConfirmed,
            sopt.ConfirmedDate,
            sopt.CreatedDate                                                AS PickedDate,
            CASE 
                WHEN ISNULL(im.StockUnitOfMeasure,'') = ISNULL(im.PurchaseUnitOfMeasure,'')
                    THEN ISNULL(sopt.QtyToShip,0)
                ELSE [dbo].[fn_ConvertUOM](
                        ISNULL(sopt.QtyToShip,0),
                        im.StockUnitOfMeasure,
                        im.PurchaseUnitOfMeasure,
                        0,
                        im.MasterCompanyId
                     )
            END AS QtyToShip,
            sl.SerialNumber,
            sl.StockLineNumber,
            sl.StockLineId,
            sl.ControlNumber,
            sl.IdNumber,
            CONCAT(emp.FirstName,  ' ', emp.LastName)                       AS PickedBy,
            CONCAT(empy.FirstName, ' ', empy.LastName)                      AS ConfirmedBy
        FROM RMAPickTicket sopt WITH(NOLOCK)
        INNER JOIN VendorRMADetail sop  WITH(NOLOCK) ON  sop.VendorRMAId       = sopt.VendorRMAId
                                                     AND sop.VendorRMADetailId = sopt.VendorRMADetailId
        LEFT  JOIN StockLine sl         WITH(NOLOCK) ON  sl.StockLineId        = sop.StockLineId
        INNER JOIN ItemMaster im        WITH(NOLOCK) ON  im.ItemMasterId       = sl.ItemMasterId
        INNER JOIN Employee emp         WITH(NOLOCK) ON  emp.EmployeeId        = sopt.PickedById
        LEFT  JOIN Employee empy        WITH(NOLOCK) ON  empy.EmployeeId       = sopt.ConfirmedById
        WHERE
            sopt.VendorRMAId       = @VendorRMAId
            AND sopt.VendorRMADetailId = @VendorRMADetailId
            AND sop.ItemMasterId       = @ItemMasterId
            AND sl.ConditionId         = @ConditionId;

    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)   = DB_NAME(),
            @AdhocComments       VARCHAR(150)   = 'sp_VendorRMA_GetPickTicketChildList',
            @ProcedureParameters VARCHAR(3000)  =
                '@VendorRMAId = '       + CAST(ISNULL(@VendorRMAId,       0) AS VARCHAR(20)) + ', ' +
                '@VendorRMADetailId = ' + CAST(ISNULL(@VendorRMADetailId, 0) AS VARCHAR(20)) + ', ' +
                '@ItemMasterId = '      + CAST(ISNULL(@ItemMasterId,      0) AS VARCHAR(20)) + ', ' +
                '@ConditionId = '       + CAST(ISNULL(@ConditionId,       0) AS VARCHAR(20)),
            @ApplicationName     VARCHAR(100)   = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error in the database. Support error number: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END