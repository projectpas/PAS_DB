/*************************************************************
 ** File:   [USP_GetDocumentExpirationFilterOptions]
 ** Author: SAHDEV SALIYA
 ** Description: Cascading option lists for the Document Expiration Report header filters
 **              (GlobalFilter rows "Document Type" and "Document Name" have no TableName, so the screen loads them here).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date               Author          Change Description
 ** --   --------           -------         ---------------------------
    1    26/Oct/2026    SAHDEV SALIYA       Created.
 **************************************************************
 EXEC USP_GetDocumentExpirationFilterOptions @MasterCompanyId = 1, @FilterType = 'DocumentType', @ModuleIds = '1,2'
 EXEC USP_GetDocumentExpirationFilterOptions @MasterCompanyId = 1, @FilterType = 'DocumentName', @DocumentTypeIds = '3', @SearchText = 'cert'
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetDocumentExpirationFilterOptions]
@MasterCompanyId INT,
@FilterType VARCHAR(20),
@ModuleIds VARCHAR(MAX) = NULL,
@DocumentTypeIds VARCHAR(MAX) = NULL,
@SearchText VARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    SET @SearchText = NULLIF(LTRIM(RTRIM(@SearchText)), '');

    IF @FilterType = 'ReportModuleId'
    BEGIN
      SELECT TOP (1) CAST(RM.ModuleId AS VARCHAR(20)) AS [Value], RM.ReportTitle AS [Label]
      FROM dbo.ReportMaster RM WITH (NOLOCK)
      WHERE RM.SPname IN ('usprpt_GetDocumentExpirationReport', 'dbo.usprpt_GetDocumentExpirationReport')
      ORDER BY RM.ModuleId;
    END
    ELSE IF @FilterType = 'DocumentType'
    BEGIN
      IF ISNULL(@ModuleIds, '') = ''
      BEGIN
        SELECT DT.DocumentTypeId AS [Value], UPPER(DT.[Name]) AS [Label]
        FROM dbo.DocumentType DT WITH (NOLOCK)
        WHERE DT.MasterCompanyId = @MasterCompanyId
          AND DT.IsActive = 1
          AND DT.IsDeleted = 0
        ORDER BY [Label];
      END
      ELSE
      BEGIN
        SELECT DISTINCT DT.DocumentTypeId AS [Value], UPPER(DT.[Name]) AS [Label]
        FROM dbo.CommonDocumentDetails CDD WITH (NOLOCK)
        INNER JOIN dbo.DocumentType DT WITH (NOLOCK) ON DT.DocumentTypeId = CDD.DocumentTypeId
        WHERE CDD.MasterCompanyId = @MasterCompanyId
          AND CDD.IsActive = 1
          AND CDD.IsDeleted = 0
          AND CDD.ModuleId IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleIds, ','))
        ORDER BY [Label];
      END
    END
    ELSE IF @FilterType = 'DocumentName'
    BEGIN
      IF ISNULL(@DocumentTypeIds, '') = '' AND @SearchText IS NULL
        RETURN (0);

      -- Same name expression as usprpt_GetDocumentExpirationReport (DocName, else the file name)
      SELECT DISTINCT TOP (50) N.DocumentName AS [Value], N.DocumentName AS [Label]
      FROM dbo.CommonDocumentDetails CDD WITH (NOLOCK)
      LEFT JOIN dbo.AttachmentDetails AD WITH (NOLOCK) ON AD.AttachmentId = CDD.AttachmentId AND ISNULL(AD.IsActive, 1) = 1 AND ISNULL(AD.IsDeleted, 0) = 0
      CROSS APPLY (SELECT ISNULL(NULLIF(CDD.DocName, ''), AD.[FileName]) AS DocumentName) N
      WHERE CDD.MasterCompanyId = @MasterCompanyId
        AND CDD.IsActive = 1
        AND CDD.IsDeleted = 0
        AND N.DocumentName IS NOT NULL
        AND (ISNULL(@ModuleIds, '') = '' OR CDD.ModuleId IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleIds, ',')))
        AND (ISNULL(@DocumentTypeIds, '') = '' OR CDD.DocumentTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@DocumentTypeIds, ',')))
        AND (@SearchText IS NULL OR N.DocumentName LIKE '%' + @SearchText + '%')
      ORDER BY [Label];
    END
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
      @DatabaseName VARCHAR(100) = DB_NAME()
      -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
      ,@AdhocComments VARCHAR(150) = '[USP_GetDocumentExpirationFilterOptions]'
      ,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId,'') AS VARCHAR(100)) +
        ''', @FilterType = ''' + ISNULL(@FilterType,'') +
        ''', @ModuleIds = ''' + ISNULL(@ModuleIds,'') +
        ''', @DocumentTypeIds = ''' + ISNULL(@DocumentTypeIds,'') +
        ''', @SearchText = ''' + ISNULL(@SearchText,'') + ''''
      ,@ApplicationName VARCHAR(100) = 'PAS'
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