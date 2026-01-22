/***********************************************************
** File:  [USP_RestorePublicationById]
** Author: Ayushi Patel
** Description: Restore By publication by ID
** Purpose:  
** Date:   2025-06-20

** RETURN VALUE: 
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			Change Description
** --   --------		-------			--------------------------------
   1   20-JUN-2025    AYUSHI PATEL	    Created
 exec  USP_RestorePublicationById 710
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_RestorePublicationById]
    @PublicationRecordId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
        
        IF EXISTS (
            SELECT 1 
            FROM dbo.Publication WITH (NOLOCK)
            WHERE PublicationRecordId = @PublicationRecordId AND IsDeleted = 1
        )
        BEGIN
            UPDATE dbo.Publication
            SET 
                IsDeleted = 0,
                UpdatedDate = GETUTCDATE()
            WHERE PublicationRecordId = @PublicationRecordId;

            SELECT @PublicationRecordId AS PublicationRecordId; 
        END
        ELSE
        BEGIN
            SELECT -1 AS PublicationRecordId;
        END
		COMMIT TRAN
    END TRY
   BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_RestorePublicationById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PublicationRecordId, '') + ''
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
END