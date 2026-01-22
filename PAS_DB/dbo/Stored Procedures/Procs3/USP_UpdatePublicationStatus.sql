/***********************************************************
** File:  [USP_UpdatePublicationStatus]
** Author: Ayushi Patel
** Description: Updates status of a publication record (IsActive) and audit fields
** Purpose:  
** Date:   2025-06-19

** RETURN VALUE: 
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			Change Description
** --   --------		-------			--------------------------------
   1   19-JUN-2025    AYUSHI PATEL	    Created

***************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdatePublicationStatus]
    @PublicationRecordId BIGINT,
    @Status BIT,
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM DBO.Publication WITH (NOLOCK) WHERE PublicationRecordId = @PublicationRecordId)
        BEGIN
            UPDATE DBO.Publication
            SET 
                IsActive = @Status,
                UpdatedDate = GETUTCDATE(),
                UpdatedBy = @UpdatedBy
            WHERE PublicationRecordId = @PublicationRecordId;

            SELECT @PublicationRecordId AS PublicationRecordId;
        END
        ELSE
        BEGIN
            RAISERROR('Publication ID does not exist.', 16, 1);
        END
    END TRY
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_UpdatePublicationStatus'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
            ,@ApplicationName VARCHAR(100) = 'PAS'
        
        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
        RETURN (1);           
    END CATCH
END