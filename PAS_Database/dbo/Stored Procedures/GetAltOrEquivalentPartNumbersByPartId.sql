/*************************************************************           
 ** File:     [GetAltOrEquivalentPartNumbersByPartId]           
 ** Author:	  Vishal Suthar
 ** Description: This SP is Used to Get Alt or Equ part details
 ** Purpose:         
 ** Date:   10/30/2025 
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 ************************************************************************
  ** Change History           
 ************************************************************************
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------
	1    10/30/2025   Vishal Suthar		Created

************************************************************************/
CREATE   PROCEDURE [dbo].[GetAltOrEquivalentPartNumbersByPartId]
    @PartId INT,
	@MappingType INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT ALT.*
		FROM dbo.Nha_Tla_Alt_Equ_ItemMapping ALT WITH (NOLOCK)
		INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId
		INNER JOIN dbo.ItemMaster im1 WITH (NOLOCK) ON ALT.MappingItemMasterId = im1.ItemMasterId
		INNER JOIN dbo.Manufacturer man WITH (NOLOCK) ON im.ManufacturerId = man.ManufacturerId
		INNER JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
		WHERE ALT.IsActive = 1 
		AND ALT.IsDeleted = 0
		AND ALT.ItemMasterId = @PartId
		AND ALT.MappingType = @MappingType;
	END TRY
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetAltOrEquivalentPartNumbersByPartId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PartId, '') + '''
												@Parameter4 = ' + ISNULL(@MappingType ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
                @DatabaseName = @DatabaseName
                , @AdhocComments = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName = @ApplicationName
                , @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END