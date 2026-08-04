/*************************************************************           
 ** File:   [USP_GetReleaseNoteDetailsList]           
 ** Author:   Bhargav Saliya 
 ** Description: This Store Procedure Use to Get Release Note Detail 
 ** Purpose:         
 ** Date:   22-May-2025   
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    22-May-2025   Bhargav Saliya		Created
    2    16-Sept-2025  Devendra Shekh		Added ReleaseNotesTitleDetails Select
	3    27-nov-2025   Nakul Chandigara     Added a Missing colummn [TypeId]  
    4  03-Aug-2026     Ayushi Patel         [PN-17451]Added optional paging params so the same SP also returns a paged Titles list for one Sprint (removed the old bulk "all titles for all headers" select)
 EXEC USP_GetReleaseNoteDetailsList 2, 1, 0                     -- header list
 EXEC USP_GetReleaseNoteDetailsList 2, 1, 0, 12, 1, 10          -- paged titles for header 12, page 1, size 10

**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetReleaseNoteDetailsList]
    @EmployeeId BIGINT,
    @IsActive bit,
    @IsDelete bit,
    @ReleaseNoteHeaderId BIGINT = NULL,   
    @PageNumber INT = NULL,
    @PageSize INT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        IF @ReleaseNoteHeaderId IS NOT NULL
        BEGIN
            -- paged titles for a single Sprint 
            DECLARE @Offset INT = (ISNULL(@PageNumber, 1) - 1) * ISNULL(@PageSize, 10);
            DECLARE @Take INT = ISNULL(@PageSize, 10);

            SELECT
                rtd.[TitleId],
                rtd.[ReleaseNoteHeaderId],
                rtd.[Title],
                rtd.[SprintName],
                WT.[WorkType] AS [Type],
                rtd.[Description] AS TitleDescription,
                rtd.TypeId,
                COUNT(*) OVER() AS TotalRecords
            FROM DBO.[ReleaseNotesTitleDetails] rtd WITH (NOLOCK)
            LEFT JOIN DBO.[WorkType] WT WITH (NOLOCK) ON rtd.TypeId = WT.WorkTypeId
            WHERE rtd.ReleaseNoteHeaderId = @ReleaseNoteHeaderId
                  AND rtd.IsActive = 1 AND rtd.IsDeleted = 0
            ORDER BY rtd.TitleId DESC
            OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;

            RETURN(0);
        END

        -- header list 
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK)
                LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
                LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
                LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        SELECT DISTINCT
            RHD.ReleaseNoteHeaderId
           ,RHD.SprintName
           ,RHD.SprinDescription
           ,RHD.ReleaseDate
           ,RHD.MasterCompanyId
           ,RHD.CreatedBy
           ,RHD.UpdatedBy
           ,CASE WHEN CAST(RHD.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(RHD.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END CreatedDate
           ,CASE WHEN CAST(RHD.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(RHD.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END UpdatedDate
           ,RHD.IsActive
           ,RHD.IsDeleted
           ,RHD.[FileName]
           ,RHD.DocumentPath
           ,(SELECT COUNT(1) FROM DBO.[ReleaseNotesTitleDetails] rtd WITH (NOLOCK)
             WHERE rtd.ReleaseNoteHeaderId = RHD.ReleaseNoteHeaderId AND rtd.IsActive = 1 AND rtd.IsDeleted = 0) AS TitleCount
        FROM [dbo].[ReleaseNoteHeadersDetails] RHD WITH(NOLOCK)
        WHERE RHD.IsActive = @IsActive and RHD.IsDeleted = @IsDelete
        ORDER BY RHD.ReleaseNoteHeaderId DESC

    END TRY
    BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetReleaseNoteDetailsList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH 
END