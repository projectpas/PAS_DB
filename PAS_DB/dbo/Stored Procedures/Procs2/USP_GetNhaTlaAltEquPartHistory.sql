/*************************************************************           
 ** File:   [USP_GetNhaTlaAltEquPartHistory]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to GetNhaTlaAltEquPartHistory List
 ** Purpose:         
 ** Date:   31-10-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    31-10-2025    Sahdev Saliya       Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

	exec [dbo].[USP_GetNhaTlaAltEquPartHistory]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetNhaTlaAltEquPartHistory]
   @ItemMappingId BIGINT = NULL,
   @EmployeeId BIGINT = NULL,
   @Opr INT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @ModuleId INT 
	SELECT @ModuleId = [AttachmentModuleId] FROM dbo.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'NhaTlaAltEquItemMapping'

	IF (@Opr=1) 
	BEGIN

    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT
        @CurrntEmpTimeZoneDesc = COALESCE(
            ETZ.[Description],  -- Employee's timezone
            LTZ.[Description]   -- Fallback to LegalEntity timezone
        )
		FROM dbo.Employee E WITH (NOLOCK)
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK)
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK)
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK)
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;
	    
	SELECT  alt.NhaTlaAltEquAuditId,
			alt.ItemMappingId,
			im.ItemMasterId,
			im1.ManufacturerId,
			alt.MappingItemMasterId,
			alt.MappingType,
			im.PartNumber,
			im.PartDescription,
			man.[Name] AS Manufacturer,
			im1.PartNumber AS AltPartNo,
			im1.PartDescription AS AltPartDescription,
			alt.IsActive,
			alt.IsDeleted,
			alt.CreatedBy,
			CreatedDate = CAST(DBO.ConvertUTCtoLocal(alt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),
			alt.UpdatedBy,
			UpdatedDate = CAST(DBO.ConvertUTCtoLocal(alt.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),						
			ic.[Description] AS ItemClassification,
			alt.CustomerId,
			cust.[Name]
		FROM dbo.NhaTlaAltEquAudit alt WITH (NOLOCK)
			INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON alt.ItemMasterId = im.ItemMasterId
			INNER JOIN dbo.ItemMaster im1 WITH (NOLOCK) ON alt.MappingItemMasterId = im1.ItemMasterId
			INNER JOIN dbo.Manufacturer man WITH (NOLOCK) ON im1.ManufacturerId = man.ManufacturerId
			INNER JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im1.ItemClassificationId = ic.ItemClassificationId
			LEFT JOIN dbo.Customer cust WITH (NOLOCK) ON alt.CustomerId = cust.CustomerId
		WHERE alt.ItemMappingId = @ItemMappingId
      
	 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(im1.IsNonStock,0) = 0 END
	IF (@Opr = 2)
	BEGIN
		SELECT AD.[AttachmentDetailId]
			  ,AD.[AttachmentId]
			  ,AD.[FileName]
			  ,AD.[Description]
			  ,AD.[Link]
			  ,AD.[FileFormat]
			  ,AD.[FileSize]
			  ,AD.[FileType]
			  ,AD.[CreatedDate]
			  ,AD.[UpdatedDate]
			  ,AD.[CreatedBy]
			  ,AD.[UpdatedBy]
			  ,AD.[IsActive]
			  ,AD.[IsDeleted]
			  ,AD.[Name]
			  ,AD.[Memo]
			  ,AD.[TypeId] 
			FROM dbo.Attachment ATT WITH (NOLOCK)
            INNER JOIN dbo.AttachmentDetails AD WITH (NOLOCK) ON ATT.AttachmentId = AD.AttachmentId
            WHERE ATT.ReferenceId = @ItemMappingId
              AND ATT.ModuleId = @ModuleId
            ORDER BY AD.AttachmentDetailId DESC;
	END

   END TRY
    BEGIN CATCH
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetNhaTlaAltEquPartHistory'
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
	 END CATCH
END