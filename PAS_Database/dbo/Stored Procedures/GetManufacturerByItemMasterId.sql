/*************************************************************             
** File:   [GetManufacturerByItemMasterId]
** Author:   Vishal Suthar
** Description: This procedre is used to get manufacturer by part id
** Purpose:
** Date:   10/31/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   10/31/2025   Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

 EXEC [dbo].[GetManufacturerByItemMasterId] 96877
**************************************************************/
CREATE   PROCEDURE [dbo].[GetManufacturerByItemMasterId]
    @ItemMasterId INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		SELECT DISTINCT 
			imcls.ManufacturerId AS [value],
			imcls.Name AS [label]
		FROM DBO.Manufacturer imcls WITH (NOLOCK)
		INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON imcls.ManufacturerId = im.ManufacturerId
		WHERE imcls.IsDeleted = 0 AND im.ItemMasterId = @ItemMasterId;

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetManufacturerByItemMasterId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END