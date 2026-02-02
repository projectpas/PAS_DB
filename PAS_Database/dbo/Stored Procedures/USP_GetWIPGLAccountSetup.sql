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

exec dbo.USP_GetWIPGLAccountSetup @PageNumber=0,@PageSize=10,@SortColumn=default,@SortOrder=0,@GlobalFilter=null,@WIPCategory=null,@GLAccountName=null,@CreatedBy=null,@UpdatedBy=null,@CreatedDate=default,@UpdatedDate=default,@IsActive=0,@IsDeleted=0,@MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE dbo.USP_GetWIPGLAccountSetup
@PageNumber INT = 1,
@PageSize INT = 10,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT = -1,
@GlobalFilter VARCHAR(100) = NULL,
@WIPCategory VARCHAR(100) = NULL,
@GLAccountName VARCHAR(100) = NULL,
@CreatedBy VARCHAR(100) = NULL,
@UpdatedBy VARCHAR(100) = NULL,
@CreatedDate DATETIME = NULL,
@UpdatedDate DATETIME = NULL,
@IsActive BIT = NULL,
@IsDeleted BIT = 0,
@MasterCompanyId BIGINT,
@EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
 
  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

    SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc;

        SET @PageNumber = CASE WHEN @PageNumber < 1 THEN 1 ELSE @PageNumber END;
        SET @PageSize   = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
        SET @SortOrder  = CASE WHEN @SortOrder IN (1,-1) THEN @SortOrder ELSE -1 END;
        SET @SortColumn = UPPER(ISNULL(@SortColumn,'CREATEDDATE'));

        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        ;WITH BaseResult AS
        (
            SELECT
                WIP.WIPGLAccountId,
                WC.WIPCategoryId,
                WC.WIPCategory,
                VGL.AccountName AS GLAccountName,
                WIP.GLAccountId,
                WIP.CreatedBy,
                CASE WHEN CAST(WIP.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, WIP.CreatedDate)) END CreatedDate,
                WIP.UpdatedBy,
				CASE WHEN CAST(WIP.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, WIP.UpdatedDate)) END UpdatedDate,
                WIP.IsActive,
                WIP.IsDeleted,
                WIP.MasterCompanyId
            FROM dbo.WIPGLAccountSetup WIP WITH (NOLOCK)
            LEFT JOIN dbo.WIPCategory WC WITH (NOLOCK) ON WIP.WIPCategoryId = WC.WIPCategoryId
            LEFT JOIN dbo.View_GLAccount VGL WITH (NOLOCK) ON WIP.GLAccountId = VGL.GLAccountId
            WHERE WIP.MasterCompanyId = @MasterCompanyId AND WIP.IsDeleted = @IsDeleted 
        ),

        FilteredResult AS
        (
            SELECT  WIPGLAccountId,
                    WIPCategoryId,
                    WIPCategory,
                    GLAccountName,
                    GLAccountId,
                    CreatedBy,
                    CASE WHEN CAST(CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, CreatedDate)) END CreatedDate,
                    UpdatedBy,
                    CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, UpdatedDate)) END UpdatedDate,
                    IsActive,
                    IsDeleted,
                    MasterCompanyId
            FROM BaseResult
            WHERE
            (ISNULL(@GlobalFilter,'') <> '' AND(
                    WIPCategory LIKE '%' + @GlobalFilter + '%'
                    OR GLAccountName LIKE '%' + @GlobalFilter + '%'
                    OR CreatedBy LIKE '%' + @GlobalFilter + '%'
                    OR UpdatedBy LIKE '%' + @GlobalFilter + '%'
                ))
            OR
            (
                ISNULL(@GlobalFilter,'') = ''
                AND (ISNULL(@WIPCategory,'') = '' OR WIPCategory LIKE '%' + @WIPCategory + '%')
                AND (ISNULL(@GLAccountName,'') = '' OR GLAccountName LIKE '%' + @GLAccountName + '%')
                AND (ISNULL(@CreatedBy,'') = '' OR CreatedBy LIKE '%' + @CreatedBy + '%')
                AND (ISNULL(@UpdatedBy,'') = '' OR UpdatedBy LIKE '%' + @UpdatedBy + '%')
                AND (@CreatedDate IS NULL OR CAST(CreatedDate AS DATE) = @CreatedDate)
                AND (@UpdatedDate IS NULL OR CAST(UpdatedDate AS DATE) = @UpdatedDate)
            )
        ),
        ResultCount AS
        (
            SELECT COUNT(WIPGLAccountId) AS NumberOfItems FROM FilteredResult
        )

   
        SELECT
            WIPGLAccountId,
            WIPCategoryId,
            WIPCategory,
            GLAccountName,
            GLAccountId,
            CreatedBy,
            CASE WHEN CAST(CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, CreatedDate)) END CreatedDate,
            UpdatedBy,
            CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, UpdatedDate)) END UpdatedDate,
            IsDeleted,
            MasterCompanyId,
            NumberOfItems
        FROM FilteredResult,ResultCount
        ORDER BY
            CASE WHEN @SortColumn = 'GLACCOUNTNAME' AND @SortOrder = 1  THEN GLAccountName END ASC,
            CASE WHEN @SortColumn = 'GLACCOUNTNAME' AND @SortOrder = -1 THEN GLAccountName END DESC,

            CASE WHEN @SortColumn = 'WIPCATEGORY' AND @SortOrder = 1  THEN WIPCategory END ASC,
            CASE WHEN @SortColumn = 'WIPCATEGORY' AND @SortOrder = -1 THEN WIPCategory END DESC,

            CASE WHEN @SortColumn = 'CREATEDBY' AND @SortOrder = 1  THEN CreatedBy END ASC,
            CASE WHEN @SortColumn = 'CREATEDBY' AND @SortOrder = -1 THEN CreatedBy END DESC,

            CASE WHEN @SortColumn = 'CREATEDDATE' AND @SortOrder = 1  THEN CreatedDate END ASC,
            CASE WHEN @SortColumn = 'CREATEDDATE' AND @SortOrder = -1 THEN CreatedDate END DESC,

            CASE WHEN @SortColumn = 'UPDATEDBY' AND @SortOrder = 1  THEN UpdatedBy END ASC,
            CASE WHEN @SortColumn = 'UPDATEDBY' AND @SortOrder = -1 THEN UpdatedBy END DESC,

            CASE WHEN @SortColumn = 'UPDATEDDATE' AND @SortOrder = 1  THEN UpdatedDate END ASC,
            CASE WHEN @SortColumn = 'UPDATEDDATE' AND @SortOrder = -1 THEN UpdatedDate END DESC

        OFFSET @Offset ROWS
        FETCH NEXT @PageSize ROWS ONLY;

    END TRY

	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetWIPGLAccountSetup]'
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