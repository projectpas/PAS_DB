/*************************************************************
 ** File:   [USP_GetLeaseStockLineNoteHistory]
 ** Desc:   Notes of a lease stockline (Add Item tab -> Add/Edit Note), latest first.
 ** EXEC USP_GetLeaseStockLineNoteHistory @LeaseStocklineId = 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseStockLineNoteHistory]
    @LeaseStocklineId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT N.[LeaseStockLineNoteHistoryId],
           N.[LeaseStocklineId],
           N.[Description],
           N.[EnteredBy],
           N.[CreatedDate],
           N.[EditedBy],
           N.[UpdatedDate]
    FROM [dbo].[LeaseStockLineNoteHistory] N
    WHERE N.[LeaseStocklineId] = @LeaseStocklineId
      AND N.[IsDeleted] = 0
    ORDER BY N.[LeaseStockLineNoteHistoryId] DESC;
END