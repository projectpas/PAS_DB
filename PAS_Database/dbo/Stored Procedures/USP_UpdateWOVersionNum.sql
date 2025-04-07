/*************************************************************           
 ** File:   [USP_UpdateWOVersionNum]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Version Number
 ** Date:   30/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    30/03/2023   Rajesh Gami     Created
**************************************************************
EXEC  [dbo].[USP_UpdateWOVersionNum]  'VER-000001',34,''
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateWOVersionNum] 
  @VersionNum NVARCHAR(50),
  @CodeTypeId  INT,
  @NewVersion NVARCHAR(50) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN			   		
		DECLARE @CodePrefix NVARCHAR(50);
		DECLARE @Version INT;
		DECLARE @Prefix NVARCHAR(50);
		DECLARE @Suffix NVARCHAR(50);

		SELECT TOP 1 @CodePrefix = CodePrefix,@Suffix = CodeSufix FROM DBO.CodePrefixes WITH(NOLOCK) WHERE CodeTypeId = @CodeTypeId;

		IF ISNULL(@VersionNum, '') <> ''
		BEGIN
			IF LEN(@VersionNum) > 6
			BEGIN
				SELECT @Prefix = LEFT(@VersionNum, CHARINDEX('-', @VersionNum) - 1),
					   @Suffix = SUBSTRING(@VersionNum, CHARINDEX('-', @VersionNum) + 1, LEN(@VersionNum));
				SET @Version = CAST(@Suffix AS INT) + 1;
			END
			ELSE
			BEGIN
				SET @Suffix = SUBSTRING(@VersionNum, 3, LEN(@VersionNum));
				SET @Version = CAST(@Suffix AS INT) + 1;
			END
		END
		ELSE
		BEGIN
			SET @Version = 1;
		END

		SET @NewVersion = (SELECT * FROM dbo.udfGenerateCodeNumber(@Version,@CodePrefix, ''));
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_UpdateWOVersionNum]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@VersionNum, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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