 /*************************************************************           
 ** File: [USP_updateItemMasterMappingPartNotesById]       
 ** Author:  Bhargav Saliya
 ** Description: Update Distribution Memo   
 ** Purpose:         
 ** Date:   14-Nov-2025      
          
 ** PARAMETERS:   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    03-Dec-2025    Bhargav Saliya		Created
**************************************************************/ 
Create     PROCEDURE [dbo].[USP_updateGLAccountDistributionMemoById]
    @DistributionSetupID BIGINT,
    @Memo NVARCHAR(MAX),
    @MastercompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE ID = @DistributionSetupID AND MasterCompanyId =  @MastercompanyId)
        BEGIN
            UPDATE dbo.DistributionSetup
            SET
                Memo = @Memo,
                UpdatedDate = GETUTCDATE()
            WHERE ID = @DistributionSetupID AND MasterCompanyId =  @MastercompanyId;
            
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_updateGLAccountDistributionMemoById',
                @ProcedureParameters VARCHAR(MAX) = '@PublicationItemMasterMappingId=' + CAST(@DistributionSetupID AS VARCHAR),
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