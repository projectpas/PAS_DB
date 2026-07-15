
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_NhaTlaAltEquPartList   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_NhaTlaAltEquPartList.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_NhaTlaAltEquPartList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get NhaTlaAltEquPart List
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

    exec [dbo].[USP_NhaTlaAltEquPartList]
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_NhaTlaAltEquPartList]
    @SortField VARCHAR(256) = NULL,
	@SortOrder VARCHAR(256) = NULL,
    @ItemMasterId BIGINT = NULL,
    @MappingItemMasterId BIGINT = NULL,
	@Description VARCHAR(256) = NULL,
    @ManufacturerId BIGINT = NULL,
	@MappingType VARCHAR(50) = NULL,
	@ItemClassificationId  BIGINT = NULL,
    @IsDeleted BIT = NULL,
    @EmployeeId BIGINT = NULL,
	@ItemMappingId BIGINT = NULL,
	@First VARCHAR(256) = NULL,
	@Rows VARCHAR(256) = NULL,
	@TotalRecords INT = NULL,
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

    SET @MappingItemMasterId = CASE WHEN @MappingItemMasterId = 0 THEN NULL ELSE @MappingItemMasterId END
	SET @ManufacturerId = CASE WHEN @ManufacturerId IS NULL THEN 0 ELSE @ManufacturerId END
	SET @ItemClassificationId = CASE WHEN @ItemClassificationId IS NULL THEN 0 ELSE @ItemClassificationId END
	
    SELECT 
        @TotalRecords = COUNT(DISTINCT alt.ItemMappingId)
    FROM dbo.Nha_Tla_Alt_Equ_ItemMapping alt WITH (NOLOCK)
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON alt.MappingItemMasterId = im.ItemMasterId
        INNER JOIN dbo.ItemMaster im1 WITH (NOLOCK) ON alt.MappingItemMasterId = im1.ItemMasterId
        INNER JOIN dbo.Manufacturer man WITH (NOLOCK) ON im.ManufacturerId = man.ManufacturerId
		INNER JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
      WHERE alt.[IsActive] = 1
        AND alt.IsDeleted = @IsDeleted
        AND alt.ItemMasterId = @ItemMasterId
        AND alt.MappingType = @MappingType
        AND alt.MappingItemMasterId = ISNULL(@MappingItemMasterId,alt.MappingItemMasterId)
		AND	(@Description IS NULL OR @Description = '' OR im.PartDescription LIKE '%' + @Description + '%')
        AND (@ManufacturerId = 0 OR im.ManufacturerId = @ManufacturerId)
	    AND (@ItemClassificationId = 0 OR im.ItemClassificationId = @ItemClassificationId) AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(im1.IsNonStock,0) = 0 ;

     SELECT alt.ItemMappingId,
            im.PartNumber,
            im.PartDescription,
            man.[Name] AS Manufacturer,
            im1.ManufacturerId,
            im.ItemMasterId,
            im1.PartNumber AS AltPartNo,
            alt.MappingItemMasterId,
            im1.PartDescription AS AltPartDescription,
            alt.IsActive,
            alt.IsDeleted,
            alt.CreatedBy,
			CreatedDate = CAST(DBO.ConvertUTCtoLocal(alt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),
            alt.MasterCompanyId,
            alt.UpdatedBy,
			UpdatedDate = CAST(DBO.ConvertUTCtoLocal(alt.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),						
            alt.MappingType,
			alt.Memo,
            im1.ItemClassificationId,
			ic.[Description] AS ItemClassification,
            @TotalRecords AS TotalRecords                       
        FROM dbo.Nha_Tla_Alt_Equ_ItemMapping alt WITH (NOLOCK)
            INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON alt.ItemMasterId = im.ItemMasterId
            INNER JOIN dbo.ItemMaster im1 WITH (NOLOCK) ON alt.MappingItemMasterId = im1.ItemMasterId
            INNER JOIN dbo.Manufacturer man WITH (NOLOCK) ON im1.ManufacturerId = man.ManufacturerId
			INNER JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im1.ItemClassificationId = ic.ItemClassificationId          
          WHERE alt.[IsActive] = 1
            AND alt.IsDeleted = @IsDeleted
            AND alt.ItemMasterId = @ItemMasterId
			AND alt.MappingType = @MappingType
			AND alt.MappingItemMasterId = ISNULL(@MappingItemMasterId,alt.MappingItemMasterId)
			AND	(@Description IS NULL OR @Description = '' OR im1.PartDescription LIKE '%' + @Description + '%')
			AND (@ManufacturerId = 0 OR im1.ManufacturerId = @ManufacturerId)
			AND (@ItemClassificationId = 0 OR im1.ItemClassificationId = @ItemClassificationId) AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(im1.IsNonStock,0) = 0 ;
	END
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
				AND ISNULL(ATT.IsDeleted,0) = 0
				AND ISNULL(ATT.IsActive,0) = 1
			ORDER BY AD.AttachmentDetailId DESC;
	END
    END TRY
    BEGIN CATCH
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_NhaTlaAltEquPartList'
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