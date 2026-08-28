/***********************************************************
** File:  [USP_CheckUserRoleForDelete]
** Author: SAHDEV SALIYA
** Description: Checks whether a user role is currently assigned to any
**              employee (dbo.EmployeeUserRole), so the caller can block
**              removing or inactivating an in-use role.
** Purpose:
** Date:   2026-08-27

** RETURN VALUE: single row with IsInUse (bit)
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			   Change Description
** --   --------		-------			   --------------------------------
   1   27-AUG-2026    	SAHDEV SALIYA	   Created
 exec  USP_CheckUserRoleForDelete 710
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckUserRoleForDelete]
    @Id BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY

        DECLARE @IsInUse BIT = 0;

        IF EXISTS (
            SELECT 1
            FROM dbo.EmployeeUserRole WITH (NOLOCK)
            WHERE RoleId = @Id AND IsDeleted = 0
        )
        BEGIN
            SET @IsInUse = 1;
        END

        SELECT @IsInUse AS IsInUse;

    END TRY
    BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CheckUserRoleForDelete'
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