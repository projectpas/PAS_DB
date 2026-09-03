/*************************************************************
 ** File:   [USP_LOTOtherCostDetails_Delete]
 ** Author: RAJESH GAMI
 ** Description: [PN-17853] Soft-deletes a manually-entered Other Cost row (LOTOtherCostDetails). Only
 **              rows created through the Other Cost tab's "+" Add/Edit popup can ever reach this SP -
 **              PO/RO/SO-sourced rows have no LOTOtherCostDetails row to delete in the first place, and
 **              the Angular side only shows the Delete action for rows where LotOtherCostDetailId is set.
 **              USP_Lot_GetAllLotViewsByLotId_Filter's OtherCost branch already filters
 **              ISNULL(loc.IsDeleted,0) = 0 on this table, so a deleted row disappears from the grid
 **              immediately without any change needed there.
 ** Date:   03-Sep-2026
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author  		Change Description
 ** --   --------     -------		---------------------------
    1    03-Sep-2026  RAJESH GAMI     [PN-17853] Created
**************************************************************
 EXEC USP_LOTOtherCostDetails_Delete
**************************************************************/
CREATE PROCEDURE [dbo].[USP_LOTOtherCostDetails_Delete]
@LotOtherCostDetailId bigint,
@UpdatedBy varchar(256)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		UPDATE [dbo].[LOTOtherCostDetails]
		   SET [IsDeleted] = 1
		      ,[IsActive] = 0
		      ,[UpdatedBy] = @UpdatedBy
		      ,[UpdatedDate] = GETUTCDATE()
		 WHERE [LotOtherCostDetailId] = @LotOtherCostDetailId

		SELECT @LotOtherCostDetailId AS LotOtherCostDetailId
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_LOTOtherCostDetails_Delete]',
            @ProcedureParameters varchar(3000) = '@LotOtherCostDetailId = ''' + CAST(ISNULL(@LotOtherCostDetailId, '') AS varchar(100))
            + '@UpdatedBy = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END