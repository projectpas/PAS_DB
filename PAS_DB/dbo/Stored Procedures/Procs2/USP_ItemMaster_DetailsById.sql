/*************************************************************           
 ** File:   [USP_ItemMaster_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get ItemMaster Details By ItemMasterId
 ** Date:   06/20/2023
 ** PARAMETERS: @ItemMasterId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/20/2023   Moin Bloch     Created
*******************************************************************************
EXEC USP_ItemMaster_DetailsById 41186
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ItemMaster_DetailsById] 
@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
            SELECT IM.[ItemMasterId]
				  ,IM.[PartNumber]	
				  ,IM.[PartDescription]
				  ,IM.[GLAccountId]
				  ,IM.[GLAccount]
				  ,IM.[IsTimeLife]
				  ,IM.[IsSerialized]
				  ,IM.[ManufacturerId]
				  ,IM.[IsExpirationDateAvailable]
				  ,IM.[DaysReceived]
				  ,IM.[OpenDays]
				  ,IM.[ManufacturingDays]
				  ,IM.[IsManufacturingDateAvailable]
				  ,IM.[IsReceivedDateAvailable]
				  ,IM.[IsTagDateAvailable]
				  ,IM.[IsOpenDateAvailable]
				  ,IM.[ManufacturerName]
				  ,IM.[IsPma]
				  ,IM.[IsDER]
				  ,IM.[SiteId]
				  ,IM.[WarehouseId]
                  ,IM.[LocationId]
                  ,IM.[ShelfId]
                  ,IM.[BinId]
              FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId;
	END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_ItemMaster_DetailsById]'			
			,@ProcedureParameters VARCHAR(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
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