/***********************************************************
** File:  [USP_RestoreUserRoleById]
** Author: SAHDEV SALIYA
** Description: Restore user role by Id
** Purpose:
** Date:   2026-08-27

** RETURN VALUE:
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			    Change Description
** --   --------		-------			    --------------------------------
   1   27-AUG-2026    	SAHDEV SALIYA	    Created
 exec  USP_RestoreUserRoleById 710, 'jim.roberts'
***************************************************************/
CREATE     PROCEDURE [dbo].[USP_RestoreUserRoleById]
    @Id BIGINT,
    @UpdatedBy VARCHAR(200) = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN TRAN

        IF EXISTS (
            SELECT 1
            FROM dbo.UserRole WITH (NOLOCK)
            WHERE Id = @Id AND IsDeleted = 1
        )
        BEGIN
            UPDATE dbo.UserRole
            SET
                IsDeleted = 0,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE Id = @Id;

            SELECT @Id AS Id;
        END
        ELSE
        BEGIN
            SELECT -1 AS Id;
        END
		COMMIT TRAN
    END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_RestoreUserRoleById'
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@Id AS VARCHAR(20)), '') + ''
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