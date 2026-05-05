/*********************           
 ** File:		       [USP_GetUomSetup]   
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To 
 ** Purpose:         
 ** Date:   
 **********************           
 ** Change History           
 **********************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	09-03-2026           Nakul Chandigra     Created (PN-15597)
	2	05-May-2026          Rajesh Gami		 Set @Factor = NULL When it is 0 or blank
exec dbo.USP_GetUomSetup @PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@FromUOM=NULL,@ToUOM=NULL,@Factor=0,@CreatedBy=NULL,@UpdatedBy=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,@IsDeleted=0,@MasterCompanyId=1,@EmployeeId=2
**********************/
CREATE   PROCEDURE [dbo].[USP_GetUomSetup]
@PageNumber INT = 1,
@PageSize INT = 10,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT = -1,
@GlobalFilter VARCHAR(100) = NULL,
@FromUOM VARCHAR(100) = NULL,
@ToUOM VARCHAR(100) = NULL,
@Factor VARCHAR(100) = NULL,
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
		IF(@Factor = '' OR @Factor = 0)
		BEGIN
			SET @Factor = NULL;
		END
        SET @PageNumber = CASE WHEN @PageNumber < 1 THEN 1 ELSE @PageNumber END;
        SET @PageSize   = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
        SET @SortOrder  = CASE WHEN @SortOrder IN (1,-1) THEN @SortOrder ELSE -1 END;
        SET @SortColumn = UPPER(ISNULL(@SortColumn,'CREATEDDATE'));

        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        ;WITH BaseResult AS
        (
            SELECT
                UOM.UOMConversionId,
                UOM.FromUOM,
                UOM.ToUOM,
                UOM.Factor,
                UOM.CreatedBy,
                CASE WHEN CAST(UOM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, UOM.CreatedDate)) END CreatedDate,
                UOM.UpdatedBy,
				CASE WHEN CAST(UOM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, UOM.UpdatedDate)) END UpdatedDate,
                UOM.IsActive,
                UOM.IsDeleted,
                UOM.MasterCompanyId
            FROM  dbo.UOMConversion UOM WITH (NOLOCK)
            
            WHERE UOM.MasterCompanyId = @MasterCompanyId AND UOM.IsDeleted = @IsDeleted 
        ),

        FilteredResult AS
        (
            SELECT  UOMConversionId,
                    FromUOM,
                    ToUOM,
                    Factor,
                    CreatedBy,
                    CreatedDate,
                    UpdatedBy,
                    UpdatedDate,
                    IsActive,
                    IsDeleted,
                    MasterCompanyId
            FROM BaseResult
            WHERE
            (ISNULL(@GlobalFilter,'') <> '' AND(
                    FromUOM LIKE '%' + @GlobalFilter + '%'
                    OR Factor LIKE '%' + @GlobalFilter + '%'
                    OR ToUOM LIKE '%' + @GlobalFilter + '%'
                    OR CreatedBy LIKE '%' + @GlobalFilter + '%'
                    OR UpdatedBy LIKE '%' + @GlobalFilter + '%'
                ))
            OR
            (
                ISNULL(@GlobalFilter,'') = ''
                AND (ISNULL(@FromUOM,'') = '' OR FromUOM LIKE '%' + @FromUOM + '%')
                AND (ISNULL(@Factor,'') = '' OR Factor LIKE '%' + @Factor + '%')
                AND (ISNULL(@ToUOM,'') = '' OR ToUOM LIKE '%' + @ToUOM + '%')
                AND (ISNULL(@CreatedBy,'') = '' OR CreatedBy LIKE '%' + @CreatedBy + '%')
                AND (ISNULL(@UpdatedBy,'') = '' OR UpdatedBy LIKE '%' + @UpdatedBy + '%')
                AND (@CreatedDate IS NULL OR CAST(CreatedDate AS DATE) = @CreatedDate)
                AND (@UpdatedDate IS NULL OR CAST(UpdatedDate AS DATE) = @UpdatedDate)
            )
        ),
        ResultCount AS
        (
            SELECT COUNT(UOMConversionId) AS NumberOfItems FROM FilteredResult
        )

   
        SELECT
            UOMConversionId,
            FromUOM,
            ToUOM,
            Factor,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            IsDeleted,
            MasterCompanyId,
            NumberOfItems
        FROM FilteredResult,ResultCount
        ORDER BY
            CASE WHEN @SortColumn = 'FROMUOM' AND @SortOrder = 1  THEN FromUOM END ASC,
            CASE WHEN @SortColumn = 'FROMUOM' AND @SortOrder = -1 THEN FromUOM END DESC,

            CASE WHEN @SortColumn = 'TOUOM' AND @SortOrder = 1  THEN ToUOM END ASC,
            CASE WHEN @SortColumn = 'TOUOM' AND @SortOrder = -1 THEN ToUOM END DESC,

            CASE WHEN @SortColumn = 'FACTOR' AND @SortOrder = 1  THEN Factor END ASC,
            CASE WHEN @SortColumn = 'FACTOR' AND @SortOrder = -1 THEN Factor END DESC,

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
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetUomSetup]'
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