/*************************************************************           
 ** File:		          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To 
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 02/02/2026          Nakul Chandigra     Created 

	declare @p1 dbo.WIPGLAccountSetupType
insert into @p1 values(1,15,N'ADMIN User','2026-01-22 08:03:24.6440000',N'ADMIN User','2026-01-22 08:03:24.6440000',1,0,1)

declare @p2 bit
set @p2=0
exec DBO.USP_AddWIPGLAccountSetup @tblType_WIPGLAccountSetupType=@p1,@IsSuccess=@p2 output
select @p2
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddWIPGLAccountSetup]
@tblType_WIPGLAccountSetupType [WIPGLAccountSetupType] READONLY,
@WIPGLAccountId BIGINT,
@IsError BIT OUTPUT
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
    SET @IsError = 0;

    SELECT [WIPCategoryId],[GLAccountId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[MasterCompanyId] 
    into  #ColumnData 
    FROM @tblType_WIPGLAccountSetupType

    IF (@WIPGLAccountId IS NOT NULL AND @WIPGLAccountId > 0)
    BEGIN

        IF EXISTS (SELECT 1 FROM dbo.WIPGLAccountSetup T WITH(NOLOCK) INNER JOIN #ColumnData C ON T.WIPCategoryId = C.WIPCategoryId AND T.GLAccountId   = C.GLAccountId )
        BEGIN 
            SET @IsError = 1
        END 
        ELSE 
        BEGIN
            UPDATE T
            SET
                T.WIPCategoryId = S.WIPCategoryId,
                T.GLAccountId   = S.GLAccountId,
                T.UpdatedBy     = S.UpdatedBy,
                T.UpdatedDate   = GETUTCDATE()
            FROM dbo.WIPGLAccountSetup T
            CROSS APPLY
            (
                SELECT
                    WIPCategoryId,
                    GLAccountId,
                    UpdatedBy
                FROM @tblType_WIPGLAccountSetupType
            ) S
            WHERE T.WIPGLAccountId = @WIPGLAccountId;
        END
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.WIPGLAccountSetup T WITH(NOLOCK) INNER JOIN #ColumnData C ON T.WIPCategoryId = C.WIPCategoryId AND T.GLAccountId   = C.GLAccountId )
        BEGIN 
            SET @IsError = 1
        END 
        ELSE 
        BEGIN 
            INSERT INTO dbo.WIPGLAccountSetup ([WIPCategoryId],[GLAccountId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[MasterCompanyId])
		    SELECT  [WIPCategoryId],[GLAccountId],[CreatedBy],GETUTCDATE(),[UpdatedBy],GETUTCDATE(),[IsActive],[IsDeleted],[MasterCompanyId]
		    FROM @tblType_WIPGLAccountSetupType
        END
    END

END TRY
BEGIN CATCH
IF @@trancount > 0		  
	ROLLBACK TRAN;  
	DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_AddWIPGLAccountSetup]'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
		,@AdhocComments = @AdhocComments
		,@ProcedureParameters = @ProcedureParameters
		,@ApplicationName = @ApplicationName
		,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1); 
END CATCH
END