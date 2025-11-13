/*************************************************************           
 ** File: [USP_PublicationItemMasterMapping_InsertBatch]       
 ** Author:  Ayushi Patel 
 ** Description: Inserts ItemMaster mappings for a Publication.Prevents duplicates and returns flag if any existed    
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
CREATE   PROCEDURE [dbo].[USP_PublicationItemMasterMapping_InsertBatch]
    @IMPNMapping PublicationItemMasterMappingType READONLY,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @Notes VARCHAR(MAX),
    @OutputFlag BIT OUTPUT 
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
        DECLARE @Now DATETIME = GETUTCDATE();
        SET @OutputFlag = 0;

        IF EXISTS (
            SELECT 1
            FROM @IMPNMapping t
            WHERE EXISTS (
                SELECT 1
                FROM dbo.PublicationItemMasterMapping p WITH (NOLOCK)
                WHERE 
                    p.PublicationRecordId = t.PublicationRecordId AND
                    p.ItemMasterId = t.ItemMasterId AND
                    p.MasterCompanyId = t.MasterCompanyId
            )
        )
        BEGIN
            SET @OutputFlag = 1;
        END

        INSERT INTO dbo.PublicationItemMasterMapping (
            PublicationRecordId,
            ItemMasterId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            IsActive,
            IsDeleted,
			Notes
        )
        SELECT 
            t.PublicationRecordId,
            t.ItemMasterId,
            t.MasterCompanyId,
            @CreatedBy,
            @UpdatedBy,
            @Now,
            @Now,
            t.IsActive,
            t.IsDeleted,
			@Notes
        FROM @IMPNMapping t
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.PublicationItemMasterMapping p WITH (NOLOCK)
            WHERE 
                p.PublicationRecordId = t.PublicationRecordId AND
                p.ItemMasterId = t.ItemMasterId AND
                p.MasterCompanyId = t.MasterCompanyId
        );

    COMMIT TRAN

    END  TRY
    BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_PublicationItemMasterMapping_InsertBatch' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END;