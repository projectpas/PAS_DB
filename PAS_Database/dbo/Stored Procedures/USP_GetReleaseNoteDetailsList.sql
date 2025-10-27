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

EXEC [USP_GetReleaseNoteDetailsList] 233, 1, 0
**************************************************************/
CREATE   PROCEDURE	[dbo].[USP_GetReleaseNoteDetailsList]
    @EmployeeId BIGINT,
	@IsActive bit,
	@IsDelete bit
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

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
		   ,CASE WHEN CAST(RHD.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(RHD.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate
		   ,CASE WHEN CAST(RHD.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(RHD.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate
		   ,RHD.IsActive
		   ,RHD.IsDeleted
		   ,RHD.[FileName]
		   ,RHD.DocumentPath
		FROM [dbo].[ReleaseNoteHeadersDetails] RHD WITH(NOLOCK)
		WHERE RHD. IsActive = @IsActive and RHD.IsDeleted = @IsDelete 
		ORDER BY RHD.ReleaseNoteHeaderId DESC

		SELECT 
			[TitleId], [ReleaseNoteHeaderId], [Title], [SprintName], [Type], [TitleDescription]
		FROM
		(
			SELECT 
				rtd.[TitleId],
				rtd.[ReleaseNoteHeaderId],
				rtd.[Title],
				rtd.[SprintName],
				WT.[WorkType] AS [Type],
				rtd.[Description] AS TitleDescription
			FROM DBO.[ReleaseNotesTitleDetails] rtd WITH (NOLOCK) 
			INNER JOIN DBO.[ReleaseNoteHeadersDetails] rh WITH(NOLOCK) ON rtd.[ReleaseNoteHeaderId] = rh.[ReleaseNoteHeaderId]
			LEFT JOIN DBO.[WorkType] WT WITH(NOLOCK) ON rtd.TypeId = WT.WorkTypeId
			WHERE rh. IsActive = @IsActive and rh.IsDeleted = @IsDelete 
		) AS Titles;
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