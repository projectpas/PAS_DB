/*************************************************************
 ** File:   [USP_GetCustomerATAMappingByFilters]
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to search Customer ATAMappingData By MultiTypeId ATAID and ATASUBID
 ** Purpose:
 ** Date:   05/19/2025
    
 ** PARAMETERS: @CustomerId BIGINT, @ContactIdList NVARCHAR(MAX), @ATAChapterIdList NVARCHAR(MAX), @ATASubChapterIdList NVARCHAR(MAX)

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    05/19/2025   EKTA CHANDEGRA	Created
	

exec dbo.USP_GetCustomerATAMappingByFilters @CustomerId=4301,@ContactIdList=N'13104,13114',@ATAChapterIdList=NULL,@ATASubChapterIdList=NULL
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerATAMappingByFilters]
    @CustomerId BIGINT,
    @ContactIdList NVARCHAR(MAX),
    @ATAChapterIdList NVARCHAR(MAX),
    @ATASubChapterIdList NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-- Convert comma-separated strings into table variables
		DECLARE @ATAChapterIds TABLE (Id BIGINT);
		DECLARE @ATASubChapterIds TABLE (Id BIGINT);
		DECLARE @ContactIds TABLE (Id BIGINT);


		-- Split the strings into table values
		IF @ATAChapterIdList IS NOT NULL AND LTRIM(RTRIM(@ATAChapterIdList)) <> ''
		BEGIN
			INSERT INTO @ATAChapterIds (Id)
			SELECT CAST(value AS BIGINT)
			FROM STRING_SPLIT(@ATAChapterIdList, ',')
			WHERE value <> '';
		END

		IF @ATASubChapterIdList IS NOT NULL AND LTRIM(RTRIM(@ATASubChapterIdList)) <> ''
		BEGIN
			INSERT INTO @ATASubChapterIds (Id)
			SELECT CAST(value AS BIGINT)
			FROM STRING_SPLIT(@ATASubChapterIdList, ',')
			WHERE value <> '';
		END

		IF @ContactIdList IS NOT NULL AND LTRIM(RTRIM(@ContactIdList)) <> ''
		BEGIN
			INSERT INTO @ContactIds (Id)
			SELECT CAST(value AS BIGINT)
			FROM STRING_SPLIT(@ContactIdList, ',')
			WHERE value <> '';
		END

		-- Main query
		IF @ATAChapterIdList IS NOT NULL AND @ATASubChapterIdList IS NOT NULL AND @ContactIdList IS NOT NULL 
		BEGIN
			 SELECT
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = cATA.Level1
					+ CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END
					+ CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE
				cATA.CustomerId = @CustomerId
				AND cATA.ATAChapterId IN (SELECT Id FROM @ATAChapterIds)
				AND cATA.ATASubChapterId IN (SELECT Id FROM @ATASubChapterIds)
				AND cont.ContactId IN (SELECT Id FROM @ContactIds)
				AND ISNULL(cATA.IsDeleted,0) = 0
		END

		IF @ATAChapterIdList IS NOT NULL AND @ATASubChapterIdList IS NULL AND @ContactIdList IS NULL
		BEGIN
			SELECT
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				ATASubChapterDescription = ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				cATA.ATASubChapterId,
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					cATA.Level1 + 
					CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END + 
					CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE
				cATA.CustomerId = @CustomerId
				AND cATA.ATAChapterId IN (SELECT Id FROM @ATAChapterIds)
				AND ISNULL(cATA.IsDeleted, 0) <> 1
	   END

	   IF @ATAChapterIdList IS NOT NULL AND @ATASubChapterIdList IS NULL AND @ContactIdList IS NOT NULL
	   BEGIN
			SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					cATA.Level1 
					+ CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END
					+ CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
		FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
		INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
		LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
		LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
		WHERE 
			cATA.CustomerId = @CustomerId
			AND cATA.ATAChapterId IN (SELECT Id FROM @ATAChapterIds)
			AND cont.ContactId IN (SELECT Id FROM @ContactIds)
			AND ISNULL(cATA.IsDeleted, 0) = 0;

	   END

	   IF @ATAChapterIdList IS NULL AND @ATASubChapterIdList IS NOT NULL AND @ContactIdList IS NOT NULL
	   BEGIN
			 SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					cATA.Level1 
					+ CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END
					+ CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE 
				cATA.CustomerId = @CustomerId
				AND cATA.ATASubChapterId IN (SELECT Id FROM @ATASubChapterIds)
				AND cont.ContactId IN (SELECT Id FROM @ContactIds)
				AND ISNULL(cATA.IsDeleted, 0) = 0;
	   END

	   IF @ATAChapterIdList IS NULL AND @ATASubChapterIdList IS NOT NULL AND @ContactIdList IS NULL
	   BEGIN
			SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					cATA.Level1
					+ CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END
					+ CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA  WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE 
				cATA.CustomerId = @CustomerId
				AND cATA.ATASubChapterId IN (SELECT Id FROM @ATASubChapterIds)
				AND ISNULL(cATA.IsDeleted, 0) = 0;
	   END

	   IF @ATAChapterIdList IS NOT NULL AND @ATASubChapterIdList IS NOT NULL AND @ContactIdList IS NULL
	   BEGIN 
			SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					cATA.Level1
					+ CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END
					+ CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE 
				cATA.CustomerId = @CustomerId
				AND cATA.ATAChapterId IN (SELECT Id FROM @ATAChapterIds)
				AND cATA.ATASubChapterId IN (SELECT Id FROM @ATASubChapterIds)
				AND ISNULL(cATA.IsDeleted, 0) = 0;
	   END

	   IF @ATAChapterIdList IS NULL AND @ATASubChapterIdList IS NULL AND @ContactIdList IS NOT NULL
	   BEGIN
			SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					ISNULL(cATA.Level1, '') +
					CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END +
					CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE 
				cATA.CustomerId = @CustomerId
				AND cont.ContactId IN (SELECT Id FROM @ContactIds)
				AND ISNULL(cATA.IsDeleted, 0) = 0;
	   END

	   ELSE
	   BEGIN
			SELECT 
				cATA.CustomerContactATAMappingId,
				cATA.CustomerId,
				cATA.ATAChapterId,
				ISNULL(cATA.ATAChapterCode,'') AS ATAChapterCode,
				cATA.ATASubChapterId,
				ATASubChapterDescription = 
					ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(cATA.ATASubChapterDescription, ''),
				contt.FirstName,
				cATA.CreatedBy,
				cATA.CreatedDate,
				cATA.UpdatedBy,
				cATA.UpdatedDate,
				contt.ContactId,
				ATAChapterName = 
					ISNULL(cATA.Level1, '') +
					CASE WHEN ISNULL(cATA.Level2, '') <> '' THEN '-' + cATA.Level2 ELSE '' END +
					CASE WHEN ISNULL(cATA.Level3, '') <> '' THEN '-' + cATA.Level3 ELSE '' END
			FROM [dbo].[CustomerContactATAMapping] cATA WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerContact] cont WITH(NOLOCK) ON cATA.CustomerContactId = cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] contt WITH(NOLOCK) ON cont.ContactId = contt.ContactId
			LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON cATA.ATASubChapterId = atasub.ATASubChapterId
			WHERE 
				cATA.CustomerId = @CustomerId
				AND ISNULL(cATA.IsDeleted, 0) = 0;
	   END

	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerATAMappingByFilters'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@CustomerId AS varchar(10)) ,'') +''',
												 @Parameter2 = ' + ISNULL(CAST(@ContactIdList AS varchar(10)) ,'') +'''
												 @Parameter3 = ' + ISNULL(CAST(@ATAChapterIdList AS varchar(10)) ,'') +'''
												 @Parameter4 = ' + ISNULL(CAST(@ATASubChapterIdList AS varchar(10)) ,'') +''

        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END