/*************************************************************           
 ** File: [USP_DeletePublicationItemMasterMappingById]       
 ** Author:  Ayushi Patel 
 ** Description: Delete Publication By ItemMasterMappingById    
 ** Purpose:         
 ** Date:   23-Jun-2025      
          
 ** PARAMETERS:   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    23-Jun-2025   Ayushi Patel		Created
**************************************************************/ 
CREATE   PROCEDURE dbo.USP_DeletePublicationItemMasterMappingById
    @PublicationItemMasterMappingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 
            FROM dbo.PublicationItemMasterMapping WITH(NOLOCK)
            WHERE PublicationItemMasterMappingId = @PublicationItemMasterMappingId
              AND ISNULL(IsDeleted,0) = 0
        )
        BEGIN
            UPDATE dbo.PublicationItemMasterMapping
            SET
                IsDeleted = 1,
                UpdatedDate = GETUTCDATE()
            WHERE PublicationItemMasterMappingId = @PublicationItemMasterMappingId;

            SELECT @PublicationItemMasterMappingId AS PublicationItemMasterMappingId;
        END
        ELSE
        BEGIN
            SELECT NULL AS PublicationItemMasterMappingId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_DeletePublicationItemMasterMappingById',
                @ProcedureParameters VARCHAR(MAX) = '@PublicationItemMasterMappingId=' + CAST(@PublicationItemMasterMappingId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error occurred. ErrorLogID = %d', 16, 1, @ErrorLogID);
    END CATCH
END;