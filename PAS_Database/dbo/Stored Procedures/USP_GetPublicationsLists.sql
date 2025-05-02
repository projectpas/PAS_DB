/************************************************************************************           
 ** File:   [USP_GetPublicationsLists]           
 ** Author: 
 ** Description: This stored procedure is used to get USP_GetPublicationsLists.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    5-01-2025			Amit Ghediya			Created

	 EXEC [dbo].[USP_GetPublicationsLists] '7,15',225,1
****************************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetPublicationsLists]
	@PublicationIds VARCHAR(1000) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@EmployeeId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
			
				DECLARE @ManufactureTypeId INT;
				DECLARE @VendorTypeId INT;

				SET @ManufactureTypeId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Manufacturer');
				SET @VendorTypeId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor');

				SELECT DISTINCT p.PublicationRecordId,
				       p.RevisionNum,
					   p.PublicationId,
					   p.[Description],
					   pt.[Name] AS PublicationType,
					   pemp.ModuleName AS PublishedBy,
					   CASE WHEN p.PublishedById = @ManufactureTypeId THEN ISNULL(M.[Name],'') WHEN p.PublishedById = @VendorTypeId THEN ISNULL(V.VendorName,'') ELSE ISNULL(p.PublishedByOthers,'') END  AS PublishedByName
				  FROM [dbo].[Publication] p WITH (NOLOCK)
				  LEFT JOIN [dbo].[PublicationType] pt WITH (NOLOCK) ON p.PublicationTypeId = pt.PublicationTypeId
				  LEFT JOIN [dbo].[Module] pemp WITH (NOLOCK) ON p.PublishedById = pemp.ModuleId 
				  LEFT JOIN [dbo].[Manufacturer] M with (NOLOCK) ON p.PublishedByRefId = M.ManufacturerId
				  LEFT JOIN [dbo].[Vendor] V with (NOLOCK) ON p.PublishedByRefId = V.VendorId
				  WHERE p.PublicationRecordId IN(SELECT Item FROM DBO.SPLITSTRING(@PublicationIds,','))

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPublicationsLists' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PublicationIds, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END